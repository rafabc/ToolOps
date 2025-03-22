


export AWS_ACCESS_KEY_ID=$1
export AWS_SECRET_ACCESS_KEY=$2
export AWS_SESSION_TOKEN=$3



export HTTP_PROXY=41.1.1.1:8080
export HTTPS_PROXY=41.1.1.1:8080
export NO_PROXY=41.1.1.1:8080

echo 
echo 
echo "Exec aws sts"

FINAL_CREDENTIALS=$(aws sts assume-role --role-arn "arn:aws:iam::$4:role/$5" --role-session-name EKS-Session)
echo "$FINAL_CREDENTIALS"

echo
echo "AWS_ACCESS_KEY_ID"
echo $FINAL_CREDENTIALS | awk '{print $5;}'

echo "AWS_SECRET_ACCESS_KEY"
echo $FINAL_CREDENTIALS | awk '{print $5;}'

echo "AWS_SESSION_TOKEN"
echo $FINAL_CREDENTIALS | awk '{print $8;}'

echo
echo
export AWS_ACCESS_KEY_ID=$(echo $FINAL_CREDENTIALS | awk '{print $5;}')
export AWS_SECRET_ACCESS_KEY=$(echo $FINAL_CREDENTIALS | awk '{print $7;}')
export AWS_SESSION_TOKEN=$(echo $FINAL_CREDENTIALS | awk '{print $8;}')


aws sts get-caller-identity

aws eks --region eu-west-1 update-kubeconfig --name $6

kubectl config set-context --current --namespace=$6