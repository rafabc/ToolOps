#!/usr/bin/env bash

function git_commit_and_push_develop() {
    IMAGE=$1
    VERSION=$2
    START=$(date +%s)
    msg_task "Pushing local changes with new version $VERSION to develop"
    git status
    git add .
    git commit -m "new $1 version $VERSION"
    git push origin develop
    check_operation $? "Local changes pushed to develop"
}

function git_merge_and_push_master() {
    IMAGE=$1
    VERSION=$2
    DEPLOYBRANCH=$3
    START=$(date +%s)
    msg_task "merging develop changes with new version $VERSION to $DEPLOYBRANCH"
    git checkout $DEPLOYBRANCH
    git status
    git merge develop
    git push origin $DEPLOYBRANCH
    check_operation $? "OS branch updated"
}

function git_tag() {
    IMAGE=$1
    VERSION=$2
    START=$(date +%s)
    msg_task "Closing new tag for version $VERSION"
    git tag $VERSION
    git push origin $VERSION
    check_operation $? "New tag $VERSION closed"
}

function git_checkout_develop() {
    IMAGE=$1
    VERSION=$2
    START=$(date +%s)
    msg_task "Checking out to develop"
    git checkout develop
    check_operation $? "Checkout develop completed"
}
