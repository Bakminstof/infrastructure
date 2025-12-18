@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM Общие параметры
REM ============================================================

REM Базовая директория infrastructure
set "BASE_DIR=%~dp0"

REM ---------- Hosts ----------
REM Путь к файлу hosts (UNC или локальный)
set "HOSTS_SOURCE=\\10.23.100.5\tmp-utils\hosts"

REM ---------- Salt ----------
REM IP или DNS мастера Salt
set "SALT_MASTER=salt-master.school-2.local"

REM ID minion (по умолчанию имя ПК)
set /p "SALT_MINION_ID=Minion name: "

REM Каталог инструментов
set "BASE_TOOLS_DIR=C:\Tools"

REM Пропустить проверку установки Salt
set "SKIP_INSTALL_CHECK=0"

REM ============================================================
REM Пути к скриптам
REM ============================================================

set "PS_EXE=powershell.exe"
set "PS_OPTS=-NoProfile -ExecutionPolicy Bypass"

set "UPDATE_HOSTS_PS=%BASE_DIR%\Scripts\DNS\Update-HostsFromSource.ps1"
set "INSTALL_SALT_PS=%BASE_DIR%\Scripts\Salt\Install-SaltMinion.ps1"

REM ============================================================
REM Проверка прав администратора
REM ============================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Script must be run as Administrator
    pause
    exit /b 1
)

REM ============================================================
REM Обновление hosts
REM ============================================================

echo.
echo === Updating hosts file ===

"%PS_EXE%" %PS_OPTS% ^
  -File "%UPDATE_HOSTS_PS%" ^
  -SourceHostsPath "%HOSTS_SOURCE%"

if %errorlevel% neq 0 (
    echo [ERROR] Hosts update failed
    pause
    exit /b 1
)

REM ============================================================
REM Установка Salt Minion
REM ============================================================

echo.
echo === Installing Salt Minion ===

"%PS_EXE%" %PS_OPTS% ^
  -File "%INSTALL_SALT_PS%" ^
  -MasterAddress "%SALT_MASTER%" ^
  -MinionId "%SALT_MINION_ID%" ^
  -BaseToolsDir "%BASE_TOOLS_DIR%" ^
  %SKIP_INSTALL_CHECK%

if %errorlevel% neq 0 (
    echo [ERROR] Salt Minion installation failed
    pause
    exit /b 1
)

echo.
echo === Bootstrap completed successfully ===
pause
exit /b 0
