# Version System

CustomRC uses a simple file-based versioning system that provides clear identification of the framework version and integrates with the CLI for easy version checking.

## Overview

The version system serves two primary purposes:

1. **User Identification** — Allows users to quickly identify which version of CustomRC is installed
2. **Update Verification** — Enables users to confirm successful updates and track framework changes

## Version Storage

### The `version` File

The version number is stored in a dedicated file at the repository root:

```
~/.customrc/version
```

**Current format:**

```
1.2.0
```

This file contains only the version string and serves as the single source of truth for the CustomRC version.

### Design Rationale

The dedicated `version` file approach was chosen for several reasons:

| Advantage | Description |
|-----------|-------------|
| **Simple to read** | No parsing required; just `cat version` |
| **Git-tracked** | Version changes are part of the commit history |
| **Shell-agnostic** | Works across Bash, Zsh, and other POSIX shells |
| **Human-readable** | Easy to check without running any commands |
| **Build-free** | No preprocessing or templating required |

## How Versioning Works

### At Startup

When `customrc.sh` initializes, it reads the version file:

```bash
# From customrc.sh
CUSTOMRC_VERSION=$(cat "$CURRENT_PATH/version" 2>/dev/null || echo "unknown")
```

This makes the version available throughout the CustomRC system via the `CUSTOMRC_VERSION` environment variable.

### Version Display

The version can be displayed using the CLI:

```bash
# Show version
customrc version

# Output:
# customrc 1.2.0
```

Alternative ways to check the version:

```bash
# Using short flag
customrc -v

# Using long flag
customrc --version
```

### Version in Status Output

The version is also displayed as part of the status command:

```bash
customrc status
```

**Example output:**

```
━━━━[CustomRC Status]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Version:     1.2.0
  Path:        /Users/you/.customrc
  Modules:     /Users/you/.customrc/rc-modules
  Cache:       /Users/you/.cache/customrc
  ...
```

## Version Numbering

CustomRC follows [Semantic Versioning](https://semver.org/) (SemVer) principles:

```
MAJOR.MINOR.PATCH
```

| Component | When to Increment | Example |
|-----------|-------------------|---------|
| **MAJOR** | Breaking changes that require user action | New configuration format |
| **MINOR** | New features, backward compatible | New CLI command added |
| **PATCH** | Bug fixes, backward compatible | Cache fix, typo correction |

### Recent Version History

| Version | Date | Notable Changes |
|---------|------|-----------------|
| 1.2.0 | Current | Added autocomplete functionality |
| 1.1.3 | Previous | Cache modification time fixes |
| 1.1.2 | | Glob qualifier improvements |
| 1.1.1 | | Update check in doctor command |
| 1.1.0 | | Monolithic caching system |
| 1.0.0 | | Initial stable release |

## Implementation Details

### Source Code Locations

| Component | Location | Purpose |
|-----------|----------|---------|
| Version file | `version` | Stores the version string |
| Version loader | `customrc.sh:8` | Reads version at startup |
| Version command | `helpers/customrc-cli.sh:874-876` | Displays version to user |
| Status display | `helpers/customrc-cli.sh:707` | Shows version in status output |

### The `_customrc_version` Function

```bash
_customrc_version() {
  echo "customrc ${CUSTOMRC_VERSION:-unknown}"
}
```

This function:

- Displays the version with the `customrc` prefix
- Falls back to `unknown` if `CUSTOMRC_VERSION` is unset
- Is called by `customrc version`, `customrc -v`, and `customrc --version`

## For Developers

### Updating the Version

When preparing a new release:

1. **Determine the new version** using SemVer principles:
   - Bug fix → increment PATCH (1.2.0 → 1.2.1)
   - New feature → increment MINOR (1.2.0 → 1.3.0)
   - Breaking change → increment MAJOR (1.2.0 → 2.0.0)

2. **Update the version file:**

   ```bash
   echo "1.3.0" > version
   ```

3. **Commit with a conventional commit message:**

   ```bash
   git add version
   git commit -m "chore: update version to 1.3.0"
   ```

### Version Verification

After updating, verify the new version is recognized:

```bash
# Source CustomRC
source ~/.customrc/customrc.sh

# Check version
customrc version
```

### Handling Missing Version File

If the `version` file is missing or unreadable, CustomRC gracefully handles this:

```bash
# From customrc.sh:8
CUSTOMRC_VERSION=$(cat "$CURRENT_PATH/version" 2>/dev/null || echo "unknown")
```

This ensures that:

- CustomRC continues to function even without a version file
- Users see `customrc unknown` instead of an error
- The system is resilient to file system issues

## Troubleshooting

### "unknown" Version Displayed

If `customrc version` shows `customrc unknown`:

1. **Check if the version file exists:**

   ```bash
   cat ~/.customrc/version
   ```

2. **Verify file permissions:**

   ```bash
   ls -la ~/.customrc/version
   ```

3. **Restore the version file:**

   ```bash
   cd ~/.customrc
   git checkout version
   ```

### Version Doesn't Match After Update

If the version doesn't reflect the latest update:

1. **Ensure the shell was restarted:**

   ```bash
   exec $SHELL
   ```

2. **Verify the update succeeded:**

   ```bash
   cd ~/.customrc && git log --oneline -3
   ```

3. **Check the version file content:**

   ```bash
   cat ~/.customrc/version
   ```

## Related Documentation

- [CLI Reference](helpers/customrc-cli.md) — Complete guide to all `customrc` commands
- [Updating CustomRC](updating.md) — How to update to the latest version
- [User Guide](user-guide.md) — Installation and customization guide
