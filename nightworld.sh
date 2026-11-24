#!/usr/bin/env bash
# ============================================
#   N I G H T   W O R L D
#   Version: 2.0 (Public)
#   Engine : 7.3 (Standardized Boot Sequence)
#   By bogor x ploit
# ============================================

VERSION="2.0"
MODULE_URL="https://raw.githubusercontent.com/sword764/Nightworld/main"

# --- AUTO-SYNC LIBRARY ---
if [ ! -f "bxp_libcore.sh" ]; then
    echo -e "\033[1;33m[*] Core library not found. Downloading from GitHub...\033[0m"
    curl -sL -o bxp_libcore.sh "${MODULE_URL}/bxp_libcore.sh"
fi
source ./bxp_libcore.sh

if ! command -v bxp_ascii_title >/dev/null 2>&1; then
    C='\033[0;36m'; N='\033[0m'
    bxp_ascii_title() { echo -e "${C}=== $1 ===${N}\n"; }
fi

detect_env() {
    OS_NAME="Unknown"; ROOT_STATUS="Unknown"; IS_TERMUX=0
    ARCH=$(uname -m); KERNEL=$(uname -r); DEV_MODEL=$(uname -n)

    if [ -n "$PREFIX" ] && echo "$PREFIX" | grep -qi "com.termux"; then
        OS_NAME="Termux (Android)"; IS_TERMUX=1
        if command -v getprop >/dev/null 2>&1; then
            DEV_MODEL=$(getprop ro.product.model 2>/dev/null); [ -z "$DEV_MODEL" ] && DEV_MODEL="Android Device"
            ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
            CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "$ARCH")
        fi
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            kali) OS_NAME="Kali Linux" ;; blackarch) OS_NAME="BlackArch Linux" ;;
            *) OS_NAME="${PRETTY_NAME:-$ID}" ;;
        esac
        DEV_MODEL=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "PC Device")
    else
        OS_NAME="$(uname -s) Linux"
    fi

    if [ "$(id -u)" -eq 0 ]; then ROOT_STATUS="Root"; else
        if command -v su >/dev/null 2>&1 && timeout 3 su -c id >/dev/null 2>&1; then ROOT_STATUS="Root (su available)"; else ROOT_STATUS="Non-Root"; fi
    fi
    USER_NAME="$(whoami 2>/dev/null || echo unknown)"
    COLS="$(tput cols 2>/dev/null || echo 80)"
    export OS_NAME ROOT_STATUS IS_TERMUX ARCH KERNEL DEV_MODEL USER_NAME ANDROID_VER CPU_ABI COLS
}

# --- LAYOUT UTILITY ---
print_line() {
    local char="$1"
    local w=$(tput cols 2>/dev/null || echo 80)
    [ "$w" -gt 100 ] && w=100
    local str=$(printf "%${w}s" | tr ' ' "$char")
    echo -e "${C}${str}${N}"
}

clear_screen() {
    clear
    printf '\033[3J'
}

# --- ASCII MAIN HEADER (ASLI DARI TUAN) ---
ascii_mobile() { cat <<'ASCII'
        /\
       /  \
      |    |
      | || |
      | || |
      | || |
   ___|_||_|___
   \    ||     /
    \   ||    /
     \__||__ /
        ||
        ||
     .--||--.
    /   ||   \
   |  _ || _  |
   | / \||/ \ |
   |/  -||-  \|
   |\  _||_  /|
    \  '||'  /
     '. || .'
        ||
        ||
        |/
   NIGHT WORLD
 By bogor x ploit
      v2.0
ASCII
}
ascii_pc() { cat <<'ASCII'
                    /\
                   /   \
                  /     \
                 |       |
                 |   ||  |
                 |   ||  |
                 |   ||  |
    ____________|    ||    |____________
   \          __     ||     __        /
    \   .----'    \  ||  /   `----.  /
     \/            \_||_/           \/
                     ||
         .---.-'     ||     '-.----.
      .-'  /         ||         \     `-.
    .'    /          ||          \      `.
   /     /           ||           \      \
  /     /            ||            \      \
 ;     /         _..-||-.._         \     ;
.     /       .'  .- || -.  `.       \     .
|    /       /    /  ||  \    \       \    |
|---/-------|----|---||----|---|-------\---|
|  /         \    \  ||  /    /         \   |
. /           `.   '-||-'   .'           \ .
;              `.._  ||  _..'             ;
 \                 ` || '                /
  \  /\              ||              /\  /
   `.  `-._          ||          _.-'  .'
     `.    `'--._    ||    _..--'`    .'
       `-.           ||           .-'
          `---.      ||      .---'
                \    ||    /
                 \   ||   /
                  \  ||  /
                   \ || /
                    \||/
                     ||
                     ||
                     ||
                     |/
ASCII
}

