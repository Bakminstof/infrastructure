@echo off
chcp 65001 > nul
setlocal

:: === Настройки ===
set REPO_URL=git@github.com:Bakminstof/infrastructure.git
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

echo Обновление репозитория

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
