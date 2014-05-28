package client;

import client.CsvLineParser;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.*;
import java.math.BigDecimal;

public class Symbols {


	private Random rand = new Random();

	public class Symbol {
		public String symbol;
		public int price;
		
		public String toString() {
			return symbol + " = " + price;
		}
	}

	private ArrayList<Symbol> symbols = new ArrayList<Symbol>();

	public Symbol getRandom() {
		int i = rand.nextInt(symbols.size());
		return incrementAndGet(i);
	}

	public Symbol incrementAndGet(int index) {
		Symbol s = symbols.get(index);
		if (rand.nextInt(10) == 0) {
			s.price = (int)Math.round(s.price * (1+rand.nextGaussian()/2000));

			// don't allow price to fall to zero
			if (s.price < 100) {
				s.price = 100;
			}
		}
		return s;
	}
    
	public void loadFile(String filename) {
		try {
			FileReader fileReader = new FileReader(filename);
			BufferedReader bufferedReader = new BufferedReader(fileReader);
			CsvLineParser parser = new CsvLineParser();
			
			// skip first line (headers)
			String line = bufferedReader.readLine();

			// read remaining lines
			int i=0;
			Iterator it;
			BigDecimal bd10000 = new BigDecimal(10000);
			while ((line = bufferedReader.readLine()) != null) {
				i++;
				it = parser.parse(line);
				Symbol s = new Symbol();
				s.symbol = (String)it.next();
				it.next(); // skip name
				String price = (String)it.next();
				if (price.equals("n/a")) {
					price = "20";
				}
				BigDecimal priceBD = new BigDecimal(price);
				s.price = priceBD.multiply(bd10000).intValue();

				symbols.add(s);
		
				//System.out.println(s.symbol + "   " + price + "   " + s.price);
			}
			bufferedReader.close();
			System.out.println("read " + i + " lines");
		} catch (IOException e) {
			e.printStackTrace();
		}

	}

	public static void main(String[] args) throws Exception {
		Symbols s = new Symbols();
		s.loadFile("data/NYSE.csv");

		for (int i=0; i<20; i++) {
			Symbol sym = s.incrementAndGet(100);	    
			System.out.println(sym);
		}
	}
}
