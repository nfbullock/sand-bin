#!/bin/bash

# Emergency script to force laptop display back on

# Set PATH for Apple Silicon Macs
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "Force-enabling laptop display..."

# Method 1: Try simple enable first
echo "Attempting method 1: Simple enable"
LAPTOP_ID=$(displayplacer list | grep -B2 "Type: MacBook built in screen" | grep "Persistent screen id:" | awk '{print $4}')

if [ -n "$LAPTOP_ID" ]; then
    displayplacer "id:$LAPTOP_ID enabled:true" 2>&1 | grep -v "Unable to find screen"
else
    echo "Could not find laptop display ID"
fi

# Method 2: Use full parameters
echo ""
echo "Attempting method 2: Full parameters"

# Get full display list
DISPLAY_INFO=$(displayplacer list)

# Extract laptop display info and current parameters
LAPTOP_SECTION=$(echo "$DISPLAY_INFO" | grep -B20 "Type: MacBook built in screen" | tail -21)

if [ -n "$LAPTOP_SECTION" ]; then
    # Parse all needed parameters
    ID=$(echo "$LAPTOP_SECTION" | grep "Persistent screen id:" | awk '{print $4}')
    
    # Try common MacBook resolutions if current mode not found
    echo "Trying with detected ID: $ID"
    
    # M1 Pro 14" common resolution
    displayplacer "id:$ID res:2056x1329 hz:120 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0" 2>&1 | grep -v "Unable to find screen"
    
    # If that fails, try other common resolutions
    if [ $? -ne 0 ]; then
        echo "Trying fallback resolutions..."
        # Native resolution
        displayplacer "id:$ID res:3456x2234 hz:120 color_depth:8 enabled:true scaling:off origin:(0,0) degree:0" 2>&1 | grep -v "Unable to find screen"
        # Scaled resolution
        displayplacer "id:$ID res:1728x1117 hz:120 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0" 2>&1 | grep -v "Unable to find screen"
    fi
else
    echo "ERROR: Cannot find built-in MacBook display!"
    echo "This might mean:"
    echo "1. The display is in an unusual state"
    echo "2. displayplacer needs to be restarted"
    echo ""
    echo "Try: killall displayplacer && displayplacer list"
fi

echo ""
echo "Done. If your screen is still dark:"
echo "1. Try closing and opening your laptop lid"
echo "2. Press any key or move the mouse"
echo "3. Try: sudo killall WindowServer (this will log you out!)"