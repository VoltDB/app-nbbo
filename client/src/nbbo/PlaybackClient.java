package nbbo;

import org.voltdb.*;
import org.voltdb.client.*;
import org.voltdb.types.TimestampType;

public class PlaybackClient {

    public static void main(String[] args) throws Exception {

        org.voltdb.client.Client client;
        client = ClientFactory.createClient();

        // first argument is a comma-separated list of servers
        String[] servers = args[0].split(",");
        for (String server : servers) {
            client.createConnection(server);
        }


        // get the min and max timestamps from ticks table (or you could take inputs for a desired time range)
        String sql0 = "SELECT MIN(time), MAX(time) FROM ticks";
        VoltTable v0 = client.callProcedure("@AdHoc",sql0).getResults()[0];
        v0.advanceRow();
        TimestampType startTimestamp = v0.getTimestampAsTimestamp(0);
        long startTime = v0.getTimestampAsLong(0);
        TimestampType endTimestamp = v0.getTimestampAsTimestamp(1);
        long endTime = v0.getTimestampAsLong(1);

        // get the range in microseconds
        long microsInRange = endTime - startTime;
        System.out.println(microsInRange +" microseconds between "+startTimestamp+" and "+endTimestamp);

        // get the number of rows in the range
        String query =
            "SELECT COUNT(*) FROM ticks "+
            "WHERE time >= TO_TIMESTAMP(MICROS,"+startTime+") AND "+
            "time <= TO_TIMESTAMP(MICROS,"+endTime+")";
        long rowCount = client.callProcedure("@AdHoc",query).getResults()[0].asScalarLong();

        // get a sample of records to estimate the average row size
        int sampleSize = 100;
        VoltTable t2 = client.callProcedure("@AdHoc","SELECT * FROM ticks LIMIT "+sampleSize).getResults()[0];
        double bytesPerRow = t2.getSerializedSize()/sampleSize;

        // max result size is 50MB/call, but it is less disruptive to fetch less data per call
        int targetBytesPerCall = 10000000; // 10MB

        // to get the approximately the target bytes per call, estimate how many microseconds to offset each call
        double estBytesInRange = bytesPerRow * rowCount;
        int targetCalls = (int)estBytesInRange/targetBytesPerCall;
        int microsOffset = (int)microsInRange/targetCalls;

        // for reporting
        long retrievedRowCount = 0;
        long retrievedBytes = 0;
        
        // get the data in chunks defined by ranges of timestamp values
        for (long t=startTime; t<endTime; t+=microsOffset) {
            long t1 = t+microsOffset;
            String sql = "SELECT * FROM ticks WHERE time >= TO_TIMESTAMP(MICROS," + t + ") AND time < TO_TIMESTAMP(MICROS," + t1 + ") ORDER BY time";
            VoltTable v = client.callProcedure("@AdHoc",sql).getResults()[0];
            retrievedBytes+=v.getSerializedSize();
            long rows = 0;
            while (v.advanceRow()) {
                retrievedRowCount++;
                rows++;
            }
            System.out.println("  got " + rows + " rows ("+v.getSerializedSize()+" bytes)");
            
        }
        
        System.out.println("----------------------------------");
        System.out.println(" Expected rows:  "+rowCount);
        System.out.println(" Retrieved rows: "+rowCount);
        System.out.println();
        System.out.println(" Expected bytes:  "+(int)(rowCount * bytesPerRow)+" (estimated)");
        System.out.println(" Retrieved bytes: "+retrievedBytes+" (actual)");

        client.close();
    }
}
