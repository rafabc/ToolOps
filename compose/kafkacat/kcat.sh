


export BROKERS=localhost:9092
export USERNAME=username
export PASSWORD=password
export TOPIC=demo


############################# LOCAL #################################
#kafkacat -b $BROKERS -L  | grep topic
echo "T1" $?
for i in {1..5}
do
    echo $(uptime) > test
    kafkacat -b $BROKERS -t $TOPIC  -P test
    #cat test
done
echo "T2" $?
kafkacat -b $BROKERS -t $TOPIC 
echo "T3" $?



