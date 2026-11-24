#!/usr/bin/env bash
# Modul SHADOW LINEAGE (OSINT) - Native Engine

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

clear
bxp_ascii_title "SHADOW LINEAGE"

# Deteksi Root / Non-Root secara REAL
if [ "$(id -u)" -eq 0 ]; then
    STATUS_TXT="${G}[+] ROOT MODE${N}"
else
    STATUS_TXT="${R}[!] NON-ROOT MODE${N}"
fi

# UI BORDER (Pake warna Cyan / ${C})
echo -e "${C}  ==================================================${N}"
echo -e "     ${W}SHADOW LINEAGE RECONNAISSANCE${N}"
echo -e "     Status: ${STATUS_TXT}"
echo -e "${C}  ==================================================${N}"
echo ""
echo -e "  \033[1;32m[1]\033[0m  ${W}Scan Single Target (Standard)${N}"
echo ""
echo -e "  \033[1;32m[2]\033[0m  ${W}Scan From Custom Wordlist${N}"
echo ""
echo -e "  \033[1;32m[3]\033[0m  ${W}Filter Only Alive Subdomains${N}"
echo ""
echo -e "  \033[1;32m[4]\033[0m  ${W}Export Results to TXT${N}"
echo ""
echo -e "  \033[1;31m[0]\033[0m  ${W}Back to Main Menu${N}"
echo ""
echo -e "${C}  --------------------------------------------------${N}"
echo ""
echo -ne "  ${Y}Select option > ${N}"
read -r choice

# ---------------------------------------------------------
# LOGIC RACIKAN MURNI (Native Engine)
# ---------------------------------------------------------

DEFAULT_WORDLIST=("www" "mail" "ftp" "admin" "api" "dev" "test" "blog" "vpn" "cpanel" "webmail" "ns1" "ns2" "smtp" "pop")

scan_subdomain() {
    local domain="$1"
    local wordlist_file="$2"
    local found_count=0
    
    echo -e "\n  ${Y}[*] Scanning target: ${W}$domain${N}"
    echo -e "  ${C}--------------------------------------------------${N}"
    
    local words=()
    if [ -n "$wordlist_file" ] && [ -f "$wordlist_file" ]; then
        mapfile -t words < "$wordlist_file"
    else
        words=("${DEFAULT_WORDLIST[@]}")
    fi

    for sub in "${words[@]}"; do
        [ -z "$sub" ] && continue
        
        local target="$sub.$domain"
        # RACIKAN NATIVE: Nembak DNS resolver pake getent
        if getent hosts "$target" > /dev/null 2>&1; then
            local ip=$(getent hosts "$target" | awk '{print $1}' | head -n 1)
            echo -e "  ${G}[+] FOUND:${N} $target ${C}->${N} ${W}$ip${N}"
            echo "$target" >> .shadow_results.tmp
            ((found_count++))
        else
            echo -e "  ${R}[-] NOT FOUND:${N} $target"
        fi
    done
    
    echo -e "  ${C}--------------------------------------------------${N}"
    echo -e "  ${G}[*] Scan complete. Found ${W}$found_count${N}${G} subdomains.${N}"
}

case "$choice" in
    1)
        echo ""
        read -p "  Enter target domain (e.g., example.com) > " target
        [ -z "$target" ] && { echo -e "  ${R}[!] Domain cannot be empty.${N}"; sleep 2; exit 1; }
        
        rm -f .shadow_results.tmp
        scan_subdomain "$target" ""
        
        if [ -f .shadow_results.tmp ]; then
            mv .shadow_results.tmp "results_${target}.txt"
            echo -e "  ${G}[+] Results saved to: results_${target}.txt${N}"
        fi
        read -p "  Press Enter to return..."
        ;;
    2)
        echo ""
        read -p "  Enter target domain (e.g., example.com) > " target
        read -p "  Enter path to wordlist > " wordpath
        [ -z "$target" ] && { echo -e "  ${R}[!] Domain cannot be empty.${N}"; sleep 2; exit 1; }
        [ ! -f "$wordpath" ] && { echo -e "  ${R}[!] Wordlist not found!${N}"; sleep 2; exit 1; }
        
        rm -f .shadow_results.tmp
        scan_subdomain "$target" "$wordpath"
        
        if [ -f .shadow_results.tmp ]; then
            mv .shadow_results.tmp "results_${target}.txt"
            echo -e "  ${G}[+] Results saved to: results_${target}.txt${N}"
        fi
        read -p "  Press Enter to return..."
        ;;
    3)
        echo ""
        echo -e "  ${Y}[*] Checking Alive Subdomains (HTTP 200)...${N}"
        
        local_file=$(ls -t results_*.txt 2>/dev/null | head -n 1)
        if [ -z "$local_file" ]; then
            echo -e "  ${R}[!] No results file found. Run Scan (Menu 1/2) first.${N}"
            sleep 2; exit 1
        fi
        
        echo -e "  ${C}[*] Using file: $local_file${N}"
        echo -e "  ${C}--------------------------------------------------${N}"
        
        while IFS= read -r subdomain; do
            [ -z "$subdomain" ] && continue
            # RACIKAN NATIVE: Nembak HTTP pake bxp_curl (otomatis lewat Tor kalo nyala)
            status_code=$(bxp_curl -o /dev/null -s -w "%{http_code}" --connect-timeout 3 "http://$subdomain")
            
            if [ "$status_code" == "200" ] || [ "$status_code" == "301" ] || [ "$status_code" == "302" ]; then
                echo -e "  ${G}[+] ALIVE:${N} $subdomain ${C}(HTTP $status_code)${N}"
            else
                echo -e "  ${R}[-] DEAD:${N} $subdomain ${C}(HTTP $status_code)${N}"
            fi
        done < "$local_file"
        
        read -p "  Press Enter to return..."
        ;;
    4)
        echo ""
        local_file=$(ls -t results_*.txt 2>/dev/null | head -n 1)
        if [ -z "$local_file" ]; then
            echo -e "  ${R}[!] No results file found. Run Scan first.${N}"
            sleep 2; exit 1
        fi
        
        echo -e "  ${G}[+] Exported results are available at:${N}"
        echo -e "      ${W}$(pwd)/$local_file${N}"
        echo -e "  ${Y}[*] You can use 'cat $local_file' to view it.${N}"
        read -p "  Press Enter to return..."
        ;;
    0)
        exit 0
        ;;
    *)
        echo -e "\n  ${R}[!] Invalid choice.${N}"
        sleep 1
        ;;
esac
