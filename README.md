# Open Fishing

> An interactive fishing dashboard for exploring destinations and checking local weather and marine conditions.

**Team:** Solo  
**Members:** Johan  
**Demo video:** [Add a link to your demo]

---

## 1. The problem

Planning a fishing trip means checking a destination, its weather, and marine
conditions in different places. Open Fishing brings location search, a globe,
and available conditions together in one dashboard, with a local catch log and
fishing event tools for anglers.

## 2. What we built

The app includes:

- An interactive globe and destination search.
- Current weather, wind, wave, sea-temperature, and daylight information when
  available. Tide predictions and local fish reports are not provided.
- A fishing event list, catch log, and angler profile.
- Local storage for profile details, catches, events, participation, and the
  selected destination.

## 3. How it works

- **OpenEdge components used:** None in this app. Although it is located inside
  a Progress OpenEdge installation folder, this app does not use OpenEdge or ABL.
- **AI components used:** None.
- **Architecture overview:** The browser runs the HTML, CSS, and JavaScript UI.
  A small Windows PowerShell server serves the app and reads/writes its local
  SQLite database. The browser requests location search, weather, and marine
  forecasts from Open-Meteo.

```text
Browser app ──local HTTP──> PowerShell server ──> SQLite file on this PC
     │
     └──HTTPS──> Open-Meteo geocoding, weather, and marine APIs
```

## 4. How to run it

### Requirements

- **OpenEdge version:** Not required; this standalone app does not use OpenEdge.
- **Other tools:** Windows PowerShell and the Windows-provided SQLite library
  (`winsqlite3.dll`). No package installation, account, or API key is required.
- An internet connection is needed for Open-Meteo location search and forecast
  data.

### Setup

1. Clone the repository:

   ```powershell
   git clone <your-repo-url>
   cd <cloned-folder>
   ```

2. Install dependencies / configure the environment:

   No dependencies or environment configuration are required.

3. Add any required configuration or API keys:

   No API keys or secrets are required. Do not add personal app data or local
   database files to the repository; they are excluded by `.gitignore`.

4. Start the project from PowerShell:

   ```powershell
   .\Start-Open-Fishing.bat
   ```

   The batch file starts the local server and opens
   <http://127.0.0.1:8765/> in your browser. Keep the console window open while
   using the app; press Ctrl+C in that window to stop the server.

### Quick test

Open the app, search for a city (for example, `Cape Town`), and choose a result.
The selected destination and available weather and marine conditions should
update. The profile, events, and catch-log sections can also be opened from the
navigation.

> The app is designed to run locally on Windows. The server listens on
> `127.0.0.1` and is not intended to be exposed as a public web service.

## 5. Demo

**Demo video:** [Add a link to your 2–3 minute demo]

## 6. Challenges and learnings

This section should describe the team's actual development experience. Possible
topics to cover include keeping user data on the local machine, handling
unavailable marine data, and connecting a browser interface to a local SQLite
database.

## 7. What's next (optional)

- Add a demo video and screenshots of the running app.
- Consider optional tide and local fish-report integrations.
- Add automated tests and document supported Windows versions.

## Data, privacy, and attribution

Profile details, profile pictures, catches, events, event participation, and the
selected destination are stored in `open-fishing.sqlite3` on this computer.
Location searches send the search query to Open-Meteo's geocoding service.
Weather and marine forecast requests send the selected coordinates to
Open-Meteo. See <https://open-meteo.com/> for its service terms and privacy
information.

The globe uses Natural Earth 1:50m land data, which is in the public domain:
<https://www.naturalearthdata.com/>.

No project license is included. All rights to the project code and artwork are
reserved by default; 
