#!/usr/bin/env bash

APPNAME="nbbo"

# find voltdb binaries in either installation or distribution directory.
if [ -n "$(which voltdb 2> /dev/null)" ]; then
    VOLTDB_BIN=$(dirname "$(which voltdb)")
else
    VOLTDB_BIN="$(dirname $(dirname $(pwd)))/bin"
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
CLIENTCLASSPATH=$CLASSPATH:$({ \
    \ls -1 "$VOLTDB_VOLTDB"/voltdbclient-*.jar; \
    \ls -1 "$VOLTDB_LIB"/commons-cli-1.2.jar; \
} 2> /dev/null | paste -sd ':' - )
VOLTDB="$VOLTDB_BIN/voltdb"
VOLTADMIN="$VOLTDB_BIN/voltadmin"
SQLCMD="$VOLTDB_BIN/sqlcmd"
LOG4J="$VOLTDB_VOLTDB/log4j.xml"
LICENSE="$VOLTDB_VOLTDB/license.xml"
HOST="localhost"
DEPLOYMENT=deployment.xml

# remove build artifacts
function clean() {
    rm -rf debugoutput log $APPNAME.jar voltdbroot \
           procedures/nbbo/*.class \
           client/nbbo/*.class \
           statement-plans catalog-report.html nohup.log log
}

# compile the source code for procedures and the client
function srccompile() {
    javac -target 1.7 -source 1.7 -classpath $APPCLASSPATH \
        procedures/nbbo/*.java \
        client/nbbo/*.java
    # stop if compilation fails
    if [ $? != 0 ]; then exit; fi
}

# build an application catalog
function catalog() {
    srccompile
    echo "Compiling the voter application catalog."
    echo "To perform this action manually, use the command line: "
    echo
    echo "voltdb compile -o $APPNAME.jar ddl.sql"
    echo
    $VOLTDB compile -o $APPNAME.jar ddl.sql
    # stop if compilation fails
    if [ $? != 0 ]; then exit; fi
}

# run the voltdb server locally
function server() {
    # if a catalog doesn't exist, build one
    if [ ! -f $APPNAME.jar ]; then catalog; fi
    # run the server
    echo "Starting the VoltDB server."
    echo "To perform this action manually, use the command line: "
    echo
    echo "$VOLTDB create -d deployment.xml -l $LICENSE -H $HOST $APPNAME.jar"
    echo
    nohup $VOLTDB create -d $DEPLOYMENT -l $LICENSE -H $HOST $APPNAME.jar \
          > nohup.log 2>&1 &
}

# update catalog on a running database
function update() {
    catalog
    $VOLTADMIN update $APPNAME.jar deployment.xml
}

function client() {
    srccompile
    echo "running nbbo benchmark test..."
    java -classpath client:$CLIENTCLASSPATH -Dlog4j.configuration=file://$LOG4J \
	nbbo.NbboBenchmark \
	--displayinterval=5 \
	--warmup=5 \
	--duration=30 \
	--ratelimit=20000 \
	--autotune=true \
	--latencytarget=3 
}

function truncate() {
    echo "truncate table ticks; truncate table last_ticks; truncate table nbbos;" | $SQLCMD
}

function help() {
    echo "Usage: ./run.sh {clean|catalog|server|client|truncate|demo}"
}

function demo() {
    server
    echo "waiting 10 seconds to start client benchmark..."
    sleep 10
	web/run.sh start
	client
	web/run.sh stop
	$VOLTADMIN shutdown
}

# Run the target passed as the first arg on the command line
# If no first arg, run server
if [ $# -gt 1 ]; then help; exit; fi
if [ $# = 1 ]; then $1; else server; fi
