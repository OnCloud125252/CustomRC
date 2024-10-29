export PROTO_HOME="$HOME/.proto"
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:/opt/homebrew/sbin:$PATH"

alias plist="proto list --aliases"
alias psearch="proto list-remote --aliases"
alias pupgrade="proto upgrade"
function pinstall() {
  if [[ $# -eq 1 ]]; then
    echo -e "\033[0;33mWarning: No version provided. Using 'latest' as version tag.\033[0m"
    echo
    proto install --pin global $1 latest
  else
    proto install --pin global $1 $2
  fi
}
function prm() {
  if [[ $# -eq 1 ]]; then
    echo -e "\033[0;33mWarning: No version provided. Using 'latest' as version tag.\033[0m"
    echo
    proto uninstall $1 latest
  else
    proto uninstall $1 $2
  fi
}
function puse() {
  if [[ $# -eq 1 ]]; then
    echo -e "\033[0;33mWarning: No version provided. Using 'latest' as version tag.\033[0m"
    echo
    proto pin --resolve --global $1 latest
  else
    proto pin --resolve --global $1 $2
  fi
}
function poutdated() {
  if [[ -f .prototools ]]; then
    proto outdated
  elif [[ $# -eq 0 ]]; then
    echo -e "\033[0;33mWarning: No argument provided. Checking global tools...\033[0m"
    echo
    (cd $PROTO_HOME && proto outdated)
  elif [[ -d $1 ]]; then
    (cd $1 && proto outdated)
  else
    echo -e "\033[0;31mInvalid argument: $1\033[0m"
  fi
}
function ptools() {
  if [[ -f .prototools ]]; then
    proto status
  elif [[ $# -eq 0 ]]; then
    echo -e "\033[0;33mWarning: No argument provided. Checking global tools...\033[0m"
    echo
    (cd $PROTO_HOME && proto status)
  elif [[ -d $1 ]]; then
    (cd $1 && proto status)
  else
    echo -e "\033[0;31mInvalid argument: $1\033[0m"
  fi
}

function phelp() {
  echo "Custom commands for Proto."
  echo
  echo "Usage: <P-COMMAND> [OPTIONS]"
  echo
  echo "Commands:"
  echo "    puse <TOOL> <[VERSION]>      - Use <TOOL> at <[VERSION]> ."
  echo "                                   If <[VERSION]>  is not provided, it will be set to 'latest'."
  echo "    pinstall <TOOL> <[VERSION]>  - Install <TOOL> at <[VERSION]> ."
  echo "                                   If <[VERSION]>  is not provided, it will be set to 'latest'."
  echo "    prm <TOOL> <[VERSION]>       - Uninstall <TOOL> at <[VERSION]> ."
  echo "                                   If <[VERSION]>  is not provided, it will be set to 'latest'."
  echo "    plist <TOOL>                 - List all installed versions of <TOOL>."
  echo "    psearch <TOOL>               - Search for available versions of <TOOL>."
  echo "    pupgrade                     - Upgrade proto itself."
  echo "    poutdated <[DIRECTORY]>      - Show outdated tools in <directory>."
  echo "                                   If <[DIRECTORY]> is not provided, it will be set to '$PROTO_HOME'."
  echo "    ptools <[DIRECTORY]>         - List all installed tools in <directory>."
  echo "                                   If <[DIRECTORY]> is not provided, it will be set to '$PROTO_HOME'."
}
