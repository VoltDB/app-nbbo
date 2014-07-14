package nbbo;

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

    // intermediate table (latest price on each exchange for each symbol traded)
    public final SQLStmt updateLastTick = new SQLStmt(
        "UPDATE last_ticks SET " +
	"  symbol = ?," +
	"  time = ?," +
	"  seq = ?," +
	"  exch = ?," +
	"  bid = ?," +
	"  bid_size = ?," +
	"  ask = ?," +
	"  ask_size = ? " +
        " WHERE symbol = ? AND exch = ?;");

    public final SQLStmt insertLastTick = new SQLStmt(
        "INSERT INTO last_ticks VALUES (" +
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

	// Queue tick insert
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

	// Queue last_ticks update
	voltQueueSQL(updateLastTick,
		     symbol,
		     time,
		     seq_number,
		     exchange,
		     bidPrice,
		     bid_size,
		     askPrice,
		     ask_size,
		     symbol,
		     exchange
                     );

	// Queue best bid and ask selects
	voltQueueSQL(selectMaxBid,symbol);
	voltQueueSQL(selectMinAsk,symbol);

	// Execute queued statements 
        VoltTable results0[] = voltExecuteSQL();

	// Check if the last_ticks update affected a row, otherwise we'll need to insert later
        long updateRowsAffected = results0[1].asScalarLong();
	
	// Variables for the max bid and ask values
	VoltTable tb = null;
	VoltTable ta = null;
	String bex = "";
	Integer bid = 0;
	Integer bsize = 0;
	String aex = "";
	Integer ask = 0;
	Integer asize = 0;
	
	if (updateRowsAffected == 1) {
	    // Use initial select results for best bid and ask
	    tb = results0[2];
	    ta = results0[3];

	} else {
	    // update affected 0 rows, need to insert into last_ticks, then re-run the selects

	    // queue the last_ticks insert
	    voltQueueSQL(insertLastTick,
			 symbol,
			 time,
			 seq_number,
			 exchange,
			 bid_price,
			 bid_size,
			 ask_price,
			 ask_size
                         );

	    // queue the selects
	    voltQueueSQL(selectMaxBid,symbol);
	    voltQueueSQL(selectMinAsk,symbol);

	    // execute queued statements
	    VoltTable results1[] = voltExecuteSQL();

	    // use the second set of select results for best bid and ask
	    tb = results1[1];
	    ta = results1[2];
	}

	// Read the best bid and ask results
	tb.advanceRow();
	bex = tb.getString(0);
	bid = (int)tb.getLong(1);
	bsize = (int)tb.getLong(2);

	ta.advanceRow();
	aex = ta.getString(0);
	ask = (int)ta.getLong(1);
	asize = (int)ta.getLong(2);

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