show_banner() {
    print_line "-"
    echo -e "  NIGHT WORLD ${C}|${W} By bogor x ploit"
    print_line "-"
    echo -e "  Version : v${VERSION}"
    echo -e "  OS      : ${OS_NAME}"
    echo -e "  Device  : ${DEV_MODEL}"
    echo -e "  User    : ${USER_NAME}"
    echo -e "  Access  : ${ROOT_STATUS}"
    print_line "-"
}

show_menu() {
    echo -e "${G}  # MAIN MENU #${N}"
    print_line "="
    echo ""
    echo -e "  \033[1;36m[1]\033[0m  \033[1;37mCyber Kill Chain\033[0m"
    echo -e "  \033[1;36m[2]\033[0m  \033[1;37mExploitation\033[0m"
    echo -e "  \033[1;36m[3]\033[0m  \033[1;37mNetscan\033[0m"
    echo -e "  \033[1;36m[4]\033[0m  \033[1;37mUser Guide\033[0m"
    echo -e "  \033[1;36m[5]\033[0m  \033[1;37mVPN / Proxy\033[0m"
    echo ""
    echo -e "  \033[1;31m[0]\033[0m  \033[1;37mExit\033[0m"
    echo ""
    print_line "="
}

menu_kill_chain() {
    while true; do
        clear_screen
        print_line "="
        echo -e "    TOOLS HUB | Cyber Kill Chain"
        print_line "="
        echo ""
        echo -e "  \033[1;32m[1]\033[0m  \033[1;37mCyber Attack (API/Web)\033[0m"
        echo -e "  \033[1;32m[2]\033[0m  \033[1;37mPhising (Credential Harvester)\033[0m"
        echo -e "  \033[1;31m[3]\033[0m  \033[1;37mBack to Main Menu\033[0m"
        echo ""
        print_line "-"
        echo -ne "  Select menu > "
        read -r kc_choice

        case "$kc_choice" in
            1) run_tool "CYBER ATTACK" "cyber_attack.sh" ;;
            2) run_tool "PHISING" "phising.sh" ;;
            3) return ;;
            *) echo -e "  [!] Invalid choice."; sleep 1 ;;
        esac
    done
}

menu_netscan() {
    while true; do
        clear_screen
        print_line "="
        echo -e "    TOOLS HUB | Netscan (Wi-Fi)"
        print_line "="
        echo ""
        echo -e "  \033[1;32m[1]\033[0m  \033[1;37mExhume Disguise\033[0m"
        echo -e "  \033[1;32m[2]\033[0m  \033[1;37mChoke The Hunters\033[0m"
        echo -e "  \033[1;32m[3]\033[0m  \033[1;37mReclaim Catch In Mid-Air\033[0m"
        echo -e "  \033[1;32m[4]\033[0m  \033[1;37mOuija Magnifying Glass\033[0m"
        echo -e "  \033[1;31m[5]\033[0m  \033[1;37mBack to Main Menu\033[0m"
        echo ""
        print_line "-"
        echo -ne "  Select menu > "
        read -r ns_choice

        case "$ns_choice" in
            1) run_tool "EXHUME DISGUISE" "exhume_disguise.sh" ;;
            2) run_tool "CHOKE THE HUNTERS" "choke_hunters.sh" ;;
            3) run_tool "RECLAIM CATCH" "reclaim_catch.sh" ;;
            4) run_tool "OUIJA MAGNIFYING" "ouija_magnifying.sh" ;;
            5) return ;;
            *) echo -e "  [!] Invalid choice."; sleep 1 ;;
        esac
    done
}

menu_exploit() {
    while true; do
        clear_screen
        print_line "="
        echo -e "    TOOLS HUB | Exploitation"
        print_line "="
        echo ""
        echo -e "  \033[1;32m[1]\033[0m  \033[1;37mNYCTOPHOBIA\033[0m"
        echo -e "  \033[1;32m[2]\033[0m  \033[1;37mSLEEP PARALYSIS\033[0m"
        echo -e "  \033[1;32m[3]\033[0m  \033[1;37mNOCTURNAL DECAY\033[0m"
        echo -e "  \033[1;31m[4]\033[0m  \033[1;37mBack to Main Menu\033[0m"
        echo ""
        print_line "-"
        echo -ne "  Select menu > "
        read -r sub_pilihan

        case "$sub_pilihan" in
            1) run_tool "NYCTOPHOBIA" "nyctophobia.sh" ;;
            2) run_tool "SLEEP PARALYSIS" "sleep_paralysis.sh" ;;
            3) run_tool "NOCTURNAL DECAY" "nocturnal_decay.sh" ;;
            4) return ;;
            *) echo -e "  [!] Invalid choice."; sleep 1 ;;
        esac
    done
}

