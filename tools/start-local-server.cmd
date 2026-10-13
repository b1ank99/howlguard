@echo off
cd /d "%~dp0"
set PORT=9080
set BIND_ADDRESS=127.0.0.1
echo Starting Howlguard development server. Close this window to stop.
Howlguard.console.exe --headless -- --server
