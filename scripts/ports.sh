


function chech_port_in_use() {
    local port=$1
    local pid=$(lsof -i -P | grep LISTEN | grep -i $port | awk -F ' ' 'NR==1{print $2}')
    if [ -n "$pid" ]; then
        echo "$port port pid to kill -->" $pid
        #taskkill //PID $pid  //F
        kill -9 $pid
    else
        echo "PUERTO NO DETECTADO EN USO"
    fi
}