menu_vpn_entry() {
    if [ ! -f "vpn_module.py" ] && [ ! -f "vpn_module.sh" ]; then
        echo -e "${C}[*] Mengunduh modul VPN...${N}"
        curl -sL -o vpn_module.py "${MODULE_URL}/vpn_module.py"
        curl -sL -o vpn_module.sh "${MODULE_URL}/vpn_module.sh"
    fi

    if command -v python3 >/dev/null 2>&1 && [ -f "vpn_module.py" ]; then
        python3 vpn_module.py
    elif [ -f "vpn_module.sh" ]; then
        bash vpn_module.sh
    else
        echo -e "${R}[!] Modul VPN gagal dimuat.${N}"
        sleep 2
    fi
}

# --- FUNGSI RUN TOOL ---
run_tool() {
    TOOL_NAME="$1"; FILE_NAME="$2"; MARKER_FILE=".${FILE_NAME}.installed"
    
    clear_screen
    
    # --- LOGIKA TAMPILAN ASCII ASLI DARI TUAN ---
    case "$TOOL_NAME" in
        "EXHUME DISGUISE")
            echo -e "\033[38;2;255;0;0m" # MERAH
            cat <<'ASCII'
███████╗██╗  ██╗██╗  ██╗██╗   ██╗███╗   ███╗███████╗    ██████╗ ██╗███████╗ ██████╗ ██╗   ██╗██╗███████╗███████╗
██╔════╝╚██╗██╔╝██║  ██║██║   ██║████╗ ████║██╔════╝    ██╔══██╗██║██╔════╝██╔════╝ ██║   ██║██║██╔════╝██╔════╝
█████╗   ╚███╔╝ ███████║██║   ██║██╔████╔██║█████╗      ██║  ██║██║███████╗██║  ███╗██║   ██║██║███████╗█████╗  
██╔══╝   ██╔██╗ ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝      ██║  ██║██║╚════██║██║   ██║██║   ██║██║╚════██║██╔══╝  
███████╗██╔╝ ██╗██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗    ██████╔╝██║███████║╚██████╔╝╚██████╔╝██║███████║███████╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝    ╚═════╝ ╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚══════╝
ASCII
            echo -e "\033[0m"
            ;;
        "CHOKE THE HUNTERS")
            echo -e "\033[38;2;255;215;0m" # EMAS
            cat <<'ASCII'
██████╗██╗  ██╗ ██████╗ ██╗  ██╗███████╗    ████████╗██╗  ██╗███████╗    ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗
██╔════╝██║  ██║██╔═══██╗██║ ██╔╝██╔════╝    ╚══██╔══╝██║  ██║██╔════╝    ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝
██║     ███████║██║   ██║█████╔╝ █████╗         ██║   ███████║█████╗      ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝███████╗
██║     ██╔══██║██║   ██║██╔═██╗ ██╔══╝         ██║   ██╔══██║██╔══╝      ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗╚════██║
╚██████╗██║  ██║╚██████╔╝██║  ██╗███████╗       ██║   ██║  ██║███████╗    ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝       ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝
ASCII
            echo -e "\033[0m"
            ;;
        "RECLAIM CATCH")
            echo -e "\033[38;2;148;0;211m" # UNGU
            cat <<'ASCII'
██████╗ ███████╗ ██████╗██╗      █████╗ ██╗███╗   ███╗     ██████╗ █████╗ ████████╗ ██████╗██╗  ██╗
██╔══██╗██╔════╝██╔════╝██║     ██╔══██╗██║████╗ ████║    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝██║  ██║
██████╔╝█████╗  ██║     ██║     ███████║██║██╔████╔██║    ██║     ███████║   ██║   ██║     ███████║
██╔══██╗██╔══╝  ██║     ██║     ██╔══██║██║██║╚██╔╝██║    ██║     ██╔══██║   ██║   ██║     ██╔══██║
██║  ██║███████╗╚██████╗███████╗██║  ██║██║██║ ╚═╝ ██║    ╚██████╗██║  ██║   ██║   ╚██████╗██║  ██║
╚═╝  ╚═╝╚══════╝ ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝     ╚═════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝
ASCII
            echo -e "\033[0m"
            ;;
        "OUIJA MAGNIFYING")
            echo -e "\033[38;2;0;255;255m" # CYAN
            cat <<'ASCII'
 ██████╗ ██╗   ██╗██╗     ██╗ █████╗     ███╗   ███╗ █████╗  ██████╗ ███╗   ██╗██╗███████╗██╗   ██╗
