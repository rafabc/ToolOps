#!/bin/bash

OK="\u1"
OK1="\u2714"
ERROR="\u2"
ERROR2="\u2718"
ARROW="\u10"
ARROW2="\u25ba"
ARROW3="\u27a4"

RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
BLUE="\e[0;34m"
CYAN="\e[0;36m"
PURPLE="\e[0;35m"

RED_HIGH="\e[0;91m"
GREEN_HIGH="\e[0;92m"
YELLOW_HIGH="\e[0;93m"
BLUE_HIGH="\e[0;94m"
PURPLE_HIGH="\e[0;95m"
CYAN_HIGH="\e[0;96m"

RESET="\e[0m"

START=$(date +%s)
END=$(date +%s)

RUNTIME=$((END - START))

function start() {
	printf "%s$GREEN%s-------------------------------------------------------------------------------\n"
}
function end() {
	printf "%s$GREEN%s \n %s$1%s \n\n"
	printf "%s$GREEN%s-------------------------------------------------------------------------------%s$RESET%s\n"
}

function msg_ok() {
	printf "%s$GREEN%s %s$OK%s  %s$1%s %s$2%s $ARROW %s$PURPLE_HIGH%s %s$3%s %s$YELLOW%s  calculado en %s$PURPLE_HIGH%s %s$((END - START)) sg\n"
}

function msg_ko() {
	printf "%s$RED%s %s$ERROR%s $1 $2 $3 $4%s$RESET%s\n"
	printf "%s$RED%s-------------------------------------------------------------------------------%s$RESET%s\n"
}

function check_operation() {
	STATUS=$1
	END=$(date +%s)
	if [ $STATUS != 0 ]; then
		msg_ko "$2 fail operation"
		exit 1
	fi
}

responsedb=$(curl --connect-timeout 60 --max-time 60 -sb -H "Accept: application/json" "http://localhost:3000/api/info/db")
check_operation $? "curl ejecutado salida: $?  -- "
#salida curl = 28 --> supera connet-timeout o max-time

pm2 reset all &>/dev/null
check_operation $? "estadisticas pm2 refrescadas"

dbstatus=$(jq -n "$responsedb" | jq --raw-output .status)
dbvalidated=$(jq -n "$responsedb" | jq --raw-output .validated)

cpu=$(pm2 status | awk -F '│' 'FNR>3 {print $11;}')
mem=$(pm2 status | awk -F '│' 'FNR>3 {print $12;}')
status=$(pm2 status | awk -F '│' 'FNR>3 {print $10;}')

#echo 'Consumo memoria:' $mem
#echo 'Consumo CPU:' $cpu
#echo 'Estado nodo:' $status
#echo 'Estado db': $statusdb
#echo 'validacion db: ' $validated

#para cambiar el separador de campo
#oIFS="$IFS"
#IFS=" "

declare -a ram=($mem)
declare -a acpu=($cpu)
declare -a astatus=($status)

start

NODO=0
MAX_MEMORY=512
for x in "${ram[@]}"; do
	#echo "Memoria a analizar [$x]"
	m=$(echo $x | cut -d . -f 1)
	if [ "$m" -gt "$MAX_MEMORY" ]; then
		msg_ko "Memoria en nodo $NODO superior a la maxima permitida:" $MAX_MEMORY'mb' 'actual:' $m'mb'
		exit 1
	fi
	msg_ok 'Memoria en nodo' $NODO $m'mb'
	NODO=$(($NODO + 1))
done

NODO=0
MAX_CPU=80

DOCKERCPU=$(top -n 1 -b | awk '/^%Cpu/{print $2}')
if awk "BEGIN {exit !($DOCKERCPU >= $MAX_CPU)}"; then
	msg_ko "CPU Contenedor superior al maximo permitido:" $MAX_CPU'%' 'actual:' $DOCKERCPU'%'
	exit 1
else
	msg_ok 'Consumo CPU en Contenedor' $DOCKERCPU'%%'
fi


for x in "${acpu[@]}"; do
	#echo "Cpu a analizar [$x]"
	c=$(echo $x | cut -d % -f 1)
	#echo "Consumo CPU: $c"
	if [ "$c" -gt "$MAX_CPU" ]; then
		msg_ko "CPU en nodo $NODO superior al maximo permitido:" $MAX_CPU'%' 'actual:' $c'%'
		exit 1
	fi
	msg_ok 'Consumo CPU en nodo' $NODO $c'%%'
	NODO=$(($NODO + 1))
done



NODO=0
for x in "${astatus[@]}"; do
	#echo "Estado a analizar [$x]"
	s=$(echo $x | cut -d ' ' -f 1)
	if [ "$s" != "online" ]; then
		msg_ko "Estado nodo $NODO cluster pm2" $s
		exit 1
	fi
	msg_ok 'Estado nodo' $NODO $s
	NODO=$(($NODO + 1))
done

if [ "$dbstatus" != "connected" ]; then
	msg_ko "Estado conexion a la base de datos" $dbstatus
	exit 1
fi
msg_ok 'Estado base de datos' '' $dbstatus

if [ "$dbvalidated" != "true" ]; then
	msg_ko "Estado validacion de la conexion por sequelize" $dbvalidated
	exit 1
fi
msg_ok 'Estado validacion sequelize base de datos' '' $dbvalidated

end "El estado del cluster esta funcionando correctamente"
