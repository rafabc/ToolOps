#!/usr/bin/env bash

function check_operation() {
	STATUS=$1
    END=`date +%s`
	if [ $STATUS -eq 0 ]; then
		msg_ok "$2 executed success"
	else
		msg_ko "$2 fail operation"
		exit 1
	fi
}


function check_operation_no_break() {
	STATUS=$1
	END=`date +%s`
	if [ $STATUS -eq 0 ]; then
		msg_ok "$2 executed success"
	else
		msg_ko "$2 fail operation"
	fi
}
