USE minimum_wage;

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