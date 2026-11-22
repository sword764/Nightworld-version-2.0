#!/usr/bin/env bash
# ============================================
#   MODULE: EXHUME DISGUISE (v5.0 Anti-Freeze)
# ============================================

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

show_ascii() {
    clear
    echo -e "\033[38;2;255;0;0m" # MERAH
    cat <<'ASCII'
███████╗██╗  ██╗██╗  ██╗██╗   ██╗███╗   ███╗███████╗    ██████╗ ██╗███████╗ ██████╗ ██╗   ██╗██╗███████╗███████╗
██╔════╝╚██╗██╔╝██║  ██║██║   ██║████╗ ████║██╔════╝    ██╔══██╗██║██╔════╝██╔════╝ ██║   ██║██║██╔════╝██╔════╝
█████╗   ╚███╔╝ ███████║██║   ██║██╔████╔██║█████╗      ██║  ██║██║███████╗██║  ███╗██║   ██║██║███████╗█████╗  
██╔══╝   ██╔██╗ ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝      ██║  ██║██║╚════██║██║   ██║██║   ██║██║╚════██║██╔══╝  
███████╗██╔╝ ██╗██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗    ██████╔╝██║███████║╚██████╔╝╚██████╔╝██║███████║███████╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝    ╚═════╝ ╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚══════╝
ASCII
    echo -e "\033[0m\n"
}

detect_env() {
    IS_TERMUX=0
    if [ -n "$PREFIX" ] && echo "$PREFIX" | grep -qi "com.termux"; then IS_TERMUX=1; fi
    if [ "$(id -u)" -eq 0 ]; then
        ROOT_MODE=1; STATUS_MSG="\033[1;32m[+] ROOT MODE ACTIVE\033[0m"
    else
        ROOT_MODE=0; STATUS_MSG="\033[1;33m[!] NON-ROOT MODE (LIMITED)\033[0m"
    fi
}

# --- FUNGSI CLEANUP (PAKE PKILL -9 BIAR MATI TOTAL) ---
cleanup() {
    echo -e "\n\033[0;33m[*] Memaksa proses berhenti & mengembalikan mode normal...\033[0m"
    pkill -9 -f "airodump-ng" 2>/dev/null
    pkill -9 -f "tcpdump" 2>/dev/null
    pkill -9 -f "aireplay-ng" 2>/dev/null
    pkill -9 -f "wpa_supplicant" 2>/dev/null
    if [ -n "$MON_IFACE" ]; then
        ip link set "$MON_IFACE" down 2>/dev/null
        iw dev "$MON_IFACE" set type managed 2>/dev/null
        ip link set "$MON_IFACE" up 2>/dev/null
    fi
    systemctl restart NetworkManager 2>/dev/null
    svc wifi enable 2>/dev/null
    sleep 1
}

trap cleanup SIGINT SIGTERM

