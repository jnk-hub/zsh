git() {
	if [ "$1" = "log" ]
	then
		command git log --graph "${@:2}";
	else
		command git "$@";
	fi;
}
