"""
Load real daily weather into a SQLite database.

Data source: Open-Meteo historical weather API (free, no API key).
Usage:
    python load_weather.py            # last 90 days
    python load_weather.py --days 365 # last year
"""

import argparse
import json
import sqlite3
import time
import urllib.parse
import urllib.request
from datetime import date, timedelta
from pathlib import Path

DB_PATH = Path(__file__).with_name("weather.db")
SCHEMA_PATH = Path(__file__).with_name("schema.sql")

# Edit this list to match the cities on your Weather Board.
CITIES = [
    # name,            country,       latitude, longitude
    ("San Jose",       "USA",          37.3382, -121.8863),
    ("San Francisco",  "USA",          37.7749, -122.4194),
    ("Salt Lake City", "USA",          40.7608, -111.8910),
    ("New York",       "USA",          40.7128,  -74.0060),
    ("Seattle",        "USA",          47.6062, -122.3321),
    ("Taipei",         "Taiwan",       25.0330,  121.5654),
    ("Taichung",       "Taiwan",       24.1477,  120.6736),
    ("Tokyo",          "Japan",        35.6762,  139.6503),
    ("London",         "UK",           51.5074,   -0.1278),
]

API_URL = "https://archive-api.open-meteo.com/v1/archive"
DAILY_FIELDS = "temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum"


def fetch_daily(lat, lon, start, end):
    """Ask Open-Meteo for one city's daily weather between two dates."""
    params = urllib.parse.urlencode({
        "latitude": lat,
        "longitude": lon,
        "start_date": start.isoformat(),
        "end_date": end.isoformat(),
        "daily": DAILY_FIELDS,
        "timezone": "auto",
    })
    with urllib.request.urlopen(f"{API_URL}?{params}", timeout=30) as resp:
        return json.load(resp)["daily"]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--days", type=int, default=90, help="how many days of history")
    args = parser.parse_args()

    # The archive runs a few days behind, so stop a week ago.
    end = date.today() - timedelta(days=7)
    start = end - timedelta(days=args.days - 1)

    con = sqlite3.connect(DB_PATH)
    con.executescript(SCHEMA_PATH.read_text())

    for name, country, lat, lon in CITIES:
        cur = con.execute(
            "INSERT INTO cities (name, country, latitude, longitude) VALUES (?, ?, ?, ?)",
            (name, country, lat, lon),
        )
        city_id = cur.lastrowid

        daily = fetch_daily(lat, lon, start, end)
        rows = [
            (city_id, d, tmax, tmin, rain, snow)
            for d, tmax, tmin, rain, snow in zip(
                daily["time"],
                daily["temperature_2m_max"],
                daily["temperature_2m_min"],
                daily["precipitation_sum"],
                daily["snowfall_sum"],
            )
        ]
        con.executemany(
            "INSERT INTO daily_weather VALUES (?, ?, ?, ?, ?, ?)", rows
        )
        print(f"{name:<15} {len(rows)} days")
        time.sleep(0.5)  # be polite to the free API

    con.commit()
    con.close()
    print(f"\nSaved to {DB_PATH.name} ({start} to {end})")


if __name__ == "__main__":
    main()
