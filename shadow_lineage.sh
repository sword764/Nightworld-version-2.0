#!/usr/bin/env bash
# Modul SHADOW LINEAGE (OSINT) - Native Engine

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

clean_domain() {
    local raw="$1"
    raw=$(echo "$raw" | sed -e 's|^[^/]*//||')
    raw=$(echo "$raw" | cut -d'/' -f1)
    raw=$(echo "$raw" | tr -d ' ')
    echo "$raw"
}

while true; do
    clear
    bxp_ascii_title "SHADOW LINEAGE"

    # Panggil dependency 'dig'
    bxp_require "dig"

    if [ "$(id -u)" -eq 0 ]; then
        STATUS_TXT="${G}[+] ROOT MODE${N}"
    else
        STATUS_TXT="${R}[!] NON-ROOT MODE${N}"
    fi

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
            local ip=$(dig +short "$target" | head -n 1)
            
            if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
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
            while true; do
                echo ""
                read -p "  Enter target domain (e.g., example.com) > " target
                if [ -z "$target" ]; then
                    echo -e "  ${R}[!] Domain cannot be empty. Please try again.${N}"
                    sleep 1
                    continue
                fi
                if [ "$target" == "0" ]; then break; fi
                
                target=$(clean_domain "$target")
                rm -f .shadow_results.tmp
                scan_subdomain "$target" ""
                
                if [ -f .shadow_results.tmp ]; then
                    mv .shadow_results.tmp "results_${target}.txt"
                    echo -e "  ${G}[+] Results saved to: results_${target}.txt${N}"
                fi
                
                echo ""
                read -p "  Press Enter to return to Shadow Lineage menu..."
                break
            done
            ;;
        2)
            while true; do
                echo ""
                read -p "  Enter target domain (e.g., example.com) > " target
                if [ -z "$target" ]; then
                    echo -e "  ${R}[!] Domain cannot be empty. Please try again.${N}"
                    sleep 1
                    continue
                fi
                if [ "$target" == "0" ]; then break; fi
                
                target=$(clean_domain "$target")
                
                read -p "  Enter path to wordlist (or 0 to cancel) > " wordpath
                if [ "$wordpath" == "0" ]; then break; fi
                if [ ! -f "$wordpath" ]; then
                    echo -e "  ${R}[!] Wordlist not found! Please check the path.${N}"
                    sleep 2
                    continue
                fi
                
                rm -f .shadow_results.tmp
                scan_subdomain "$target" "$wordpath"
                
                if [ -f .shadow_results.tmp ]; then
                    mv .shadow_results.tmp "results_${target}.txt"
                    echo -e "  ${G}[+] Results saved to: results_${target}.txt${N}"
                fi
                
                echo ""
                read -p "  Press Enter to return to Shadow Lineage menu..."
                break
            done
            ;;
        3)
            echo ""
            echo -e "  ${Y}[*] Checking Alive Subdomains (HTTP 200)...${N}"
            
            local_file=$(ls -t results_*.txt 2>/dev/null | head -n 1)
            if [ -z "$local_file" ]; then
                echo -e "  ${R}[!] No results file found. Run Scan (Menu 1/2) first.${N}"
                sleep 2
                continue 
            fi
            
            echo -e "  ${C}[*] Using file: $local_file${N}"
            echo -e "  ${C}--------------------------------------------------${N}"
            
            while IFS= read -r subdomain; do
                [ -z "$subdomain" ] && continue
                status_code=$(bxp_curl -o /dev/null -s -w "%{http_code}" --connect-timeout 3 "http://$subdomain")
                
                if [ "$status_code" == "200" ] || [ "$status_code" == "301" ] || [ "$status_code" == "302" ]; then
                    echo -e "  ${G}[+] ALIVE:${N} $subdomain ${C}(HTTP $status_code)${N}"
                else
                    echo -e "  ${R}[-] DEAD:${N} $subdomain ${C}(HTTP $status_code)${N}"
                fi
            done < "$local_file"
            
            echo ""
            read -p "  Press Enter to return to Shadow Lineage menu..."
            ;;
        4)
            echo ""
            local_file=$(ls -t results_*.txt 2>/dev/null | head -n 1)
            if [ -z "$local_file" ]; then
                echo -e "  ${R}[!] No results file found. Run Scan first.${N}"
                sleep 2
                continue 
            fi
            
            echo -e "  ${G}[+] Exported results are available at:${N}"
            echo -e "      ${W}$(pwd)/$local_file${N}"
            echo -e "  ${Y}[*] You can use 'cat $local_file' to view it.${N}"
            echo ""
            read -p "  Press Enter to return to Shadow Lineage menu..."
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "\n  ${R}[!] Invalid choice.${N}"
            sleep 1
            ;;
    esac
done
