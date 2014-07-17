#!/usr/bin/env bash

APPNAME="nbbo"
HOST=localhost
DEPLOYMENT=deployment.xml

WEB_PORT=8081

# Get the PID from PIDFILE if we don't have one yet.
if [[ -z "${PID}" && -e web/http.pid ]]; then
  PID=$(cat web/http.pid);
fi

# find voltdb binaries in either installation or distribution directory.
if [ -n "$(which voltdb 2> /dev/null)" ]; then
    VOLTDB_BIN=$(dirname "$(which voltdb)")
else
    VOLTDB_BIN="$(pwd)/../../../bin"
    echo "The VoltDB scripts are not in your PATH."
    echo "For ease of use, add the VoltDB bin directory: "
    echo
    echo $VOLTDB_BIN
    echo
    echo "to your PATH."
    echo
fi
# installation layout has all libraries in $VOLTDB_ROOT/lib/voltdb
if [ -d "$VOLTDB_BIN/../lib/voltdb" ]; then
    VOLTDB_BASE=$(dirname "$VOLTDB_BIN")
    VOLTDB_LIB="$VOLTDB_BASE/lib/voltdb"
    VOLTDB_VOLTDB="$VOLTDB_LIB"
# distribution layout has libraries in separate lib and voltdb directories
else
    VOLTDB_BASE=$(dirname "$VOLTDB_BIN")
    VOLTDB_LIB="$VOLTDB_BASE/lib"
    VOLTDB_VOLTDB="$VOLTDB_BASE/voltdb"
fi

APPCLASSPATH=$CLASSPATH:$({ \
    \ls -1 "$VOLTDB_VOLTDB"/voltdb-*.jar; \
    \ls -1 "$VOLTDB_LIB"/*.jar; \
    \ls -1 "$VOLTDB_LIB"/extension/*.jar; \
} 2> /dev/null | paste -sd ':' - )
VOLTDB="$VOLTDB_BIN/voltdb"
LOG4J="$VOLTDB_VOLTDB/log4j.xml"
LICENSE="$VOLTDB_VOLTDB/license.xml"

# remove non-source files
function clean() {
    rm -rf voltdbroot statement-plans log catalog-report.html
    rm web/http.log web/http.pid
    rm -rf db/obj db/$APPNAME.jar db/nohup.log
    rm -rf client/obj client/log
}

function start_web() {
    if [[ -z "${PID}" ]]; then
        nohup python -m SimpleHTTPServer $PORT > web/http.log 2>&1 &
        echo $! > web/http.pid
    else
        echo "http server is already running (PID: ${PID})"
    fi
}

function stop_web() {
  if [[ -z "${PID}" ]]; then
    echo "http server is not running (missing PID)."
  else
      kill ${PID}
      rm web/http.pid
      echo "stopped http server (PID: ${PID})."
  fi
}

# compile any java stored procedures
function compile_procedures() {
    mkdir -p db/obj
    SRC=`find db/src -name "*.java"`
    if [ ! -z $SRC ]; then
	javac -target 1.7 -source 1.7 -classpath $APPCLASSPATH -d db/obj $SRC
        # stop if compilation fails
        if [ $? != 0 ]; then exit; fi
    fi
}

# build an application catalog
function catalog() {
    compile_procedures
    $VOLTDB compile --classpath db/obj -o db/$APPNAME.jar db/ddl.sql
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

function nohup_server() {
    # if a catalog doesn't exist, build one
    if [ ! -f db/$APPNAME.jar ]; then catalog; fi
    # run the server
    nohup $VOLTDB create -d db/$DEPLOYMENT -l $LICENSE -H $HOST db/$APPNAME.jar > db/nohup.log 2>&1 &
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

function demo() {
    nohup_server
    echo "starting web server..."
    start_web
    sleep 5
    echo "starting client..."
    sleep 5
    echo "Boo!"
    # add client later
    
}

function help() {
    echo "Usage: ./run.sh {clean|catalog|server}"
}

# Run the target passed as the first arg on the command line
# If no first arg, run server
if [ $# -gt 1 ]; then help; exit; fi
if [ $# = 1 ]; then $1; else server; fi
