@echo off

SETLOCAL

REM Путь к PowerShell скрипту
SET "PS_SCRIPT=%~dp0Salt\Bootstrap-Minion.ps1"

REM Проверка существования скрипта
IF NOT EXIST "%PS_SCRIPT%" (
    echo [ERROR] PowerShell script not found: %PS_SCRIPT%
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

REM Проверка кода выхода PowerShell
IF ERRORLEVEL 1 (
    echo [ERROR] Bootstrap.ps1 завершился с ошибкой.
    exit /b 1
)

echo [INFO] Bootstrap.ps1 выполнен успешно.
ENDLOCAL
exit /b 0
