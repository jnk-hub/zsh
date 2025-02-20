# Функция для поиска go.mod в родительских директориях
function find_go_mod {
  local DIR=$(pwd)

  # Ищем go.mod в родительских директориях до корня
  while [ "$DIR" != "/" ]; do
    if [ -f "$DIR/go.mod" ]; then
      echo "$DIR/go.mod"
      return
    fi
    DIR=$(dirname "$DIR")  # Переходим в родительскую директорию
  done

  return 1
}

# Функция для получения последней стабильной версии Go для основной версии
function get_latest_stable_version {
  local VERSION=$1
  local API_URL="https://go.dev/dl/?mode=json&include=all"

  # Загружаем список всех релизов в формате JSON и фильтруем по основной версии
  LATEST_VERSION=$(curl -sSL "$API_URL" | jq -r '.[] | select(.version | startswith("go'$VERSION'")) | .version' | sort -V | tail -n 1)

  # Убираем префикс "go" из версии, оставляем только "1.22.12" вместо "go1.22.12"
  LATEST_VERSION=${LATEST_VERSION/go/}

  # Если версия не найдена, выводим ошибку
  if [ -z "$LATEST_VERSION" ]; then
    echo "Ошибка: Не удалось найти последнюю стабильную версию для $VERSION."
    return 1
  fi

  echo "$LATEST_VERSION"
}

# Функция для скачивания нужной версии Go для macOS ARM
function download_go_version {
  local VERSION=$1
  local GO_DOWNLOAD_URL="https://golang.org/dl/go$VERSION.darwin-arm64.tar.gz"
  local SDK_PATH="$HOME/sdk"
  local VERSION_PATH="$SDK_PATH/go$VERSION"
  local GO_ARCHIVE="go$VERSION.darwin-arm64.tar.gz"

  # Создаем директорию для SDK, если её нет
  mkdir -p "$SDK_PATH"

  echo "Необходима версия Go ($VERSION)."
  echo "Хотите скачать $VERSION? (y/N): "
  read response
  if [[ "$response" != "y" || "$response" != "Y" ]]; then
    return 1
  fi
  echo "Скачиваю..."

  # Если нужная версия ещё не скачана
  if [ ! -d "$VERSION_PATH" ]; then
    # Скачиваем и распаковываем архив с нужной версией Go
    curl -sSL "$GO_DOWNLOAD_URL" -o "$SDK_PATH/$GO_ARCHIVE"

    # Показываем прогресс загрузки
    echo -n "Загружаем файл..."
    while ! curl -sSL "$GO_DOWNLOAD_URL" -o "$SDK_PATH/$GO_ARCHIVE"; do
      echo -n "."
      sleep 1
    done
    echo " Завершено."

    tar -C "$SDK_PATH" -xzf "$SDK_PATH/$GO_ARCHIVE"
    mv "$SDK_PATH/go" "$VERSION_PATH"  # Переименовываем в нужную версию

    # Удаляем архив после распаковки
    rm "$SDK_PATH/$GO_ARCHIVE"
    echo "Версия Go $VERSION успешно установлена."
  else
    echo "Версия Go $VERSION уже установлена."
  fi
}

# Функция для автоматического переключения версии Go на основе go.mod
function switch_go_version {
  local GO_MOD_PATH=$(find_go_mod)

  if [ -n "$GO_MOD_PATH" ]; then
    # Если найден go.mod, то устанавливаем нужную версию Go
    VERSION=$(grep '^go ' "$GO_MOD_PATH" | awk '{print $2}')

    if [ -n "$VERSION" ]; then
      # Если версия без патча (например, 1.22), получаем последнюю стабильную
      # Проверяем, что версия состоит только из основной и минорной части (например, 1.22)
      if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
        VERSION=$(get_latest_stable_version "$VERSION")
        if [ $? -ne 0 ]; then
          return 1  # Если не удалось получить последнюю стабильную версию, выходим
        fi
      fi

      SDK_PATH="$HOME/sdk"
      VERSION_PATH="$SDK_PATH/go$VERSION"
      INSTALLED_VERSIONS=$(ls -d "$VERSION_PATH" 2>/dev/null)

      if [ -z "$INSTALLED_VERSIONS" ]; then
        # Если нужная версия не найдена, скачиваем её
        download_go_version "$VERSION"
      fi

      # Устанавливаем GOROOT и обновляем PATH для использования самой свежей версии Go
      export GOROOT=$VERSION_PATH
      export PATH=$GOROOT/bin:$PATH
    fi
  else
    # Если go.mod не найден, сбрасываем на стандартную версию Go
    reset_go_version
  fi
}

# Функция для сброса версии Go на стандартную
function reset_go_version {
  DEFAULT_GO="/usr/local/go"
  
  if [ -d "$DEFAULT_GO" ]; then
    export GOROOT="$DEFAULT_GO"
    export PATH="$GOROOT/bin:$PATH"
  fi
}

# Переопределяем команду cd, чтобы автоматически переключать версии Go
function cd {
  # Выполняем стандартный cd
  builtin cd "$@" || return

  # Вызываем функцию переключения версии Go, если в новой директории есть go.mod
  switch_go_version
}

# Перезагружаем настройки при старте терминала
switch_go_version

