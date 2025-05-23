function shutdown() {
  tput cnorm # reset cursor
}
trap shutdown EXIT

function cursorBack() {
  #echo "\033[$1D"
  tput cuu 1 && tput el
}

function clearLastLine() {
  tput cuu 1 && tput el
}

function spinner() {
  # make sure we use non-unicode character type locale
  # (that way it works for any locale as long as the font supports the characters)
  local LC_CTYPE=C
  local pid=$1 # Process Id of the previous running command
  local msg=$2

  #case $(($RANDOM % 12)) in
  case $((10)) in
  0)
    local spin='⠁⠂⠄⡀⢀⠠⠐⠈'
    local charwidth=3
    ;;
  1)
    local spin='-\|/'
    local charwidth=1
    ;;
  2)
    local spin="▁▂▃▄▅▆▇█▇▆▅▄▃▂▁"
    local charwidth=3
    ;;
  3)
    local spin="▉▊▋▌▍▎▏▎▍▌▋▊▉"
    local charwidth=3
    ;;
  4)
    local spin='←↖↑↗→↘↓↙'
    local charwidth=3
    ;;
  5)
    local spin='▖▘▝▗'
    local charwidth=3
    ;;
  6)
    local spin='┤┘┴└├┌┬┐'
    local charwidth=3
    ;;
  7)
    local spin='◢◣◤◥'
    local charwidth=3
    ;;
  8)
    local spin='◰◳◲◱'
    local charwidth=3
    ;;
  9)
    local spin='◴◷◶◵'
    local charwidth=3
    ;;
  10)
    local spin='◐◓◑◒'
    local charwidth=3
    ;;
  11)
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local charwidth=3
    ;;
  esac

  local i=0

  tput civis # cursor invisible
  ti=$(date +%s)
  while kill -0 $pid 2>/dev/null; do
    local i=$(((i + $charwidth) % ${#spin}))
    printf "\r%s$YELLOW%s" "${spin:$i:$charwidth}           $INFO  $2"
    check_time $ti
    sleep .1
  done
  #msg_info "Process $pid finish        "
  echo
  tput cnorm
  wait $pid # capture exit code
  return $?
}

("$@") &

spinner $!

function check_time() {
  tiempo_maximo=300
  tiempo_inicio=$1
  tiempo_actual=$(date +%s)
  tiempo_transcurrido=$((tiempo_actual - tiempo_inicio))

  #sleep 1
  # Comprobar si el tiempo de ejecución ha superado el límite
  if [ $tiempo_transcurrido -gt $tiempo_maximo ]; then
    # Matar el proceso
    printf "\r%s$RED%s" 
    printf "\r%s" "            $ERROR  Process hang up  - killing process         "
   # printf "\r%s$RED%s" "       $ERROR  Process hang up  - killing process                 "
    kill -9 $pid &>/dev/null
    echo
    msg_warn "Proceso $pid matado despues de $tiempo_transcurrido segundos."
    echo
  # else
  #   sleep 1
  #   echo "El proceso $pid ha estado funcionando durante $tiempo_actual segundos."
  fi
}
