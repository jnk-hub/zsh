lai() {
  emulate -L zsh

  local model="${LAI_MODEL:-gemma4}"
  local -a ollama_args=()
  local -a prompt_parts=()

  while (( $# )); do
    case "$1" in
      -m|--model)
        [[ -z "$2" ]] && { echo "lai: missing value for $1" >&2; return 1; }
        model="$2"
        shift 2
        ;;
      --help|-h)
        cat <<'EOF'
Usage:
  lai [options] [prompt]
  echo "prompt" | lai [options]

Options:
  -m, --model NAME  model name (default: $LAI_MODEL or gemma4)
  --                stop parsing options
  -h, --help        show help
EOF
        return 0
        ;;
      --)
        shift
        prompt_parts+=("$@")
        break
        ;;
      -*)
        ollama_args+=("$1")
        shift
        ;;
      *)
        prompt_parts+=("$1")
        shift
        ;;
    esac
  done

  local prompt=""
  if [[ -t 0 ]]; then
    prompt="${(j: :)prompt_parts}"
  else
    local stdin_data
    stdin_data="$(cat)"
    if (( ${#prompt_parts[@]} )); then
      prompt="${stdin_data}"$'\n\n'"${(j: :)prompt_parts}"
    else
      prompt="${stdin_data}"
    fi
  fi

  if [[ -z "$prompt" ]]; then
    command ollama run "${ollama_args[@]}" "$model"
  else
    command ollama run "${ollama_args[@]}" "$model" "$prompt"
  fi
}
