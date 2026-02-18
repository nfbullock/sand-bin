#!/bin/bash

# Setup script for display auto-toggle

echo "Display Auto-Toggle Setup"
echo "========================="
echo ""
echo "Choose monitoring mode:"
echo "1) Hybrid (recommended) - Fast detection, efficient operation"
echo "2) Reactive - Pure event-driven (may not catch all hub events)"
echo "3) Polling - Checks every 2 seconds (legacy)"
echo ""
read -p "Select mode (1, 2, or 3): " MODE

if [ "$MODE" != "1" ] && [ "$MODE" != "2" ] && [ "$MODE" != "3" ]; then
    echo "Invalid selection. Exiting."
    exit 1
fi

# Get current username
USERNAME=$(whoami)

# Unload any existing services
launchctl unload ~/Library/LaunchAgents/com.display.autotoggle.plist 2>/dev/null
launchctl unload ~/Library/LaunchAgents/com.display.autotoggle.reactive.plist 2>/dev/null
launchctl unload ~/Library/LaunchAgents/com.display.autotoggle.hybrid.plist 2>/dev/null

if [ "$MODE" == "1" ]; then
    # Hybrid mode
    SCRIPT_NAME="display-auto-toggle-hybrid.sh"
    PLIST_NAME="com.display.autotoggle.hybrid.plist"
    echo "Installing hybrid mode..."
elif [ "$MODE" == "2" ]; then
    # Reactive mode
    SCRIPT_NAME="display-auto-toggle-reactive.sh"
    PLIST_NAME="com.display.autotoggle.reactive.plist"
    echo "Installing reactive mode..."
else
    # Polling mode
    SCRIPT_NAME="display-auto-toggle.sh"
    PLIST_NAME="com.display.autotoggle.plist"
    echo "Installing polling mode..."
fi

SCRIPT_PATH="$HOME/$SCRIPT_NAME"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"

# Make script executable
chmod +x "$SCRIPT_NAME"

# Copy script to home directory
cp "$SCRIPT_NAME" "$SCRIPT_PATH"

# Update plist with correct username
sed "s/YOUR_USERNAME/$USERNAME/g" "$PLIST_NAME" > "$PLIST_NAME.tmp"

# Install launch agent
mkdir -p ~/Library/LaunchAgents
cp "$PLIST_NAME.tmp" "$PLIST_PATH"
rm "$PLIST_NAME.tmp"

# Load the launch agent
launchctl load "$PLIST_PATH"

echo "✅ Display auto-toggle installed!"
echo ""
if [ "$MODE" == "1" ]; then
    echo "The hybrid service is now running. It will:"
    echo "- Check every 0.5 seconds using lightweight system_profiler"
    echo "- Only run displayplacer when changes are detected"
    echo "- Disable laptop display when external monitor is connected"
    echo "- Enable laptop display when external monitor is disconnected"
elif [ "$MODE" == "2" ]; then
    echo "The reactive service is now running. It will:"
    echo "- Monitor system logs for display events"
    echo "- Instantly respond to display connection/disconnection events"
    echo "- Disable laptop display when external monitor is connected"
    echo "- Enable laptop display when external monitor is disconnected"
else
    echo "The polling service is now running. It will:"
    echo "- Check every 2 seconds for display changes"
    echo "- Disable laptop display when external monitor is connected"
    echo "- Enable laptop display when external monitor is disconnected"
fi
echo ""
echo "Commands:"
echo "  Check status:  launchctl list | grep com.display.autotoggle"
echo "  View logs:     tail -f ~/.display-toggle.log"
if [ "$MODE" == "1" ]; then
    echo "  View errors:   tail -f /tmp/display-toggle-hybrid.err"
    echo "  Stop service:  launchctl unload ~/Library/LaunchAgents/com.display.autotoggle.hybrid.plist"
    echo "  Start service: launchctl load ~/Library/LaunchAgents/com.display.autotoggle.hybrid.plist"
elif [ "$MODE" == "2" ]; then
    echo "  View errors:   tail -f /tmp/display-toggle-reactive.err"
    echo "  Stop service:  launchctl unload ~/Library/LaunchAgents/com.display.autotoggle.reactive.plist"
    echo "  Start service: launchctl load ~/Library/LaunchAgents/com.display.autotoggle.reactive.plist"
else
    echo "  View errors:   tail -f /tmp/display-toggle.err"
    echo "  Stop service:  launchctl unload ~/Library/LaunchAgents/com.display.autotoggle.plist"
    echo "  Start service: launchctl load ~/Library/LaunchAgents/com.display.autotoggle.plist"
fi