#!/bin/bash
set -e

# === Настройки ===
REPO_URL="git@github.com:Bakminstof/BatchScripts.git"
DEFAULT_BRANCH="master"
LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Проверка наличия git
if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: Git не установлен. Установите git и повторите."
    exit 1
fi

# Проверка наличия git lfs
if ! command -v git-lfs >/dev/null 2>&1; then
    echo "WARNING: Git LFS не установлен. LFS-файлы не будут загружены."
    USE_LFS=false
else
    USE_LFS=true
fi

# Клонирование, если репозиторий отсутствует
if [ ! -d "$LOCAL_DIR/.git" ]; then
    echo "Клонирование репозитория (shallow clone, depth=1)"
    git clone --depth 1 "$REPO_URL" "$LOCAL_DIR"
    echo "Клонирование завершено."
    cd "$LOCAL_DIR"
    $USE_LFS && git lfs pull
    sleep 5
    exit 0
fi

# Обновление существующего репозитория
echo "Обновление существующего репозитория"
cd "$LOCAL_DIR"
git fetch --depth=1 origin
git reset --hard origin/$DEFAULT_BRANCH
$USE_LFS && git lfs pull
echo "Репозиторий успешно обновлён."

# Ждём 5 секунд перед завершением
sleep 5
