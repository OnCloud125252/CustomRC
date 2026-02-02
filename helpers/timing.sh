# Calculates elapsed time in milliseconds from a start timestamp
get_duration_ms() {
  echo $(( ($(date +%s%N) - $1) / 1000000 ))
}

# Returns an ANSI color code based on individual file load duration
get_duration_color() {
  (( $1 < 10 )) && echo "$GREEN" && return
  (( $1 < 50 )) && echo "$YELLOW" && return
  echo "$RED"
}

# Returns an ANSI color code based on total initialization duration
get_total_duration_color() {
  (( $1 < 1000 )) && echo "$GREEN" && return
  (( $1 < 2000 )) && echo "$YELLOW" && return
  echo "$RED"
}
