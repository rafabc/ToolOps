

export BROKERS=kafka2-des-confluent.apps.oca.des.comunidad.madrid:443
export BROKERS2=localhost:9092
export USERNAME=username
export PASSWORD=password
export TOPIC=demo


############################# LOCAL #################################
#kafkacat -b $BROKERS2 -L  | grep topic
echo "T1" $?
for i in {1..5}
do
    echo $(uptime) > test
    kafkacat -b $BROKERS2 -t $TOPIC  -P test
    #cat test
done
echo "T2" $?
kafkacat -b $BROKERS2 -t $TOPIC 
echo "T3" $?



############################# MD #################################
# kafkacat -b $BROKERS -L -X enable.ssl.certificate.verification=false -X security.protocol=PLAINTEXT  | grep topic
# echo "T1" $?
# kafkacat -b $BROKERS -t $TOPIC -X security.protocol=SSL  -X ssl.ca.location=cert-509_2.cer -X debug=all -P test
# echo "T2" $?
# kafkacat -b $BROKERS -t $TOPIC -X security.protocol=SSL -X ssl.ca.location=cert-509.cer
# echo "T3" $?


