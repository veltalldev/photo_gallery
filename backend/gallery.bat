@echo off
PUSHD "%~dp0"
setlocal

call venv\Scripts\activate.bat

echo Starting backend server for local Photo Gallery..
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

endlocal
exit /b