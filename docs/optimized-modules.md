# Writing Optimized RC Modules

This guide covers best practices for creating fast-loading shell modules in CustomRC.

## TL;DR

| Technique | When to Use | Example |
|-----------|-------------|---------|
| **Lazy Loading** | CLI tools with completions you don't use every session | ngrok, kubectl |
| **Cached Init** | Frequently-used tools with expensive init | fzf, atuin, starship |
| **Static Values** | Environment variables that rarely change | JAVA_HOME, GOROOT |
| **Conditional Loading** | Only load when dependencies exist | `[[ -d "$HOME/.cargo" ]] && source ...` |

**Quick wins:**
- Replace `eval "$(tool init)"` with cached file sourcing
- Use `command -v tool &>/dev/null || return 0` for early exits
- Avoid subshells for static values: `$(<file)` instead of `$(cat file)`
- Never make network calls during shell init

**Target load times:** Aliases < 2ms | Functions < 5ms | Cached completions < 10ms

## The Problem: Shell Startup Time

Every millisecond counts during shell initialization. Common culprits that slow down startup:

| Operation | Typical Cost | Example |
|-----------|--------------|---------|
| Process spawn | 30-100ms | `eval "$(cmd completion)"` |
| Subshell | 10-50ms | `export VAR=$(command)` |
| Heavy script source | 20-60ms | SDKMAN, NVM init scripts |
| Network calls | 100ms+ | Version checks, updates |

## Optimization Techniques

### 1. Lazy Loading (Best for CLI tools with completions)

Defer initialization until the command is first used:

```bash
# ❌ SLOW: Runs on every shell start
if command -v mytool &>/dev/null; then
  eval "$(mytool completion zsh)"
fi

# ✅ FAST: Only runs when mytool is first called
if command -v mytool &>/dev/null; then
  _mytool_lazy_init() {
    unfunction mytool 2>/dev/null
    eval "$(command mytool completion zsh)"
  }
  mytool() {
    _mytool_lazy_init
    command mytool "$@"
  }
fi
```

**When to use:** Tools you don't use in every session (ngrok, kubectl, etc.)

### 2. Cached Initialization (Best for frequently-used tools)

Pre-generate init scripts and source from cache:

```bash
# ❌ SLOW: Spawns process every time
eval "$(fzf --zsh)"

# ✅ FAST: Sources cached file
_cache="$HOME/.cache/fzf/init.zsh"
if [[ ! -f "$_cache" ]] || [[ "$(command -v fzf)" -nt "$_cache" ]]; then
  mkdir -p "${_cache:h}"
  fzf --zsh > "$_cache" 2>/dev/null
fi
[[ -f "$_cache" ]] && source "$_cache"
unset _cache
```

**Cache invalidation:** The `-nt` (newer than) check regenerates cache when the binary is updated.

**When to use:** Tools you use frequently that have expensive init (fzf, atuin, starship)

### 3. Static Values (Best for environment variables)

Replace runtime lookups with cached values:

```bash
# ❌ SLOW: Spawns java_home every shell start (13ms)
export JAVA_HOME=$(/usr/libexec/java_home -v 15)

# ✅ FAST: Reads cached path (1ms)
_cache="$HOME/.cache/java_home.txt"
if [[ ! -f "$_cache" ]]; then
  mkdir -p "$HOME/.cache"
  /usr/libexec/java_home -v 15 2>/dev/null > "$_cache"
fi
[[ -s "$_cache" ]] && export JAVA_HOME="$(<$_cache)"
unset _cache
```

**When to use:** Paths or values that rarely change (JAVA_HOME, GOROOT, etc.)

### 4. Conditional Loading

Only load when dependencies exist:

```bash
# ✅ Check before loading
[[ -d "$HOME/.cargo" ]] && source "$HOME/.cargo/env"

# ✅ Check command exists
command -v docker &>/dev/null || return 0
# ... docker aliases and functions
```

### 5. Avoid These Patterns

```bash
# ❌ Network calls during init
curl -s https://api.example.com/version

# ❌ Unnecessary subshells
MY_VAR="$(echo 'hello')"  # Just use: MY_VAR="hello"

# ❌ Multiple command -v checks for same tool
if command -v foo &>/dev/null; then
  # ...
fi
if command -v foo &>/dev/null; then  # Redundant!
  # ...
fi

# ❌ Sourcing in a loop
for f in ~/.config/tool/*.sh; do
  source "$f"  # Each source has overhead
done
# ✅ Better: Concatenate files first, source once
```

## Module Template

Here's a template for a well-optimized module:

```bash
#!/usr/bin/env zsh
# Module: mytool.sh
# Description: Brief description of what this module does

# Early exit if tool not available
command -v mytool &>/dev/null || return 0

# Environment variables (static, no subshells)
export MYTOOL_HOME="$HOME/.mytool"
export MYTOOL_CONFIG="$MYTOOL_HOME/config"

# PATH additions (check before adding)
[[ -d "$MYTOOL_HOME/bin" ]] && path=("$MYTOOL_HOME/bin" $path)

# Aliases (cheap, no overhead)
alias mt='mytool'
alias mtl='mytool list'

# Functions (defined but not executed - no overhead)
mtrun() {
  mytool run "$@"
}

# Completions (lazy-loaded)
_mytool_lazy_init() {
  unfunction mytool 2>/dev/null
  eval "$(command mytool completion zsh)"
}
mytool() {
  _mytool_lazy_init
  command mytool "$@"
}
```

## Measuring Performance

Test your module's load time:

```bash
# Time a single module
time zsh -c 'source ~/.customrc/rc-modules/Global/mymodule.sh'

# Full CustomRC timing
source ~/.customrc/customrc.sh
# Look for: [!] Duration: XXXms

# Profile with zprof
zmodload zsh/zprof
source ~/.customrc/customrc.sh
zprof | head -20
```

## Performance Targets

| Module Type | Target Load Time |
|-------------|------------------|
| Aliases only | < 2ms |
| Functions + aliases | < 5ms |
| With completions (cached) | < 10ms |
| Heavy init (SDKMAN, NVM) | < 50ms |

## Cache Management

All caches are stored in `~/.cache/`. To regenerate:

```bash
# Clear all CustomRC caches
rm -rf ~/.cache/atuin ~/.cache/fzf ~/.cache/java_home.txt

# Restart shell to regenerate
exec zsh
```

## Ignore List

For modules that are too slow or rarely needed, add them to the ignore list in `~/.customrc/configs.sh`:

```bash
CUSTOMRC_GLOBAL_IGNORE_LIST=(
  "nvm.sh"           # 200ms+ - use fnm instead
  "thefuck.sh"       # 100ms+ - lazy load if needed
)
```
