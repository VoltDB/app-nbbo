package procedures;

//import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.Calendar;

import org.voltdb.*;
import org.voltdb.types.TimestampType;
import org.voltdb.client.ClientResponse;

public class ProcessTick extends VoltProcedure {

    // base table
    public final SQLStmt insertTick = new SQLStmt(
        "INSERT INTO ticks VALUES (" +
        "?,?,?,?,?,?,?,?" + // 8
        ");");

    public final SQLStmt upsertLastTick = new SQLStmt(
        "UPSERT INTO last_ticks VALUES (" +
        "?,?,?,?,?,?,?,?" + // 8
        ");");

    public final SQLStmt selectMaxBid = new SQLStmt(
	"SELECT exch,bid,bid_size "+
	"FROM last_ticks "+
	"WHERE symbol = ? "+
	"ORDER BY bid DESC,seq ASC LIMIT 1;");

    public final SQLStmt selectMinAsk = new SQLStmt(
	"SELECT exch,ask,ask_size "+
	"FROM last_ticks "+
	"WHERE symbol = ? AND ask > 0 "+
	"ORDER BY ask ASC,seq ASC LIMIT 1;");
    
    // NBBO output table
    public final SQLStmt insertNBBO = new SQLStmt(
        "INSERT INTO nbbos VALUES (" +
        "?,?,?,?,?,?,?,?,?" + // 9
        ");");

    // "main method" the procedure starts here.
    public long run( 
	String symbol,
	TimestampType time,
	long seq_number,
	String exchange,
	int bid_price,
	int bid_size,
	int ask_price,
	int ask_size
		     ) throws VoltAbortException {

	// convert bid and ask 0 values to null
	Integer bidPrice = null;
	if (bid_price > 0)
	    bidPrice = bid_price;

	Integer askPrice = null;
	if (ask_price > 0)
	    askPrice = ask_price;

	voltQueueSQL(insertTick,
		     symbol,
		     time,
		     seq_number,
		     exchange,
		     bidPrice,
		     bid_size,
		     askPrice,
		     ask_size
		     );

        voltQueueSQL(upsertLastTick,
                     symbol,
                     time,
                     seq_number,
                     exchange,
                     bid_price,
                     bid_size,
                     ask_price,
                     ask_size
                     );

        
	// Queue best bid and ask selects
	voltQueueSQL(selectMaxBid,symbol);
	voltQueueSQL(selectMinAsk,symbol);

	// Execute queued statements 
        VoltTable results0[] = voltExecuteSQL();

	// Read the best bid results
	VoltTable tb = results0[2];
	tb.advanceRow();
	String bex = tb.getString(0);
	Integer bid = (int)tb.getLong(1);
	Integer bsize = (int)tb.getLong(2);

        // Read the best ask results
        VoltTable ta = results0[3];
	ta.advanceRow();
	String aex = ta.getString(0);
	Integer ask = (int)ta.getLong(1);
	Integer asize = (int)ta.getLong(2);

	// check if the tick is part of the nbbo
	if (bex.equals(exchange) || aex.equals(exchange)) {
	    // this new quote was the best bid or ask
	    //  insert a new NBBO record
	    //  use this quote's symbol, time and sequence number
	    voltQueueSQL(insertNBBO,
			 symbol,
			 time,
			 seq_number,
			 bid,
			 bsize,
			 bex,
			 ask,
			 asize,
			 aex
			 );

	    voltExecuteSQL(true);
	}

	return ClientResponse.SUCCESS;
    }
}
