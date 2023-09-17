USE minimum_wage;

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