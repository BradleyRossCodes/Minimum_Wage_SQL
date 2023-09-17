USE minimum_wage;

-- Creates initial tables (including Washington D.C. and U.S Territories).
CREATE TABLE IF NOT EXISTS state_minimum_wage (
    year_date YEAR,
    state VARCHAR(30),
    state_min DECIMAL(5,2),
    PRIMARY KEY (year_date, state)
);

-- Create and remove duplicate rows from original tables.
CREATE TABLE IF NOT EXISTS cpi (
    year_date YEAR,
    cpi_average DECIMAL(7,2)
);
    
CREATE TABLE IF NOT EXISTS fed_minimum_wage(
	year_date YEAR,
    fed_min DECIMAL(5,2),
    fed_min_2020_adjust DECIMAL(5,2)
    );
   
-- ***Import using 'Data Table Import Wizard'*** 

-- Add a unique identifier to append only non-duplicate rows to the final table.
ALTER TABLE fed_minimum_wage
ADD COLUMN id_num INTEGER PRIMARY KEY AUTO_INCREMENT;

CREATE TABLE IF NOT EXISTS temp_fed_minimum_wage AS
SELECT MIN(id_num) AS id_num, 
	year_date, 
	fed_min
FROM fed_minimum_wage
GROUP BY year_date, fed_min, fed_min_2020_adjust;

CREATE TABLE IF NOT EXISTS federal_minimum_wage (
    year_date YEAR PRIMARY KEY,
    fed_min DECIMAL(5,2)
);

INSERT INTO federal_minimum_wage (year_date, fed_min)
SELECT year_date, 
	fed_min
FROM temp_fed_minimum_wage;

ALTER TABLE cpi 
ADD COLUMN id_num INTEGER PRIMARY KEY AUTO_INCREMENT;

CREATE TABLE IF NOT EXISTS temp_cpi AS
SELECT MIN(id_num) AS id_num, 
	year_date, 
    cpi_average
FROM cpi
GROUP BY year_date, cpi_average;

CREATE TABLE IF NOT EXISTS consumer_price_index (
    year_date YEAR PRIMARY KEY,
    cpi_average DECIMAL(5,2)
);

INSERT INTO consumer_price_index (year_date, cpi_average)
SELECT year_date, cpi_average
FROM temp_cpi;

-- Drop original and temporary tables as they are no longer needed.
DROP TABLE temp_fed_minimum_wage;
DROP TABLE fed_minimum_wage;
DROP TABLE temp_cpi;
DROP TABLE cpi;

--  Consumer price index(CPI) represents the value of a dollar based on current prices of goods and services.

-- Add a column to the federal_minimum_wage table for 2020 equivalents.
ALTER TABLE federal_minimum_wage
ADD fed_min_2020_adjust DECIMAL(5,2);

UPDATE federal_minimum_wage AS fmw
JOIN consumer_price_index
    ON fmw.year_date = consumer_price_index.year_date
SET fmw.fed_min_2020_adjust = fmw.fed_min * (
    (SELECT cpi_average
     FROM consumer_price_index
     WHERE year_date = (SELECT MAX(year_date) FROM consumer_price_index))
     / consumer_price_index.cpi_average);
    
-- Add 2020 equivalents column to state_minimum_wage table.
ALTER TABLE state_minimum_wage
ADD state_min_2020_adjust DECIMAL(5,2);

UPDATE state_minimum_wage AS smw
JOIN consumer_price_index
    ON smw.year_date = consumer_price_index.year_date
SET smw.state_min_2020_adjust = smw.state_min * (
    (SELECT cpi_average
     FROM consumer_price_index
     WHERE year_date = (SELECT MAX(year_date) FROM consumer_price_index))
     / consumer_price_index.cpi_average);
     
-- Count states each year with no state-specific minimum wage (relying on federal law).
SELECT COUNT(DISTINCT state), year_date
FROM state_minimum_wage
WHERE state_min = 0
GROUP BY year_date;
-- In 1968, 15 states relied on federal minimum wage, decreasing to 5 by 2014.

-- Retrieve states in 2020 relying on federal minimum wage law (no state-specific minimum wage).
SELECT state
FROM state_minimum_wage
WHERE state_min = 0 AND year_date = 2020;
-- Alabama and 4 other states rely on federal minimum wage.

-- Get states with the highest state-set minimum wage.
SELECT year_date,
	state,
    state_min
FROM state_minimum_wage
ORDER BY state_min DESC
;
-- In 2020, the District of Columbia and Washington State had the highest minimum wages, $14.00 and $13.50 respectively.

-- Get top ten states with the highest cumulative minimum wage since 1968.
SELECT state, 
	SUM(state_min) AS total_state_min
FROM state_minimum_wage
GROUP BY state
ORDER BY total_state_min DESC
LIMIT 10;
-- In 2020, the District of Columbia has the highest minimum wage, but historically, Alaska held this distinction.

