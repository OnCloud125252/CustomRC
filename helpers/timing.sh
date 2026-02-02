# Calculates elapsed time in milliseconds from a start timestamp
# Usage: get_duration_ms $start_time result_var
get_duration_ms() {
  printf -v "$2" '%d' "$(( ($(date +%s%N) - $1) / 1000000 ))"
}

# Returns an ANSI color code based on individual file load duration
# Usage: get_duration_color $duration result_var
get_duration_color() {
  if (( $1 < 10 )); then printf -v "$2" '%s' "$GREEN"
  elif (( $1 < 50 )); then printf -v "$2" '%s' "$YELLOW"
  else printf -v "$2" '%s' "$RED"; fi
}

# Returns an ANSI color code based on total initialization duration
# Usage: get_total_duration_color $duration result_var
get_total_duration_color() {
  if (( $1 < 1000 )); then printf -v "$2" '%s' "$GREEN"
  elif (( $1 < 2000 )); then printf -v "$2" '%s' "$YELLOW"
  else printf -v "$2" '%s' "$RED"; fi
}
