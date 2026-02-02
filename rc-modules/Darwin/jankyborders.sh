echo '
options=(
	style=round
	width=2
	hidpi=on
	active_color=0xff54565d
	inactive_color=0xff323337
)

borders "${options[@]}"
' >~/.config/borders/bordersrc

if ! pgrep -x "borders" >/dev/null; then
  $SHELL $(nohup borders </dev/null >/dev/null 2>&1 &) </dev/null >/dev/null 2>&1
fi
