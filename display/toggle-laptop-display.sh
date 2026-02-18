#!/bin/bash

# Manual toggle for laptop display

# Install displayplacer if needed
if ! command -v displayplacer &> /dev/null; then
    echo "Installing displayplacer..."
    brew tap jakehilborn/jakehilborn
    brew install displayplacer
fi

# Get laptop display info
LAPTOP_INFO=$(displayplacer list | grep -B2 "type:built-in")
LAPTOP_ID=$(echo "$LAPTOP_INFO" | grep "Persistent screen id:" | awk '{print $4}')
CURRENT_STATE=$(echo "$LAPTOP_INFO" | grep -q "enabled:true" && echo "enabled" || echo "disabled")

echo "Laptop Display ID: $LAPTOP_ID"
echo "Current State: $CURRENT_STATE"

if [ "$1" == "on" ]; then
    echo "Enabling laptop display..."
    displayplacer "id:$LAPTOP_ID enabled:true"
elif [ "$1" == "off" ]; then
    echo "Disabling laptop display..."
    displayplacer "id:$LAPTOP_ID enabled:false"
else
    # Toggle
    if [ "$CURRENT_STATE" == "enabled" ]; then
        echo "Toggling OFF laptop display..."
        displayplacer "id:$LAPTOP_ID enabled:false"
    else
        echo "Toggling ON laptop display..."
        displayplacer "id:$LAPTOP_ID enabled:true"
    fi
fi