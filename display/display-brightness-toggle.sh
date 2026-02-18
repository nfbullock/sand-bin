#!/bin/bash

# Alternative approach using brightness control instead of disabling display
# This avoids the critical flaw where disabled displays disappear

# Set PATH for Apple Silicon Macs
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Install brightness if not present
if ! command -v brightness &> /dev/null; then
    echo "Installing brightness tool..."
    if command -v brew &> /dev/null; then
        brew install brightness
    else
        echo "Error: Please install brightness tool manually"
        exit 1
    fi
fi

# Configuration
LOG_FILE="$HOME/.display-toggle.log"
CHECK_INTERVAL=2
LAST_EXTERNAL_COUNT=-1

echo "$(date): Brightness-based toggle started" >> "$LOG_FILE"

# Get display IDs using brightness tool
get_display_ids() {
    brightness -l | grep "display" | awk -F'display ' '{print $2}' | awk '{print $1}'
}

# Set brightness for built-in display
set_builtin_brightness() {
    local brightness_val="$1"
    # Display 0 is typically the built-in display
    brightness -d 0 -v "$brightness_val" 2>&1 >> "$LOG_FILE"
    echo "$(date): Set built-in display brightness to $brightness_val" >> "$LOG_FILE"
}

# Count external displays using displayplacer (still reliable for counting)
count_external_displays() {
    displayplacer list 2>/dev/null | grep -c 'Type:.*external screen'
}

# Main loop
while true; do
    EXTERNAL_COUNT=$(count_external_displays)
    
    if [ "$EXTERNAL_COUNT" != "$LAST_EXTERNAL_COUNT" ]; then
        echo "$(date): Display configuration changed, external: $EXTERNAL_COUNT" >> "$LOG_FILE"
        
        if [ "$EXTERNAL_COUNT" -gt 0 ]; then
            # External display connected - dim laptop to minimum
            set_builtin_brightness 0.0
        else
            # No external display - restore laptop brightness
            set_builtin_brightness 1.0
        fi
        
        LAST_EXTERNAL_COUNT=$EXTERNAL_COUNT
    fi
    
    sleep $CHECK_INTERVAL
done