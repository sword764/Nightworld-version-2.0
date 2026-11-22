#!/usr/bin/env bash
# ============================================
#   MODULE: EXHUME DISGUISE (Universal PC & Termux)
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

# --- DETEKSI OS & ROOT ---
detect_env() {
    IS_TERMUX=0
    if [ -n "$PREFIX" ] && echo "$PREFIX" | grep -qi "com.termux"; then
        IS_TERMUX=1
    fi

    if [ "$(id -u)" -eq 0 ]; then
        ROOT_MODE=1
        STATUS_MSG="\033[1;32m[+] ROOT MODE ACTIVE\033[0m"
    else
        ROOT_MODE=0
        STATUS_MSG="\033[1;33m[!] NON-ROOT MODE (LIMITED)\033[0m"
    fi
}

# --- FUNGSI SETUP MONITOR MODE (PC / Termux Root) ---
setup_monitor() {
    # Cari interface
    IFACE=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -n 1)
    if [ -z "$IFACE" ]; then
        echo -e "\033[0;31m[!] ERROR: Wi-Fi interface tidak ditemukan.\033[0m"
        return 1
    fi
    
    echo -e "\033[0;33m[*] Menyiapkan Monitor Mode di $IFACE...\033[0m"
    
    # Matiin service yang ngeganggu (Kali/BlackArch)
    airmon-ng check kill >/dev/null 2>&1
    ip link set "$IFACE" down 2>/dev/null
    iw dev "$IFACE" set type monitor 2>/dev/null
    ip link set "$IFACE" up 2>/dev/null
    
    # Simpen nama interface monitor (di PC biasanya tetep sama atau ada embel2 mon)
    MON_IFACE="$IFACE"
    return 0
}

restore_monitor() {
    echo -e "\033[0;33m[*] Mengembalikan mode normal...\033[0m"
    ip link set "$MON_IFACE" down 2>/dev/null
    iw dev "$MON_IFACE" set type managed 2>/dev/null
    ip link set "$MON_IFACE" up 2>/dev/null
    systemctl restart NetworkManager 2>/dev/null
    svc wifi enable 2>/dev/null
}

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
                # LOGIKA TERMUX
                if ! command -v termux-wifi-scaninfo >/dev/null 2>&1; then
                    echo -e "\033[0;31m[!] ERROR: termux-api tidak ditemukan.\033[0m"; read -p "Press Enter..."; continue
                fi
                if ! command -v jq >/dev/null 2>&1; then
                    echo -e "\033[0;33m[*] 'jq' belum ada. Menginstall...\033[0m"
                    pkg install jq -y >/dev/null 2>&1
                fi
                echo -e "${G}[*] Scanning Wi-Fi sekitar...${N}"
                termux-wifi-scaninfo | jq -r '.[] | "SSID: \(.SSID // .ssid // "Hidden") | BSSID: \(.BSSID // .bssid // "N/A") | Signal: \(.RSSI // .rssi // "N/A") dBm"' 2>/dev/null || termux-wifi-scaninfo
            else
                # LOGIKA PC (Kali/BlackArch)
                echo -e "${G}[*] Scanning Wi-Fi sekitar (Menggunakan nmcli/iw)...${N}"
                if command -v nmcli >/dev/null 2>&1; then
                    nmcli -f SSID,BSSID,SIGNAL dev wifi list
                else
                    iw dev | grep -E "SSID|signal"
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        2)
            if [ "$ROOT_MODE" -eq 0 ]; then echo -e "\n\033[0;31m[!] Butuh Root!\033[0m"; read -p "Press Enter..."; continue; fi
            echo -e "\n${Y}[*] Menjalankan Hidden SSID Extractor...${N}"
            setup_monitor || { read -p "Press Enter..."; continue; }
            
            echo -e "${G}[*] Scanning Wi-Fi (30 detik)... Tekan CTRL+C untuk stop.${N}"
            # REAL EXECUTION AIRODUMP
            timeout 30 airodump-ng "$MON_IFACE" --band abg --output-format csv -w /tmp/nw_hidden_scan > /dev/null 2>&1
            
            echo -e "\n${G}[+] Scan Selesai! Mengekstrak Hidden SSID...${N}"
            # Parsing CSV
            awk -F',' '/^([0-9A-F]{2}:){5}[0-9A-F]{2}/ {print "BSSID: "$1" | CH: "$4" | ESSID: "$14}' /tmp/nw_hidden_scan-01.csv 2>/dev/null | grep -iE "hidden|length|" | head -n 10
            
            restore_monitor
            read -p "Press Enter to continue..."
            ;;
        3)
            if [ "$ROOT_MODE" -eq 0 ]; then echo -e "\n\033[0;31m[!] Butuh Root!\033[0m"; read -p "Press Enter..."; continue; fi
            echo -e "\n${Y}[*] Menangkap Probe Request...${N}"
            setup_monitor || { read -p "Press Enter..."; continue; }
            
            echo -e "${G}[*] Menangkap paket Probe Request (20s)...${N}"
            # REAL EXECUTION TCPDUMP
            timeout 20 tcpdump -i "$MON_IFACE" -e -s 256 type mgt subtype probe-req
            
            restore_monitor
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
