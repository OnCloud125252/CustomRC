export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# eval "$(pyenv virtualenv-init -)" # deprecated, bad performance
eval "$(pyenv virtualenv-init - | sed s/precmd/precwd/g)"