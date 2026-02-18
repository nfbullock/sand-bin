#!/bin/bash

# Setup script for display auto-toggle

echo "Setting up display auto-toggle..."

# Get current username
USERNAME=$(whoami)
SCRIPT_PATH="$HOME/display-auto-toggle.sh"
PLIST_PATH="$HOME/Library/LaunchAgents/com.display.autotoggle.plist"

# Make script executable
chmod +x display-auto-toggle.sh

# Copy script to home directory
cp display-auto-toggle.sh "$SCRIPT_PATH"

# Update plist with correct username
sed "s/YOUR_USERNAME/$USERNAME/g" com.display.autotoggle.plist > com.display.autotoggle.tmp.plist

# Install launch agent
mkdir -p ~/Library/LaunchAgents
cp com.display.autotoggle.tmp.plist "$PLIST_PATH"
rm com.display.autotoggle.tmp.plist

# Load the launch agent
launchctl load "$PLIST_PATH"

echo "✅ Display auto-toggle installed!"
echo ""
echo "The service is now running. It will:"
echo "- Disable laptop display when external monitor is connected"
echo "- Enable laptop display when external monitor is disconnected"
echo ""
echo "Commands:"
echo "  Check status:  launchctl list | grep com.display.autotoggle"
echo "  View logs:     tail -f ~/.display-toggle.log"
echo "  Stop service:  launchctl unload ~/Library/LaunchAgents/com.display.autotoggle.plist"
echo "  Start service: launchctl load ~/Library/LaunchAgents/com.display.autotoggle.plist"