#!/usr/bin/env bash
# ============================================
#   VPN / PROXY MODULE (Shell) - NightWorld v2.0
#   Patched by Ijul v2.0
# ============================================

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; W='\033[1;37m'; N='\033[0m'
PROXY_LIST="proxy_list.txt"
STATE_FILE=".vpn_state"
ENV_FILE="$HOME/.nightworld_vpn_env"
TOR_PORT=9050

save_env_to_file() {
    local proxy_url="$1"
    cat > "$ENV_FILE" <<EOF
export http_proxy="$proxy_url"
export https_proxy="$proxy_url"
export ALL_PROXY="$proxy_url"
export HTTP_PROXY="$proxy_url"
export HTTPS_PROXY="$proxy_url"
EOF
}

clear_env_file() {
    rm -f "$ENV_FILE"
}

install_tor() {
    echo -e "${Y}[*] Tor tidak ditemukan. Menginstall otomatis...${N}"
    if [ -n "$PREFIX" ] && echo "$PREFIX" | grep -qi "com.termux"; then
        pkg update -y >/dev/null 2>&1; pkg install -y tor >/dev/null 2>&1
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y >/dev/null 2>&1; sudo apt-get install -y tor >/dev/null 2>&1
    fi
    command -v tor >/dev/null 2>&1 && { echo -e "${G}[+] Tor berhasil diinstall.${N}"; return 0; } || { echo -e "${R}[!] Gagal install Tor.${N}"; return 1; }
}

get_status() {
    local vpn="OFF"; local proxy="OFF"
    pgrep -x tor >/dev/null 2>&1 && vpn="ON"
    [ -f "$STATE_FILE" ] && grep -qE "^(TOR|PROXY:)" "$STATE_FILE" && proxy="ON"
    
    echo -e "  ${C}[*] VPN Tor : ${W}$vpn${N}"
    echo -e "  ${C}[*] Proxy   : ${W}$proxy${N}"
}

start_tor() {
    if ! command -v tor >/dev/null 2>&1; then install_tor || return 1; fi
    if pgrep -x tor >/dev/null 2>&1; then
        echo -e "${G}[+] Tor daemon sudah berjalan.${N}"
    else
        echo -e "${Y}[*] Menjalankan Tor...${N}"
        tor > /dev/null 2>&1 & sleep 5
    fi
    echo "TOR" > "$STATE_FILE"
    
    local proxy_url="socks5h://127.0.0.1:$TOR_PORT"
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export ALL_PROXY="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    
    save_env_to_file "$proxy_url"
    echo -e "${G}[+] VPN Tor Aktif (Port $TOR_PORT).${N}"
}

start_proxy() {
    if [ ! -f "$PROXY_LIST" ]; then
        echo -e "${Y}[*] Mengunduh proxy dari TheSpeedX...${N}"
        local tmp_socks=$(mktemp)
        local tmp_http=$(mktemp)
        
        if curl -sL --max-time 15 -o "$tmp_socks" "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks5.txt" && \
           curl -sL --max-time 15 -o "$tmp_http" "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt"; then
            echo "# SOCKS5" > "$PROXY_LIST"
            cat "$tmp_socks" >> "$PROXY_LIST"
            echo "# HTTP" >> "$PROXY_LIST"
            cat "$tmp_http" >> "$PROXY_LIST"
            echo -e "${G}[+] Proxy list berhasil diunduh.${N}"
        else
            echo -e "${R}[!] Gagal mengunduh proxy list. Cek koneksi internet.${N}"
            rm -f "$tmp_socks" "$tmp_http"
            return 1
        fi
        rm -f "$tmp_socks" "$tmp_http"
    fi
    
    local count=$(grep -vcE '^\s*#|^\s*$' "$PROXY_LIST")
    [ "$count" -eq 0 ] && { echo -e "${R}[!] List kosong.${N}"; return 1; }
    
    echo -e "${C}[*] Total $count proxy.${N}"
    read -p "  Pilih nomor (Enter=Random) > " num
    
    local chosen=""
    if [ -z "$num" ]; then chosen=$(grep -vE '^\s*#|^\s*$' "$PROXY_LIST" | shuf -n 1)
    elif [[ "$num" =~ ^[0-9]+$ ]]; then chosen=$(grep -vE '^\s*#|^\s*$' "$PROXY_LIST" | sed -n "${num}p")
    else chosen="$num"; fi

    [[ ! "$chosen" =~ ^(http|https|socks5|socks5h):// ]] && chosen="http://$chosen"
    
    echo "PROXY:$chosen" > "$STATE_FILE"
    export http_proxy="$chosen" https_proxy="$chosen" ALL_PROXY="$chosen" HTTP_PROXY="$chosen" HTTPS_PROXY="$chosen"
    
    save_env_to_file "$chosen"
    echo -e "${G}[+] Proxy Aktif: $chosen${N}"
}

stop_vpn() {
    pkill -x tor 2>/dev/null
    [ -f "$STATE_FILE" ] && grep -q "TOR" "$STATE_FILE" && rm -f "$STATE_FILE"
    unset http_proxy https_proxy ALL_PROXY HTTP_PROXY HTTPS_PROXY
    clear_env_file
    echo -e "${G}[+] VPN Tor dimatikan.${N}"
}

stop_proxy() {
    unset http_proxy https_proxy ALL_PROXY HTTP_PROXY HTTPS_PROXY
    rm -f "$STATE_FILE"
    clear_env_file
    echo -e "${G}[+] Proxy dimatikan.${N}"
}

draw_layout() {
    local cols=$(tput cols 2>/dev/null || echo 80); [ "$cols" -gt 80 ] && cols=80
    local border=$(printf "%${cols}s" | tr ' ' '='); local dash=$(printf "%${cols}s" | tr ' ' '-')

    clear; printf '\033[3J'
    echo -e "${C}${border}${N}"
    printf "${W}%*s${N}\n" $(( (cols + 13) / 2 )) "V P N  /  P R O X Y"
    echo -e "${C}${border}${N}"
    get_status
    echo -e "${C}${dash}${N}"
    echo -e "  ${G}[1]${N} ${W}Aktifkan (Tor)${N}"
    echo -e "  ${G}[2]${N} ${W}Aktifkan (Proxy Manual){N}"
    echo -e "  ${R}[3]${N} ${W}Matikan VPN${N}"
    echo -e "  ${R}[4]${N} ${W}Matikan Proxy${N}"
    echo -e "  ${Y}[0]${N} ${W}Kembali${N}"
    echo -e "${C}${dash}${N}"
    echo -e "\n\n\n"
}

menu_vpn() {
    while true; do
        draw_layout
        read -p "  Select menu > " choice
        case "$choice" in
            1) start_tor ;; 2) start_proxy ;;
            3) stop_vpn ;; 4) stop_proxy ;;
            0) return ;; *) sleep 1 ;;
        esac
        echo ""; read -p "  Press Enter..."
    done
}

menu_vpn
