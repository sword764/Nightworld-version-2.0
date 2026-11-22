#!/usr/bin/env bash
# ============================================
#   MODULE: OUIJA MAGNIFYING GLASS (v3.3 Final)
# ============================================

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

show_ascii() {
    clear
    echo -e "\033[38;2;0;255;255m"
    cat <<'ASCII'
 ██████╗ ██╗   ██╗██╗     ██╗ █████╗     ███╗   ███╗ █████╗  ██████╗ ███╗   ██╗██╗███████╗██╗   ██╗
██╔═══██╗██║   ██║██║    ██║██╔══██╗    ████╗ ████║██╔══██╗██╔════╝ ████╗  ██║██║██╔════╝╚██╗ ██╔╝
██║   ██║██║   ██║██║    ██║███████║    ██╔████╔██║███████║██║  ███╗██╔██╗ ██║██║█████╗   ╚████╔╝ 
██║   ██║██║   ██║██║    ██║██╔══██║    ██║╚██╔╝██║██╔══██║██║   ██║██║╚██╗██║██║██╔══╝    ╚██╔╝  
╚██████╔╝╚██████╔╝███████╗██║██║  ██║    ██║ ╚═╝ ██║██║  ██║╚██████╔╝██║ ╚████║██║██║        ██║   
 ╚═════╝  ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝        ╚═╝   
ASCII
    echo -e "\033[0m\n"
}

detect_env() {
    IS_TERMUX=0
    if [ -n "$PREFIX" ] && echo "$PREFIX" | grep -qi "com.termux"; then IS_TERMUX=1; fi
    if [ "$(id -u)" -eq 0 ]; then ROOT_MODE=1; else ROOT_MODE=0; fi
}

while true; do
    show_ascii; detect_env
    echo -e "${C}======================================================${N}"
    echo -e "${W}    WPA/WPA3 BRUTE-FORCE ENGINE${N}"
    echo -e "    Status: \033[1;32m[+] READY\033[0m"
    echo -e "${C}======================================================${N}"
    echo ""
    echo -e "  \033[1;32m[1]\033[0m  \033[1;37mStandard Crack (Aircrack-ng)\033[0m"
    if [ "$IS_TERMUX" -eq 0 ]; then
        echo -e "  \033[1;32m[2]\033[0m  \033[1;37mHashcat Hybrid (PC Only)\033[0m"
    else
        echo -e "  \033[1;30m[2] Hashcat Hybrid (Not Supported on Termux)\033[0m"
    fi
    echo ""; echo -e "  \033[1;31m[0]\033[0m  \033[1;37mBack to Main Menu\033[0m"; echo ""
    echo -e "${C}------------------------------------------------------${N}"; echo -ne "  ${Y}Select option > ${N}"
    read -r ouija_choice

    case "$ouija_choice" in
        1)
            echo -e "\n${Y}[*] Menyiapkan Standard Crack...${N}"
            read -p "Masukkan path file .cap: " CAP_FILE
            read -p "Masukkan path Wordlist: " WORDLIST
            if [ ! -f "$CAP_FILE" ] || [ ! -f "$WORDLIST" ]; then
                echo -e "\n\033[0;31m[!] File capture atau wordlist tidak ditemukan!\033[0m"
                read -p "Press Enter..."; continue
            fi
            echo -e "\n${R}[*] Memulai Brute-Force (Standard)...${N}"
            aircrack-ng -w "$WORDLIST" "$CAP_FILE"
            read -p "Press Enter to continue..."
            ;;
        2)
            if [ "$IS_TERMUX" -eq 1 ]; then
                echo -e "\n\033[0;31m[!] Hashcat Hybrid di Termux tidak didukung (Rawan OOM/Crash).\033[0m"
                echo -e "\033[0;33m    Gunakan opsi [1] Standard Crack.\033[0m"
                read -p "Press Enter..."; continue
            fi
            echo -e "\n${Y}[*] Menyiapkan Hashcat Hybrid...${N}"
            if ! command -v hashcat >/dev/null 2>&1; then
                echo -e "\n\033[0;31m[!] ERROR: 'hashcat' tidak ditemukan!\033[0m"
                read -p "Press Enter..."; continue
            fi
            read -p "Masukkan path file .cap / .22000: " HASH_FILE
            read -p "Masukkan path Wordlist: " WORDLIST
            read -p "Masukkan Mask (contoh: ?d?d?d?d): " MASK
            if [ ! -f "$HASH_FILE" ] || [ ! -f "$WORDLIST" ]; then
                echo -e "\n\033[0;31m[!] File tidak ditemukan!\033[0m"
                read -p "Press Enter..."; continue
            fi
            echo -e "\n${R}[*] Memulai Hashcat Hybrid...${N}"
            hashcat -m 22000 -a 6 "$HASH_FILE" "$WORDLIST" "$MASK" --force
            read -p "Press Enter to continue..."
            ;;
        0) exit 0 ;;
        *) echo -e "  ${R}[!] Invalid choice.${N}"; sleep 1 ;;
    esac
done
