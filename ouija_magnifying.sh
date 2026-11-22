#!/usr/bin/env bash
# ============================================
#   MODULE: OUIJA MAGNIFYING GLASS (Smart Fallback)
# ============================================

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

show_ascii() {
    clear
    echo -e "\033[38;2;0;255;255m" # CYAN
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

# Trik Refresh PATH (Kadang Termux butuh ini abis install package baru)
export PATH=$PATH:$PREFIX/bin

while true; do
    show_ascii
    
    echo -e "${C}======================================================${N}"
    echo -e "${W}    WPA/WPA3 BRUTE-FORCE ENGINE${N}"
    echo -e "    \033[1;32m[+] Jalan di Root / Non-Root\033[0m"
    echo -e "${C}======================================================${N}"
    echo ""
    echo -e "  \033[1;32m[1]\033[0m  \033[1;37mStandard Crack (Wordlist)\033[0m"
    echo -e "  \033[1;32m[2]\033[0m  \033[1;37mHashcat Hybrid (Wordlist + Mask)\033[0m"
    echo ""
    echo -e "  \033[1;31m[0]\033[0m  \033[1;37mBack to Main Menu\033[0m"
    echo ""
    echo -e "${C}------------------------------------------------------${N}"
    echo -ne "  ${Y}Select option > ${N}"
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
            echo -e "\n${Y}[*] Menyiapkan Hashcat Hybrid...${N}"
            # Pengecekan hashcat pake command -v dan which (dobel tameng)
            if ! command -v hashcat >/dev/null 2>&1 && ! which hashcat >/dev/null 2>&1; then
                echo -e "\n\033[0;31m[!] ERROR: 'hashcat' tidak ditemukan!\033[0m"
                echo -e "\033[0;33m    1. Pastikan lo udah 'pkg install hashcat'\033[0m"
                echo -e "\033[0;33m    2. Coba ketik 'hashcat --version' di luar script buat ngetes.\033[0m"
                read -p "Press Enter..."; continue
            fi
            read -p "Masukkan path file .cap / .22000: " HASH_FILE
            read -p "Masukkan path Wordlist: " WORDLIST
            read -p "Masukkan Mask (contoh: ?d?d?d?d): " MASK
            if [ ! -f "$HASH_FILE" ] || [ ! -f "$WORDLIST" ]; then
                echo -e "\n\033[0;31m[!] File capture atau wordlist tidak ditemukan!\033[0m"
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
