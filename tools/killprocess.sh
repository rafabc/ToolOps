#!gitbash


PORT=$1

pid=$(lsof -i -P | grep LISTEN | grep -i $PORT | awk -F ' ' 'NR==1{print $2}')

#pid=$(netstat -ano | grep 3300 | awk -F ' ' 'NR==1{print $5}')
echo "$PORT port pid to kill -->" $pid
#taskkill //PID $pid  //F
kill -9 $pid

OUT=$?


 if [ $OUT -ne 0 ]; then
    echo "PUERTO NO DETECTADO EN USO"
 fi


# pid=$(lsof -i -P | grep LISTEN | grep -i 8888 | awk -F ' ' 'NR==1{print $2}')

# #pid=$(netstat -ano | grep 3300 | awk -F ' ' 'NR==1{print $5}')
# echo "8888 port pid to kill -->" $pid
# #taskkill //PID $pid  //F
# kill -9 $pid


# pid=$(lsof -i -P | grep LISTEN | grep -i 8080 | awk -F ' ' 'NR==1{print $2}')

# #pid=$(netstat -ano | grep 3300 | awk -F ' ' 'NR==1{print $5}')
# echo "8888 port pid to kill -->" $pid
# #taskkill //PID $pid  //F
# kill -9 $pid