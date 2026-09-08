@echo off
echo Rebuilding Git index...
if exist .git\index del /f /q .git\index
git reset
git status
echo Git index successfully restored!
pause
