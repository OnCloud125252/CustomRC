# FZF initialization - using cached output for faster startup
_fzf_cache="$HOME/.cache/fzf/init.zsh"
if [[ ! -f "$_fzf_cache" ]] || [[ "$(command -v fzf)" -nt "$_fzf_cache" ]]; then
  mkdir -p "$HOME/.cache/fzf"
  fzf --zsh > "$_fzf_cache" 2>/dev/null
fi
[[ -f "$_fzf_cache" ]] && source "$_fzf_cache"
unset _fzf_cache

export FZF_COMPLETION_TRIGGER='**'
export FZF_COMPLETION_OPTS='--layout=default'

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix"

_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -100; else bat -n --color=always --line-range :100 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -100'"

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza -1 --color=always {}' "$@" ;;
    export|unset) fzf --preview "eval 'echo ${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

source "$HOME/.customrc/rc-modules/Global/fzf-git/fzf-git.sh"
