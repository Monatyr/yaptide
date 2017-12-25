#!/usr/bin/env bash

# get script parent directory absolute path
# http://www.ostricher.com/2014/10/the-right-way-to-get-the-directory-of-a-bash-script/
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $SCRIPT_PATH/build_tools/db_tools.sh

set -e

if [ "$1" = "client:check" ]; then
    cd $SCRIPT_PATH
    npm run check
elif [ "$1" = "client:deploy" ]; then
    cd $SCRIPT_PATH
    rm -rf $SCRIPT_PATH/static # optional(to create clean build)
    npm install
    npm run deploy
elif [ "$1" = "client:run" ]; then
    cd $SCRIPT_PATH
    npm install
    YAPTIDE_BASE_URL=http://localhost:3000 npm start
elif [ "$1" = "server:run" ]; then
    cd $SCRIPT_PATH
    echo "{\"port\": \"3000\", \"dbName\": \"yaptide-db-dev\", \"dbUsername\": \"yaptide-db-dev\", \"dbPassword\": \"password\", \"dbPort\": \"3005\"}" > $SCRIPT_PATH/conf.json
    startDB "dev" "3005"
    DEV=true go run main.go
elif [ "$1" = "server:run:dev" ]; then
    # go get github.com/codegangsta/gin
    echo "{\"port\": \"3001\", \"dbName\": \"yaptide-db-dev\", \"dbUsername\": \"yaptide-db-dev\", \"dbPassword\": \"password\", \"dbPort\": \"3005\"}" > $SCRIPT_PATH/conf.json
    cd $SCRIPT_PATH
    startDB "dev" "3005"
    DEV=true gin
elif [ "$1" = "server:check" ]; then
    # go get -u github.com/alecthomas/gometalinter
    # gometalinter --install
    # /... - checking recursively all files inside
    cd $SCRIPT_PATH
    gometalinter --config=.gometalinter.json --deadline 200s ./...
    govendor test +local
elif [ "$1" = "check" ]; then
    cd $SCRIPT_PATH
    gometalinter --config=.gometalinter.json --deadline 1000s ./...
    govendor test +local
    npm run check
elif [ "$1" = "docker:run" ]; then
    cd $SCRIPT_PATH
    echo "{\"port\": \"3301\", \"dbName\": \"yaptide-db-docker\", \"dbUsername\": \"yaptide-db-docker\", \"dbPassword\": \"password\", \"dbPort\": \"27017\". \"dbHost\": \"172.17.1.1\"}" > $SCRIPT_PATH/conf.json
    startDB "docker" "27017"
    docker build --force-rm --tag yaptide $SCRIPT_PATH
    docker run --tty --interactive --rm -p 3301:3301 --name=yaptide yaptide:latest
elif [ "$1" = "prod:run" ]; then
    echo "{\"port\": \"3101\", \"dbName\": \"yaptide-db-prod\", \"dbUsername\": \"yaptide-db-prod\", \"dbPassword\": \"password\", \"dbPort\": \"3105\"}" > $SCRIPT_PATH/conf.json
    cd $SCRIPT_PATH
    startDB "prod" "3105"
    YAPTIDE_BASE_URL=http://localhost:3101 ./run.sh client:deploy


    go install -v
    DEV=true yaptide
elif [ "$1" = "setup:go" ]; then
    cd $SCRIPT_PATH
    go get -u github.com/alecthomas/gometalinter
    gometalinter --install
    go get -u github.com/kardianos/govendor
    go get  github.com/codegangsta/gin
    npm install
elif [ "$1" = "server:test" ]; then
    shift
    govendor test +local $@
else
    echo "\
Usage: $0 COMMAND [ARGS]

Commands:
    client:check	run all checks lint+flow+test
    client:deploy	generate static client code
    client:run		run client dev server

    setup:go		get all tools required in dev environment
    server:run		run server
    server:run:dev	run server with hot reloading - TODO
    server:check	run linters and tests on backend
    server:test		run server tests

    check		server:check + client:check
    docker:run		build & run new docker container
    prod:run		run production version localy
    "
fi

