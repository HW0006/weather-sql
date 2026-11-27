-- Weather SQL: 10 questions, 10 queries
-- Run all:  sqlite3 weather.db < queries.sql
-- Or open:  sqlite3 weather.db   then paste one query at a time.

.headers on
.mode column

-- 1. Did the data load? How many days per city?
SELECT c.name AS city, COUNT(*) AS days, MIN(w.date) AS first_day, MAX(w.date) AS last_day
FROM daily_weather w
JOIN cities c ON c.city_id = w.city_id
GROUP BY c.name
ORDER BY c.name;

-- 2. Which city needed an umbrella most often?
SELECT city, SUM(umbrella) AS umbrella_days
FROM daily_advice
GROUP BY city
ORDER BY umbrella_days DESC;

-- 3. Average high and low per city.
SELECT city,
       ROUND(AVG(temp_max_c), 1) AS avg_high_c,
       ROUND(AVG(temp_min_c), 1) AS avg_low_c
FROM daily_weather w
JOIN (SELECT city_id, name AS city FROM cities) c USING (city_id)
GROUP BY city
ORDER BY avg_high_c DESC;

-- 4. Each city's hottest day (window function: ROW_NUMBER).
SELECT city, date, temp_max_c
FROM (
    SELECT city, date, temp_max_c,
           ROW_NUMBER() OVER (PARTITION BY city ORDER BY temp_max_c DESC) AS rn
    FROM daily_advice
)
WHERE rn = 1
ORDER BY temp_max_c DESC;

-- 5. What share of days needed long sleeves (high below 25 °C)?
SELECT city,
       ROUND(100.0 * SUM(long_sleeves) / COUNT(*), 0) AS pct_long_sleeve_days
FROM daily_advice
GROUP BY city
ORDER BY pct_long_sleeve_days DESC;

-- 6. Snow days and total snowfall (only cities that had snow).
SELECT city, SUM(snow_alert) AS snow_days, ROUND(SUM(snowfall_cm), 1) AS total_snow_cm
FROM daily_advice
GROUP BY city
HAVING SUM(snow_alert) > 0
ORDER BY total_snow_cm DESC;

-- 7. Total rain per city per month.
SELECT city, strftime('%Y-%m', date) AS month, ROUND(SUM(precip_mm), 1) AS rain_mm
FROM daily_advice
GROUP BY city, month
ORDER BY city, month;

-- 8. Biggest day-to-day jump in high temperature (window function: LAG).
WITH swings AS (
    SELECT city, date, temp_max_c,
           temp_max_c - LAG(temp_max_c) OVER (PARTITION BY city ORDER BY date) AS change_c
    FROM daily_advice
)
SELECT city, date, temp_max_c, ROUND(change_c, 1) AS change_from_yesterday_c
FROM swings
WHERE change_c IS NOT NULL
ORDER BY ABS(change_c) DESC
LIMIT 5;

-- 9. Rank cities by rainfall within each month (window function: RANK).
WITH monthly AS (
    SELECT city, strftime('%Y-%m', date) AS month, SUM(precip_mm) AS rain_mm
    FROM daily_advice
    GROUP BY city, month
)
SELECT month, city, ROUND(rain_mm, 1) AS rain_mm,
       RANK() OVER (PARTITION BY month ORDER BY rain_mm DESC) AS wettest_rank
FROM monthly
ORDER BY month, wettest_rank;

-- 10. On how many days was it raining in at least half the cities? (CTE + subquery)
WITH per_day AS (
    SELECT date, SUM(umbrella) AS cities_with_rain, COUNT(*) AS cities
    FROM daily_advice
    GROUP BY date
)
SELECT COUNT(*) AS widespread_rain_days
FROM per_day
WHERE cities_with_rain * 2 >= cities;
