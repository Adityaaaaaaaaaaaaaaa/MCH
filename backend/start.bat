@echo off
REM ===================================================
REM   FastAPI Backend Start Script
REM ===================================================

echo.
echo ==================================================
echo   🚀  Starting FastAPI Backend
echo ==================================================
echo   Activating Python virtual environment...
call .venv\Scripts\activate

echo.
echo   Backend is launching! Open your browser to:
echo     http://<your-PC-IP>:8000/docs
echo   (From another device, replace <your-PC-IP> with your actual PC IP.)
echo   (Press Ctrl+C in this window to stop the backend)
echo.

REM Start FastAPI server on all network interfaces
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

echo.
echo ==================================================
echo   FastAPI backend has stopped!
echo ==================================================
pause
