CURRENT_PATH=$(dirname "$0")

CUSTOMRC_SILENT_OUTPUT=false

CUSTOMRC_GLOBAL_IGNORE_LIST=(
  "zoxide.sh"
  "podman.sh"
)
CUSTOMRC_Darwin_IGNORE_LIST=(
  "cursor.sh"
  "iterm.sh"
  "jankyborders.sh"
)
CUSTOMRC_Linux_IGNORE_LIST=(
)

is_ignored() {
  local item="$1"
  local ignoreList=("${@:2}")
  for ignore in "${ignoreList[@]}"; do
    if [[ "$ignore" == "$item" ]]; then
      return 0
    fi
  done
  return 1
}

CUSTOMRC_GLOBAL_RC_PATH="$CUSTOMRC_PATH/Global"
for file in $CUSTOMRC_GLOBAL_RC_PATH/*; do
  fileName=$(basename "$file")
  if ! is_ignored $fileName $CUSTOMRC_GLOBAL_IGNORE_LIST; then
    if [[ -f $file ]]; then
      source "$file"
    fi
  elif [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
    echo "Customrc: ignoring $fileName (global)"
  fi
done

OS_NAME=$(uname)
if [[ $OS_NAME == "Darwin" || $OS_NAME == "Linux" ]]; then
  if [[ $OS_NAME == "Darwin" ]]; then
    CUSTOMRC_OS_IGNORE_LIST=("${CUSTOMRC_Darwin_IGNORE_LIST[@]}")
  elif [[ $OS_NAME == "Linux" ]]; then
    CUSTOMRC_OS_IGNORE_LIST=("${CUSTOMRC_Linux_IGNORE_LIST[@]}")
  fi

  CUSTOMRC_RC_PATH="$CUSTOMRC_PATH/$OS_NAME"
  for file in $CUSTOMRC_RC_PATH/*; do
    fileName=$(basename "$file")
    if ! is_ignored $fileName $CUSTOMRC_OS_IGNORE_LIST; then
      if [[ -f $file ]]; then
        source "$file"
      fi
    elif [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
      echo "Customrc: ignoring $fileName"
    fi
  done
else
  echo "Customrc: unsupported OS $OS_NAME, skipping OS-specific rc files"
fi

if [[ -f "$CURRENT_PATH/fix-prompt-at-bottom.sh" ]]; then
  source "$CURRENT_PATH/fix-prompt-at-bottom.sh"
fi

fileName=
file=
