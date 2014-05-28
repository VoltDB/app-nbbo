#!/usr/bin/env bash

SERVERS=localhost

# This script assumes voltdb/bin is in your path
VOLTDB_HOME=$(dirname $(dirname "$(which voltdb)"))

# set the classpath
CLASSPATH=`ls -1 $VOLTDB_HOME/voltdb/voltdb-*.jar`
if [ ! -f $CLASSPATH ]; then
    echo "voltdb-*.jar file not found for CLASSPATH, edit this script to provide the correct path"
    exit
fi
# the VoltDB client uses google guava
#CLASSPATH="$CLASSPATH:`ls -1 $VOLTDB_HOME/lib/guava-*.jar`"
# the benchmark uses Apache commons CLI
CLASSPATH="$CLASSPATH:`ls -1 $VOLTDB_HOME/lib/commons-cli-*.jar`"

# compile
function compile() {
    mkdir -p obj
    SRC=`find src -name "*.java"`
    javac -Xlint:unchecked -classpath $CLASSPATH -d obj $SRC
    # stop if compilation fails
    if [ $? != 0 ]; then exit; fi
}

# remove non-source files
function clean() {
    rm -rf obj log
}

#java -classpath obj:$CLASSPATH:obj -Dlog4j.configuration=file://$VOLTDB_HOME/voltdb/log4j.xml client.Symbols

function truncate() {
    echo "truncate table ticks; truncate table last_ticks; truncate table nbbos;" | sqlcmd
}


function client() {
    compile
    #truncate
    echo "running sync benchmark test..."
    java -classpath obj:$CLASSPATH:obj -Dlog4j.configuration=file://$VOLTDB_HOME/voltdb/log4j.xml \
	client.NbboBenchmark \
	--displayinterval=5 \
	--warmup=5 \
	--duration=300 \
	--ratelimit=20000 \
	--autotune=true \
	--latencytarget=3 \
	--servers=$SERVERS
}

# Run the target passed as the first arg on the command line
# If no first arg, run server
if [ $# -gt 1 ]; then help; exit; fi
if [ $# = 1 ]; then $1; else client; fi

