#!/bin/bash

# Optimized Display Auto-Toggle for macOS
# Uses displayplacer list for counting but avoids heavy operations until needed

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
LOG_FILE="$HOME/.display-toggle.log"
CHECK_INTERVAL=1  # 1 second for good balance
LAST_EXTERNAL_COUNT=-1
LAST_TOGGLE_TIME=0
DEBOUNCE_SECONDS=2
LAPTOP_ENABLED_STATE="unknown"

# Count external displays (lightweight - just grep)
count_external_displays_fast() {
    displayplacer list | grep -c "Type:.*external screen"
}

# Check if laptop display is enabled (lightweight - just grep)
is_laptop_enabled_fast() {
    displayplacer list | grep -A5 "Type: MacBook built in screen" | grep -q "Enabled: true"
}

# Get the built-in display info (only when needed)
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

# Toggle laptop display (only when state change needed)
toggle_laptop_display() {
    local external_count="$1"
    local desired_state="$2"
    
    # Debounce rapid toggles
    local current_time=$(date +%s)
    if [ $((current_time - LAST_TOGGLE_TIME)) -lt $DEBOUNCE_SECONDS ]; then
        echo "$(date): Skipping toggle (debounce)" >> "$LOG_FILE"
        return
    fi
    
    # Get laptop display info
    local laptop_info=$(get_laptop_display_info)
    
    if [ -z "$laptop_info" ]; then
        echo "$(date): ERROR: Could not find laptop display" >> "$LOG_FILE"
        return
    fi
    
    # Get laptop parameters
    local laptop_params=$(get_laptop_display_params "$laptop_info")
    
    # Update the enabled parameter
    local new_params=$(echo "$laptop_params" | sed "s/enabled:[^ ]*/enabled:$desired_state/")
    
    # If params don't contain enabled, add it
    if ! echo "$new_params" | grep -q "enabled:"; then
        new_params="$new_params enabled:$desired_state"
    fi
    
    echo "$(date): Setting laptop display to enabled:$desired_state (external count: $external_count)" >> "$LOG_FILE"
    displayplacer "$new_params" 2>&1 | grep -v "Unable to find screen" >> "$LOG_FILE"
    
    LAST_TOGGLE_TIME=$current_time
    LAPTOP_ENABLED_STATE=$desired_state
}

# Main monitoring loop
echo "Starting optimized display auto-toggle monitor..."
echo "$(date): Optimized monitor started (${CHECK_INTERVAL}s interval)" >> "$LOG_FILE"

# Test displayplacer is working
if ! displayplacer list &>/dev/null; then
    echo "Error: displayplacer not working properly" >> "$LOG_FILE"
    exit 1
fi

# Initial state
LAST_EXTERNAL_COUNT=$(count_external_displays_fast)
if is_laptop_enabled_fast; then
    LAPTOP_ENABLED_STATE="true"
else
    LAPTOP_ENABLED_STATE="false"
fi

echo "Initial state: $LAST_EXTERNAL_COUNT external display(s), laptop enabled: $LAPTOP_ENABLED_STATE"
echo "$(date): Initial state: external=$LAST_EXTERNAL_COUNT, laptop=$LAPTOP_ENABLED_STATE" >> "$LOG_FILE"

# Main loop
while true; do
    # Count external displays
    CURRENT_EXTERNAL_COUNT=$(count_external_displays_fast)
    
    # Determine desired laptop state
    if [ "$CURRENT_EXTERNAL_COUNT" -gt 0 ]; then
        DESIRED_LAPTOP_STATE="false"
    else
        DESIRED_LAPTOP_STATE="true"
    fi
    
    # Check if we need to toggle
    if [ "$CURRENT_EXTERNAL_COUNT" != "$LAST_EXTERNAL_COUNT" ] || [ "$LAPTOP_ENABLED_STATE" != "$DESIRED_LAPTOP_STATE" ]; then
        echo "Change detected: external=$CURRENT_EXTERNAL_COUNT (was $LAST_EXTERNAL_COUNT), laptop should be $DESIRED_LAPTOP_STATE (is $LAPTOP_ENABLED_STATE)"
        
        # Only toggle if state doesn't match desired
        if [ "$LAPTOP_ENABLED_STATE" != "$DESIRED_LAPTOP_STATE" ]; then
            # Small delay to let configuration settle
            sleep 0.5
            
            # Perform toggle
            toggle_laptop_display "$CURRENT_EXTERNAL_COUNT" "$DESIRED_LAPTOP_STATE"
            
            # Update state
            LAPTOP_ENABLED_STATE=$DESIRED_LAPTOP_STATE
        fi
        
        LAST_EXTERNAL_COUNT=$CURRENT_EXTERNAL_COUNT
    fi
    
    sleep $CHECK_INTERVAL
done