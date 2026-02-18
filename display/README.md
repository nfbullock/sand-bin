# Display Management Scripts

Auto-toggle MacBook Pro display when external monitors connect/disconnect using `displayplacer`.

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
- `displayplacer` (installed automatically by scripts)

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