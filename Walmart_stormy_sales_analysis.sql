/*Add a table called clean_weather after post-processing weather data to handle missing data.*/
/* M represents missing value and T represents Trace. Hence replacing with NULL and 0 respectively*/
CREATE TABLE clean_weather AS
SELECT 
    date,
    station_nbr,
    CAST(
      CASE 
        WHEN preciptotal = 'M' THEN NULL
        WHEN preciptotal = 'T' THEN '0.0'
        ELSE preciptotal
      END AS FLOAT
    ) AS precip,
    CAST(
      CASE 
        WHEN snowfall = 'M' THEN NULL
        WHEN snowfall = 'T' THEN '0.0'
        ELSE snowfall
      END AS FLOAT
    ) AS snow
FROM weather;


/*Q1: Which products are most sensitive to weather changes? */

-- stormy days with more than 1 inch of rain or 2 inches of snow
WITH stormy_days AS (
    SELECT DISTINCT date, station_nbr 
    FROM clean_weather
    WHERE precip > 1.0 OR snow > 2.0
),
-- all other days are non-stormy
non_stormy_days AS (
    SELECT DISTINCT date, station_nbr
    FROM clean_weather
	WHERE (date, station_nbr) NOT IN (
        SELECT date, station_nbr FROM stormy_days
    )
),
-- extract sales data for stormy days and non-stormy days
stormy_sales AS (
    SELECT t.date, t.item_nbr, t.units
    FROM train t
    JOIN key k ON t.store_nbr = k.store_nbr
    JOIN stormy_days s ON k.station_nbr = s.station_nbr AND t.date = s.date
),
non_stormy_sales AS (
    SELECT t.date, t.item_nbr, t.units
    FROM train t
    JOIN key k ON t.store_nbr = k.store_nbr
    JOIN non_stormy_days ns ON k.station_nbr = ns.station_nbr AND t.date = ns.date
),
-- calculate daily average sales for each item on stormy days and non-stormy days
stormy_avg AS (
    SELECT item_nbr, AVG(units) AS avg_stormy
    FROM stormy_sales
    GROUP BY item_nbr
),
non_stormy_avg AS (
    SELECT item_nbr, AVG(units) AS avg_non_stormy
    FROM non_stormy_sales
    GROUP BY item_nbr
)
-- calculate percentage change in daily average sales
SELECT 
    COALESCE(s.item_nbr, n.item_nbr) AS item_nbr,
    avg_stormy,
    avg_non_stormy,
    -- Round to 2 decimal places and apply NULLIF to avoid divide by zero errors
    ROUND(
        (avg_stormy - avg_non_stormy) * 100.0 / NULLIF(avg_non_stormy, 0),
        2
    ) AS percent_change
FROM stormy_avg s
FULL OUTER JOIN non_stormy_avg n ON s.item_nbr = n.item_nbr
-- add condition that daily sales must be at least 1 unit on either stormy or non-stormy days
WHERE 
    COALESCE(avg_stormy, 0) >= 1
    OR COALESCE(avg_non_stormy, 0) >= 1
ORDER BY percent_change DESC;



/*Q2: Are there products that sell better during snow vs rain? */

-- snow days with more than 2 inches of snow
WITH snow_days AS (
    SELECT DISTINCT date, station_nbr
    FROM clean_weather
    WHERE snow > 2.0 AND precip <= 1.0
),
-- rain days with more than 1 inch of rain
rain_days AS (
    SELECT DISTINCT date, station_nbr
    FROM clean_weather
    WHERE precip > 1.0 AND snow <= 2.0
),
-- all other days
non_stormy_days AS (
    SELECT DISTINCT date, station_nbr
    FROM clean_weather
	WHERE (date, station_nbr) NOT IN (
		SELECT date, station_nbr FROM snow_days 
		UNION
		SELECT date, station_nbr FROM rain_days
		)
),
-- calculate daily average sales for each day type
sales_snow AS (
    SELECT t.date, t.item_nbr, t.units
    FROM train t JOIN key k ON t.store_nbr = k.store_nbr
    JOIN snow_days s ON t.date = s.date AND k.station_nbr = s.station_nbr
),
sales_rain AS (
    SELECT t.date, t.item_nbr, t.units
    FROM train t JOIN key k ON t.store_nbr = k.store_nbr
    JOIN rain_days r ON t.date = r.date AND k.station_nbr = r.station_nbr
),
sales_nonstormy AS (
    SELECT t.date, t.item_nbr, t.units
    FROM train t JOIN key k ON t.store_nbr = k.store_nbr
    JOIN non_stormy_days ns ON t.date = ns.date AND k.station_nbr = ns.station_nbr
),
avg_snow AS (
    SELECT item_nbr, AVG(units) AS avg_snow FROM sales_snow GROUP BY item_nbr
),
avg_rain AS (
    SELECT item_nbr, AVG(units) AS avg_rain FROM sales_rain GROUP BY item_nbr
),
avg_nonstormy AS (
    SELECT item_nbr, AVG(units) AS avg_nonstormy FROM sales_nonstormy GROUP BY item_nbr
)
-- calculate % change in sales compared to non-stormy days for both snowy and rainy days
SELECT 
    COALESCE(ns.item_nbr, rn.item_nbr, nn.item_nbr) AS item_nbr,
    avg_snow, avg_rain, avg_nonstormy,
    ROUND((avg_snow - avg_nonstormy) * 100.0 / NULLIF(avg_nonstormy, 0), 2) AS pct_change_snow,
    ROUND((avg_rain - avg_nonstormy) * 100.0 / NULLIF(avg_nonstormy, 0), 2) AS pct_change_rain
