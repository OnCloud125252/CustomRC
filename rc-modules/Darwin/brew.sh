export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1
export PATH=/opt/homebrew/bin:$PATH

alias brew-full-update="brew update ; brew upgrade --cask --greedy ; brew upgrade $(brew outdated | awk '{ print $1 }') ; brew cleanup"
