@echo off
setlocal

:: === Настройки ===
set REPO_URL=https://github.com/<user>/<repo>.git

:: Каталог BatchScripts — скрипт внутри него
set LOCAL_DIR=%~dp0

:: Проверка наличия git
git --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Git не установлен. Установите git и повторите.
    exit /b 1
)

:: Клонирование, если репозиторий отсутствует
if not exist "%LOCAL_DIR%\.git" (
    echo Клонирование репозитория (shallow clone, depth=1)...
    git clone --depth 1 "%REPO_URL%" "%LOCAL_DIR%"
    if %ERRORLEVEL% neq 0 (
        echo Ошибка при клонировании репозитория
        exit /b 1
    )
    echo Клонирование завершено.
    cd /d "%LOCAL_DIR%"
    git lfs pull
    exit /b 0
)

:: Обновление существующего репозитория
echo Обновление существующего репозитория...
cd /d "%LOCAL_DIR%"
git fetch --depth=1 origin
git reset --hard origin/main
git lfs pull
if %ERRORLEVEL% neq 0 (
    echo Ошибка при обновлении репозитория
    exit /b 1
)
echo Репозиторий успешно обновлён.
endlocal
exit /b 0
