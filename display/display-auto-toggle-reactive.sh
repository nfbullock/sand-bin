#!/bin/bash

# Reactive Display Auto-Toggle for macOS using displayplacer v1.4.0+
# Listens to macOS display events instead of polling

# Install displayplacer if not present
if ! command -v displayplacer &> /dev/null; then
    echo "Installing displayplacer..."
    brew tap jakehilborn/jakehilborn
    brew install displayplacer
fi

# Configuration
LOG_FILE="$HOME/.display-toggle.log"
LAST_ACTION_TIME=0
DEBOUNCE_SECONDS=2

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
    
    echo "$(date): Setting laptop display to enabled:$enabled_state (external count: $external_count)" >> "$LOG_FILE"
    displayplacer "$new_params" 2>&1 | grep -v "Unable to find screen" >> "$LOG_FILE"
}

# Handle display change event
handle_display_change() {
    # Debounce rapid events
    local current_time=$(date +%s)
    if [ $((current_time - LAST_ACTION_TIME)) -lt $DEBOUNCE_SECONDS ]; then
        return
    fi
    LAST_ACTION_TIME=$current_time
    
    # Small delay to let display configuration settle
    sleep 0.5
    
    # Get current laptop display info
    local laptop_info=$(get_laptop_display_info)
    
    if [ -n "$laptop_info" ]; then
        # Get laptop parameters
        local laptop_params=$(get_laptop_display_params "$laptop_info")
        
        # Get current external display count
        local external_count=$(count_external_displays)
        
        echo "$(date): Display event detected, external displays: $external_count" >> "$LOG_FILE"
        
        if [ "$external_count" -gt 0 ]; then
            # External display connected - disable laptop
            toggle_laptop_display "$laptop_params" "$external_count" "false"
        else
            # No external display - enable laptop
            toggle_laptop_display "$laptop_params" "$external_count" "true"
        fi
    fi
}

# Initial state check
echo "Starting reactive display auto-toggle monitor..."
echo "$(date): Reactive monitor started" >> "$LOG_FILE"
handle_display_change

# Monitor display events via log stream
echo "Monitoring display events (reactive mode)..."

# Watch for display configuration changes in system logs
log stream --predicate '
    eventMessage CONTAINS "Display reconfiguration" OR
    eventMessage CONTAINS "CGSDisplayReconfiguration" OR
    eventMessage CONTAINS "displays changed" OR
    eventMessage CONTAINS "Display added" OR
    eventMessage CONTAINS "Display removed" OR
    subsystem == "com.apple.CoreGraphics" OR
    subsystem == "com.apple.windowserver.displays"
' --style compact | while read -r line; do
    # Check if this line indicates a display change
    if echo "$line" | grep -qE "(reconfigur|display.*change|display.*add|display.*remove|CGSDisplay)"; then
        echo "$(date): Display event detected: $line" >> "$LOG_FILE"
        handle_display_change
    fi
done