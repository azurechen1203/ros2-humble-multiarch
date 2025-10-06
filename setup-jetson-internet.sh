#!/bin/bash
#
# Internet Sharing Setup: Laptop -> Jetson Orin Nano via USB-C
# Run this script on your LAPTOP after connecting Jetson via USB-C
#

set -e

echo "=== Internet Sharing Setup for Jetson Orin Nano ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
USB_INTERFACE="enxa61e56f88050"  # USB-C interface to Jetson
WIFI_INTERFACE="wlo1"             # Your laptop's WiFi interface
JETSON_IP="192.168.55.1"          # Jetson's IP address
LAPTOP_IP="192.168.55.100"        # Your laptop's IP on USB network

echo "Step 1: Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
echo -e "${GREEN}✓ IP forwarding enabled${NC}"
echo ""

echo "Step 2: Setting up NAT (Network Address Translation)..."
# Clear existing NAT rules for these interfaces to avoid duplicates
sudo iptables -t nat -D POSTROUTING -o $WIFI_INTERFACE -j MASQUERADE 2>/dev/null || true
sudo iptables -D FORWARD -i $USB_INTERFACE -o $WIFI_INTERFACE -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -i $WIFI_INTERFACE -o $USB_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

# Add NAT rules
sudo iptables -t nat -A POSTROUTING -o $WIFI_INTERFACE -j MASQUERADE
sudo iptables -A FORWARD -i $USB_INTERFACE -o $WIFI_INTERFACE -j ACCEPT
sudo iptables -A FORWARD -i $WIFI_INTERFACE -o $USB_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
echo -e "${GREEN}✓ NAT rules configured${NC}"
echo ""

echo "Step 3: Verifying Jetson connectivity..."
if ping -c 2 -W 2 $JETSON_IP > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Jetson is reachable at $JETSON_IP${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Cannot ping Jetson at $JETSON_IP${NC}"
    echo "  Make sure Jetson is powered on and USB-C is connected"
fi
echo ""

echo "=== Laptop setup complete! ==="
echo ""
echo "Now run this command on the JETSON (via SSH):"
echo ""
echo -e "${YELLOW}sudo route add default gw $LAPTOP_IP && echo -e 'nameserver 8.8.8.8\nnameserver 8.8.4.4' | sudo tee /etc/resolv.conf${NC}"
echo ""
echo "Test internet on Jetson with: ping 8.8.8.8"
echo ""
