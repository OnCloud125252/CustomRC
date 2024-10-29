CUSTOMRC_SILENT_OUTPUT=false

CUSTOMRC_GLOBAL_IGNORE_LIST=(
)
CUSTOMRC_IGNORE_LIST=(
  "cursor.sh"
  "iterm.sh"
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

CUSTOMRC_RC_PATH="$CUSTOMRC_PATH/$(uname)"
for file in $CUSTOMRC_RC_PATH/*; do
  fileName=$(basename "$file")
  if ! is_ignored $fileName $CUSTOMRC_IGNORE_LIST; then
    if [[ -f $file ]]; then
      source "$file"
    fi
  elif [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
    echo "Customrc: ignoring $fileName"
  fi
done


if [[ -f "$(dirname "$0")/fix-prompt-at-bottom.sh" ]]; then
  source "$(dirname "$0")/fix-prompt-at-bottom.sh"
fi

fileName=
file=
