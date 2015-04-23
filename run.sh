#!/usr/bin/env bash

set -o errexit #exit on any single command fail

# VoltDB variables
APPNAME="nbbo"
HOST=localhost
DEPLOYMENT=deployment.xml

# WEB SERVER variables
WEB_PORT=8081

# CLIENT variables
SERVERS=localhost

# This script assumes voltdb/bin is in your path
VOLTDB_HOME=$(dirname $(dirname "$(which voltdb)"))


function start_web() {
    stop_web
    cd web
    nohup python -m SimpleHTTPServer $WEB_PORT > http.log 2>&1 &
    cd .. 
    echo "started demo http server"
}

function stop_web() {
    WEB_PID=$(ps -ef | grep "SimpleHTTPServer $WEB_PORT" | grep python | awk '{print $2}')
    if [[ ! -z "$WEB_PID" ]]; then
        kill $WEB_PID
        echo "stopped demo http server"
    fi
}


# remove non-source files
function clean() {
    rm -rf voltdbroot statement-plans log catalog-report.html
    rm -f web/http.log
    rm -rf db/obj db/$APPNAME.jar db/nohup.log
    rm -rf client/obj client/log
}


# compile any java stored procedures
function compile_procedures() {
    mkdir -p db/obj
    CLASSPATH=`ls -1 $VOLTDB_HOME/voltdb/voltdb-*.jar`
    SRC=`find db/src -name "*.java"`
    if [ ! -z "$SRC" ]; then
	javac -classpath $CLASSPATH -d db/obj "$SRC"
        # stop if compilation fails
        if [ $? != 0 ]; then exit; fi
    fi
}

function procedure_jar() {
    compile_procedures
    jar cf db/procs.jar -C db/obj .
}


# DEPRECATED - build an application catalog 
function catalog() {
    compile_procedures
    voltdb compile --classpath db/obj -o db/$APPNAME.jar db/ddl.sql
    # stop if compilation fails
    if [ $? != 0 ]; then exit; fi
}

# run the voltdb server locally
function server() {
    nohup_server
    echo "------------------------------------"
    echo "|  Ctrl-C to stop tailing the log  |"
    echo "------------------------------------"
    tail -f db/nohup.log
}

function nohup_server_no_catalog() {
    nohup voltdb create -d db/$DEPLOYMENT -H $HOST > db/nohup.log 2>&1 &
}

function init() {
    procedure_jar
    cd db
    sqlcmd < ddl.sql
    cd ..
}

function nohup_server() {
    # if a catalog doesn't exist, build one
    if [ ! -f "db/$APPNAME.jar" ]; then catalog; fi
    # run the server
    nohup voltdb create -d db/$DEPLOYMENT -H $HOST db/$APPNAME.jar > db/nohup.log 2>&1 &
}

function cluster-server() {
    export DEPLOYMENT=deployment-cluster.xml
    server
}

# update catalog on a running database
function update() {
    catalog
    voltadmin update $APPNAME.jar deployment.xml
}

function client() {
    # if the class files don't exist, compile the client
    if [ ! -d client/obj ]; then compile-client; fi

    CLASSPATH=`ls -1 $VOLTDB_HOME/voltdb/voltdb-*.jar`
    CLASSPATH="$CLASSPATH:`ls -1 $VOLTDB_HOME/lib/commons-cli-*.jar`"

    cd client

    echo "running sync benchmark test..."
    java -classpath obj:$CLASSPATH -Dlog4j.configuration=file://$VOLTDB_HOME/voltdb/log4j.xml \
	nbbo.NbboBenchmark \
	--displayinterval=5 \
	--warmup=5 \
	--duration=1800 \
	--ratelimit=20000 \
	--autotune=true \
	--latencytarget=3 \
	--servers=$SERVERS

    cd ..
}

function compile-client() {
    CLASSPATH=`ls -1 $VOLTDB_HOME/voltdb/voltdb-*.jar`
    CLASSPATH="$CLASSPATH:`ls -1 $VOLTDB_HOME/lib/commons-cli-*.jar`"

    pushd client
    # compile client
    mkdir -p obj
    SRC=`find src -name "*.java"`
    javac -Xlint:unchecked -classpath $CLASSPATH -d obj $SRC
    # stop if compilation fails
    if [ $? != 0 ]; then exit; fi
    popd
}

# compile the catalog and client code
function demo-compile() {
    catalog
    compile-client
}

function demo() {
    export DEPLOYMENT=deployment-demo.xml
    nohup_server
    echo "starting client..."
    sleep 10
    client
}

function help() {
    echo "Usage: ./run.sh {clean|catalog|server}"
}

# Run the target passed as the first arg on the command line
# If no first arg, run server
if [ $# -gt 1 ]; then help; exit; fi
if [ $# = 1 ]; then $1; else server; fi
