# Display Management Scripts

Auto-toggle MacBook Pro display when external monitors connect/disconnect using `displayplacer`.

## Compatibility

- **displayplacer v1.4.0+** required (newer versions need full display parameters)
- **macOS 26.3+** tested and working

## Scripts

### setup-display-toggle.sh
One-time installation script. Installs the auto-toggle service as a LaunchAgent.

```bash
chmod +x setup-display-toggle.sh
./setup-display-toggle.sh
```

### display-auto-toggle.sh
Main monitoring script that runs in the background. Automatically:
- Disables laptop display when external monitor connects
- Re-enables laptop display when all external monitors disconnect
- Checks every 2 seconds for display changes
- Logs activity to `~/.display-toggle.log`

**Note:** The script now handles newer displayplacer format requirements and filters out "Unable to find screen" messages that appear when toggling displays off.

### toggle-laptop-display.sh
Manual control for the laptop display. Use when you need to override auto-toggle.

```bash
./toggle-laptop-display.sh       # toggle current state
./toggle-laptop-display.sh on    # force laptop display on
./toggle-laptop-display.sh off   # force laptop display off
```

### com.display.autotoggle.plist
LaunchAgent configuration that runs display-auto-toggle.sh on login.

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