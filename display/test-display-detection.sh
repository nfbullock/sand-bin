#!/bin/bash

# Test script to diagnose display detection issues

# Set PATH for Apple Silicon Macs
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "=== Display Detection Test ==="
echo "PATH: $PATH"
echo ""

# Check displayplacer
echo "1. Checking displayplacer installation:"
which displayplacer || echo "ERROR: displayplacer not found!"
echo ""

# Count displays
echo "2. Counting displays:"
echo "   Total displays: $(displayplacer list | grep -c 'Persistent screen id:')"
echo "   External displays: $(displayplacer list | grep -c 'Type:.*external screen')"
echo "   Built-in displays: $(displayplacer list | grep -c 'Type: MacBook built in screen')"
echo ""

# Show laptop display info
echo "3. Laptop display info:"
displayplacer list | grep -B5 -A15 "Type: MacBook built in screen" || echo "ERROR: No built-in display found!"
echo ""

# Check laptop enabled state
echo "4. Laptop display enabled:"
if displayplacer list | grep -A5 "Type: MacBook built in screen" | grep -q "Enabled: true"; then
    echo "   YES (enabled)"
else
    echo "   NO (disabled)"
fi
echo ""

# Show external displays
echo "5. External displays:"
displayplacer list | grep -B5 "Type:.*external screen" || echo "   No external displays found"
echo ""

echo "6. Test detection loop (5 seconds):"
echo "   Unplug/plug your display to see if detection works..."
for i in {1..5}; do
    EXT_COUNT=$(displayplacer list | grep -c 'Type:.*external screen')
    echo "   Second $i: $EXT_COUNT external display(s)"
    sleep 1
done