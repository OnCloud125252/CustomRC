# Lazy-load thefuck only when first used (saves ~200ms startup time)
fuck() {
  unfunction fuck fk 2>/dev/null
  eval "$(thefuck --alias)"
  eval "$(thefuck --alias fk)"
  fuck "$@"
}
fk() { fuck "$@"; }

