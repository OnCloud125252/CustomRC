# Updating CustomRC

This guide covers everything you need to know about updating CustomRC to the latest version, including best practices, troubleshooting, and rollback procedures.

## Table of Contents

- [Overview](#overview)
- [Basic Update Workflow](#basic-update-workflow)
- [Pre-Update Checklist](#pre-update-checklist)
- [Handling Uncommitted Changes](#handling-uncommitted-changes)
- [Post-Update Steps](#post-update-steps)
- [Troubleshooting Updates](#troubleshooting-updates)
- [Rollback Procedure](#rollback-procedure)
- [Automated Updates (Optional)](#automated-updates-optional)

---

## Overview

### What Updating Means

Updating CustomRC refers to pulling the latest changes to the **core framework** (the `~/.customrc` repository). This includes:

- Bug fixes and performance improvements
- New CLI commands and features
- Updates to helper scripts and caching system
- Documentation updates

**Your personal modules in `rc-modules/` are completely separate** and are not affected by CustomRC updates. This separation ensures that your customizations remain safe.

### How Updates Work

CustomRC uses git for updates. The `customrc update` command:

1. Checks if the CustomRC directory is a valid git repository
2. Fetches the latest changes from the remote repository
3. Shows you what commits will be applied
4. Pulls the updates
5. Rebuilds the monolithic cache automatically

### Update Safety

| What Gets Updated | What Stays Preserved |
|-------------------|---------------------|
| Core framework files | `rc-modules/` directory |
| Helper scripts | `configs.sh` settings |
| CLI commands | Your personal modules |
| Documentation | Cache metadata |

---

## Basic Update Workflow

The simplest way to update CustomRC:

```bash
customrc update
```

This command will:

1. **Check prerequisites** — Verifies CustomRC is a git repository with a configured remote
2. **Detect uncommitted changes** — Warns if you have local modifications to core files
3. **Fetch and display** — Shows new commits before pulling
4. **Apply updates** — Pulls the latest changes from the remote
5. **Rebuild cache** — Regenerates the monolithic cache automatically
6. **Prompt for restart** — Reminds you to restart your shell

### Example Output

```
━━━━[CustomRC Update]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[i] Fetching from origin/main...
[i] Found 3 new commit(s)

89b682a feat: add platform detection and improve module command help messages
fecc4ed feat: add update command for CustomRC to fetch and pull latest changes
a96413a feat: enhance user guide with CLI commands for module management

[i] Pulling updates...
[✓] Updated CustomRC to latest version

[i] Rebuilding cache...
[i] Clearing monolithic cache...
[i] Rebuilding monolithic cache...
[✓] Rebuilt monolithic cache

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[✓] Update complete!
[i] Restart your shell to apply changes
```

---

## Pre-Update Checklist

Before running `customrc update`, it's good practice to:

### 1. Check Current Status

```bash
customrc status
```

This shows:

- Current CustomRC version
- Installation path
- Debug mode status
- Module counts by platform

### 2. Run Health Checks

```bash
customrc doctor
```

Verifies:

- CustomRC is properly initialized
- `rc-modules/` directory exists
- Required helper files are present
- Cache system is functional
- Git repository status
- **Available updates** (fetches from remote and reports if updates are available)

### 3. Check for Uncommitted Changes

```bash
customrc sync status
```

Or manually:

```bash
cd ~/.customrc && git status
```

If you have local modifications to CustomRC core files (not your `rc-modules/`), you'll need to decide whether to preserve or discard them.

### 4. Review Local Modifications

If you've modified core CustomRC files (not recommended), review them:

```bash
cd ~/.customrc && git diff
```

---

## Handling Uncommitted Changes

If `customrc update` detects uncommitted changes in the CustomRC directory, it will stop and warn you. You have three options:

### Option 1: Use `--force` (Discards Changes)

If you don't need your local modifications:

```bash
customrc update --force
```

**Warning:** This uses `git reset --hard` and permanently discards any uncommitted changes in the CustomRC directory.

### Option 2: Stash Local Changes

To preserve changes for later:

```bash
cd ~/.customrc
git stash
customrc update
# Later, if needed:
git stash pop
```

### Option 3: Commit Your Changes

If you've intentionally modified CustomRC core files:

```bash
cd ~/.customrc
git add -A
git commit -m "My local modifications"
customrc update
```

**Note:** This may create merge conflicts if your changes overlap with upstream updates.

### What Gets Preserved vs. Lost

| Action | Preserved | Lost |
|--------|-----------|------|
| `--force` | `rc-modules/`, `configs.sh` | Uncommitted core file changes |
| `git stash` | Stashed changes | Nothing |
| `git commit` | Committed changes | Nothing (may conflict) |

---

## Post-Update Steps

After a successful update:

### 1. Restart Your Shell

Updates to CustomRC core files require a fresh shell session:

```bash
exec $SHELL
```

Or simply start a new terminal window/tab.

### 2. Verify the Update

```bash
customrc status
```

Check that:

- The version number reflects the update
- No errors are displayed during initialization
- Your modules are still loading correctly

### 3. Run Health Checks

```bash
customrc doctor
```

This verifies all systems are functioning correctly after the update and confirms you're on the latest version.

### 4. Test Your Configuration

Run a few of your usual commands to ensure:

- Aliases work correctly
- Functions are available
- Environment variables are set
- No unexpected errors appear

---

## Troubleshooting Updates

### "Not a git repository" Error

```
[✗] CustomRC is not a git repository: ~/.customrc
```

**Cause:** CustomRC was installed manually without git, or the `.git` directory was removed.

**Solutions:**

1. **Reinstall with git** (recommended):

   ```bash
   # Backup your modules first
   cp -r ~/.customrc/rc-modules ~/rc-modules-backup

   # Reinstall
   rm -rf ~/.customrc
   git clone https://github.com/OnCloud125252/CustomRC.git ~/.customrc
   cp -r ~/rc-modules-backup ~/.customrc/rc-modules
   ```

2. **Continue manual updates:**
   Download and extract the latest release manually, preserving your `rc-modules/`.

### "No remote configured" Error

```
[✗] No git remote configured
```

**Cause:** The repository has no remote origin configured.

**Solution:**

```bash
cd ~/.customrc
git remote add origin https://github.com/OnCloud125252/CustomRC.git
customrc update
```

### Network Issues During Fetch

```
[✗] Failed to fetch updates
```

**Causes:**

- No internet connection
- GitHub is unreachable
- Proxy or firewall issues

**Solutions:**

1. Check your internet connection:

   ```bash
   ping github.com
   ```

2. If behind a proxy, configure git:

   ```bash
   git config --global http.proxy http://proxy.example.com:8080
   ```

3. Try again later if GitHub is experiencing issues.

### Merge Conflicts

If you see merge conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) after an update:

**Solution:**

```bash
cd ~/.customrc

# See conflicting files
git status

# Resolve each file (edit to remove conflict markers)
# Then mark as resolved:
git add <filename>

# Complete the merge
git commit
```

Or abort the merge and start over:

```bash
git merge --abort
customrc update --force
```

### Cache Not Rebuilding

If the cache fails to rebuild after an update:

```bash
# Manually rebuild
customrc cache rebuild

# If that fails, clear and rebuild
rm ~/.customrc/.cache/monolithic.sh
customrc cache rebuild
```

---

## Rollback Procedure

If an update causes issues, you can rollback to a previous version:

### Method 1: Git Revert (Recommended)

```bash
cd ~/.customrc

# See recent commits
git log --oneline -10

# Revert to a specific commit
git reset --hard abc1234  # Replace with the commit hash

# Rebuild cache
customrc cache rebuild

# Restart shell
exec $SHELL
```

### Method 2: Use Git Reflog

If you don't know the previous commit hash:

```bash
cd ~/.customrc

# See all recent operations
git reflog

# Find the entry before the update, then:
git reset --hard HEAD@{1}  # Or the appropriate reflog entry

# Rebuild cache
customrc cache rebuild
```

### Method 3: Restore from Backup

If you have a backup of your CustomRC directory:

```bash
# Preserve your current modules
cp -r ~/.customrc/rc-modules ~/rc-modules-backup

# Restore from backup
rm -rf ~/.customrc
cp -r /path/to/backup/.customrc ~/

# Restore modules if needed
cp -r ~/rc-modules-backup ~/.customrc/rc-modules

# Restart shell
exec $SHELL
```

### Preventing Future Issues

Before major updates, consider creating a quick backup:

```bash
# Create a backup tag
cd ~/.customrc
git tag backup-$(date +%Y%m%d)

# Now update
customrc update
```

To restore from the tag later:

```bash
cd ~/.customrc
git reset --hard backup-20240101  # Replace with your tag
```

---

## Automated Updates (Optional)

If you want to check for updates automatically, you can add a hook to your shell:

### Shell Hook Method

Add to your `rc-modules/Global/` (e.g., `rc-modules/Global/update-check.sh`):

```bash
# Check for CustomRC updates weekly
_customrc_auto_update_check() {
  local marker_file="$HOME/.customrc/.last_update_check"
  local check_interval=604800  # 7 days in seconds

  # Skip if marker is recent
  if [[ -f "$marker_file" ]]; then
    local last_check=$(stat -f%m "$marker_file" 2>/dev/null || stat -c%Y "$marker_file" 2>/dev/null)
    local now=$(date +%s)
    if [[ $((now - last_check)) -lt $check_interval ]]; then
      return
    fi
  fi

  # Update marker
  touch "$marker_file"

  # Check for updates (non-blocking)
  (
    cd ~/.customrc && git fetch origin main 2>/dev/null || exit 0
    local behind=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)
    if [[ $behind -gt 0 ]]; then
      echo ""
      echo "[CustomRC] $behind update(s) available. Run: customrc update"
      echo ""
    fi
  ) &
}

_customrc_auto_update_check
unset -f _customrc_auto_update_check
```

### Cron Job Method

For a system-level check without shell integration:

```bash
# Edit crontab
crontab -e

# Add weekly check (Mondays at 9 AM)
0 9 * * 1 cd ~/.customrc && git fetch origin main 2>/dev/null && [ $(git rev-list --count HEAD..origin/main 2>/dev/null) -gt 0 ] && echo "CustomRC updates available" | mail -s "CustomRC Update" $USER
```

---

## Summary

| Task | Command |
|------|---------|
| Update CustomRC | `customrc update` |
| Force update (discard changes) | `customrc update --force` |
| Check status | `customrc status` |
| Run health checks + update check | `customrc doctor` |
| Rebuild cache | `customrc cache rebuild` |
| Rollback to commit | `git reset --hard <commit>` |

---

## Related Documentation

- [User Guide](user-guide.md) — Installation, customization, and syncing
- [CLI Reference](helpers/customrc-cli.md) — Comprehensive guide to the `customrc` command
- [Configuration](configuration.md) — Operating modes, ignore lists, cache management
- [Caching System](caching.md) — Cache helper API documentation
