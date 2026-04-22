git() {
    local first_arg="$1"
    local remaining_args=("${@:2}")

    if [ "$first_arg" = "log" ]; then
        command git log --graph "${remaining_args[@]}";

    elif [ "$first_arg" = "pull" ]; then
        command git pull --rebase "${remaining_args[@]}";

    elif [ "$first_arg" = "push" ]; then
        command git push --force-with-lease "${remaining_args[@]}";

    else
        command git "$@";
    fi;
}
