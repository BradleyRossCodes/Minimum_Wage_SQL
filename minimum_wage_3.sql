USE minimum_wage;

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