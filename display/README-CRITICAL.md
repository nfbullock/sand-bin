# CRITICAL ISSUE - PLEASE READ

## The Problem

**displayplacer has a critical flaw**: When you disable a display with `enabled:false`, it disappears from `displayplacer list` entirely. This means you CANNOT re-enable it using displayplacer.

## What This Means

1. The auto-toggle scripts can disable your laptop screen
2. They CANNOT bring it back
3. You're left with a dark screen

## Recovery Options

If your screen goes dark:

1. **Close and reopen your laptop lid** (easiest)
2. **Connect external display and use System Preferences** > Displays > Mirror
3. **Nuclear option**: `sudo killall WindowServer` (logs you out)

## Alternative Approaches

Instead of the flawed display toggle approach, consider:

### Option 1: Brightness Control
```bash
./display-brightness-toggle.sh
```
This dims the laptop screen to 0% instead of disabling it. Screen stays active but black.

### Option 2: Manual Mirroring
```bash
./display-mirror-toggle.sh
```
Use macOS's built-in mirror mode and close your lid when using external display.

### Option 3: Don't Auto-Toggle
Just manually use System Preferences > Displays when needed. It's more reliable.

## Bottom Line

The displayplacer-based auto-toggle approach is fundamentally broken. It can disable your screen but can't reliably re-enable it. Use alternatives or accept manual control.