██╔═══██╗██║   ██║██║    ██║██╔══██╗    ████╗ ████║██╔══██╗██╔════╝ ████╗  ██║██║██╔════╝╚██╗ ██╔╝
██║   ██║██║   ██║██║    ██║███████║    ██╔████╔██║███████║██║  ███╗██╔██╗ ██║██║█████╗   ╚████╔╝ 
██║   ██║██║   ██║██║    ██║██╔══██║    ██║╚██╔╝██║██╔══██║██║   ██║██║╚██╗██║██║██╔══╝    ╚██╔╝  
╚██████╔╝╚██████╔╝███████╗██║██║  ██║    ██║ ╚═╝ ██║██║  ██║╚██████╔╝██║ ╚████║██║██║        ██║   
 ╚═════╝  ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝        ╚═╝   
ASCII
            echo -e "\033[0m"
            ;;
        *)
            bxp_ascii_title "$TOOL_NAME"
            ;;
    esac
    # --------------------------------------------------

    print_line "="
    
    if [ -f "$MARKER_FILE" ]; then
        echo -e "  ${G}[+] Module $TOOL_NAME is already installed. Booting up...${N}"
        sleep 1
    else
        echo -ne "  ${Y}[?] Do you want to install $TOOL_NAME module? (Y/N) > ${N}"
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "  ${R}[-] Installation aborted.${N}"; sleep 1.5; return
        fi

        if [ ! -f "$FILE_NAME" ]; then
            echo -e "\n  ${G}[*] Downloading module from GitHub Server...${N}"
            curl -fsSL --max-time 30 --retry 3 -o "$FILE_NAME" "${MODULE_URL}/${FILE_NAME}" || { echo -e "  ${R}[-] Download failed!${N}"; sleep 2; return; }
            if [[ ! -f "$FILE_NAME" ]] || ! head -n 1 "$FILE_NAME" | grep -qE '^#!.*(bash|sh)'; then
                echo -e "  ${R}[-] CRITICAL: Invalid format!${N}"; rm -f "$FILE_NAME"; sleep 2; return
            fi
            echo -e "  ${G}[+] Module found in local cache. Preparing boot sequence...${N}"
        fi
        touch "$MARKER_FILE"
    fi

    echo ""
    echo -ne "  Installing... ["
    for i in {1..20}; do
        echo -ne "${W}=${N}"
        sleep 0.05
    done
    echo -e "] 100%"
    echo ""
    sleep 0.5

    bxp_boot_sequence "$TOOL_NAME"
    
    echo ""
    chmod +x "$FILE_NAME" 2>/dev/null
    
    bash "$FILE_NAME"
    MODULE_EXIT=$?
    
    if [ "$MODULE_EXIT" -ne 0 ]; then
        echo -e "\n  ${R}[!] Module exited with error code: $MODULE_EXIT${N}"
    fi
    
    echo ""
    read -p "  Press Enter to return to menu..."
}

user_guide() {
    clear_screen
    print_line "="
    echo -e "               USER GUIDE / MANUAL"
    echo -e "               NIGHT WORLD v2.0"
    print_line "="
    echo ""
    echo -e "  ${Y}[1] INSTALLATION PROCESS${N}"
    echo -e "    - Select a category (Cyber / Exploit / Netscan)."
    echo -e "    - Choose the desired module."
    echo -e "    - Type 'Y' when prompted to install (only required once)."
    echo -e "    - Wait for the download and boot sequence to complete."
    echo ""
    echo -e "  ${Y}[2] USING THE LISTENERS${N}"
    echo -e "    - For Session Hooks (NYCTOPHOBIA), the listener port is 2010."
    echo -e "    - For Session Bridges (SLEEP PARALYSIS), the listener port is 2015."
    echo -e "    - Ensure these ports are not used by other applications."
    echo ""
    echo -e "  ${Y}[3] TIPS & TRICKS${N}"
    echo -e "    - Gunakan menu [5] VPN / Proxy untuk routing traffic."
    echo -e "    - Do not close the terminal while a listener is running."
    echo -e "    - Press CTRL+C to stop the listener safely."
    echo ""
    print_line "="
    read -p "  Press Enter to return to main menu..."
}

main() {
    detect_env
    while true; do
        clear_screen
        if [ "$IS_TERMUX" -eq 1 ]; then echo -e "${B}"; ascii_mobile; echo -e "${N}"
        else echo -e "${B}"; ascii_pc; echo -e "${N}"; fi
        show_banner
        show_menu
        echo -ne "  ${Y}Select menu > ${N}"
        read -r pilihan

        case "$pilihan" in
            1) menu_kill_chain ;;
            2) menu_exploit ;;
            3) menu_netscan ;;
            4) user_guide ;;
            5) menu_vpn_entry ;;
            0) echo -e "  ${G}Exiting NIGHT WORLD...${N}"; exit 0 ;;
            *) echo -e "  ${R}[!] Invalid choice.${N}"; sleep 1 ;;
        esac
    done
}

main
