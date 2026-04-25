t() {
  local duration="25m"
  local say_msg="done"
  local os_msg="done"
  local use_say=false
  local use_os=true

  while (( $# )); do
    case "$1" in
      -h|--help)
        cat <<'EOF'
Usage: t [time] [-say [msg]] [-os [msg]]

Flags:
  -say [msg]   Enable voice (default msg: "done")
  -os  [msg]   macOS notification (default msg: "done")
  -h           Show this help

Examples:
  t
  t 5
  t 10s
  t 5 -say
  t 5 -say "stop"
  t 5 -os "break"
  t 5 -os -say "done"
EOF
        return
        ;;
      -say)
        use_say=true
        if [[ -n "$2" && "$2" != -* ]]; then
          shift
          say_msg="$1"
        fi
        ;;
      -os)
        use_os=true
        if [[ -n "$2" && "$2" != -* ]]; then
          shift
          os_msg="$1"
        fi
        ;;
      <->)
        duration="${1}m"
        ;;
      *)
        duration="$1"
        ;;
    esac
    shift
  done

  (
    sleep "$duration"

    [[ "$use_say" == false || "$use_os" == true ]] && osascript -e 'on run argv' \
      -e 'display notification (item 1 of argv) with title "Timer" sound name "Glass"' \
      -e 'end run' \
      "$os_msg"

    [[ "$use_say" == true ]] && say "$say_msg"
  ) >/dev/null 2>&1 &!
}
