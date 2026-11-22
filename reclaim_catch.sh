#!/usr/bin/env bash
# ============================================
#   MODULE: RECLAIM CATCH (v4.0 Final)
# ============================================

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

show_ascii() {
    clear
    echo -e "\033[38;2;148;0;211m"
    cat <<'ASCII'
██████╗ ███████╗ ██████╗██╗      █████╗ ██╗███╗   ███╗     ██████╗ █████╗ ████████╗ ██████╗██╗  ██╗
██╔══██╗██╔════╝██╔════╝██║     ██╔══██╗██║████╗ ████║    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝██║  ██║
██████╔╝█████╗  ██║     ██║     ███████║██║██╔████╔██║    ██║     ███████║   ██║   ██║     ███████║
██╔══██╗██╔══╝  ██║     ██║     ██╔══██║██║██║╚██╔╝██║    ██║     ██╔══██║   ██║   ██║     ██╔══██║
██║  ██║███████╗╚██████╗███████╗██║  ██║██║██║ ╚═╝ ██║    ╚██████╗██║  ██║   ██║   ╚██████╗██║  ██║
╚═╝  ╚═╝╚══════╝ ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝     ╚═════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝
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
    pkill -9 -f "airodump-ng" 2>/dev/null
    if [ -n "$MON_IFACE" ]; then airmon-ng stop "$MON_IFACE" >/dev/null 2>&1; fi
    if [ -n "$IFACE" ]; then airmon-ng stop "$IFACE" >/dev/null 2>&1; fi
    systemctl restart NetworkManager 2>/dev/null; nmcli radio wifi on 2>/dev/null; svc wifi enable 2>/dev/null
}
trap cleanup SIGINT SIGTERM

while true; do
    show_ascii; detect_env
    echo -e "${C}======================================================${N}"
    echo -e "${W}    WPA/WPA3 HANDSHAKE CAPTURE ENGINE${N}"
    echo -e "    Status: $STATUS_MSG"
    echo -e "${C}======================================================${N}"
    echo ""
    if [ "$ROOT_MODE" -eq 1 ] && [ "$IS_TERMUX" -eq 0 ]; then
        echo -e "  \033[1;32m[1]\033[0m  \033[1;37mStart Handshake Capture\033[0m"
    else
        echo -e "  \033[1;30m[1] Start Handshake Capture (Requires PC & Root)\033[0m"
    fi
    echo -e "  \033[1;32m[2]\033[0m  \033[1;37mVerify Captured Handshake\033[0m"
    echo ""; echo -e "  \033[1;31m[0]\033[0m  \033[1;37mBack to Main Menu\033[0m"; echo ""
    echo -e "${C}------------------------------------------------------${N}"; echo -ne "  ${Y}Select option > ${N}"
    read -r catch_choice

    if [ "$catch_choice" = "1" ]; then
        if [ "$IS_TERMUX" -eq 1 ]; then
            echo -e "\n\033[0;31m[!] DITOLAK: Termux (HP) tidak support Handshake Capture tanpa USB Adapter.\033[0m"
            read -p "Press Enter..."; continue
        fi
        if [ "$ROOT_MODE" -eq 0 ]; then
            echo -e "\n\033[0;31m[!] DITOLAK: Butuh Root (sudo) untuk Capture.\033[0m"
            read -p "Press Enter..."; continue
        fi
    fi

    case "$catch_choice" in
        1)
            pilih_interface || { read -p "Press Enter..."; continue; }
            read -p "Masukkan BSSID Target: " BSSID
            read -p "Masukkan Channel Target: " CHAN
            setup_monitor; iw dev "$MON_IFACE" set channel "$CHAN" >/dev/null 2>&1
            
            echo -e "\n${Y}[*] Menangkap Handshake dari $BSSID...${N}"
            OUT_PREFIX="/tmp/nw_handshake_$(date +%s)"
            airodump-ng -c "$CHAN" --bssid "$BSSID" -w "$OUT_PREFIX" --output-format pcap "$MON_IFACE" > /dev/null 2>&1 &
            AIRODUMP_PID=$!
            echo -e "\033[1;33m[*] Capture berjalan. Tekan [ENTER] untuk STOP...\033[0m"; read -r
            kill -9 $AIRODUMP_PID 2>/dev/null; wait $AIRODUMP_PID 2>/dev/null
            
            CAP_FILE="${OUT_PREFIX}-01.cap"
            if [ -f "$CAP_FILE" ]; then
                echo -e "\n${G}[+] Capture selesai. File: $CAP_FILE${N}"
                if aircrack-ng "$CAP_FILE" 2>/dev/null | grep -q "1 handshake"; then echo -e "${G}[+] SUKSES! Handshake DITEMUKAN!${N}"; else echo -e "${Y}[!] Handshake belum ketangkep.${N}"; fi
            else
                echo -e "\n${R}[-] Gagal membuat file capture.${N}"
            fi
            cleanup; read -p "Press Enter to continue..."
            ;;
        2)
            echo -e "\n${Y}[*] Verifikasi Handshake (Bisa Non-Root)...${N}"
            read -p "Masukkan path file .cap: " CAP_PATH
            if [ ! -f "$CAP_PATH" ]; then echo -e "\n\033[0;31m[!] File tidak ditemukan!\033[0m"; read -p "Press Enter..."; continue; fi
            echo -e "\n${G}[*] Menganalisis file...${N}"; aircrack-ng "$CAP_PATH"
            read -p "Press Enter to continue..."
            ;;
        0) exit 0 ;;
        *) echo -e "  ${R}[!] Invalid choice.${N}"; sleep 1 ;;
    esac
done
