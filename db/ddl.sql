-- This file is part of VoltDB.
-- Copyright (C) 2008-2013 VoltDB Inc.
--
-------------------- EXAMPLE SQL -----------------------------------------------
-- CREATE TABLE example_of_types (
--   id              INTEGER NOT NULL, -- java int, 4-byte signed integer, -2,147,483,647 to 2,147,483,647
--   name            VARCHAR(40),      -- java String
--   data            VARBINARY(256),   -- java byte array 
--   status          TINYINT,          -- java byte, 1-byte signed integer, -127 to 127
--   type            SMALLINT,         -- java short, 2-byte signed integer, -32,767 to 32,767
--   pan             BIGINT,           -- java long, 8-byte signed integer, -9,223,372,036,854,775,807 to 9,223,372,036,854,775,807
--   balance_open    FLOAT,            -- java double, 8-byte numeric
--   balance         DECIMAL,          -- java BigDecimal, 16-byte fixed scale of 12 and precision of 38
--   last_updated    TIMESTAMP,        -- java long, org.voltdb.types.TimestampType, 8-byte signed integer (milliseconds since epoch)
--   CONSTRAINT pk_example_of_types PRIMARY KEY (id)
-- );
-- PARTITION TABLE example_of_types ON COLUMN id;
-- CREATE INDEX idx_example ON example_of_types (type,balance);
--
-- CREATE VIEW view_example AS 
--  SELECT type, COUNT(*) AS records, SUM(balance)
--  FROM example_of_types
--  GROUP BY type;
-- 
-- CREATE PROCEDURE FROM CLASS procedures.UpsertSymbol;
-- PARTITION PROCEDURE UpsertSymbol ON TABLE symbols COLUMN symbol PARAMETER 0;
---------------------------------------------------------------------------------

CREATE TABLE ticks (
  symbol		    VARCHAR(16) NOT NULL,
  time                      TIMESTAMP NOT NULL,
  seq                       BIGINT NOT NULL,
  exch                      VARCHAR(2) NOT NULL,
  bid                       INTEGER,
  bid_size		    INTEGER,
  ask                       INTEGER,
  ask_size 		    INTEGER
);
PARTITION TABLE ticks ON COLUMN symbol;

CREATE TABLE last_ticks (
  symbol		    VARCHAR(16) NOT NULL,
  time                      TIMESTAMP NOT NULL,
  seq                       BIGINT NOT NULL,
  exch                      VARCHAR(2) NOT NULL,
  bid                       INTEGER,
  bid_size		    INTEGER,
  ask                       INTEGER,
  ask_size 		    INTEGER
);
PARTITION TABLE last_ticks ON COLUMN symbol;
CREATE INDEX idx_last_ticks_bid ON last_ticks (symbol,bid,seq);
CREATE INDEX idx_last_ticks_ask ON last_ticks (symbol,ask,seq);

CREATE TABLE nbbos (
  symbol                    VARCHAR(16) NOT NULL,
  time			    TIMESTAMP NOT NULL,
  seq			    BIGINT,
  bid                       INTEGER,
  bsize			    INTEGER,
  bid_exch                  VARCHAR(2),
  ask			    INTEGER,
  asize			    INTEGER,
  ask_exch		    VARCHAR(2)
);
PARTITION TABLE nbbos ON COLUMN symbol;

CREATE PROCEDURE FROM CLASS procedures.ProcessTick;
PARTITION PROCEDURE ProcessTick ON TABLE ticks COLUMN symbol PARAMETER 0;

CREATE PROCEDURE nbbo_symbol AS
SELECT * FROM nbbos WHERE symbol = ? ORDER BY time desc LIMIT 1;
PARTITION PROCEDURE nbbo_symbol ON TABLE nbbos COLUMN symbol PARAMETER 0;

CREATE PROCEDURE last_ticks_symbol AS
SELECT * FROM last_ticks WHERE symbol = ? ORDER BY time desc;
PARTITION PROCEDURE last_ticks_symbol ON TABLE last_ticks COLUMN symbol PARAMETER 0;

