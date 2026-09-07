@echo off
echo ===================================================
echo   ISRO Study Companion - PC & Phone Launcher
echo ===================================================
echo [PC Address]    : http://localhost:8080
echo [Phone Address] : http://192.168.0.107:8080
echo.
echo Opening on your PC...
start "" "http://localhost:8080"
echo.
echo Open Chrome on your phone and type: http://192.168.0.107:8080
echo (Make sure your phone is connected to the same Wi-Fi)
echo ===================================================
python -m http.server 8080 --bind 0.0.0.0 --directory "build\web"
pause
