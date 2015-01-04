/* This file is part of VoltDB.
 * Copyright (C) 2008-2015 VoltDB Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with VoltDB.  If not, see <http://www.gnu.org/licenses/>.
 */

package nbbo;

import java.util.Random;
import java.math.BigDecimal;
import java.math.MathContext;
import org.voltdb.types.TimestampType;

public class NbboBenchmark extends BaseBenchmark {

	private Random rand = new Random();
	private MathContext mc = new MathContext(2);
	private BigDecimal bd0 = new BigDecimal(0);
	private long startTime = new TimestampType(System.currentTimeMillis()*1000).getTime();

	Symbols symbols;
	String[] exchanges = {"AM",
	                      "BO",
	                      "CI",
	                      "IS",
	                      "JA",
	                      "KX",
	                      "MW",
	                      "NA",
	                      "ND",
	                      "NY",
	                      "PB",
	                      "PC",
	                      "WT",
	                      "YB",
	                      "ZB"
	};
	int[] sizes = {100,200,500,1000,2000};
	long seq = 0l;
    
	// constructor
	public NbboBenchmark(BenchmarkConfig config) {
		super(config);
        
	}

	public void initialize() throws Exception {
		symbols = new Symbols();
		symbols.loadFile("data/NYSE.csv");
		symbols.loadFile("data/NASDAQ.csv");
		symbols.loadFile("data/AMEX.csv");
	}

	public void iterate() throws Exception {

		Symbols.Symbol s = symbols.getRandom();
		int ask = (int)Math.round(s.price * (1+rand.nextFloat()/20));
		int bid = (int)Math.round(s.price * (1-rand.nextFloat()/20));

		String exch = exchanges[rand.nextInt(exchanges.length)];

		client.callProcedure(new BenchmarkCallback("ProcessTick"),
		                     "ProcessTick",
		                     s.symbol,
		                     new TimestampType(),
		                     seq++, //seq_number
		                     exch, // exchange
		                     bid, //bid_price
		                     sizes[rand.nextInt(sizes.length)], //bid_size
		                     ask, //ask_price
		                     sizes[rand.nextInt(sizes.length)] //ask_size
		                     );
	}

	public static void main(String[] args) throws Exception {
		BenchmarkConfig config = BenchmarkConfig.getConfig("NbboBenchmark",args);
        
		BaseBenchmark benchmark = new NbboBenchmark(config);
		benchmark.runBenchmark();

	}
}
