@echo off
rem Starts SmartStay without Maven or an IDE.
rem Needs: Java 17+ on PATH, and the MySQL database created from database\schema.sql + database\sample-data.sql.
rem Database settings are inside the jar (src/main/resources/config/db.properties); rebuild with "mvn package" after changing them.
cd /d "%~dp0"
java --module-path "dist\lib\javafx" --add-modules javafx.controls,javafx.fxml -cp "dist\smartstay-hotel-booking-1.0.0.jar;dist\lib\*" com.smartstay.Launcher
if errorlevel 1 pause