FROM avg_snow ns
FULL OUTER JOIN avg_rain rn ON ns.item_nbr = rn.item_nbr
FULL OUTER JOIN avg_nonstormy nn ON COALESCE(ns.item_nbr, rn.item_nbr) = nn.item_nbr
-- ensure at least 1 unit sold on either snowy/rainy/non-stormy days
WHERE COALESCE(avg_snow, 0) >= 1 OR COALESCE(avg_rain, 0) >= 1 OR COALESCE(avg_nonstormy, 0) >= 1
ORDER BY pct_change_snow DESC, pct_change_rain DESC;


/*Q3: Which items see panic buying before stormy days? */

-- stormy days with more than 1 inch of rain or 2 inches of snow
WITH stormy_days AS (
    SELECT DISTINCT date, station_nbr FROM clean_weather
    WHERE precip > 1.0 OR snow > 2.0
),
-- panic days : 1 day before a stormy day
panic_days AS (
    SELECT DATE(date, '-1 day') AS date, station_nbr FROM stormy_days
),
-- non-stormy days : all other days
non_stormy_days AS (
    SELECT DISTINCT date, station_nbr
    FROM clean_weather
	WHERE (date, station_nbr) NOT IN (
		SELECT date, station_nbr FROM stormy_days 
		UNION
		SELECT date, station_nbr FROM panic_days
		)
),
-- calculating daily average sales for each item for each type of day
sales_panic AS (
    SELECT t.date, t.item_nbr, t.units
    FROM train t
    JOIN key k ON t.store_nbr = k.store_nbr
    JOIN panic_days p ON t.date = p.date AND k.station_nbr = p.station_nbr
),
sales_nonstormy AS (
    SELECT t.date, t.item_nbr, t.units
    FROM train t
    JOIN key k ON t.store_nbr = k.store_nbr
    JOIN non_stormy_days n on t.date = n.date AND k.station_nbr = n.station_nbr
),
avg_panic AS (
    SELECT item_nbr, AVG(units) AS avg_panic FROM sales_panic GROUP BY item_nbr
),
avg_nonstormy AS (
    SELECT item_nbr, AVG(units) AS avg_nonstormy FROM sales_nonstormy GROUP BY item_nbr
) 
SELECT 
    p.item_nbr,
    avg_panic,
    avg_nonstormy,
    -- Round to 2 decimal places and apply NULLIF to avoid divide by zero errors
    ROUND((avg_panic - avg_nonstormy) * 100.0 / NULLIF(avg_nonstormy, 0), 2) AS percent_change
FROM avg_panic p
JOIN avg_nonstormy n ON p.item_nbr = n.item_nbr
-- ensure at least 1 unit sold on either snowy/rainy/non-stormy days
WHERE avg_panic >= 1 OR avg_nonstormy >= 1
ORDER BY percent_change DESC;


/*Q4: Which stores are most affected by stormy weather, and which are most resilient? */

-- stormy days with more than 1 inch of rain or 2 inches of snow
WITH stormy_days AS (
    SELECT DISTINCT date, station_nbr 
    FROM clean_weather
    WHERE precip > 1.0 OR snow > 2.0
),
-- all other days are non-stormy
non_stormy_days AS (
    SELECT DISTINCT date, station_nbr
    FROM clean_weather
	WHERE (date, station_nbr) NOT IN (
        SELECT date, station_nbr FROM stormy_days
    )
),
-- extract daily sales for each store on stormy and non-stormy days
stormy_daily_sales AS (
    SELECT t.date, t.store_nbr, SUM(t.units) AS daily_units
    FROM train t
    JOIN key k ON t.store_nbr = k.store_nbr
    JOIN stormy_days s ON t.date = s.date AND k.station_nbr = s.station_nbr
    GROUP BY t.date, t.store_nbr
),
nonstormy_daily_sales AS (
    SELECT t.date, t.store_nbr, SUM(t.units) AS daily_units
    FROM train t
    JOIN key k ON t.store_nbr = k.store_nbr
    JOIN non_stormy_days n ON t.date = n.date AND k.station_nbr = n.station_nbr
    GROUP BY t.date, t.store_nbr
),
-- calculate daily average sales for each store on stormy vs non-stormy days
avg_stormy AS (
    SELECT store_nbr, AVG(daily_units) AS avg_stormy
    FROM stormy_daily_sales
    GROUP BY store_nbr
),
avg_nonstormy AS (
    SELECT store_nbr, AVG(daily_units) AS avg_nonstormy
    FROM nonstormy_daily_sales
    GROUP BY store_nbr
)
-- calculate percentage change in sales for each store on stormy vs non-stormy days
SELECT 
    a.store_nbr,
    avg_stormy,
    avg_nonstormy,
    ROUND((avg_stormy - avg_nonstormy) * 100.0 / NULLIF(avg_nonstormy, 0), 2) AS percent_change
FROM avg_stormy a
JOIN avg_nonstormy b ON a.store_nbr = b.store_nbr
ORDER BY percent_change;
