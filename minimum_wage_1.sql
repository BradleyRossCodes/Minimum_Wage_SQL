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