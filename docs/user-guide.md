# User Guide

This guide covers installation, customization, and syncing CustomRC across machines.

## Installation

### Quick Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/OnCloud125252/CustomRC.git ~/.customrc

# Run the installer
~/.customrc/install.sh
```

The installer will:
1. Check that you have a compatible shell (Bash 4+ or Zsh 5+)
2. Create `rc-modules/` from the example templates
3. Back up your existing shell configuration
4. Add CustomRC to your shell startup

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/OnCloud125252/CustomRC.git ~/.customrc

# Copy template modules to create your personal modules
cp -r ~/.customrc/rc-modules.example ~/.customrc/rc-modules

# Add to your shell profile (~/.zshrc or ~/.bashrc)
export CUSTOMRC_PATH="$HOME/.customrc"
source "$CUSTOMRC_PATH/customrc.sh"

# Restart your shell
exec $SHELL
```

## Customizing Your Modules

### Module Structure

Your personal modules live in `rc-modules/`:

```
rc-modules/
├── Global/          # Loaded on all platforms
│   └── ...
├── Darwin/          # Loaded only on macOS
│   └── ...
└── Linux/           # Loaded only on Linux
    └── ...
```

### Adding New Modules

The easiest way to add a new module is using the CLI:

```bash
customrc modules new Global/git
```

This creates the file with a template and opens it in your editor.

Alternatively, you can manually create a `.sh` file in the appropriate directory:

| Directory | When Loaded |
|-----------|-------------|
| `rc-modules/Global/` | Always (all platforms) |
| `rc-modules/Darwin/` | Only on macOS |
| `rc-modules/Linux/` | Only on Linux |

The module will be automatically loaded on next shell start.

### Example: Adding a Git Module

Create `rc-modules/Global/git.sh`:

```bash
# Git aliases and configuration

alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline -10"

# Git functions
gclone() {
  git clone "$1" && cd "$(basename "$1" .git)"
}
```

## Syncing Across Machines

Your `rc-modules/` directory is gitignored from CustomRC, giving you flexibility in how you sync your personal configurations.

### Using the CLI (Recommended)

The `customrc` CLI makes syncing easy.

**On your first machine:**

1. Initialize your modules directory as a git repo:
   ```bash
   cd ~/.customrc/rc-modules
   git init
   git add .
   git commit -m "Initial commit"
   ```
2. Create a repository on GitHub/GitLab.
3. Link and push:
   ```bash
   customrc sync init https://github.com/YOU/my-shell-config.git
   customrc sync push
   ```

**On other machines:**

After installing CustomRC, simply run:

```bash
customrc sync init https://github.com/YOU/my-shell-config.git
```

**Daily usage:**

```bash
customrc sync pull   # Get latest changes
customrc sync push   # Save your changes
```

### Manual Method: Separate Repository

Keep your personal modules in their own Git repository:

```bash
# On your first machine
cd ~/.customrc
rm -rf rc-modules  # Remove the template copy
git clone https://github.com/YOU/my-shell-config.git rc-modules

# On other machines, after installing CustomRC
cd ~/.customrc
rm -rf rc-modules
git clone https://github.com/YOU/my-shell-config.git rc-modules
```

Benefits:
- Your personal configs are versioned separately
- Update CustomRC without affecting your modules
- Easy to share modules between machines
- Keep sensitive configs in a private repo

### Option 2: Dotfiles Repository

If you already have a dotfiles repository:

```bash
# Symlink your modules directory
ln -s ~/dotfiles/shell-modules ~/.customrc/rc-modules
```

### Option 3: Manual Sync

For simple setups, copy files manually or use a sync tool:

```bash
# Using rsync
rsync -av ~/.customrc/rc-modules/ user@otherhost:~/.customrc/rc-modules/
```

## Configuration

See [Configuration](configuration.md) for detailed options including:
- Operating modes (debug vs production)
- Ignore lists for disabling modules
- Cache management

## Debug Mode

Enable debug mode to see timing information for each module:

```bash
customrc debug on
```

To return to production mode:

```bash
customrc debug off
```

This shows:
- Which modules are loaded
- Load time for each module
- Total initialization time

Use this to identify slow modules that need optimization.

## Performance Tips

1. **Add slow modules to ignore lists** in `configs.sh`
2. **Use lazy loading** for tools you don't use every session
3. **Leverage the cache system** for expensive initializations

See [Writing Optimized Modules](optimized-modules.md) for detailed guidance.

## Updating CustomRC

```bash
customrc update
```

This command will:
- Check if CustomRC is a git repository
- Warn about uncommitted changes (use `--force` to override)
- Fetch and show new commits before pulling
- Pull updates and rebuild cache automatically

If you have uncommitted changes and want to update anyway:

```bash
customrc update --force
```

Your personal modules in `rc-modules/` are unaffected by updates.

## Checking Status

To see an overview of your CustomRC installation:

```bash
customrc status
```

This displays:
- Version, paths, and debug mode status
- Git sync status of rc-modules
- Module counts by category (Global, Darwin, Linux)

## Troubleshooting

### Running Health Checks

Use the doctor command to diagnose common issues:

```bash
customrc doctor
```

This checks:
- CustomRC directory exists
- rc-modules directory is present
- Required helpers are available
- Module syntax is valid
- Cache is writable

### Shell startup is slow

1. Enable debug mode to identify slow modules
2. Add slow modules to the appropriate ignore list in `configs.sh`
3. Consider lazy loading for heavy tools (nvm, pyenv, etc.)

### Module not loading

1. Check the file has a `.sh` extension
2. Verify the file is in the correct directory for your OS
3. Check if it's in an ignore list in `configs.sh`
4. Look for syntax errors: `bash -n rc-modules/Global/yourmodule.sh`
5. Run `customrc doctor` to check for configuration issues

### Changes not taking effect

In production mode, changes are cached. Either:
- Remove the cache: `rm -rf ~/.cache/customrc/`
- Or restart your shell (cache auto-rebuilds when files change)

## FAQs

### Can I use this with Oh My Zsh / Prezto / other frameworks?

Yes! CustomRC complements shell frameworks. Load CustomRC after your framework in your shell rc file.

### How is this different from just having multiple source files?

CustomRC adds:
- Automatic platform detection (Darwin/Linux)
- Smart caching for production performance
- Debug mode with timing
- Ignore lists for easy module management

### Do I need to fork CustomRC to use it?

No. Your personal modules live in `rc-modules/` which is gitignored. You can update CustomRC independently of your personal configurations.
