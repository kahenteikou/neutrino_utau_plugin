@echo off
robocopy %1 %2 /s /e
xcopy %3 %4 /Y
exit /b 0
