#!/bin/bash

# Display Auto-Toggle for macOS using displayplacer
# Automatically disables laptop display when external monitors are connected

# Install displayplacer if not present
if ! command -v displayplacer &> /dev/null; then
    echo "Installing displayplacer..."
    brew tap jakehilborn/jakehilborn
    brew install displayplacer
fi

# Configuration
LAPTOP_DISPLAY_ID="37D8832A-2D66-02CA-B9F7-8F30A301B230"  # Will be auto-detected
CHECK_INTERVAL=2  # seconds
LOG_FILE="$HOME/.display-toggle.log"

# Get the built-in display ID (laptop screen)
get_laptop_display_id() {
    displayplacer list | grep -B2 "type:built-in" | grep "Persistent screen id:" | awk '{print $4}'
}

# Count external displays
count_external_displays() {
    displayplacer list | grep -c "type:external"
}

# Toggle laptop display
toggle_laptop_display() {
    local laptop_id="$1"
    local external_count="$2"
    
    if [ "$external_count" -gt 0 ]; then
        # External display connected - disable laptop
        echo "$(date): External display detected, disabling laptop display" >> "$LOG_FILE"
        displayplacer "id:$laptop_id enabled:false"
    else
        # No external display - enable laptop
        echo "$(date): No external display, enabling laptop display" >> "$LOG_FILE"
        displayplacer "id:$laptop_id enabled:true"
    fi
}

# Main monitoring loop
echo "Starting display auto-toggle monitor..."
echo "$(date): Monitor started" >> "$LOG_FILE"

# Get laptop display ID on startup
LAPTOP_DISPLAY_ID=$(get_laptop_display_id)
echo "Laptop display ID: $LAPTOP_DISPLAY_ID"

# Track previous state
PREV_EXTERNAL_COUNT=-1

while true; do
    # Get current external display count
    CURRENT_EXTERNAL_COUNT=$(count_external_displays)
    
    # Only act on changes
    if [ "$CURRENT_EXTERNAL_COUNT" != "$PREV_EXTERNAL_COUNT" ]; then
        echo "Display configuration changed: $CURRENT_EXTERNAL_COUNT external display(s)"
        toggle_laptop_display "$LAPTOP_DISPLAY_ID" "$CURRENT_EXTERNAL_COUNT"
        PREV_EXTERNAL_COUNT=$CURRENT_EXTERNAL_COUNT
    fi
    
    sleep $CHECK_INTERVAL
done