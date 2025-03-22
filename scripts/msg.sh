
function msg() {
    printf "%s$CYAN%s     %s[INFO]%s $1 %s$PURPLE_HIGH%s $2 %s$CYAN%s $3 $4 $5 $6 $7 $8 $9\n"
}

function msg_ok() {
	printf "%s$GREEN%s-------------------------------------------------------------------------------------\n"
	printf "%s$GREEN%s %s$OK%s  %s$1%s in %s$PURPLE_HIGH%s %s$((END-START)) sg\n";
	printf "%s$GREEN%s-------------------------------------------------------------------------------------%s$RESET%s\n"
}

function msg_ko() {
	printf "%s$RED%s-------------------------------------------------------------------------------------\n"
	printf "%s$RED%s %s$ERROR%s $1\n";
	printf "%s$RED%s-------------------------------------------------------------------------------------%s$RESET%s\n"
}

function msg_task() {
	printf "\n%s$YELLOW%s-------------------------------------------------------------------------------------\n"
	printf "%s$YELLOW%s %s$ARROW%s $1 %s$BLUE_HIGH%s$2\n";
	printf "%s$YELLOW%s-------------------------------------------------------------------------------------%s$RESET%s\n"
}

function msg_ko_exit() {
	printf "%s$RED%s-------------------------------------------------------------------------------------\n"
	printf "%s$RED%s %s$ERROR%s $1\n";
	printf "%s$RED%s-------------------------------------------------------------------------------------%s$RESET%s\n"
	exit 1
}

function msg_check_success() {
	printf "%s$GREEN%s            %s$OK2%s  %s$1%s";
	printf "%s$GREEN%s%s$RESET%s\n"
}

function msg_check_fail() {
	printf "%s$RED%s            %s$ERROR%s  %s$1%s";
	printf "%s$RED%s%s$RESET%s\n"
}
function msg_info() {
	printf "%s$YELLOW%s            %s$INFO%s  %s$1%s";
	printf "%s$YELLOW%s%s$RESET%s\n"
}
function msg_warn() {
	printf "%s$PURPLE%s       	    %s$WARN%s  %s$1%s";
	printf "%s$PURPLE%s%s$RESET%s\n"
}

function msg_info_idented() {
	printf "%s$YELLOW%s            	%s$INFO%s  %s$1%s";
	printf "%s$YELLOW%s%s$RESET%s\n"
}
function msg_warn_idented() {
	printf "%s$PURPLE%s            	%s$WARN%s  %s$1%s";
	printf "%s$PURPLE%s%s$RESET%s\n"
}

function msg_check_fail_idented() {
	printf "%s$RED%s            	%s$ERROR%s  %s$1%s";
	printf "%s$RED%s%s$RESET%s\n"
}
function msg_check_success_idented() {
	printf "%s$GREEN%s           	%s$OK2%s  %s$1%s";
	printf "%s$GREEN%s%s$RESET%s\n"
}



export -f msg_ok
export -f msg_ko
export -f msg_task
export -f msg_ko_exit
export -f msg_check_success
export -f msg_check_fail
export -f msg_info
