# VoltDB NBBO Example App

Use Case
--------
NBBO is the National Best Bid and Offer, defined as the lowest available ask price and highest available bid price across the participating markets for a given security.  Brokers should route trade orders to the market with the best price, and by law must guarantee customers the best available price.

This example app includes a VoltDB database schema that stores each market data tick and automatically inserts a new NBBO record whenever there is a change to the best available bid or ask price.  This can be used to serve the current NBBO or the history of NBBO changes on demand to consumers such as the dashboard or other applications.

The example includes a web dashboard that shows the real-time NBBO for a security and the latest avaialble prices from each exchange.  It also includes a client benchmark application that generates synthetic market data ticks for all of the listed stocks from NYSE, AMEX, and NASDAQ.  The prices are simulated using a random walk algorithm that starts from the end of day closing price that is initially read from a CSV file.  It is not intended to be a realistic simulation of market data, but simply to generate simulated data for demonstration purposes.

Code organization
-----------------
The code is divided into projects:

- "db": the database project, which contains the schema, stored procedures and other configurations that are compiled into a catalog and run in a VoltDB database.  
- "client": a java client that generates tick events and records performance metrics.
- "web": a simple web server that provides the demo dashboard.

See below for instructions on running these applications.  For any questions, 
please contact fieldengineering@voltdb.com.

Pre-requisites
--------------
Before running these scripts you need to have VoltDB 4.0 or later installed, and the bin subdirectory should be added to your PATH environment variable.  For example, if you installed VoltDB Enterprise 4.5 in your home directory, you could add it to the PATH with the following command:

    export PATH="$PATH:$HOME/voltdb-ent-4.5/bin"


Instructions
------------

1. Start the database (in the background)

    cd db
    ./run.sh
     
2. Start the web server for the dashboard

    cd web
    ./run.sh

3. Run the client benchmark application

    cd client
    ./run.sh

To stop the database:

    voltadmin shutdown
    
To stop the web server:

    cd web
    ./run.sh stop


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



