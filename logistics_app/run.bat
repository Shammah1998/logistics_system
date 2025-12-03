@echo off
REM Flutter App Run Script with Environment Variables
REM This script automatically loads .env file and passes variables to flutter run
REM The app connects to the backend API, which handles Supabase authentication

REM Check if .env file exists, create if not
if not exist .env (
    echo Creating .env file with default values...
    (
        echo # Flutter App Environment Variables
        echo # For Android Emulator: use http://10.0.2.2:3000/api
        echo # For iOS Simulator: use http://localhost:3000/api
        echo # For Physical Device: use http://YOUR_COMPUTER_IP:3000/api
        echo # Find your IP with: ipconfig
        echo API_BASE_URL=http://10.0.2.2:3000/api
    ) > .env
)

REM Read API_BASE_URL from .env file
set API_BASE_URL=http://10.0.2.2:3000/api
for /f "tokens=2 delims==" %%a in ('findstr /b /c:"API_BASE_URL=" .env') do set API_BASE_URL=%%a

REM Remove any quotes from the value
set API_BASE_URL=%API_BASE_URL:"=%

REM Run Flutter with environment variables
echo Running Flutter app with API_BASE_URL=%API_BASE_URL%
echo Note: The app will auto-detect platform if API_BASE_URL is not set
flutter run --dart-define=API_BASE_URL=%API_BASE_URL%
