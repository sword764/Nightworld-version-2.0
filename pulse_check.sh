#!/usr/bin/env bash
# Modul PULSE CHECK (OSINT) - Native TCP Port Scanner

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

clean_domain() {
    local raw="$1"
    raw=$(echo "$raw" | sed -e 's|^[^/]*//||')
    raw=$(echo "$raw" | cut -d'/' -f1)
    raw=$(echo "$raw" | tr -d ' ')
    echo "$raw"
}

# Fungsi pengecekan 1 port native pake /dev/tcp
check_port() {
    local host="$1"
    local port="$2"
    local timeout=1
    
    # Trik Bash native buat ngecek koneksi TCP
    if timeout "$timeout" bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "  ${G}[+] OPEN:${N} Port $port ${C}(TCP)${N}"
        echo "$port" >> .pulse_results.tmp
    fi
}

while true; do
    clear
    bxp_ascii_title "PULSE CHECK"

    if [ "$(id -u)" -eq 0 ]; then
        STATUS_TXT="${G}[+] ROOT MODE${N}"
    else
        STATUS_TXT="${R}[!] NON-ROOT MODE${N}"
    fi

    echo -e "${C}  ==================================================${N}"
    echo -e "     ${W}PULSE CHECK RECONNAISSANCE${N}"
    echo -e "     Status: ${STATUS_TXT}"
    echo -e "${C}  ==================================================${N}"
    echo ""
    echo -e "  \033[1;32m[1]\033[0m  ${W}Quick Scan (Top 20 Ports)${N}"
    echo ""
    echo -e "  \033[1;32m[2]\033[0m  ${W}Specific Port Scan${N}"
    echo ""
    echo -e "  \033[1;32m[3]\033[0m  ${W}Full Scan (1-1024)${N}"
    echo ""
    echo -e "  \033[1;32m[4]\033[0m  ${W}Export Results to TXT${N}"
    echo ""
    echo -e "  \033[1;31m[0]\033[0m  ${W}Back to OSINT Menu${N}"
    echo ""
    echo -e "${C}  --------------------------------------------------${N}"
    echo ""
    echo -ne "  ${Y}Select option > ${N}"
    read -r choice

    # Port list umum (Top 20)
    TOP_PORTS=(21 22 23 25 53 80 110 135 139 143 443 445 1433 1521 3306 3389 5432 8080 8443 27017)

    case "$choice" in
        1)
            while true; do
                echo ""
                read -p "  Enter target IP/Domain (or 0 to cancel) > " target
                if [ -z "$target" ]; then
                    echo -e "  ${R}[!] Target cannot be empty.${N}"; sleep 1; continue
                fi
                if [ "$target" == "0" ]; then break; fi
                
                target=$(clean_domain "$target")
                rm -f .pulse_results.tmp
                
                echo -e "\n  ${Y}[*] Scanning $target (Top 20 Ports)...${N}"
                echo -e "  ${C}--------------------------------------------------${N}"
                
                # Nembak port satu-satu pake fungsi native
                for port in "${TOP_PORTS[@]}"; do
                    check_port "$target" "$port"
                done
                
                echo -e "  ${C}--------------------------------------------------${N}"
                if [ -f .pulse_results.tmp ]; then
                    mv .pulse_results.tmp "pulse_results_${target}.txt"
                    echo -e "  ${G}[+] Scan complete. Results saved to: pulse_results_${target}.txt${N}"
                else
                    echo -e "  ${R}[-] Scan complete. No open ports found.${N}"
                fi
                
                echo ""
                read -p "  Press Enter to return to Pulse Check menu..."
                break
            done
            ;;
        2)
            while true; do
                echo ""
                read -p "  Enter target IP/Domain (or 0 to cancel) > " target
                [ -z "$target" ] && { echo -e "  ${R}[!] Empty input.${N}"; sleep 1; continue; }
                [ "$target" == "0" ] && break
                
                target=$(clean_domain "$target")
                
                read -p "  Enter specific port(s) separated by comma (e.g. 80,443,8080) > " port_input
                [ -z "$port_input" ] && { echo -e "  ${R}[!] Port cannot be empty.${N}"; sleep 1; continue; }
                [ "$port_input" == "0" ] && break
                
                # Ubah koma jadi spasi
                port_list=$(echo "$port_input" | tr ',' ' ')
                rm -f .pulse_results.tmp
                
                echo -e "\n  ${Y}[*] Scanning $target on specific ports...${N}"
                echo -e "  ${C}--------------------------------------------------${N}"
                
                for port in $port_list; do
                    check_port "$target" "$port"
                done
                
                echo -e "  ${C}--------------------------------------------------${N}"
                if [ -f .pulse_results.tmp ]; then
                    mv .pulse_results.tmp "pulse_results_${target}.txt"
                    echo -e "  ${G}[+] Results saved to: pulse_results_${target}.txt${N}"
                fi
                echo ""
                read -p "  Press Enter to return..."
                break
            done
            ;;
        3)
            while true; do
                echo ""
                read -p "  Enter target IP/Domain (or 0 to cancel) > " target
                [ -z "$target" ] && { echo -e "  ${R}[!] Empty input.${N}"; sleep 1; continue; }
                [ "$target" == "0" ] && break
                
                target=$(clean_domain "$target")
                rm -f .pulse_results.tmp
                
                echo -e "\n  ${Y}[*] Full Scan 1-1024 on $target (This may take a while)...${N}"
                echo -e "  ${C}--------------------------------------------------${N}"
                
                for port in {1..1024}; do
                    check_port "$target" "$port"
                done
                
                echo -e "  ${C}--------------------------------------------------${N}"
                if [ -f .pulse_results.tmp ]; then
                    mv .pulse_results.tmp "pulse_results_${target}.txt"
                    echo -e "  ${G}[+] Results saved to: pulse_results_${target}.txt${N}"
                else
                    echo -e "  ${R}[-] No open ports found.${N}"
                fi
                echo ""
                read -p "  Press Enter to return..."
                break
            done
            ;;
        4)
            echo ""
            local_file=$(ls -t pulse_results_*.txt 2>/dev/null | head -n 1)
            if [ -z "$local_file" ]; then
                echo -e "  ${R}[!] No results file found. Run Scan first.${N}"
                sleep 2; continue
            fi
            echo -e "  ${G}[+] Latest results: ${W}$(pwd)/$local_file${N}"
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
