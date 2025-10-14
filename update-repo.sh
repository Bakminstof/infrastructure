#!/bin/bash

# === Настройки ===
REPO_URL="https://github.com/<user>/<repo>.git"

# Каталог скрипта = BatchScripts
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
    echo "Клонирование репозитория (shallow clone, depth=1)..."
    git clone --depth 1 "$REPO_URL" "$LOCAL_DIR"
    if [ $? -ne 0 ]; then
        echo "Ошибка при клонировании репозитория"
        exit 1
    fi
    echo "Клонирование завершено."
    cd "$LOCAL_DIR" || exit 1
    $USE_LFS && git lfs pull
    exit 0
fi

# Обновление существующего репозитория
echo "Обновление существующего репозитория..."
cd "$LOCAL_DIR" || { echo "Не удалось перейти в каталог $LOCAL_DIR"; exit 1; }
git fetch --depth=1 origin
git reset --hard origin/main
$USE_LFS && git lfs pull
if [ $? -ne 0 ]; then
    echo "Ошибка при обновлении репозитория"
    exit 1
fi
echo "Репозиторий успешно обновлён."
