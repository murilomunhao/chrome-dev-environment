#!/bin/bash

# Configuração do executável do Chrome
# Opções comuns: google-chrome, google-chrome-stable, chrome
CHROME_EXECUTABLE="google-chrome-stable"

# Arrays com configurações de dispositivos
declare -A MOBILE_DEVICES=(
    ["1 - iPhone 4"]="320x480"
    ["2 - iPhone 5/SE"]="320x568"
    ["3 - Galaxy S5"]="360x640"
    ["4 - iPhone 6/7/8"]="375x667"
    ["5 - Pixel 2"]="411x731"
    ["6 - iPhone 6/7/8 Plus"]="414x736"
    ["7 - iPhone X/XS"]="375x812"
    ["8 - iPhone XR"]="414x896"
    ["9 - Pixel 3 XL"]="412x847"
    ["10 - Galaxy S20"]="412x915"
)

declare -A TABLET_DEVICES=(
    ["1 - iPad Mini"]="768x1024"
    ["2 - iPad"]="810x1080"
    ["3 - iPad Air"]="820x1180"
    ["4 - iPad Pro 10.5"]="834x1112"
    ["5 - iPad Pro 11"]="834x1194"
    ["6 - iPad Pro 12.9"]="1024x1366"
)

# Cores ANSI para personalização da interface
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_PURPLE='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_BOLD='\033[1m'
COLOR_GRAY='\033[0;90m'
COLOR_NC='\033[0m' # No Color

# Função para detectar automaticamente o executável do Chrome
detect_chrome_executable() {
    local chrome_options=("google-chrome-stable" "google-chrome" "chrome")
    
    for exec_name in "${chrome_options[@]}"; do
        if command -v "$exec_name" >/dev/null 2>&1; then
            CHROME_EXECUTABLE="$exec_name"
            return
        fi
    done
    
    echo "⚠️ Nenhuma versão do Chrome foi encontrada. Por favor, instale o Google Chrome."
    exit 1
}

# Função para rotacionar as dimensões do dispositivo
get_device_dimensions() {
    local size=$1
    local orientation=$2
    local width height

    IFS='x' read -r width height <<< "$size"
    
    if [[ "$orientation" == "2" ]]; then
        # Retorna dimensões horizontais (rotacionadas)
        echo "${height}x${width}"
    else
        # Retorna dimensões verticais (original)
        echo "${width}x${height}"
    fi
} 