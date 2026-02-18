#!/bin/bash

# Simple Display Auto-Toggle - No state tracking, just toggle based on external count

# Set PATH for Apple Silicon Macs
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Install displayplacer if not present
if ! command -v displayplacer &> /dev/null; then
    echo "ERROR: displayplacer not found at startup!" >> "$HOME/.display-toggle.log"
    exit 1
fi

# Configuration
LOG_FILE="$HOME/.display-toggle.log"
CHECK_INTERVAL=2  # Check every 2 seconds
LAST_ACTION=""

echo "$(date): Simple monitor started" >> "$LOG_FILE"

# Function to enable laptop display
enable_laptop() {
    echo "$(date): Enabling laptop display" >> "$LOG_FILE"
    
    # Get laptop ID
    local laptop_id=$(displayplacer list | grep -B2 "Type: MacBook built in screen" | grep "Persistent screen id:" | awk '{print $4}')
    
    if [ -z "$laptop_id" ]; then
        echo "$(date): ERROR: Cannot find laptop display!" >> "$LOG_FILE"
        return
    fi
    
    # Try with common M1 Pro 14" parameters
    displayplacer "id:$laptop_id res:2056x1329 hz:120 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0" 2>&1 >> "$LOG_FILE"
}

# Function to disable laptop display
disable_laptop() {
    echo "$(date): Disabling laptop display" >> "$LOG_FILE"
    
    # Get laptop ID
    local laptop_id=$(displayplacer list | grep -B2 "Type: MacBook built in screen" | grep "Persistent screen id:" | awk '{print $4}')
    
    if [ -z "$laptop_id" ]; then
        echo "$(date): ERROR: Cannot find laptop display!" >> "$LOG_FILE"
        return
    fi
    
    # Get current parameters to maintain them
    local laptop_info=$(displayplacer list | grep -B20 "Type: MacBook built in screen" | tail -21)
    local res=$(echo "$laptop_info" | grep -A200 "Resolutions for rotation" | grep "<-- current mode" | sed 's/<-- current mode//' | awk '{print $3}' | sed 's/res://')
    local hz=$(echo "$laptop_info" | grep -A200 "Resolutions for rotation" | grep "<-- current mode" | awk '{print $4}' | sed 's/hz://')
    
    # Defaults if not found
    [ -z "$res" ] && res="2056x1329"
    [ -z "$hz" ] && hz="120"
    
    displayplacer "id:$laptop_id res:$res hz:$hz color_depth:8 enabled:false scaling:on origin:(0,0) degree:0" 2>&1 >> "$LOG_FILE"
}

# Main loop
while true; do
    # Count external displays
    EXTERNAL_COUNT=$(displayplacer list 2>/dev/null | grep -c 'Type:.*external screen')
    
    # Decide what to do
    if [ "$EXTERNAL_COUNT" -gt 0 ]; then
        # External display connected - disable laptop
        if [ "$LAST_ACTION" != "disabled" ]; then
            echo "$(date): Detected $EXTERNAL_COUNT external display(s)" >> "$LOG_FILE"
            disable_laptop
            LAST_ACTION="disabled"
        fi
    else
        # No external display - enable laptop
        if [ "$LAST_ACTION" != "enabled" ]; then
            echo "$(date): No external displays detected" >> "$LOG_FILE"
            enable_laptop
            LAST_ACTION="enabled"
        fi
    fi
    
    sleep $CHECK_INTERVAL
done