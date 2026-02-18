#!/bin/bash

# Manual toggle for laptop display - compatible with displayplacer v1.4.0+

# Set PATH for Apple Silicon Macs
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Install displayplacer if needed
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

# Get full display info
DISPLAY_INFO=$(displayplacer list)

# Extract laptop display details
LAPTOP_INFO=$(echo "$DISPLAY_INFO" | grep -B20 "Type: MacBook built in screen" | tail -21)

if [ -z "$LAPTOP_INFO" ]; then
    echo "Error: Could not find MacBook built-in display"
    exit 1
fi

# Parse display parameters
LAPTOP_ID=$(echo "$LAPTOP_INFO" | grep "Persistent screen id:" | awk '{print $4}')
CURRENT_ENABLED=$(echo "$LAPTOP_INFO" | grep "Enabled:" | awk '{print $2}')

# Get current display mode parameters
CURRENT_MODE=$(echo "$DISPLAY_INFO" | grep -A300 "$LAPTOP_ID" | grep -A200 "Resolutions for rotation" | grep "<-- current mode")
RESOLUTION=$(echo "$CURRENT_MODE" | sed 's/<-- current mode//' | awk '{print $3}' | sed 's/res://')
HERTZ=$(echo "$CURRENT_MODE" | awk '{print $4}' | sed 's/hz://')
COLOR_DEPTH=$(echo "$CURRENT_MODE" | awk '{print $5}' | sed 's/color_depth://')
SCALING=$(echo "$CURRENT_MODE" | awk '{print $6}' | sed 's/scaling://')

# Get position and rotation
ORIGIN=$(echo "$LAPTOP_INFO" | grep "Origin:" | sed 's/.*Origin: //' | sed 's/ -.*//' | tr -d ' ')
ROTATION=$(echo "$LAPTOP_INFO" | grep "Rotation:" | awk '{print $2}')

# Default scaling if not found
if [ -z "$SCALING" ] || [ "$SCALING" = "mode" ]; then
    SCALING="on"
fi

echo "Laptop Display ID: $LAPTOP_ID"
echo "Current State: $CURRENT_ENABLED"
echo "Resolution: $RESOLUTION @ ${HERTZ}Hz"

# Build displayplacer command
build_command() {
    local enabled="$1"
    echo "id:$LAPTOP_ID res:$RESOLUTION hz:$HERTZ color_depth:$COLOR_DEPTH enabled:$enabled scaling:$SCALING origin:$ORIGIN degree:$ROTATION"
}

if [ "$1" == "on" ]; then
    echo "Enabling laptop display..."
    displayplacer "$(build_command true)" 2>&1 | grep -v "Unable to find screen"
elif [ "$1" == "off" ]; then
    echo "Disabling laptop display..."
    displayplacer "$(build_command false)" 2>&1 | grep -v "Unable to find screen"
else
    # Toggle
    if [ "$CURRENT_ENABLED" == "true" ]; then
        echo "Toggling OFF laptop display..."
        displayplacer "$(build_command false)" 2>&1 | grep -v "Unable to find screen"
    else
        echo "Toggling ON laptop display..."
        displayplacer "$(build_command true)" 2>&1 | grep -v "Unable to find screen"
    fi
fi