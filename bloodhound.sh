#!/usr/bin/env bash
# Modul BLOODHOUND (OSINT) - Native IP Geolocator (3-Layer Fallback)

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

clean_domain() {
    local raw="$1"
    raw=$(echo "$raw" | sed -e 's|^[^/]*//||')
    raw=$(echo "$raw" | cut -d'/' -f1)
    raw=$(echo "$raw" | tr -d ' ')
    echo "$raw"
}

trace_ip() {
    local target="$1"
    
    # Filter IP Private
    if [[ "$target" =~ ^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.) ]]; then
        echo -e "\n  ${R}[!] Private IP Detected: ${W}$target${N}"
        echo -e "  ${Y}[*] Cannot trace local network IPs using public API.${N}"
        return 1
    fi

    echo -e "\n  ${Y}[*] Tracing target: ${W}$target${N}"
    echo -e "  ${C}--------------------------------------------------${N}"
    
    local ip="N/A"
    local country="N/A"
    local city="N/A"
    local org="N/A"
    local loc="N/A"
    local success=0

    # --- LAPIS 1: ip-api.com (HTTP, Cepet) ---
    local json1=$(bxp_curl "http://ip-api.com/json/$target")
    if echo "$json1" | grep -q '"status":"success"'; then
        ip=$(echo "$json1" | jq -r '.query')
        country=$(echo "$json1" | jq -r '.country')
        city=$(echo "$json1" | jq -r '.city')
        org=$(echo "$json1" | jq -r '.isp')
        local lat=$(echo "$json1" | jq -r '.lat')
        local lon=$(echo "$json1" | jq -r '.lon')
        loc="$lat, $lon"
        success=1
    fi

    # --- LAPIS 2: ipwhois.app (HTTPS) ---
    if [ "$success" -eq 0 ]; then
        local json2=$(bxp_curl "https://ipwhois.app/json/$target")
        if echo "$json2" | grep -q '"success":true'; then
            ip=$(echo "$json2" | jq -r '.ip')
            country=$(echo "$json2" | jq -r '.country')
            city=$(echo "$json2" | jq -r '.city')
            org=$(echo "$json2" | jq -r '.isp')
            local lat=$(echo "$json2" | jq -r '.latitude')
            local lon=$(echo "$json2" | jq -r '.longitude')
            loc="$lat, $lon"
            success=1
        fi
    fi

    # --- LAPIS 3: ipinfo.io (HTTPS) ---
    if [ "$success" -eq 0 ]; then
        local json3=$(bxp_curl "https://ipinfo.io/$target/json")
        if ! echo "$json3" | grep -q '"error"'; then
            ip=$(echo "$json3" | jq -r '.ip // "N/A"')
            country=$(echo "$json3" | jq -r '.country // "N/A"')
            city=$(echo "$json3" | jq -r '.city // "N/A"')
            org=$(echo "$json3" | jq -r '.org // "N/A"')
            loc=$(echo "$json3" | jq -r '.loc // "N/A"')
            if [ "$ip" != "N/A" ]; then success=1; fi
        fi
    fi

    # --- HASIL AKHIR ---
    if [ "$success" -eq 1 ]; then
        echo -e "  ${G}[+] IP Address :${N} ${W}$ip${N}"
        echo -e "  ${G}[+] Country    :${N} ${W}$country${N}"
        echo -e "  ${G}[+] City       :${N} ${W}$city${N}"
        echo -e "  ${G}[+] ISP/Org    :${N} ${W}$org${N}"
        echo -e "  ${G}[+] Coordinates:${N} ${W}$loc${N}"
        echo -e "  ${C}--------------------------------------------------${N}"
        echo "$target | $ip | $country | $city | $org | $loc" >> .bloodhound_results.tmp
    else
        echo -e "  ${R}[!] Failed to retrieve data. API Rate Limited or Target Invalid.${N}"
        echo -e "  ${C}--------------------------------------------------${N}"
    fi
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
