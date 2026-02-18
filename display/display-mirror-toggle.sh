#!/bin/bash

# Alternative using display mirroring - when external connected, mirror and close lid

# Set PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

LOG_FILE="$HOME/.display-toggle.log"

echo "Display Mirror Toggle Instructions" 
echo "================================="
echo ""
echo "This approach uses macOS display mirroring:"
echo ""
echo "When external display is connected:"
echo "1. System Preferences > Displays > Arrangement"
echo "2. Check 'Mirror Displays'"
echo "3. Close your laptop lid - external remains active"
echo ""
echo "When external display is disconnected:"
echo "1. Open laptop lid"
echo "2. Uncheck 'Mirror Displays' if desired"
echo ""
echo "Benefits:"
echo "- No dark screen issues"
echo "- System handles display management"
echo "- Reliable recovery (just open lid)"
echo ""

# Try to set mirroring via displayplacer
echo "Attempting to enable mirroring..."

# Get display IDs
DISPLAYS=$(displayplacer list | grep "Persistent screen id:" | awk '{print $4}')
DISPLAY_COUNT=$(echo "$DISPLAYS" | wc -l | tr -d ' ')

if [ "$DISPLAY_COUNT" -gt 1 ]; then
    # Build mirror command
    MIRROR_CMD=""
    for id in $DISPLAYS; do
        if [ -z "$MIRROR_CMD" ]; then
            MIRROR_CMD="id:$id"
        else
            MIRROR_CMD="$MIRROR_CMD+id:$id"
        fi
    done
    
    echo "Enabling mirror mode: $MIRROR_CMD"
    displayplacer "$MIRROR_CMD"
else
    echo "Only one display found, mirroring not applicable"
fi