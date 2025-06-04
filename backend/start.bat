@echo off
REM ===============================
REM   FastAPI Backend Start Script
REM ===============================

echo.
echo ===============================
echo   🚀  Starting FastAPI Backend
echo ===============================
echo   Activating Python virtual environment...
call .venv\Scripts\activate

echo.
echo   Backend is launching! Open your browser to:
echo     http://127.0.0.1:8000/docs
echo   (Press Ctrl+C in this window to stop the backend)
echo.

REM Start FastAPI server
uvicorn app.main:app --reload

echo.
echo ===============================
echo   FastAPI backend has stopped!
echo ===============================
pause
