function setup_semver() {

    SEMVER_ACTION=$1
    DESTINATION=$2
    #ACTUALVERSION=$(grep -oP '(?<="version": ")[^"]*' package.json) --> NO TIRA EN MAC POR -P
    JSON=$(cat package.json)
    ACTUALVERSION=$(echo $JSON | grep -o '"version": "[^"]*' | grep -o '[^"]*$')
   
    START=$(date +%s)
    END=$(date +%s)

    echo "SEMVER ACTION $SEMVER_ACTION $ACTUALVERSION"

    case "$SEMVER_ACTION" in
    0)
        setup_new_version "patch"
        ;;
    1)
        setup_new_version "minor"
        ;;
    2)
        setup_new_version "major"
        ;;
    3)
        setup_new_version "release"
        ;;
    4)
        setup_new_version "prerel"
        ;;
    esac
}

function setup_new_version() {
    START=$(date +%s)
    msg_task "Setting up new $1 VERSION from actual version" $ACTUALVERSION
    msg 'ACTUAL PATH:' $PWD
    ls ../ToolOps
    VERSION=$(source ../ToolOps/scripts/semver.sh bump $1 $ACTUALVERSION)
    JSONVERSION=$(echo '"version": "'$ACTUALVERSION'"')
    JSONNEWVERSION=$(echo '"version": "'$VERSION'"')
    msg "version actual:" $ACTUALVERSION
    msg "version nueva a establecer: $VERSION"
    perl -i -pe"s/$JSONVERSION/$JSONNEWVERSION/g" package.json
    JSON=$(cat package.json)
    CHECKVERSION=$(echo $JSON | grep -o '"version": "[^"]*' | grep -o '[^"]*$')
   
    
    msg "version establecida package.json: $CHECKVERSION"
    check_operation $? "package.json $1 version updated to $VERSION"
}
