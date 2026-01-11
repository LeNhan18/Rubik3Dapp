@echo off
echo ========================================
echo    RUBIK MASTER BACKEND SERVER
echo ========================================
echo.

cd /d "%~dp0"

echo [1] Activating virtual environment...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo ERROR: Cannot activate virtual environment!
    pause
    exit /b 1
)

echo [2] Starting server...
echo.
echo Server will run on: http://localhost:8000
echo API Docs: http://localhost:8000/docs
echo.
echo Press Ctrl+C to stop
echo ========================================
echo.

python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

echo.
echo Server stopped.
pause
