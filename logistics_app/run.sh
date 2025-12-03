#!/bin/bash
# Flutter App Run Script with Environment Variables
# This script automatically loads .env file and passes variables to flutter run
# The app connects to the backend API, which handles Supabase authentication

# Check if .env file exists, create if not
if [ ! -f .env ]; then
    echo "Creating .env file with default values..."
    cat > .env << EOF
# Flutter App Environment Variables
# For Android Emulator: use http://10.0.2.2:3000/api
# For iOS Simulator: use http://localhost:3000/api
# For Physical Device: use http://YOUR_COMPUTER_IP:3000/api
# Find your IP with: ifconfig (Mac/Linux) or ipconfig (Windows)
API_BASE_URL=http://10.0.2.2:3000/api
EOF
fi

# Load .env file
export $(grep -v '^#' .env | xargs)

# Set default if not set
if [ -z "$API_BASE_URL" ]; then
    API_BASE_URL="http://10.0.2.2:3000/api"
fi

# Run Flutter with environment variables
echo "Running Flutter app with API_BASE_URL=$API_BASE_URL"
echo "Note: The app will auto-detect platform if API_BASE_URL is not set"
flutter run --dart-define=API_BASE_URL="$API_BASE_URL"
