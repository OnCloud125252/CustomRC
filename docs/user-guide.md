# User Guide

This guide covers installation and common usage patterns for CustomRC.

## Installation

Clone the repository:

```bash
git clone --recurse-submodules https://github.com/OnCloud125252/CustomRC.git ~/.customrc
```

Add the configuration to your shell profile (e.g., `~/.zshrc`):

```bash
cat << 'EOF' >> ~/.zshrc
# CustomRC
export CUSTOMRC_PATH="$HOME/.customrc"
source $CUSTOMRC_PATH/customrc.sh
# CustomRC End
EOF
```

Restart your shell or run `source ~/.zshrc` to activate.

## Configuration

See [Configuration](configuration.md) for detailed options including:
- Operating modes (debug vs production)
- Ignore lists for disabling modules
- Cache management

## Adding New Modules

Create a `.sh` file in the appropriate directory:

| Directory | Use Case |
|-----------|----------|
| `rc-modules/Global/` | Cross-platform modules |
| `rc-modules/Darwin/` | macOS-specific modules |
| `rc-modules/Linux/` | Linux-specific modules |

The module will be automatically loaded on next shell start.

See [Writing Optimized Modules](optimized-modules.md) for performance best practices.

## FAQs

### Is this safe to use on my machine?

This repository contains personal configurations. Some modules may not work in your environment or may conflict with your existing setup. Review the modules in `rc-modules/Global`, `rc-modules/Darwin`, and `rc-modules/Linux` before using.

### How do I debug slow shell startup?

1. Set `CUSTOMRC_DEBUG_MODE=true` in `configs.sh`
2. Restart your shell
3. Look for modules with high load times
4. Add slow modules to the appropriate ignore list
5. Set `CUSTOMRC_DEBUG_MODE=false` for daily use

### How do I update CustomRC?

```bash
cd ~/.customrc
git pull --recurse-submodules
```

The monolithic cache will auto-regenerate on next shell start.
