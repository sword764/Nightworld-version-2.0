#!/usr/bin/env bash
# Modul BLOODHOUND (OSINT) - Native IP Geolocator

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

clean_domain() {
    local raw="$1"
    raw=$(echo "$raw" | sed -e 's|^[^/]*//||')
    raw=$(echo "$raw" | cut -d'/' -f1)
    raw=$(echo "$raw" | tr -d ' ')
    echo "$raw"
}

# Fungsi native buat narik data JSON pake grep
trace_ip() {
    local target="$1"
    echo -e "\n  ${Y}[*] Tracing target: ${W}$target${N}"
    echo -e "  ${C}--------------------------------------------------${N}"
    
    # Nembak API ip-api.com pake bxp_curl (biar lewat proxy kalo aktif)
    local json=$(bxp_curl "http://ip-api.com/json/$target")
    
    if echo "$json" | grep -q '"status":"fail"'; then
        echo -e "  ${R}[!] Target not found or invalid.${N}"
        return 1
    fi

    # Parsing JSON murni pake grep/sed
    local country=$(echo "$json" | grep -o '"country":"[^"]*' | cut -d'"' -f4)
    local city=$(echo "$json" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
    local isp=$(echo "$json" | grep -o '"isp":"[^"]*' | cut -d'"' -f4)
    local org=$(echo "$json" | grep -o '"org":"[^"]*' | cut -d'"' -f4)
    local lat=$(echo "$json" | grep -o '"lat":[^,]*' | cut -d':' -f2)
    local lon=$(echo "$json" | grep -o '"lon":[^,]*' | cut -d':' -f2)
    local ip=$(echo "$json" | grep -o '"query":"[^"]*' | cut -d'"' -f4)

    echo -e "  ${G}[+] IP Address :${N} ${W}$ip${N}"
    echo -e "  ${G}[+] Country    :${N} ${W}$country${N}"
    echo -e "  ${G}[+] City       :${N} ${W}$city${N}"
    echo -e "  ${G}[+] ISP        :${N} ${W}$isp${N}"
    echo -e "  ${G}[+] Org        :${N} ${W}$org${N}"
    echo -e "  ${G}[+] Coordinates:${N} ${W}$lat, $lon${N}"
    echo -e "  ${C}--------------------------------------------------${N}"
    
    # Simpen hasil ke file
    echo "$target | $ip | $country | $city | $isp | $org" >> .bloodhound_results.tmp
}

while true; do
    clear
    bxp_ascii_title "BLOODHOUND"

    if [ "$(id -u)" -eq 0 ]; then
        STATUS_TXT="${G}[+] ROOT MODE${N}"
    else
        STATUS_TXT="${R}[!] NON-ROOT MODE${N}"
    fi

    echo -e "${C}  ==================================================${N}"
    echo -e "     ${W}BLOODHOUND RECONNAISSANCE${N}"
    echo -e "     Status: ${STATUS_TXT}"
    echo -e "${C}  ==================================================${N}"
    echo ""
    echo -e "  \033[1;32m[1]\033[0m  ${W}Trace IP Location${N}"
    echo ""
    echo -e "  \033[1;32m[2]\033[0m  ${W}Trace Domain Location${N}"
    echo ""
    echo -e "  \033[1;32m[3]\033[0m  ${W}Bulk IP Scan (From File)${N}"
    echo ""
    echo -e "  \033[1;32m[4]\033[0m  ${W}Export Results to TXT${N}"
    echo ""
    echo -e "  \033[1;31m[0]\033[0m  ${W}Back to OSINT Menu${N}"
    echo ""
    echo -e "${C}  --------------------------------------------------${N}"
    echo ""
    echo -ne "  ${Y}Select option > ${N}"
    read -r choice

    case "$choice" in
        1|2)
            while true; do
                echo ""
                read -p "  Enter IP/Domain target (or 0 to cancel) > " target
                if [ -z "$target" ]; then
                    echo -e "  ${R}[!] Target cannot be empty.${N}"; sleep 1; continue
                fi
                if [ "$target" == "0" ]; then break; fi
                
                target=$(clean_domain "$target")
                rm -f .bloodhound_results.tmp
                
                trace_ip "$target"
                
                if [ -f .bloodhound_results.tmp ]; then
                    mv .bloodhound_results.tmp "bloodhound_${target}.txt"
                    echo -e "  ${G}[+] Results saved to: bloodhound_${target}.txt${N}"
                fi
                
                echo ""
                read -p "  Press Enter to return to Bloodhound menu..."
                break
            done
            ;;
        3)
            while true; do
                echo ""
                read -p "  Enter path to IP list file (or 0 to cancel) > " filepath
                [ -z "$filepath" ] && { echo -e "  ${R}[!] Path cannot be empty.${N}"; sleep 1; continue; }
                [ "$filepath" == "0" ] && break
                if [ ! -f "$filepath" ]; then
                    echo -e "  ${R}[!] File not found!${N}"; sleep 2; continue
                fi
                
                rm -f .bloodhound_results.tmp
                echo -e "\n  ${Y}[*] Processing bulk scan from: ${W}$filepath${N}"
                
                while IFS= read -r ip_line; do
                    [ -z "$ip_line" ] && continue
                    trace_ip "$ip_line"
                done < "$filepath"
                
                if [ -f .bloodhound_results.tmp ]; then
                    mv .bloodhound_results.tmp "bloodhound_bulk_results.txt"
                    echo -e "  ${G}[+] Bulk scan complete. Saved to: bloodhound_bulk_results.txt${N}"
                fi
                
                echo ""
                read -p "  Press Enter to return..."
                break
            done
            ;;
        4)
            echo ""
            local_file=$(ls -t bloodhound_*.txt 2>/dev/null | head -n 1)
            if [ -z "$local_file" ]; then
                echo -e "  ${R}[!] No results file found. Run Trace first.${N}"
                sleep 2; continue
            fi
            echo -e "  ${G}[+] Latest results: ${W}$(pwd)/$local_file${N}"
            echo -e "  ${Y}[*] Use 'cat $local_file' to view it.${N}"
            echo ""
            read -p "  Press Enter to return..."
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "\n  ${R}[!] Invalid choice.${N}"; sleep 1
            ;;
    esac
done
