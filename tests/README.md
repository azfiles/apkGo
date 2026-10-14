# Device smoke test

Use a dedicated emulator: this test clears only the Schulte Flow app's local data. It installs both signed APKs, injects touches into the app, verifies all three board sizes, pause and restoration, and stores screenshots in the app's external files directory. The shell script requires the explicit PASS marker; an instrumentation process exit alone is not sufficient.
