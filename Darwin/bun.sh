export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Using Proto
[ -s "$HOME/.proto/bin/bun/_bun" ] && source "$HOME/.proto/bin/bun/_bun"
# alias bun='sde -chip-check-disable -- bun'
