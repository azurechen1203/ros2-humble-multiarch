#!/bin/bash


# Internet Sharing Setup: Laptop -> Remote Device
# Run this script on your LAPTOP after connecting device via USB-C or Ethernet

set -e

################################################################################
# Configuration
################################################################################

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NO_COLOUR='\033[0m'

# Laptop WiFi interface
WIFI_INTERFACE="wlo1"

# USB-C connection profile (auto-configured network)
USBC_INTERFACE="enxa61e56f88050"    # USB-C interface
USBC_DEVICE_IP="192.168.55.1"       # Device's IP address
USBC_LAPTOP_IP="192.168.55.100"     # Laptop's IP on USB network

# Ethernet connection profile (manual configuration required)
ETH_INTERFACE="eno2"                # Ethernet interface
ETH_LAPTOP_IP="192.168.137.1"       # Laptop's IP on Ethernet network
ETH_DEVICE_IP="192.168.137.2"       # Device's IP

################################################################################
# Connection Type Selection
################################################################################

echo "=== Internet Sharing Setup ==="
echo ""
echo "Select connection type:"
echo "  1) USB-C (auto-configured network)"
echo "  2) Ethernet (requires manual setup)"
echo "  3) Auto-detect"
echo ""
read -p "Enter choice [1-3]: " CONNECTION_CHOICE

case $CONNECTION_CHOICE in
    1)
        CONNECTION_TYPE="usbc"
        ;;
    2)
        CONNECTION_TYPE="ethernet"
        ;;
    3)
        # Auto-detect based on interface availability
        if ip link show "$USBC_INTERFACE" &>/dev/null; then
            CONNECTION_TYPE="usbc"
            echo -e "${GREEN}Detected: USB-C connection${NO_COLOUR}"
        elif ip link show "$ETH_INTERFACE" &>/dev/null; then
            CONNECTION_TYPE="ethernet"
            echo -e "${GREEN}Detected: Ethernet connection${NO_COLOUR}"
        else
            echo -e "${RED}Error: Could not detect connection. Check cables.${NO_COLOUR}"
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}Invalid choice${NO_COLOUR}"
        exit 1
        ;;
esac

################################################################################
# Set Connection-Specific Variables
################################################################################

if [ "$CONNECTION_TYPE" = "usbc" ]; then
    TARGET_INTERFACE="$USBC_INTERFACE"
    DEVICE_IP="$USBC_DEVICE_IP"
    LAPTOP_IP="$USBC_LAPTOP_IP"
    CONNECTION_NAME="USB-C"
else
    TARGET_INTERFACE="$ETH_INTERFACE"
    DEVICE_IP="$ETH_DEVICE_IP"
    LAPTOP_IP="$ETH_LAPTOP_IP"
    CONNECTION_NAME="Ethernet"
fi

echo ""
echo -e "${BLUE}=== Setting up internet sharing via $CONNECTION_NAME ===${NO_COLOUR}"
echo ""

################################################################################
# Step 1: Enable IP Forwarding
################################################################################

echo "Step 1: Enabling IP forwarding..."

sudo sysctl -w net.ipv4.ip_forward=1
echo -e "${GREEN}✓ IP forwarding enabled${NO_COLOUR}"
echo ""

################################################################################
# Step 2: Configure Network Interface
################################################################################

echo "Step 2: Configuring network interface..."

if [ "$CONNECTION_TYPE" = "ethernet" ]; then
    # For Ethernet, set static IP on laptop's interface
    if ! ip addr show "$TARGET_INTERFACE" | grep -q "$LAPTOP_IP"; then
        sudo ip addr add "$LAPTOP_IP/24" dev "$TARGET_INTERFACE" 2>/dev/null || true
        sudo ip link set "$TARGET_INTERFACE" up
        echo -e "${GREEN}✓ Configured $TARGET_INTERFACE with IP $LAPTOP_IP${NO_COLOUR}"
    else
        echo -e "${GREEN}✓ $TARGET_INTERFACE already configured${NO_COLOUR}"
    fi
