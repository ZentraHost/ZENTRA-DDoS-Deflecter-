#!/bin/bash

THRESHOLD=100
INSTALL_DIR="/opt/zentra-ddos"
LOG_FILE="$INSTALL_DIR/ddos_log.txt"
BLOCKED_IPS_FILE="$INSTALL_DIR/blocked_ips.txt"
CHECK_INTERVAL=10

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure files exist
mkdir -p "$INSTALL_DIR"
touch "$LOG_FILE"
touch "$BLOCKED_IPS_FILE"

display_header() {
    echo -e "${CYAN}============================================"
    echo -e "         ZENTRA PROTECTION v1.2"
    echo -e "============================================${NC}"
}

block_ip() {
    local ip="$1"
    if iptables -C INPUT -s "$ip" -j DROP &>/dev/null; then
        # Already blocked, do nothing or log debug
        return
    else
        iptables -A INPUT -s "$ip" -j DROP
        echo "$ip" >> "$BLOCKED_IPS_FILE"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Blocked IP: $ip" >> "$LOG_FILE"
    fi
}

# --- BACKGROUND SERVICE FUNCTION ---
daemon_mode() {
    echo "Starting ZENTRA DDoS Daemon..." >> "$LOG_FILE"
    while true; do
        # Silent blocking logic
        ss -ntu state established | awk 'NR>1 {split($5,a,":"); print a[1]}' | sort | uniq -c | while read count ip; do
            if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && "$count" -gt "$THRESHOLD" ]]; then
                block_ip "$ip"
            fi
        done
        sleep "$CHECK_INTERVAL"
    done
}

# --- STATUS DASHBOARD FUNCTION ---
status_dashboard() {
    while true; do
        clear
        echo -e "${DARK_RED}"
        echo "███████╗███████╗███╗   ██╗████████╗██████╗  █████╗ "
        echo "╚══███╔╝██╔════╝████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗"
        echo "  ███╔╝ █████╗  ██╔██╗ ██║   ██║   ██████╔╝███████║"
        echo " ███╔╝  ██╔══╝  ██║╚██╗██║   ██║   ██╔══██╗██╔══██║"
        echo "███████╗███████╗██║ ╚████║   ██║   ██║  ██║██║  ██║"
        echo "╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝"
        echo -e "${CYAN}            ZENTRA SYSTEM STATUS${NC}"
        echo -e "${CYAN}============================================${NC}"
        
        # System Info
        echo -e "${YELLOW}[+] System Info:${NC}"
        echo -e "    Host:   $(hostname)"
        echo -e "    Kernel: $(uname -r)"
        echo -e "    Uptime: $(uptime -p)"
        echo ""

        # Live Connections
        echo -e "${YELLOW}[+] Live Monitoring (Top Connections):${NC}"
        printf "%-20s %-10s\n" "IP Address" "Conns"
        echo "------------------------------"
        ss -ntu state established | awk 'NR>1 {split($5,a,":"); print a[1]}' | sort | uniq -c | sort -nr | head -n 10 | while read count ip; do
             if [ "$count" -gt "$THRESHOLD" ]; then
                echo -e "${RED}$ip          $count (OVER LIMIT)${NC}"
             else
                echo -e "${GREEN}$ip          $count${NC}"
             fi
        done
        echo ""

        # Blocked IPs
        echo -e "${YELLOW}[+] Recently Blocked IPs:${NC}"
        if [ -s "$BLOCKED_IPS_FILE" ]; then
            tail -n 5 "$BLOCKED_IPS_FILE"
        else
            echo "No IPs blocked yet."
        fi
        
        echo -e "\n${CYAN}Press Ctrl+C to exit status view.${NC}"
        sleep 2
    done
}

unblock_ip_menu() {
    blocked_ips=$(cat "$BLOCKED_IPS_FILE")
    if [ -z "$blocked_ips" ]; then
        echo -e "${YELLOW}[!] No IPs currently blocked.${NC}"
        sleep 2
        return
    fi

    ip=$(dialog --menu "Blocked IPs" 15 50 8 $(echo "$blocked_ips" | nl -w2 -s' ' | awk '{print $1, $2}') 3>&1 1>&2 2>&3)
    if [ -n "$ip" ]; then
        selected_ip=$(echo "$blocked_ips" | sed -n "${ip}p")
        iptables -D INPUT -s "$selected_ip" -j DROP
        grep -v "$selected_ip" "$BLOCKED_IPS_FILE" > temp && mv temp "$BLOCKED_IPS_FILE"
        echo -e "${GREEN}[+] Unblocked IP: $selected_ip${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Unblocked IP: $selected_ip" >> "$LOG_FILE"
    fi
}

manual_block_ip() {
    ip=$(dialog --inputbox "Enter IP to block:" 8 40 3>&1 1>&2 2>&3)
    if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        block_ip "$ip"
        echo -e "${GREEN}IP $ip Manually Blocked.${NC}"
        sleep 1
    else
        echo -e "${RED}[!] Invalid IP address.${NC}"
    fi
}

show_blocked_ips() {
    echo -e "${YELLOW}[Blocked IPs]${NC}"
    if [[ -f "$BLOCKED_IPS_FILE" ]]; then
        cat "$BLOCKED_IPS_FILE"
    else
        echo -e "${RED}No blocked IPs recorded yet.${NC}"
    fi
    read -p "Press Enter to return..."
}

# Interactive Loop (Old Monitoring) - kept for manual menu usage
ddos_monitoring_interactive() {
    echo -e "${CYAN}[*] Live DDoS Monitoring (Ctrl+C to stop)...${NC}"
    # Calls status_dashboard effectively, or we can run the loop
    status_dashboard
}

main_menu() {
    while true; do
        clear
        display_header
        echo -e "${CYAN}1.${NC} Live Status Dashboard"
        echo -e "${CYAN}2.${NC} Manually Block an IP"
        echo -e "${CYAN}3.${NC} Manually Unblock IP"
        echo -e "${CYAN}4.${NC} View Blocked IP List"
        echo -e "${CYAN}5.${NC} Exit"
        echo -ne "${YELLOW}Select an option: ${NC}"
        read choice
        case $choice in
            1) status_dashboard ;;
            2) manual_block_ip ;;
            3) unblock_ip_menu ;;
            4) show_blocked_ips ;;
            5) exit ;;
            *) echo -e "${RED}[!] Invalid option.${NC}" ;;
        esac
    done
}

# ARGUMENT HANDLING
case "$1" in
    --daemon)
        daemon_mode
        ;;
    --status)
        status_dashboard
        ;;
    *)
        main_menu
        ;;
esac