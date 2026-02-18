# Display Management Scripts

Auto-toggle MacBook Pro display when external monitors connect/disconnect using `displayplacer`.

## Compatibility

- **displayplacer v1.4.0+** required (newer versions need full display parameters)
- **macOS 26.3+** tested and working

## Scripts

### setup-display-toggle.sh
One-time installation script. Now offers two monitoring modes:

```bash
chmod +x setup-display-toggle.sh
./setup-display-toggle.sh
```

You'll be prompted to choose:
1. **Reactive mode (recommended)** - Responds instantly to display events
2. **Polling mode** - Checks every 2 seconds

### display-auto-toggle-reactive.sh
Event-driven monitoring script that listens to macOS system logs for display events. Features:
- Instant response to display connection/disconnection
- No constant polling - more efficient
- Uses `log stream` to monitor CoreGraphics events
- Debouncing to handle rapid event sequences
- Logs activity to `~/.display-toggle.log`

### display-auto-toggle.sh
Polling-based monitoring script (legacy mode). Features:
- Checks every 2 seconds for display changes
- Simple and reliable but less efficient
- Logs activity to `~/.display-toggle.log`

**Note:** Both scripts handle newer displayplacer format requirements and filter out "Unable to find screen" messages that appear when toggling displays off.

### toggle-laptop-display.sh
Manual control for the laptop display. Use when you need to override auto-toggle.

```bash
./toggle-laptop-display.sh       # toggle current state
./toggle-laptop-display.sh on    # force laptop display on
./toggle-laptop-display.sh off   # force laptop display off
```

### com.display.autotoggle.plist
LaunchAgent configuration for polling mode (runs display-auto-toggle.sh on login).

### com.display.autotoggle.reactive.plist
LaunchAgent configuration for reactive mode (runs display-auto-toggle-reactive.sh on login).

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

View logs:
```bash
tail -f ~/.display-toggle.log
tail -f /tmp/display-toggle.out
tail -f /tmp/display-toggle.err
```

Check service status:
```bash
launchctl list | grep com.display.autotoggle
```

Test displayplacer manually:
```bash
displayplacer list  # See all displays and their parameters
```