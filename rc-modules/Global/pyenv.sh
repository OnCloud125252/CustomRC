export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Lazy-load pyenv on first use (saves ~150ms startup time)
pyenv() {
  unfunction pyenv 2>/dev/null
  eval "$(command pyenv init -)"
  eval "$(command pyenv virtualenv-init - | sed s/precmd/precwd/g)"
  pyenv "$@"
}