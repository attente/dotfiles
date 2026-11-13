#!/usr/bin/env python3
"""Cached IP-based weather advice for the bar and lock screen."""
import datetime as dt
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from zoneinfo import ZoneInfo

CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "weather-advice.json"
TTL = 30 * 60
REQUEST_TIMEOUT = 8
FORECAST_DAYS = 3
FORECAST_START_HOUR = 10
FORECAST_END_HOUR = 22
JACKET_BELOW_C = 14
SWEATER_BELOW_C = 20
UMBRELLA_PROBABILITY_PERCENT = 20
UMBRELLA_PRECIPITATION_MM = 1.0
SUNSCREEN_UV_INDEX = 3
# A heat-risk proxy, not an official weather alert.
HEAT_RISK_FEELS_LIKE_C = 36
ROOM_TEMPERATURE_C = 22
GEOLOCATION_URL = "https://ipwho.is/"
FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
WEATHER_SITE_URL = "https://www.windy.com"
USER_AGENT = "weather-advice/1.0"

def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT) as response:
        return json.load(response)


def refresh():
    location = fetch(GEOLOCATION_URL)
    if not location.get("success"):
        raise ValueError("IP geolocation failed")
    lat = float(location["latitude"])
    lon = float(location["longitude"])
    params = urllib.parse.urlencode({
        "latitude": lat,
        "longitude": lon,
        "timezone": "auto",
        "forecast_days": FORECAST_DAYS,
        "hourly": "temperature_2m,apparent_temperature,precipitation_probability,precipitation,uv_index,weather_code",
    })
    data = {
        "lat": lat,
        "lon": lon,
        "city": location.get("city", ""),
        "forecast": fetch(FORECAST_URL + "?" + params),
    }
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=CACHE.parent, delete=False) as f:
        json.dump(data, f)
        tmp = f.name
    os.replace(tmp, CACHE)
    return data


def load():
    try:
        cached = json.loads(CACHE.read_text())
    except (OSError, ValueError):
        cached = None
    try:
        stale = (cached is None or time.time() - CACHE.stat().st_mtime >= TTL
                 or "weather_code" not in cached["forecast"]["hourly"])
        if stale:
            return refresh(), False
        return cached, False
    except (OSError, ValueError, KeyError):
        return cached, cached is not None


def advice(data, stale):
    forecast = data["forecast"]
    now = dt.datetime.now(ZoneInfo(forecast["timezone"]))
    tomorrow = now.hour >= FORECAST_END_HOUR
    target = now.date() + dt.timedelta(days=int(tomorrow))
    start = dt.datetime.combine(target, dt.time(FORECAST_START_HOUR))
    end = dt.datetime.combine(target, dt.time(FORECAST_END_HOUR))
    if not tomorrow:
        start = max(start, now.replace(tzinfo=None))
    hourly = forecast["hourly"]
    timestamps = [dt.datetime.fromisoformat(value) for value in hourly["time"]]
    current_hour = start.replace(minute=0, second=0, microsecond=0)

    def values(key, preceding_hour=False):
        # Precipitation covers the preceding hour; include overlapping intervals.
        def in_window(timestamp):
            if preceding_hour:
                return start < timestamp <= end
            return current_hour <= timestamp < end

        return [
            value for timestamp, value in zip(timestamps, hourly[key])
            if value is not None and in_window(timestamp)
        ]

    temperatures = values("temperature_2m")
    apparent = values("apparent_temperature")
    codes = values("weather_code")
    if not temperatures or not apparent or not codes:
        raise ValueError("Incomplete forecast for target period")

    low = min(temperatures)
    feels_low = min(apparent)
    feels_high = max(apparent)
    use_high = feels_low > ROOM_TEMPERATURE_C
    displayed_feels = feels_high if use_high else feels_low
    rain_chance = max(values("precipitation_probability", preceding_hour=True), default=0)
    rain_amount = max(values("precipitation", preceding_hour=True), default=0)
    rain = (rain_chance >= UMBRELLA_PROBABILITY_PERCENT
            or rain_amount >= UMBRELLA_PRECIPITATION_MM
            or any(code in range(51, 68) or code in range(80, 83) or code >= 95
                   for code in codes))
    sunscreen = max(values("uv_index"), default=0) >= SUNSCREEN_UV_INDEX
    heat = feels_high >= HEAT_RISK_FEELS_LIKE_C

    # Select the most disruptive forecast condition, not the most common one.
    if any(code >= 95 for code in codes):
        icon, condition = "storm", "thunderstorms"
    elif any(code in range(71, 78) or code in (85, 86) for code in codes):
        icon, condition = "snow", "snow"
    elif rain:
        icon, condition = "showers", "rain possible"
    elif any(code in (45, 48) for code in codes):
        icon, condition = "fog", "fog"
    elif 3 in codes:
        icon, condition = "overcast", "overcast"
    elif any(code in (1, 2) for code in codes):
        icon, condition = "few-clouds", "partly cloudy"
    else:
        icon, condition = "clear", "clear"

    if rain:
        color = "rain"
    elif feels_low < JACKET_BELOW_C:
        color = "jacket"
    elif feels_low < SWEATER_BELOW_C:
        color = "sweater"
    elif heat:
        color = "heat"
    elif sunscreen:
        color = "sun"
    else:
        color = "normal"

    day = "Tomorrow" if tomorrow else "Today"
    degree = chr(176)
    feels_label = "high" if use_high else "low"
    text = f"{day}: {condition}, low {low:.0f} {degree}C, feels like {feels_label} {displayed_feels:.0f} {degree}C"
    if heat:
        text += "; heat risk (not an official alert)"
    if stale:
        text += " [stale]"
    return {
        "text": text,
        "temperature": f"{displayed_feels:.0f} {degree}C",
        "icon": f"weather-{icon}-symbolic",
        "color": color,
        "tooltip": text,
        "url": f"{WEATHER_SITE_URL}/{data['lat']}/{data['lon']}?{data['lat']},{data['lon']},10",
    }


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "json"
    try:
        if mode == "open":
            data = json.loads(CACHE.read_text())
            stale = False
        else:
            data, stale = load()
        result = advice(data, stale)
    except (OSError, ValueError, KeyError, TypeError, IndexError) as error:
        if mode == "open":
            print(f"Cannot open forecast: {error}", file=sys.stderr)
        result = {
            "text": "Weather unavailable",
            "temperature": "?",
            "icon": "weather-severe-alert-symbolic",
            "color": "normal",
            "tooltip": "Forecast or IP location unavailable",
            "url": "",
        }

    if mode == "open":
        if result["url"]:
            subprocess.Popen(
                ["xdg-open", result["url"]],
                stdin=subprocess.DEVNULL,
                start_new_session=True,
            )
    elif mode == "text":
        print(result["text"])
    else:
        print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
