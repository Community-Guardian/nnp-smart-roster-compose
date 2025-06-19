@echo off
echo Converting Markdown documents to Word format...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0convert-to-word-fixed.ps1"
pause
