# VoltDB Example App: National Best Bid & Offer (NBBO) Calculation

Use Case
--------
Process incoming market data ticks to calculate the NBBO in real-time.

Client generates ticks based on stock listings (with recent end-of-day prices) from NYSE, AMEX, NASDAQ.  These prices are used as starting points, but the tick generation uses a random walk to update price.  Quantities are chosen at random.  This is a very simplistic generator, just meant to test the database workload.


Code organization
-----------------
The code is divided into projects:

- "db": the database project, which contains the schema, stored procedures and other configurations that are compiled into a catalog and run in a VoltDB database.  
- "client": a java client that generates tick events and records performance metrics.

See below for instructions on running these applications.  For any questions, 
please contact fieldengineering@voltdb.com.

Pre-requisites
--------------
Before running these scripts you need to have VoltDB 4.0 (Enterprise or Community) or later installed, and you should add the voltdb-$(VERSION)/bin directory to your PATH environment variable, for example:

    export PATH="$PATH:$HOME/voltdb-ent-4.2/bin"


Instructions
------------

1. Start the database (in the background)

    cd db
    ./run.sh
	(Ctrl-C)
     
2. Run the client benchmark application

    cd client
    ./run.sh

4. To stop the database

    voltadmin shutdown


Options
-------
You can control various characteristics of the demo by modifying the parameters passed into the NbboBenchmark java application in the client/run.sh script.

Speed & Duration:

    --duration=120                (benchmark duration in seconds)
    --autotune=true               (true = ignore rate limit, run at max throughput until latency is impacted)
                                  (false = run at the specified rate limit)
    --ratelimit=20000             (when autotune=false, run up to this rate of requests/second)


Instructions for running on a cluster
-------------------------------------

Before running this demo on a cluster, make the following changes:

1. On each server, edit the db/run.sh file to set the HOST variable to the name of the **first** server in the cluster:
    
    HOST=voltserver01
    
2. On each server, edit db/deployment.xml to change hostcount from 1 to the actual number of servers:

    <cluster hostcount="1" sitesperhost="3" kfactor="0" />

4. On each server, run the start script:

    cd db
	./run.sh
    
5. On one server, Edit the client/run.sh script to set the SERVERS variable to a comma-separated list of the servers in the cluster

    SERVERS=voltserver01,voltserver02,voltserver03
    
6. Run the client script:

	cd client
	./run.sh