-- Get years of federal minimum wage law changes starting in 1968.
SELECT MIN(year_date) AS year,
	fed_min
FROM federal_minimum_wage
GROUP BY fed_min
ORDER BY MIN(year_date) ASC;
-- Federal minimum wage remained unchanged for 10 years and increased three times from 2008 to 2010, corresponding with the Great Recession of 2008.

-- Get the cumulative difference between state minimum wage and federal minimum wage.
SELECT s.state, 
	(SUM(s.state_min) - SUM(f.fed_min)) as  total_difference
FROM state_minimum_wage s
JOIN federal_minimum_wage f
	ON s.year_date = f.year_date
GROUP BY s.state WITH ROLLUP
ORDER BY total_difference ASC;

/*
Excluding the first 5 states, all set at $230.85 (the sum of federal minimum wage since 1968),
Puerto Rico's cumulative state minimum wage has been $126.90 lower than the federal minimum wage law since 1968.
*/

-- To understand the combined impact of federal and state minimum wage laws, we'll create and explore the legal_minimum_wage table.

-- Creates table to identify the legal minimum wage based on state and federal law. (Increased row limit: 3000+)
CREATE TABLE IF NOT EXISTS legal_minimum_wage AS
SELECT 
    smw.year_date, 
    smw.state, 
    MAX(
        CASE WHEN smw.state_min > fmw.fed_min THEN smw.state_min ELSE fmw.fed_min END
    ) AS fed_state_min,
    MAX(
        CASE WHEN smw.state_min_2020_adjust > fmw.fed_min_2020_adjust THEN smw.state_min_2020_adjust ELSE fmw.fed_min_2020_adjust END
    ) AS fed_state_min_2020_adjust
FROM state_minimum_wage smw
JOIN federal_minimum_wage fmw 
    ON smw.year_date = fmw.year_date
GROUP BY smw.year_date, smw.state;
SELECT *
FROM legal_minimum_wage;


-- Count states with minimum wage equal to federal minimum wage from 1968 to 2020.
SELECT year_date, COUNT(DISTINCT state) AS state_count
FROM legal_minimum_wage
WHERE (year_date, fed_state_min) IN (
    SELECT year_date, MIN(fed_state_min) AS min_fed_state_min
    FROM legal_minimum_wage
    GROUP BY year_date
)
GROUP BY year_date
ORDER BY year_date DESC;
/* 
While exploring state data, we found that only 5 states relied on federal law. 
However, most states had minimum wages below the federal minimum wage for the majority of the 1980s, totaling 52 states (including U.S. Territories). 

Since 2000, the number of states with minimum wages below the federal minimum has steadily decreased, with nearly half of them now exceeding the federal minimum.
*/

-- Get years when the legal minimum wage exceeded the federal minimum.
SELECT fmw.year_date, SUM((lmw.fed_state_min - fmw.fed_min)) AS fed_legal_dif
FROM federal_minimum_wage fmw
JOIN legal_minimum_wage lmw
	ON lmw.year_date = fmw.year_date
GROUP BY fmw.year_date
ORDER BY year_date DESC
;
/* State minimum wage laws have significantly increased in recent years. 
The difference between state and federal requirements has tripled from 2015 to 2020 compared to federal minimum wage laws alone. */

-- Previous analysis focused on dollar amounts and did not account for the changing value of a U.S. dollar due to factors like inflation.

-- Get top 10 years where the legal minimum wage exceeded the federal minimum based on 2020 money equivalents.
SELECT fmw.year_date, SUM((lmw.fed_state_min_2020_adjust - fmw.fed_min_2020_adjust)) AS fed_legal_dif
FROM federal_minimum_wage fmw
JOIN legal_minimum_wage lmw
	ON lmw.year_date = fmw.year_date
GROUP BY fmw.year_date
ORDER BY fed_legal_dif DESC
LIMIT 10
;
-- The top ten years generally more recent with 1968 and 1969 also included.

-- Identify top state contributors in 1968 and 1969.
SELECT fmw.year_date, 
	lmw.state, 
    fed_state_min_2020_adjust AS legal_min_wage_2020_value, 
    fmw.fed_min_2020_adjust AS fed_min_wage_2020_value, 
    (lmw.fed_state_min_2020_adjust - fmw.fed_min_2020_adjust) AS fed_legal_dif
FROM federal_minimum_wage fmw
JOIN legal_minimum_wage lmw
	ON lmw.year_date = fmw.year_date
WHERE fmw.year_date = 1968 
	OR fmw.year_date = 1969
ORDER BY fed_legal_dif DESC
Limit 10;
/* Alaska and California were significant contributors to setting a minimum wage much higher than the federal requirement in 1968 and 1969. 
In fact, federal minimum wages from 1968 - 2020 never exceeded those of the ten states returned in this query. */