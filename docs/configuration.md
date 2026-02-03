# Configuration

All CustomRC configuration is managed in `~/.customrc/configs.sh`.

## Operating Modes

CustomRC supports two modes controlled by `CUSTOMRC_DEBUG_MODE`.

### Debug Mode

Enable verbose output with per-module timing by setting `CUSTOMRC_DEBUG_MODE=true`:

```
[i] Initializing Customrc...
━━━━[customrc]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Loaded: fzf.sh [Global] (3ms)
✓ Loaded: bat.sh [Global] (1ms)
✗ Ignored: nvm.sh [Global]
✓ Loaded: brew.sh [Darwin] (2ms)
━━━━[customrc]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[i] Initialization complete
    ✓ Loaded: 24
    ✗ Ignored: 5
    ⚠ Duration: 89ms
```

Use debug mode when:
- Developing new modules
- Troubleshooting slow startup times
- Identifying which modules are being loaded

### Production Mode

When `CUSTOMRC_DEBUG_MODE=false` (default), CustomRC generates a monolithic cache file combining all modules. This cache:

- Auto-regenerates when any module or `configs.sh` changes
- Sources instantly without per-file overhead
- Lives at `~/.cache/customrc/monolithic.sh`

Production mode is recommended for daily use.

## Ignore Lists

Disable slow or unused modules by adding them to platform-specific ignore lists:

```bash
CUSTOMRC_GLOBAL_IGNORE_LIST=(
  "nvm.sh"       # 200ms+ - use fnm instead
  "thefuck.sh"   # 100ms+ - lazy load if needed
)

CUSTOMRC_DARWIN_IGNORE_LIST=(
  "iterm.sh"     # Not needed if using other terminal
)

CUSTOMRC_LINUX_IGNORE_LIST=()
```

## Cache Management

### Clearing Caches

Run `cache_clear` to remove all caches, or `cache_clear <name>` for a specific one:

```bash
# Clear all caches
cache_clear

# Clear specific cache
cache_clear fzf
```

Caches are stored in `~/.cache/customrc/`.

### Force Regenerating Monolithic Cache

Delete the cache file and restart your shell:

```bash
rm ~/.cache/customrc/monolithic.sh
exec zsh
```
