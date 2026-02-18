# Display Management Scripts

Auto-toggle MacBook Pro display when external monitors connect/disconnect using `displayplacer`.

## Compatibility

- **displayplacer v1.4.0+** required (newer versions need full display parameters)
- **macOS 26.3+** tested and working
- **Apple Silicon Macs** - Scripts include PATH fix for Homebrew in `/opt/homebrew/bin`
- **Intel Macs** - Also supported with Homebrew in `/usr/local/bin`

## Scripts

### setup-display-toggle.sh
One-time installation script. Now offers three monitoring modes:

```bash
chmod +x setup-display-toggle.sh
./setup-display-toggle.sh
```

You'll be prompted to choose:
1. **Hybrid mode (recommended)** - Fast detection with efficient operation
2. **Reactive mode** - Pure event-driven (may not catch all hub events)
3. **Polling mode** - Checks every 2 seconds (legacy)

### display-auto-toggle-hybrid.sh
Optimized monitoring that balances speed with efficiency. Features:
- Uses lightweight displayplacer greps for counting (reliable)
- Only parses full display parameters when toggle is needed
- 1-second check interval for responsive feel
- Tracks state to avoid unnecessary toggles
- Clear logging shows what's happening
- Logs activity to `~/.display-toggle.log`

### display-auto-toggle-reactive.sh
Event-driven monitoring script that listens to macOS system logs for display events. Features:
- Instant response to display connection/disconnection
- No constant polling - most efficient
- Uses `log stream` to monitor CoreGraphics events
- May not catch all USB hub events
- Logs activity to `~/.display-toggle.log`

### display-auto-toggle.sh
Polling-based monitoring script (legacy mode). Features:
- Checks every 2 seconds for display changes
- Simple and reliable but least efficient
- Logs activity to `~/.display-toggle.log`

**Note:** Both scripts handle newer displayplacer format requirements and filter out "Unable to find screen" messages that appear when toggling displays off.

### toggle-laptop-display.sh
Manual control for the laptop display. Use when you need to override auto-toggle.

```bash
./toggle-laptop-display.sh       # toggle current state
./toggle-laptop-display.sh on    # force laptop display on
./toggle-laptop-display.sh off   # force laptop display off
```

### force-laptop-display-on.sh
Emergency script when your laptop screen goes dark and won't come back.

```bash
./force-laptop-display-on.sh
```

### test-display-detection.sh
Diagnostic tool to check if display detection is working properly.

```bash
./test-display-detection.sh
```

### display-auto-toggle-simple.sh
Simplified version without state tracking - just toggles based on external display count.

```bash
./display-auto-toggle-simple.sh  # Run manually to test

### com.display.autotoggle.plist
LaunchAgent configuration for polling mode (runs display-auto-toggle.sh on login).

### com.display.autotoggle.reactive.plist
LaunchAgent configuration for reactive mode (runs display-auto-toggle-reactive.sh on login).

### com.display.autotoggle.hybrid.plist
LaunchAgent configuration for hybrid mode (runs display-auto-toggle-hybrid.sh on login).

## Requirements

- macOS
- Homebrew (for installing displayplacer)
- `displayplacer` v1.4.0+ (installed automatically by scripts)

## Known Issues

- When disabling a display, displayplacer may show "Unable to find screen" messages. This is normal behavior and the scripts filter these out.
- On macOS 26.3+, displayplacer requires full display parameters (resolution, hz, color depth, etc.) to avoid segmentation faults.

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.display.autotoggle.plist
rm ~/Library/LaunchAgents/com.display.autotoggle.plist
rm ~/display-auto-toggle.sh
```

## Troubleshooting

### Screen went dark and won't come back:
```bash
./force-laptop-display-on.sh
```

### Service not detecting displays:
```bash
./test-display-detection.sh
```

### View logs:
```bash
tail -f ~/.display-toggle.log
tail -f /tmp/display-toggle.out
tail -f /tmp/display-toggle-hybrid.err  # or -reactive.err, or .err depending on mode
```

### Check service status:
```bash
launchctl list | grep com.display.autotoggle
```

### Test displayplacer manually:
```bash
displayplacer list  # See all displays and their parameters
```

### If nothing works:
1. Try closing and opening laptop lid
2. Restart the WindowServer: `sudo killall WindowServer` (logs you out!)
3. Try the simple version: `./display-auto-toggle-simple.sh`