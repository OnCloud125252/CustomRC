# Calculates elapsed time in milliseconds from a start timestamp
get_duration_ms() {
  local start_time=$1
  local end_time=$(date +%s%N)
  echo $(( (end_time - start_time) / 1000000 ))
}

# Returns an ANSI color code based on individual file load duration
get_duration_color() {
  local duration=$1
  if (( duration < 10 )); then
    echo "$GREEN"
  elif (( duration < 50 )); then
    echo "$YELLOW"
  else
    echo "$RED"
  fi
}

# Returns an ANSI color code based on total initialization duration
get_total_duration_color() {
  local duration=$1
  if (( duration < 1000 )); then
    echo "$GREEN"
  elif (( duration < 2000 )); then
    echo "$YELLOW"
  else
    echo "$RED"
  fi
}
