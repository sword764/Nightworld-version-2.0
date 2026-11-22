#!/usr/bin/env bash
# ============================================
#   MODULE: EXHUME DISGUISE (v11.0 Perfect Table)
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
    if [ "$(id -u)" -eq 0 ]; then ROOT_MODE=1; STATUS_MSG="\033[1;32m[+] ROOT MODE ACTIVE\033[0m"; else ROOT_MODE=0; STATUS_MSG="\033[1;33m[!] NON-ROOT MODE\033[0m"; fi
}

pilih_interface() {
    echo -e "\n${C}=== DAFTAR INTERFACE WIFI ===${N}"
    local IFACES=($(iw dev 2>/dev/null | awk '/Interface/{print $2}'))
    if [ ${#IFACES[@]} -eq 0 ]; then echo -e "\033[0;31m[!] Tidak ada interface.\033[0m"; return 1; fi
    for i in "${!IFACES[@]}"; do
        local SUPPORT=$(iw phy $(iw dev ${IFACES[$i]} info 2>/dev/null | grep wiphy | awk '{print $2}') info 2>/dev/null | grep -q "monitor" && echo "[Support Monitor]" || echo "[No Monitor]")
        echo -e "  \033[1;32m[$((i+1))]\033[0m ${IFACES[$i]} \033[1;33m$SUPPORT\033[0m"
    done
    read -p "Pilih nomor interface (default 1): " IFACE_CHOICE; IFACE_CHOICE=${IFACE_CHOICE:-1}; IFACE=${IFACES[$((IFACE_CHOICE-1))]}; return 0
}

setup_monitor() {
    systemctl stop NetworkManager 2>/dev/null; nmcli radio wifi off 2>/dev/null; airmon-ng check kill >/dev/null 2>&1; airmon-ng start "$IFACE" >/dev/null 2>&1
    MON_IFACE=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | grep -E "mon" | head -n 1); if [ -z "$MON_IFACE" ]; then MON_IFACE="$IFACE"; fi
}

cleanup() {
    pkill -9 -f "tcpdump" 2>/dev/null; pkill -9 -f "airodump-ng" 2>/dev/null
    if [ -n "$MON_IFACE" ]; then airmon-ng stop "$MON_IFACE" >/dev/null 2>&1; fi
    if [ -n "$IFACE" ]; then airmon-ng stop "$IFACE" >/dev/null 2>&1; fi
    systemctl restart NetworkManager 2>/dev/null; nmcli radio wifi on 2>/dev/null; svc wifi enable 2>/dev/null
}
trap cleanup SIGINT SIGTERM

while true; do
    show_ascii; detect_env
    echo -e "${C}======================================================${N}"
    echo -e "${W}    HIDDEN SIGNAL & PROBE RECONNAISSANCE${N}"
    echo -e "    Status: $STATUS_MSG"
    echo -e "${C}======================================================${N}"
    echo ""
    echo -e "  \033[1;32m[1]\033[0m  \033[1;37mWi-Fi Scanner (Basic/Passive)\033[0m"
    if [ "$ROOT_MODE" -eq 1 ] && [ "$IS_TERMUX" -eq 0 ]; then
        echo -e "  \033[1;32m[2]\033[0m  \033[1;37mHidden SSID Extractor (Root Only)\033[0m"
        echo -e "  \033[1;32m[3]\033[0m  \033[1;37mProbe Request Sniffer (Root Only)\033[0m"
    else
        echo -e "  \033[1;30m[2] Hidden SSID Extractor (Requires PC & Root)\033[0m"
        echo -e "  \033[1;30m[3] Probe Request Sniffer (Requires PC & Root)\033[0m"
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
                if ! command -v termux-wifi-scaninfo >/dev/null 2>&1; then echo -e "\033[0;31m[!] Install termux-api!\033[0m"; read -p "Press Enter..."; continue; fi
                if ! command -v jq >/dev/null 2>&1; then pkg install jq -y >/dev/null 2>&1; fi
                
                echo -e "${G}[*] Scanning Wi-Fi sekitar (Real-time)...${N}"
                echo -e "\033[1;36mBSSID                  | CH | SEC       | SIG  | SSID\033[0m"
                echo -e "\033[1;36m--------------------------------------------------------------------\033[0m"
                
                # Parsing Termux: Konversi Freq ke CH, rapihin Security
                termux-wifi-scaninfo | jq -r '.[] | 
                    (.frequency // .freq // 0) as $freq |
                    (if $freq < 3000 then 1 + (($freq - 2412) / 5 | floor) else 32 + (($freq - 5170) / 5 | floor) end) as $ch |
                    (.capabilities // .caps // "OPEN") as $caps |
                    (if $caps | contains("WPA3") then "WPA3" elif $caps | contains("WPA2") then "WPA2" elif $caps | contains("WPA") then "WPA" else "OPEN" end) as $sec |
                    "\(.BSSID // .bssid // "N/A") | \($ch) | \($sec) | \(.RSSI // .rssi // "N/A") | \(.SSID // .ssid // "(Hidden)")"' 2>/dev/null || echo -e "\033[0;33m[!] Gagal parsing data.\033[0m"
            else
                if command -v nmcli >/dev/null 2>&1; then
                    echo -e "\033[1;36mBSSID                  | CH | SEC       | SIG  | SSID\033[0m"
                    echo -e "\033[1;36m--------------------------------------------------------------------\033[0m"
                    
                    # Parsing PC: Gabung Security (WPA1/WPA2), dan rapihin spasi pake printf
                    nmcli -f BSSID,SSID,CHAN,SECURITY,SIGNAL dev wifi list | awk 'NR>1 {
                        bssid=$1; signal=$NF; security=$(NF-1); chan=$(NF-2);
                        ssid=""; for(i=2; i<=NF-3; i++) ssid=ssid" "$i;
                        gsub(/^ +| +$/, "", ssid);
                        if (ssid=="") ssid="(Hidden)"; 
                        if (security=="") security="OPEN";
                        # Gabungin WPA1 dan WPA2 jadi WPA1/WPA2
                        gsub(/WPA1 WPA2/, "WPA1/WPA2", security);
                        printf "%-22s | %-2s | %-9s | %-4s | %s\n", bssid, chan, security, signal, ssid
                    }'
                else
                    echo -e "\033[0;31m[!] 'nmcli' tidak ditemukan.\033[0m"
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        2)
            if [ "$IS_TERMUX" -eq 1 ]; then echo -e "\n\033[0;31m[!] Termux tidak support Monitor Mode tanpa USB Adapter.\033[0m"; read -p "Press Enter..."; continue; fi
            if [ "$ROOT_MODE" -eq 0 ]; then echo -e "\n\033[0;31m[!] Butuh Root!\033[0m"; read -p "Press Enter..."; continue; fi
            
            pilih_interface || { read -p "Press Enter..."; continue; }
            setup_monitor
            echo -e "\n${Y}[*] Menjalankan Hidden SSID Extractor...${N}"
            airodump-ng "$MON_IFACE" --band abg --output-format csv -w /tmp/nw_hidden_scan > /dev/null 2>&1 &
            AIRODUMP_PID=$!
            echo -e "\033[1;33m[*] Tekan [ENTER] untuk STOP...\033[0m"; read -r; kill -9 $AIRODUMP_PID 2>/dev/null; wait $AIRODUMP_PID 2>/dev/null
            echo -e "\n${G}[+] Mengekstrak Hidden SSID...${N}"
            awk -F',' '/^([0-9A-F]{2}:){5}[0-9A-F]{2}/ {print "BSSID: "$1" | CH: "$4" | ESSID: "$14}' /tmp/nw_hidden_scan-01.csv 2>/dev/null | grep -iE "hidden|length|" | head -n 10
            cleanup; read -p "Press Enter to continue..."
            ;;
        3)
            if [ "$IS_TERMUX" -eq 1 ]; then echo -e "\n\033[0;31m[!] Termux tidak support Monitor Mode tanpa USB Adapter.\033[0m"; read -p "Press Enter..."; continue; fi
            if [ "$ROOT_MODE" -eq 0 ]; then echo -e "\n\033[0;31m[!] Butuh Root!\033[0m"; read -p "Press Enter..."; continue; fi
            
            pilih_interface || { read -p "Press Enter..."; continue; }
            setup_monitor
            echo -e "\n${Y}[*] Menangkap Probe Request...${N}"
            tcpdump -i "$MON_IFACE" -e -s 256 > /tmp/probe_capture.txt 2>&1 &
            TCPDUMP_PID=$!
            echo -e "\033[1;33m[*] Tekan [ENTER] untuk STOP...\033[0m"; read -r; kill -9 $TCPDUMP_PID 2>/dev/null; wait $TCPDUMP_PID 2>/dev/null
            echo -e "\n${G}[+] Hasil:${N}"; grep -iE "Probe Request|Beacon" /tmp/probe_capture.txt | head -n 20
            cleanup; read -p "Press Enter to continue..."
            ;;
        4)
            echo ""; read -p "Masukkan MAC Address: " MAC
            if [[ ! "$MAC" =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]; then echo -e "\n\033[0;31m[!] Format MAC tidak valid!\033[0m"; read -p "Press Enter..."; continue; fi
            echo -e "\n${Y}[*] Lookup Database...${N}"; curl -s "https://api.macvendors.com/$MAC" && echo ""
            read -p "Press Enter to continue..."
            ;;
        0) exit 0 ;;
        *) echo -e "  ${R}[!] Invalid choice.${N}"; sleep 1 ;;
    esac
done