else
    # For USB-C, network is auto-configured
    echo -e "${GREEN}✓ Using auto-configured USB-C network${NO_COLOUR}"
fi
echo ""

################################################################################
# Step 3: Setup NAT (Network Address Translation)
################################################################################

echo "Step 3: Setting up NAT (Network Address Translation)..."

# Clear existing NAT rules for these interfaces to avoid duplicates
sudo iptables -t nat -D POSTROUTING -o $WIFI_INTERFACE -j MASQUERADE 2>/dev/null || true
sudo iptables -D FORWARD -i $TARGET_INTERFACE -o $WIFI_INTERFACE -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -i $WIFI_INTERFACE -o $TARGET_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

# Add NAT rules
sudo iptables -t nat -A POSTROUTING -o $WIFI_INTERFACE -j MASQUERADE
sudo iptables -A FORWARD -i $TARGET_INTERFACE -o $WIFI_INTERFACE -j ACCEPT
sudo iptables -A FORWARD -i $WIFI_INTERFACE -o $TARGET_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
echo -e "${GREEN}✓ NAT rules configured${NO_COLOUR}"
echo ""

################################################################################
# Step 4: Verify Device Connectivity
################################################################################

echo "Step 4: Verifying device connectivity..."

if ping -c 2 -W 2 $DEVICE_IP > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Device is reachable at $DEVICE_IP${NO_COLOUR}"
else
    echo -e "${YELLOW}⚠ Warning: Cannot ping device at $DEVICE_IP${NO_COLOUR}"
    if [ "$CONNECTION_TYPE" = "usbc" ]; then
        echo "  Make sure device is powered on and USB-C is connected"
    else
        echo "  Make sure device is powered on and Ethernet is connected"
        echo "  You may need to configure the device first (see instructions below)"
    fi
fi
echo ""

################################################################################
# Device Configuration Instructions
################################################################################

echo "=== Laptop setup complete! ==="
echo ""

# SSH Access Instructions
echo "--- SSH access to the device ---"
if [ "$CONNECTION_TYPE" = "usbc" ]; then
    echo "SSH to device using:"
    echo -e "  - IP address: ${BLUE}ssh user@$DEVICE_IP${NO_COLOUR}"
    echo -e "  - mDNS: ${BLUE}ssh user@hostname.local${NO_COLOUR}"
else
    echo "To access the device, you can either:"
    echo "  - Connect monitor/keyboard directly, OR"
    echo -e "  - SSH using mDNS: ${BLUE}ssh user@hostname.local${NO_COLOUR}"
    echo "    (e.g., ssh user@raspberrypi.local or ssh user@jetson.local)"
fi
echo ""

# Device Configuration Commands
echo "--- Commands to run on the DEVICE ---"
if [ "$CONNECTION_TYPE" = "usbc" ]; then
    echo -e "${YELLOW}sudo route del default 2>/dev/null || true${NO_COLOUR}"
    echo -e "${YELLOW}sudo route add default gw $LAPTOP_IP${NO_COLOUR}"
    echo -e "${YELLOW}echo -e 'nameserver 8.8.8.8\nnameserver 8.8.4.4' | sudo tee /etc/resolv.conf${NO_COLOUR}"
else
    echo -e "${YELLOW}sudo ip addr flush dev eth0${NO_COLOUR}"
    echo -e "${YELLOW}sudo ip addr add $DEVICE_IP/24 dev eth0${NO_COLOUR}"
    echo -e "${YELLOW}sudo ip route del default 2>/dev/null || true${NO_COLOUR}"
    echo -e "${YELLOW}sudo ip route add default via $LAPTOP_IP${NO_COLOUR}"
    echo -e "${YELLOW}echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf${NO_COLOUR}"
fi
echo ""
echo -e "${BLUE}Test internet on device with: ping 8.8.8.8${NO_COLOUR}"
echo ""
