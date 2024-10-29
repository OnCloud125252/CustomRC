alias _clear=$(which clear)
clear() {
  _clear
  printf '\n%.0s' {1..$(($(tput lines) - 2))}
}
printf '\n%.0s' {1..$(($(tput lines) - 2))}
