# Open Fishing SQLite database

Start the app with `Start-Open-Fishing.bat`. The local server opens the app in your browser and creates `open-fishing.sqlite3` in this folder the first time it runs. Keep the server window open while using the app; press Ctrl+C in that window to stop it.

The local database stores your profile, catches and photos, fishing events, event participation, and selected fishing destination. Browser data saved while using this same local app address is copied into SQLite the first time it connects. Data from an earlier `file://` session is isolated by the browser and is not automatically transferred. No account or sign-in is needed.

This Windows setup uses the built-in SQLite library. The database is available only on this PC. Opening `index.html` directly does not connect to SQLite; use the batch file to start the app.
