#!/usr/bin/env bash

APPNAME="nbbo"

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
    rm -rf obj $APPNAME.jar voltdbroot statement-plans log catalog-report.html nohup.log
}

# compile any java stored procedures
function srccompile() {
    mkdir -p obj
    SRC=`find src -name "*.java"`
    if [ ! -z $SRC ]; then
	javac -target 1.7 -source 1.7 -classpath $APPCLASSPATH -d obj $SRC
	# stop if compilation fails
	if [ $? != 0 ]; then exit; fi
    fi
}

# build an application catalog
function catalog() {
    srccompile
    $VOLTDB compile --classpath obj -o $APPNAME.jar ddl.sql
    # stop if compilation fails
    if [ $? != 0 ]; then exit; fi
}

# run the voltdb server locally
function server() {
    # if a catalog doesn't exist, build one
    if [ ! -f $APPNAME.jar ]; then catalog; fi
    # run the server
    nohup $VOLTDB create -d deployment.xml -l $LICENSE -H localhost $APPNAME.jar > nohup.log 2>&1 &
    echo "------------------------------------"
    echo "|  Ctrl-C to stop tailing the log  |"
    echo "------------------------------------"
    tail -f nohup.log
}

# update catalog on a running database
function update() {
    catalog
    voltadmin update $APPNAME.jar deployment.xml
}

function help() {
    echo "Usage: ./run.sh {clean|catalog|server}"
}

# Run the target passed as the first arg on the command line
# If no first arg, run server
if [ $# -gt 1 ]; then help; exit; fi
if [ $# = 1 ]; then $1; else server; fi
