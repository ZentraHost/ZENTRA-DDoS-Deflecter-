#!/bin/bash

# Colors
RED='\033[0;31m'
DARK_RED='\033[38;5;88m'
YELLOW='\033[1;33m'
NC='\033[0m' # Reset

clear
 
echo -e "${DARK_RED}"
echo "███████╗███████╗███╗   ██╗████████╗██████╗  █████╗ "
echo "╚══███╔╝██╔════╝████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗"
echo "  ███╔╝ █████╗  ██╔██╗ ██║   ██║   ██████╔╝███████║"
echo " ███╔╝  ██╔══╝  ██║╚██╗██║   ██║   ██╔══██╗██╔══██║"
echo "███████╗███████╗██║ ╚████║   ██║   ██║  ██║██║  ██║"
echo "╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝"

echo -e "${DARK_RED}"
echo "D   D   O   S    -    D   E   F   L   E   C   T   E   R"
echo -e "${NC}"
 
echo -e "${YELLOW}Enterprise Hosting Support:${NC} https://discord.gg/V4uWMy8bfP"
echo -e "${YELLOW}Technical Community:${NC} https://discord.gg/TmFZNMWuDF"

echo -e "\n${RED}⚠️ SECURITY NOTICE: This script will make significant system changes! ⚠️${NC}\n"
sleep 1

echo -e "${RED}"
echo "┌────────────────────────────────────────────┐"
echo "│  1 - Install or Update ZENTRA DDoS Deflecter │"
echo "│  2 - Remove ZENTRA DDoS Deflecter            │"
echo "│  0 - Exit                                    │"
echo "└────────────────────────────────────────────┘"
echo -e "${NC}"

read -p "Select an option: " choice

INSTALL_DIR="/opt/zentra-ddos"
DEFLECTER_SCRIPT="ddos.sh"
# NOTE: Ensure this URL is correct (removed trailing dash if it was a typo)
DOWNLOAD_URL="https://raw.githubusercontent.com/ZentraHost/ZENTRA-DDoS-Deflecter-/main/ddos.sh"

function install_or_update() {
    echo -e "${DARK_RED}[+] Checking system...${NC}"
    sleep 1
    echo -e "${RED}[+] Installing dependencies...${NC}"
    if [ -f /etc/debian_version ]; then
        sudo apt-get update && sudo apt-get install -y dialog curl iptables
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y dialog curl iptables
    fi

    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}[+] Creating directory $INSTALL_DIR...${NC}"
        sudo mkdir -p "$INSTALL_DIR"
    fi

    echo -e "${RED}[↓] Downloading script...${NC}"
    sudo curl -fsSL "$DOWNLOAD_URL" -o "$INSTALL_DIR/$DEFLECTER_SCRIPT"
    sudo chmod +x "$INSTALL_DIR/$DEFLECTER_SCRIPT"

    # --- 1. SETUP GLOBAL COMMAND 'ddos-status' ---
    echo -e "${RED}[+] Configuring 'ddos-status' command...${NC}"
    echo "#!/bin/bash" | sudo tee /usr/local/bin/ddos-status > /dev/null
    echo "sudo bash $INSTALL_DIR/$DEFLECTER_SCRIPT --status" | sudo tee -a /usr/local/bin/ddos-status > /dev/null
    sudo chmod +x /usr/local/bin/ddos-status

    # --- 2. SETUP SYSTEMD SERVICE (Auto-Start) ---
    echo -e "${RED}[+] Configuring Systemd Auto-Start Service...${NC}"
    cat <<EOF | sudo tee /etc/systemd/system/zentra-ddos.service > /dev/null
[Unit]
Description=ZENTRA DDoS Deflecter Daemon
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash $INSTALL_DIR/$DEFLECTER_SCRIPT --daemon
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable zentra-ddos.service
    sudo systemctl start zentra-ddos.service
    
    echo -e "${GREEN}[✔] ZENTRA Service Started & Enabled on Boot.${NC}"
    echo -e "${GREEN}[✔] You can now type 'ddos-status' anywhere to check the dashboard!${NC}"
    
    # Optional: Launch dashboard immediately
    # sudo bash "$INSTALL_DIR/$DEFLECTER_SCRIPT"
}

function uninstall() {
    echo -e "${RED}[-] Stopping and Removing ZENTRA DDoS Deflecter...${NC}"
    sudo systemctl stop zentra-ddos.service
    sudo systemctl disable zentra-ddos.service
    sudo rm -f /etc/systemd/system/zentra-ddos.service
    sudo systemctl daemon-reload
    
    sudo rm -f /usr/local/bin/ddos-status
    sudo rm -rf "$INSTALL_DIR"
    
    sleep 1
    echo -e "${RED}[✔] Uninstalled successfully.${NC}"
}

case $choice in
    1)
        install_or_update
        ;;
    2)
        uninstall
        ;;
    0)
        echo -e "${YELLOW}Exit. Stay protected with ZENTRA.${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        ;;
esac