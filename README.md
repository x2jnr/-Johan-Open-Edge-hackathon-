# Open Fishing

A small fishing dashboard with an interactive globe, local weather and marine
conditions, fishing events, a catch log, and an angler profile.

## Run on Windows

1. Double-click `Start-Open-Fishing.bat`.
2. The app opens at <http://127.0.0.1:8765/>.
3. Keep the console window open while using the app. Press Ctrl+C in it to stop
   the local server.

The app uses Windows PowerShell and the Windows-provided SQLite library. No
package installation or sign-in is required.

## Data and privacy

Profile details, profile pictures, catches, events, event participation, and the
selected destination are stored in `open-fishing.sqlite3` on this computer.
That database is excluded from Git by `.gitignore`; do not publish it or add it
to a commit.

Location searches use Open-Meteo's geocoding service. Weather and marine
forecasts are requested from Open-Meteo using the selected coordinates. See
<https://open-meteo.com/> for its service terms and privacy information.

The local server binds to `127.0.0.1` and is intended for use on this computer,
not as a publicly exposed service.

## Data attribution

The globe coastline data is Natural Earth 1:50m land data, which is in the
public domain: <https://www.naturalearthdata.com/>.

No project license is included. All rights to the project code and artwork are
reserved by default; add a `LICENSE` file if you want to grant reuse rights.
