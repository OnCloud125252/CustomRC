export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1
export PATH=/opt/homebrew/bin:$PATH

# Use a function instead of alias to avoid subshell evaluation at definition time
# Also runs upgrades in parallel for better performance
brew-full-update() {
  brew update
  brew upgrade --cask --greedy &
  brew upgrade $(brew outdated | awk '{ print $1 }') &
  wait
  brew cleanup
}
