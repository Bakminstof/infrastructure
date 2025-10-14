@echo off
chcp 65001 > nul
setlocal

:: === Настройки ===
set REPO_URL=git@github.com:Bakminstof/BatchScripts.git
set DEFAULT_BRANCH=master
set LOCAL_DIR=%~dp0

:: Проверка наличия git
git --version >nul 2>&1

if %ERRORLEVEL% neq 0 (
    echo ERROR: Git не установлен. Установите git и повторите.
    exit /b 1
)

:: Проверка наличия git lfs
git lfs version >nul 2>&1

if %ERRORLEVEL% neq 0 (
    echo WARNING: Git LFS не установлен. LFS-файлы не будут загружены.
    set USE_LFS=0
) else (
    set USE_LFS=1
)

:: Клонирование, если репозиторий отсутствует
if not exist "%LOCAL_DIR%\.git" (
    echo Клонирование репозитория (shallow clone, depth=1)
    git clone --depth 1 "%REPO_URL%" "%LOCAL_DIR%"
    if %ERRORLEVEL% neq 0 (
        echo Ошибка при клонировании репозитория
        exit /b 1
    )
    echo Клонирование завершено.
    cd /d "%LOCAL_DIR%"
    if %USE_LFS%==1 git lfs pull
    timeout /t 5 >nul
    exit /b 0
)

:: Обновление существующего репозитория
echo Обновление существующего репозитория
cd /d "%LOCAL_DIR%"
git fetch --depth=1 origin
if %ERRORLEVEL% neq 0 (
    echo Ошибка при fetch
    exit /b 1
)
git reset --hard origin/%DEFAULT_BRANCH%
if %ERRORLEVEL% neq 0 (
    echo Ошибка при reset
    exit /b 1
)
if %USE_LFS%==1 git lfs pull
if %ERRORLEVEL% neq 0 (
    echo Ошибка при git lfs pull
    exit /b 1
)
echo Репозиторий успешно обновлён.

:: Ждём 5 секунд перед завершением
timeout /t 5 >nul

endlocal
exit /b 0
