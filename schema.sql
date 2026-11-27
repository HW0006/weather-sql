-- Weather SQL: schema
-- Two tables: one row per city, and one row per city per day.

DROP VIEW  IF EXISTS daily_advice;
DROP TABLE IF EXISTS daily_weather;
DROP TABLE IF EXISTS cities;

CREATE TABLE cities (
    city_id    INTEGER PRIMARY KEY,
    name       TEXT    NOT NULL UNIQUE,
    country    TEXT    NOT NULL,
    latitude   REAL    NOT NULL,
    longitude  REAL    NOT NULL
);

CREATE TABLE daily_weather (
    city_id      INTEGER NOT NULL REFERENCES cities(city_id),
    date         TEXT    NOT NULL,          -- 'YYYY-MM-DD'
    temp_max_c   REAL,
    temp_min_c   REAL,
    precip_mm    REAL,                      -- rain + snow, as water
    snowfall_cm  REAL,
    PRIMARY KEY (city_id, date)             -- one row per city per day
);

-- Same rules as the Weather Board app:
--   umbrella      -> 1 mm or more of precipitation
--   long sleeves  -> high below 25 °C
--   snow alert    -> any snowfall
CREATE VIEW daily_advice AS
SELECT
    c.name                                   AS city,
    w.date,
    w.temp_max_c,
    w.precip_mm,
    w.snowfall_cm,
    CASE WHEN w.precip_mm   >= 1  THEN 1 ELSE 0 END AS umbrella,
    CASE WHEN w.temp_max_c  <  25 THEN 1 ELSE 0 END AS long_sleeves,
    CASE WHEN w.snowfall_cm >  0  THEN 1 ELSE 0 END AS snow_alert
FROM daily_weather w
JOIN cities c ON c.city_id = w.city_id;
