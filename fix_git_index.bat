@echo off
echo Rebuilding Git index...
if exist .git\index del /f /q .git\index
git read-tree HEAD
git status
echo Git index successfully restored!
pause
