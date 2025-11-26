#!/bin/bash

# Скрипт сборки RobboScratch3
# Автор: Manris

REQUIRED_NODE_VERSION="16.20.2"
current_dir=$(pwd)

# Функция для проверки успешности выполнения команды
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Ошибка: $1"
        exit 1
    fi
}

echo
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   📦 СБОРКА ROBBOSCRATCH3                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "📁 Текущая директория: $current_dir"
echo
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│                     🔍 ПРОВЕРКА СИСТЕМЫ                      │"
echo "└──────────────────────────────────────────────────────────────┘"

REQUIRED_NODE_VERSION="16.20.2"

# Загружаем NVM в текущую сессию
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Это загружает nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Теперь проверяем текущую версию Node.js
if command -v node &> /dev/null; then
    CURRENT_NODE_VERSION=$(node -v | sed 's/v//')
    echo "Текущая версия Node.js: $CURRENT_NODE_VERSION"
else
    echo "❌ Node.js не установлен"
    CURRENT_NODE_VERSION=""
fi

echo "Требуемая версия Node.js: $REQUIRED_NODE_VERSION"

# Проверяем совпадает ли версия
if [ "$CURRENT_NODE_VERSION" = "$REQUIRED_NODE_VERSION" ]; then
    echo "✅ Версия Node.js соответствует требованиям"
else
    echo "⚠️  Требуется Node.js $REQUIRED_NODE_VERSION"
    
    # Проверяем что nvm доступен
    if ! command -v nvm &> /dev/null; then
        echo "❌ NVM не доступен даже после загрузки"
        exit 1
    fi
    
    echo "✅ NVM доступен"
    
    # Проверяем установлена ли версия через nvm which
    if nvm which "$REQUIRED_NODE_VERSION" &> /dev/null; then
        echo "✅ Node.js $REQUIRED_NODE_VERSION найдена в NVM"
    else
        echo "📥 Устанавливаем Node.js $REQUIRED_NODE_VERSION через NVM..."
        nvm install "$REQUIRED_NODE_VERSION"
        check_success "Установка Node.js $REQUIRED_NODE_VERSION"
    fi
    
    # Переключаемся на нужную версию
    echo "🔄 Переключаемся на Node.js $REQUIRED_NODE_VERSION..."
    nvm use "$REQUIRED_NODE_VERSION"
    check_success "Переключение на Node.js $REQUIRED_NODE_VERSION"
    
    # Проверяем результат
    NEW_NODE_VERSION=$(node -v | sed 's/v//')
    if [ "$NEW_NODE_VERSION" = "$REQUIRED_NODE_VERSION" ]; then
        echo "✅ Успешно переключено на Node.js $NEW_NODE_VERSION"
    else
        echo "❌ Не удалось переключить версию Node.js"
        exit 1
    fi
fi
echo
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│              🚀 1. СБОРКА DEVICECONTROLAPI                   │"
echo "└──────────────────────────────────────────────────────────────┘"
cd "$current_dir/Robboscratch3_DeviceControlAPI"
npm install
check_success "Установка зависимостей DeviceControlAPI"
npm run build
check_success "Сборка DeviceControlAPI"
echo
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│                       🚀 2. СБОРКА VM                        │"
echo "└──────────────────────────────────────────────────────────────┘"
cd "$current_dir/robboscratch3_vm"
npm install --legacy-peer-deps
check_success "Установка зависимостей VM"

echo "🔗 Создание симлинка DeviceControlAPI в VM..."
cd "$current_dir/robboscratch3_vm/node_modules"
if [ -d "Robboscratch3_DeviceControlAPI" ]; then
    rm -rf Robboscratch3_DeviceControlAPI
fi
ln -sf "../../Robboscratch3_DeviceControlAPI" Robboscratch3_DeviceControlAPI
check_success "Создание симлинка DeviceControlAPI"

echo "🔍 Проверка симлинка:"
ls -la | grep Robboscratch3_DeviceControlAPI

cd "$current_dir/robboscratch3_vm"
npm run build
check_success "Сборка VM"
echo
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│                   🚀 3. СБОРКА I10N                          │"
echo "└──────────────────────────────────────────────────────────────┘"
cd "$current_dir/robboscratch3_I10n"
npm install --legacy-peer-deps
check_success "Установка зависимостей i10n"
npm run build
check_success "Сборка i10n"
echo
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│                    🚀 4. СБОРКА BLOCKS                       │"
echo "└──────────────────────────────────────────────────────────────┘"
cd "$current_dir/robboscratch3_blocks"
npm install
check_success "Установка зависимостей Blocks"
npm run prepublish
check_success "Сборка Blocks (prepublish)"
echo
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│                     🚀 5. ПОДГОТОВКА GUI                     │"
echo "└──────────────────────────────────────────────────────────────┘"
cd "$current_dir/robboscratch3_gui"
npm install --legacy-peer-deps
check_success "Установка зависимостей GUI"
echo
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│                 🔗 6. СОЗДАНИЕ СИМЛИНКОВ В GUI              │"
echo "└──────────────────────────────────────────────────────────────┘"
cd "$current_dir/robboscratch3_gui/node_modules"

# Удаляем существующие папки модулей (если есть)
modules_to_link=("scratch-blocks" "scratch-l10n" "scratch-vm")
for module in "${modules_to_link[@]}"; do
    if [ -L "$module" ] || [ -d "$module" ]; then
        echo "🗑️ Удаляем $module..."
        rm -rf "$module"
    fi
done

# Создаем симлинки
echo "🔗 Создаем симлинки..."
ln -sf "../../robboscratch3_blocks" scratch-blocks
ln -sf "../../robboscratch3_I10n" scratch-l10n  
ln -sf "../../robboscratch3_vm" scratch-vm

echo "🔍 Проверка созданных симлинков:"
ls -la | grep -E "(scratch-blocks|scratch-l10n|scratch-vm)"

check_success "Создание симлинков в GUI"
echo
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│                  🚀 7. ФИНАЛЬНАЯ СБОРКА GUI                  │"
echo "└──────────────────────────────────────────────────────────────┘"
cd "$current_dir/robboscratch3_gui"
echo "🔧 Запуск сборки GUI (может занять несколько минут)..."
npm run build -- --bail=false
check_success "Сборка GUI"
echo
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   🎉 СБОРКА ЗАВЕРШЕНА!                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo
echo "🌐 ДЛЯ ЗАПУСКА СЕРВЕРА:"
echo "   cd $current_dir/robboscratch3_gui"
echo "   npm run start"
echo
echo "📁 ДЛЯ СТАТИЧЕСКОЙ ВЕРСИИ:"
echo "   cd $current_dir/robboscratch3_gui/build"
echo "   python3 -m http.server 8000"
echo
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                        УДАЧНОЙ РАБОТЫ!                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
