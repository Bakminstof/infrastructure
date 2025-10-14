@echo off
@chcp 65001 > nul

setlocal enableextensions

rem ============================================================
rem  Reconnect-AllAdapters.cmd
rem  Обёртка для PowerShell-скрипта Reconnect-AllAdapters.ps1
rem  Запускает с правами администратора и логированием.
rem ============================================================

rem --- Проверка прав администратора ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Требуются права администратора. Перезапуск с повышением...
    powershell -Command "Start-Process -Verb RunAs cmd -ArgumentList '/c \"\"%~f0\" %*\"'"
    exit /b
)

rem --- Определение путей ---
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Scripts\Reconnect-AllAdapters\Reconnect-AllAdapters.ps1"

if not exist "%PS_SCRIPT%" (
    echo [ОШИБКА] Не найден файл PowerShell-скрипта: "%PS_SCRIPT%"
    pause
    exit /b 1
)

rem --- Запуск PowerShell с отключением ExecutionPolicy ---
echo Запуск PowerShell-скрипта...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

echo.
echo Скрипт завершён.
pause
endlocal
exit /b 0