while true; do
    show_ascii
    detect_env

    echo -e "${C}======================================================${N}"
    echo -e "${W}    HIDDEN SIGNAL & PROBE RECONNAISSANCE${N}"
    echo -e "    Status: $STATUS_MSG"
    echo -e "${C}======================================================${N}"
    echo ""
    echo -e "  \033[1;32m[1]\033[0m  \033[1;37mWi-Fi Scanner (Basic/Passive)\033[0m"
    if [ "$ROOT_MODE" -eq 1 ]; then
        echo -e "  \033[1;32m[2]\033[0m  \033[1;37mHidden SSID Extractor (Root Only)\033[0m"
        echo -e "  \033[1;32m[3]\033[0m  \033[1;37mProbe Request Sniffer (Root Only)\033[0m"
    else
        echo -e "  \033[1;30m[2] Hidden SSID Extractor (Requires Root)\033[0m"
        echo -e "  \033[1;30m[3] Probe Request Sniffer (Requires Root)\033[0m"
    fi
    echo -e "  \033[1;32m[4]\033[0m  \033[1;37mMAC Vendor Lookup\033[0m"
    echo ""
    echo -e "  \033[1;31m[0]\033[0m  \033[1;37mBack to Main Menu\033[0m"
    echo ""
    echo -e "${C}------------------------------------------------------${N}"
    echo -ne "  ${Y}Select option > ${N}"
    read -r echo_choice

    case "$echo_choice" in
        1)
            echo -e "\n${Y}[*] Menjalankan Wi-Fi Scanner...${N}"
            if [ "$IS_TERMUX" -eq 1 ]; then
                if ! command -v termux-wifi-scaninfo >/dev/null 2>&1; then
                    echo -e "\033[0;31m[!] ERROR: termux-api tidak ditemukan.\033[0m"; read -p "Press Enter..."; continue
                fi
                if ! command -v jq >/dev/null 2>&1; then pkg install jq -y >/dev/null 2>&1; fi
                termux-wifi-scaninfo | jq -r '.[] | "SSID: \(.SSID // .ssid // "Hidden") | BSSID: \(.BSSID // .bssid // "N/A") | Signal: \(.RSSI // .rssi // "N/A") dBm"' 2>/dev/null || termux-wifi-scaninfo
            else
                if command -v nmcli >/dev/null 2>&1; then nmcli -f SSID,BSSID,SIGNAL dev wifi list; else iw dev | grep -E "SSID|signal"; fi
            fi
            read -p "Press Enter to continue..."
            ;;
        2)
            if [ "$ROOT_MODE" -eq 0 ]; then echo -e "\n\033[0;31m[!] Butuh Root!\033[0m"; read -p "Press Enter..."; continue; fi
            echo -e "\n${Y}[*] Menjalankan Hidden SSID Extractor...${N}"
            
            IFACE=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -n 1)
            MON_IFACE="$IFACE"
            
            airmon-ng check kill >/dev/null 2>&1
            ip link set "$IFACE" down 2>/dev/null
            iw dev "$IFACE" set type monitor 2>/dev/null
            ip link set "$IFACE" up 2>/dev/null
            
            echo -e "${G}[*] Scanning Wi-Fi di background...${N}"
            # Jalanin di background, simpen PID
            airodump-ng "$MON_IFACE" --band abg --output-format csv -w /tmp/nw_hidden_scan > /dev/null 2>&1 &
            AIRODUMP_PID=$!
            
            echo -e "\033[1;33m[*] Scanning berjalan. Tekan [ENTER] untuk STOP & melihat hasil...\033[0m"
            read -r # Nunggu user pencet Enter
            
            echo -e "\n${Y}[*] Menghentikan scan...${N}"
            kill -9 $AIRODUMP_PID 2>/dev/null
            wait $AIRODUMP_PID 2>/dev/null
            
            echo -e "\n${G}[+] Mengekstrak Hidden SSID...${N}"
            awk -F',' '/^([0-9A-F]{2}:){5}[0-9A-F]{2}/ {print "BSSID: "$1" | CH: "$4" | ESSID: "$14}' /tmp/nw_hidden_scan-01.csv 2>/dev/null | grep -iE "hidden|length|" | head -n 10
            
            cleanup
            read -p "Press Enter to continue..."
            ;;
        3)
            if [ "$ROOT_MODE" -eq 0 ]; then echo -e "\n\033[0;31m[!] Butuh Root!\033[0m"; read -p "Press Enter..."; continue; fi
            echo -e "\n${Y}[*] Menangkap Probe Request...${N}"
            
            IFACE=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -n 1)
            MON_IFACE="$IFACE"
            
            airmon-ng check kill >/dev/null 2>&1
            ip link set "$IFACE" down 2>/dev/null
            iw dev "$IFACE" set type monitor 2>/dev/null
            ip link set "$IFACE" up 2>/dev/null
            
            echo -e "${G}[*] Menangkap paket di background...${N}"
            tcpdump -i "$MON_IFACE" -e -s 256 type mgt subtype probe-req > /tmp/probe_capture.txt 2>&1 &
            TCPDUMP_PID=$!
            
            echo -e "\033[1;33m[*] Menangkap probe. Tekan [ENTER] untuk STOP...\033[0m"
            read -r
            
            echo -e "\n${Y}[*] Menghentikan capture...${N}"
            kill -9 $TCPDUMP_PID 2>/dev/null
            wait $TCPDUMP_PID 2>/dev/null
            
            echo -e "\n${G}[+] Hasil Probe Request (Disimpan di /tmp/probe_capture.txt):${N}"
            cat /tmp/probe_capture.txt | head -n 20
            
            cleanup
            read -p "Press Enter to continue..."
            ;;
        4)
            echo ""
            read -p "Masukkan MAC Address (contoh: 00:11:22:33:44:55): " MAC
            if [[ ! "$MAC" =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]; then
                echo -e "\n\033[0;31m[!] Format MAC tidak valid!\033[0m"; read -p "Press Enter..."; continue
            fi
            echo -e "\n${Y}[*] Lookup Database...${N}"
            curl -s "https://api.macvendors.com/$MAC" && echo ""
            read -p "Press Enter to continue..."
            ;;
        0) exit 0 ;;
        *) echo -e "  ${R}[!] Invalid choice.${N}"; sleep 1 ;;
    esac
done
