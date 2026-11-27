# Weather SQL

A small SQL project built on my [Weather Board](https://heidi-weather-board.netlify.app/) app.
The app tells friends whether to bring an umbrella, wear long sleeves, or expect snow.
This project stores real daily weather for the same kind of cities in a SQLite database
and uses SQL to answer questions about it.

## What's inside

| File | What it does |
|---|---|
| `schema.sql` | Creates two tables (`cities`, `daily_weather`) and a view (`daily_advice`) that applies the Weather Board rules |
| `load_weather.py` | Downloads real daily weather from the free [Open-Meteo](https://open-meteo.com/) archive and loads it into `weather.db` |
| `queries.sql` | 10 questions answered in SQL |

## Run it

```bash
python3 load_weather.py          # last 90 days (use --days 365 for a year)
sqlite3 weather.db < queries.sql
```

No API key and no extra packages are needed (Python standard library only).

## Weather Board rules, in SQL

| Advice | Rule |
|---|---|
| Umbrella | 1 mm or more of precipitation |
| Long sleeves | High below 25 °C |
| Snow alert | Any snowfall |

## Questions the queries answer

1. Did every city load, and for which dates?
2. Which city needed an umbrella most often?
3. Average high and low per city
4. Each city's hottest day (`ROW_NUMBER`)
5. Share of days that needed long sleeves
6. Snow days and total snowfall (`HAVING`)
7. Total rain per city per month (`strftime`, `GROUP BY`)
8. Biggest day-to-day temperature jump (`LAG`)
9. Wettest city ranking within each month (`RANK`)
10. Days with rain in at least half the cities (CTE)

## SQL used

`JOIN` · `GROUP BY` / `HAVING` · `CASE` · views · subqueries · CTEs (`WITH`) · window functions (`ROW_NUMBER`, `RANK`, `LAG`)
