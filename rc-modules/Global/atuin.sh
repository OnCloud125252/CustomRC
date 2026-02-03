# Atuin shell history - using cached init for faster startup
. "$HOME/.atuin/bin/env"
cache_init "atuin" "atuin init zsh" --check-binary "$HOME/.atuin/bin/atuin"
