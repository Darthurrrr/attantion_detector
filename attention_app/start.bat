@echo off
cd /d %~dp0
start "Сервер" cmd /k uvicorn backend:app
timeout /t 3 >nul
flet run frontend.py
