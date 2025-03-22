

function acr_login() {
	USER=$1
	PASSWORD=$2
    REGISTRY=$3
	docker login $REGISTRY -u $USER -p $PASSWORD
}


function run_pipeline() {
    
	VERSION=$1
	IDPIPE=$2

	IDRETURNED=$(curl --location --request POST "https://dev.azure.com/xxx/xxx/_apis/pipelines/${IDPIPE}/runs?pipelineVersion=1&api-version=6.0" \
	--header 'Authorization: Basic xxx=' \
	--header 'Content-Type: application/json' \
	--data-raw "{
		'resources': {
			'repositories': {
				'self': {
					'refName': 'refs/heads/main'
				}
			}
		},
		'variables': {
			'VERSION': {
				'isSecret': false,
				'value': '$VERSION'
			}
		}
	}" | jq --raw-output '.id')
	echo "${IDRETURNED}"  #ECHO IS USED HERE TO RETURN VALUE ID PIPE RUNNING
	#return "$IDRETURNED"
}



function check_pipeline_status() {

	ACCOUNT=$1
	PROJECT=$2
	PIPEID=$3
	RUNID=$4
	echo "PREPARING CHECK STATUS: ${RUNID} IN PIPE ${PIPEID}"


	while [[ "$(curl -s --location --request GET https://dev.azure.com/${ACCOUNT}/${PROJECT}/_apis/pipelines/${PIPEID}/runs/$RUNID --header 'Authorization: Basic cmFmYWVsLmJsYW5jb0BpbmV0dW0uY29tOjR0ZzRwd20za3o2bW53ZzRqZ2ZsNjQ1azNqMnkzdjdscHh6dnVhdnA2ZXNneHBtemNybXE=' | jq '.result')" == null ]]
	do
		sleep 3
		printf '\r%s                      ' "Checking status - wait for finish deploy"
	done

	RESPONSE=$(curl -s --location --request GET https://dev.azure.com/${ACCOUNT}/${PROJECT}/_apis/pipelines/${PIPEID}/runs/$RUNID --header 'Authorization: Basic cmFmYWVsLmJsYW5jb0BpbmV0dW0uY29tOjR0ZzRwd20za3o2bW53ZzRqZ2ZsNjQ1azNqMnkzdjdscHh6dnVhdnA2ZXNneHBtemNybXE=')
	status=$(jq -r '.state' <<< ${RESPONSE})
	result=$(jq -r '.result' <<< ${RESPONSE})
	echo ""
	if [[ "$status" != "completed" ]]; then
        printf "Finish pipe status incorrect: ${status}"
		return 1
    fi

	if [[ "$result" != "succeeded" ]]; then
        printf "Finish pipe result incorrect: ${result}"
		return 1
    fi

	printf "Finish pipe status: ${status}  result: ${result}"
	echo ""
	return 0
}


export -f acr_login
export -f run_pipeline
export -f check_pipeline_status
