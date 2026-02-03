# Atuin shell history - using cached init for faster startup
. "$HOME/.atuin/bin/env"

# Cache atuin init output for faster loading
_atuin_cache="$HOME/.cache/atuin/init.zsh"
if [[ ! -f "$_atuin_cache" ]] || [[ "$HOME/.atuin/bin/atuin" -nt "$_atuin_cache" ]]; then
  mkdir -p "$HOME/.cache/atuin"
  atuin init zsh > "$_atuin_cache" 2>/dev/null
fi
[[ -f "$_atuin_cache" ]] && source "$_atuin_cache"
unset _atuin_cache