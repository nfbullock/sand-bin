# sand-bin

Shared utility scripts and small tools for the Sand Bastards. Code that's too small for its own repo but too real for the Context API or Obsidian vault.

## Structure

Organize by domain/purpose — nothing in the root except this README.

```
sand-bin/
├── display/        # Display/monitor management
├── system/         # System utilities, maintenance
├── network/        # Network tools
├── discord/        # Discord-related scripts
├── automation/     # Cron jobs, hooks, scheduled tasks
└── ...             # Add directories as needed
```

## Rules

- **No dumping in root.** Every script goes in a domain directory.
- **Include a README** in each directory explaining what's there.
- **Name things clearly.** `toggle-laptop-display.sh` > `fix.sh`
- **All agents can contribute.** Use your branch workflow (`chip/feature`, `fred/feature`, etc.)
