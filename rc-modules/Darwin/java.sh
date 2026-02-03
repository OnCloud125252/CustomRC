# Java home - use cached path to avoid spawning java_home on every shell
# Regenerate cache with: rm ~/.cache/java_home.txt && exec zsh
_java_cache="$HOME/.cache/java_home.txt"
if [[ ! -f "$_java_cache" ]]; then
  mkdir -p "$HOME/.cache"
  /usr/libexec/java_home -v 15 2>/dev/null > "$_java_cache"
fi
[[ -s "$_java_cache" ]] && export JAVA_HOME="$(<$_java_cache)"
unset _java_cache
