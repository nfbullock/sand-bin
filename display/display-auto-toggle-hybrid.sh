#!/bin/bash

# Hybrid Display Auto-Toggle for macOS - Efficient near-instant response
# Uses lightweight detection with system_profiler, only calls displayplacer when needed

# Install displayplacer if not present
if ! command -v displayplacer &> /dev/null; then
    echo "Installing displayplacer..."
    brew tap jakehilborn/jakehilborn
    brew install displayplacer
fi

# Configuration
LOG_FILE="$HOME/.display-toggle.log"
CHECK_INTERVAL=0.5  # Half second for near-instant response
LAST_DISPLAY_COUNT=-1
LAST_TOGGLE_TIME=0
DEBOUNCE_SECONDS=2

# Lightweight display count using system_profiler
get_display_count_fast() {
    # Count displays in system_profiler output
    system_profiler SPDisplaysDataType 2>/dev/null | grep -c "Display Type:"
}

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

# Count external displays (accurate but slower)
count_external_displays() {
    displayplacer list | grep -c "Type:.*external screen"
}

# Toggle laptop display
toggle_laptop_display() {
    local params="$1"
    local external_count="$2"
    local enabled_state="$3"
    
    # Debounce rapid toggles
    local current_time=$(date +%s)
    if [ $((current_time - LAST_TOGGLE_TIME)) -lt $DEBOUNCE_SECONDS ]; then
        echo "$(date): Skipping toggle (debounce)" >> "$LOG_FILE"
        return
    fi
    LAST_TOGGLE_TIME=$current_time
    
    # Update the enabled parameter
    local new_params=$(echo "$params" | sed "s/enabled:[^ ]*/enabled:$enabled_state/")
    
    # If params don't contain enabled, add it
    if ! echo "$new_params" | grep -q "enabled:"; then
        new_params="$new_params enabled:$enabled_state"
    fi
    
    echo "$(date): Setting laptop display to enabled:$enabled_state (external count: $external_count)" >> "$LOG_FILE"
    displayplacer "$new_params" 2>&1 | grep -v "Unable to find screen" >> "$LOG_FILE"
}

# Handle display change
handle_display_change() {
    # Get accurate external display count
    local external_count=$(count_external_displays)
    
    # Get laptop display info
    local laptop_info=$(get_laptop_display_info)
    
    if [ -n "$laptop_info" ]; then
        # Get laptop parameters
        local laptop_params=$(get_laptop_display_params "$laptop_info")
        
        echo "$(date): Display change detected, external displays: $external_count" >> "$LOG_FILE"
        
        if [ "$external_count" -gt 0 ]; then
            # External display connected - disable laptop
            toggle_laptop_display "$laptop_params" "$external_count" "false"
        else
            # No external display - enable laptop
            toggle_laptop_display "$laptop_params" "$external_count" "true"
        fi
    fi
}

# Main monitoring loop
echo "Starting hybrid display auto-toggle monitor..."
echo "$(date): Hybrid monitor started (${CHECK_INTERVAL}s interval)" >> "$LOG_FILE"

# Initial check
LAST_DISPLAY_COUNT=$(get_display_count_fast)
echo "Initial display count: $LAST_DISPLAY_COUNT"

# Use caffeinate to prevent sleep and ensure consistent monitoring
caffeinate -d -i -s bash << 'EOF' &
CAFFEINATE_PID=$!
EOF

trap "kill $CAFFEINATE_PID 2>/dev/null; exit" EXIT INT TERM

while true; do
    # Fast check for display count change
    CURRENT_COUNT=$(get_display_count_fast)
    
    if [ "$CURRENT_COUNT" != "$LAST_DISPLAY_COUNT" ]; then
        echo "Display count changed: $LAST_DISPLAY_COUNT → $CURRENT_COUNT"
        
        # Small delay to let configuration settle
        sleep 0.5
        
        # Perform the actual toggle
        handle_display_change
        
        LAST_DISPLAY_COUNT=$CURRENT_COUNT
    fi
    
    sleep $CHECK_INTERVAL
done