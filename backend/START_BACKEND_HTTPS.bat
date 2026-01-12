@echo off
echo ========================================
echo   RUBIK MASTER BACKEND - HTTPS MODE
echo ========================================
echo.

cd /d "%~dp0"

echo [1] Checking certificates...
if not exist "certs\cert.pem" (
    echo ERROR: Certificate not found!
    echo Please run: python generate_cert.py
    pause
    exit /b 1
)

echo [2] Activating virtual environment...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo ERROR: Cannot activate virtual environment!
    pause
    exit /b 1
)

echo [3] Starting HTTPS server...
echo.
echo Server will run on: https://0.0.0.0:8000
echo API Docs: https://localhost:8000/docs
echo.
echo NOTE: Your browser will show certificate warning
echo       This is normal for self-signed certificates
echo.
echo Press Ctrl+C to stop
echo ========================================
echo.

python run_https.py

echo.
echo Server stopped.
pause
