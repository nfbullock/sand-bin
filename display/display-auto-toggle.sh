#!/bin/bash

# Display Auto-Toggle for macOS using displayplacer v1.4.0+
# Automatically disables laptop display when external monitors are connected

# Set PATH for Apple Silicon Macs
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Install displayplacer if not present
if ! command -v displayplacer &> /dev/null; then
    echo "Installing displayplacer..."
    if command -v brew &> /dev/null; then
        brew tap jakehilborn/jakehilborn
        brew install displayplacer
    else
        echo "Error: Homebrew not found. Please install displayplacer manually."
        exit 1
    fi
fi

# Configuration
CHECK_INTERVAL=2  # seconds
LOG_FILE="$HOME/.display-toggle.log"

# Get the built-in display info
get_laptop_display_info() {
    displayplacer list | grep -B20 "Type: MacBook built in screen" | tail -21
}

# Get laptop display parameters from current config
get_laptop_display_params() {
    local info="$1"
    local id=$(echo "$info" | grep "Persistent screen id:" | awk '{print $4}')
    local res=$(echo "$info" | grep -A200 "Resolutions for rotation" | grep "<-- current mode" | sed 's/<-- current mode//' | awk '{print $3}' | sed 's/res://')
    local hz=$(echo "$info" | grep -A200 "Resolutions for rotation" | grep "<-- current mode" | awk '{print $4}' | sed 's/hz://')
    local color=$(echo "$info" | grep -A200 "Resolutions for rotation" | grep "<-- current mode" | awk '{print $5}' | sed 's/color_depth://')
    local scaling=$(echo "$info" | grep -A200 "Resolutions for rotation" | grep "<-- current mode" | awk '{print $6}' | sed 's/scaling://')
    local origin=$(echo "$info" | grep "Origin:" | sed 's/.*Origin: //' | sed 's/ -.*//' | tr -d ' ')
    local rotation=$(echo "$info" | grep "Rotation:" | awk '{print $2}')
    
    # Default scaling if not found
    if [ -z "$scaling" ] || [ "$scaling" = "mode" ]; then
        scaling="on"
    fi
    
    echo "id:$id res:$res hz:$hz color_depth:$color scaling:$scaling origin:$origin degree:$rotation"
}

# Count external displays
count_external_displays() {
    displayplacer list | grep -c "Type:.*external screen"
}

# Toggle laptop display
toggle_laptop_display() {
    local params="$1"
    local external_count="$2"
    local enabled_state="$3"
    
    # Update the enabled parameter
    local new_params=$(echo "$params" | sed "s/enabled:[^ ]*/enabled:$enabled_state/")
    
    # If params don't contain enabled, add it
    if ! echo "$new_params" | grep -q "enabled:"; then
        new_params="$new_params enabled:$enabled_state"
    fi
    
    echo "$(date): Setting laptop display to enabled:$enabled_state" >> "$LOG_FILE"
    displayplacer "$new_params" 2>&1 | grep -v "Unable to find screen" >> "$LOG_FILE"
}

# Main monitoring loop
echo "Starting display auto-toggle monitor for displayplacer v1.4.0+..."
echo "$(date): Monitor started" >> "$LOG_FILE"

# Track previous state
PREV_EXTERNAL_COUNT=-1
LAPTOP_PARAMS=""

while true; do
    # Get current laptop display info
    LAPTOP_INFO=$(get_laptop_display_info)
    
    # Only process if we found the laptop display
    if [ -n "$LAPTOP_INFO" ]; then
        # Get laptop parameters
        LAPTOP_PARAMS=$(get_laptop_display_params "$LAPTOP_INFO")
        
        # Get current external display count
        CURRENT_EXTERNAL_COUNT=$(count_external_displays)
        
        # Only act on changes
        if [ "$CURRENT_EXTERNAL_COUNT" != "$PREV_EXTERNAL_COUNT" ]; then
            echo "Display configuration changed: $CURRENT_EXTERNAL_COUNT external display(s)"
            
            if [ "$CURRENT_EXTERNAL_COUNT" -gt 0 ]; then
                # External display connected - disable laptop
                toggle_laptop_display "$LAPTOP_PARAMS" "$CURRENT_EXTERNAL_COUNT" "false"
            else
                # No external display - enable laptop
                toggle_laptop_display "$LAPTOP_PARAMS" "$CURRENT_EXTERNAL_COUNT" "true"
            fi
            
            PREV_EXTERNAL_COUNT=$CURRENT_EXTERNAL_COUNT
        fi
    fi
    
    sleep $CHECK_INTERVAL
done