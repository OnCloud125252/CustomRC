# Lazy-load ngrok completion - only initialize when ngrok is first called
if command -v ngrok &>/dev/null; then
  _ngrok_lazy_init() {
    unfunction ngrok 2>/dev/null
    eval "$(command ngrok completion)"
  }
  ngrok() {
    _ngrok_lazy_init
    command ngrok "$@"
  }
fi
