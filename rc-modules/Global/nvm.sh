export NVM_DIR="$HOME/.nvm"

# Lazy-load nvm on first use (saves ~300ms startup time)
nvm() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}

# Stub commands that trigger nvm loading
node() { nvm use default >/dev/null 2>&1; command node "$@"; }
npm() { nvm use default >/dev/null 2>&1; command npm "$@"; }
npx() { nvm use default >/dev/null 2>&1; command npx "$@"; }

