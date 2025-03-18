#!/bin/bash

# Carrega o arquivo de configuração
CONFIG_FILE="$(dirname "$0")/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

# Detecta o executável do Chrome disponível
detect_chrome_executable


# Função para exibir o banner
show_banner() {
    clear
    echo -e "${COLOR_BLUE}╔════════════════════════════════════════╗${COLOR_NC}"
    echo -e "${COLOR_BLUE}║${COLOR_BOLD}       Chrome Dev Environment           ${COLOR_NC}${COLOR_BLUE}║${COLOR_NC}"
    echo -e "${COLOR_BLUE}╚════════════════════════════════════════╝${COLOR_NC}"
    echo
}

# Função para perguntar ao usuário qual porta usar
ask_port() {
    echo -e "${COLOR_CYAN}📡 Configuração da Porta${COLOR_NC}"
    echo -ne "${COLOR_YELLOW}╰─➤${COLOR_BLUE} Digite a porta que deseja usar: ${COLOR_NC}"
    read PORT
    echo -ne "${COLOR_NC}"
    if [[ -z "$PORT" ]]; then
        echo -e "${COLOR_RED}❌ Erro: Porta inválida${COLOR_NC}"
        exit 1
    fi
}

# Função para mostrar dispositivos em duas colunas
show_devices() {
    local -n devices=$1  # Referência para o array de dispositivos
    local title=$2
    local columns=$3
    local total=${#devices[@]}
    local rows=$(( (total + columns - 1) / columns ))

    echo -e "\n${COLOR_CYAN}📱 $title${COLOR_NC}"
    echo 
    
    for ((i=1; i<=rows; i++)); do
        local line="${COLOR_YELLOW}│${COLOR_NC} "
        for ((j=0; j<columns; j++)); do
            local idx=$((i + j*rows))
            local key=""
            local size=""
            for k in "${!devices[@]}"; do
                if [[ $k == "$idx"* ]]; then
                    key=$k
                    size=${devices[$k]}
                    break
                fi
            done
            if [[ -n $key ]]; then
                # Extrai o número e o nome
                local num="${key%% -*}"
                local display_name="${key#* - }"
                line+="$(printf "${COLOR_BOLD}%2s)${COLOR_NC} %-17s${COLOR_GRAY}[%8s]${COLOR_NC}  " "$num" "$display_name" "$size")"
            else
                line+="$(printf "%-35s" " ")"
            fi
        done
        echo -e "$line${COLOR_NC}"
    done
    echo -e "${COLOR_YELLOW}│${COLOR_NC}"
}

# Função para perguntar a orientação do dispositivo
ask_orientation() {
    echo
    echo -e "${COLOR_CYAN}📱 Orientação do Dispositivo${COLOR_NC}"
    echo 
    echo -e "${COLOR_YELLOW}│${COLOR_NC} ${COLOR_BOLD}1)${COLOR_NC} Vertical   "
    echo -e "${COLOR_YELLOW}│${COLOR_NC} ${COLOR_BOLD}2)${COLOR_NC} Horizontal "
    echo -e "${COLOR_YELLOW}│${COLOR_NC}"
    echo -ne "${COLOR_YELLOW}╰─➤${COLOR_NC} ${COLOR_BLUE}Escolha a orientação (1 ou 2): ${COLOR_NC}"
    read ORIENTATION
    echo -ne "${COLOR_NC}"
    
    if [[ "$ORIENTATION" != "1" && "$ORIENTATION" != "2" ]]; then
        echo -e "${COLOR_RED}❌ Erro: Orientação inválida${COLOR_NC}"
        exit 1
    fi
    
    if [[ "$ORIENTATION" == "1" ]]; then
        echo -e "${COLOR_GREEN}✓ Orientação vertical selecionada${COLOR_NC}"
    else
        echo -e "${COLOR_GREEN}✓ Orientação horizontal selecionada${COLOR_NC}"
    fi
}

# Função para perguntar o modo de visualização
ask_mode() {
    echo
    echo -e "${COLOR_CYAN}🖥️  Modo de Visualização${COLOR_NC}"
    echo 
    echo -e "${COLOR_YELLOW}│${COLOR_NC} ${COLOR_BOLD}1)${COLOR_NC} Desktop"
    echo -e "${COLOR_YELLOW}│${COLOR_NC} ${COLOR_BOLD}2)${COLOR_NC} Celular"
    echo -e "${COLOR_YELLOW}│${COLOR_NC} ${COLOR_BOLD}3)${COLOR_NC} Tablet"
    echo -e "${COLOR_YELLOW}│${COLOR_NC}" 
    echo -ne "${COLOR_YELLOW}╰─➤${COLOR_NC} ${COLOR_BLUE} Escolha sua opção (1, 2 ou 3): ${COLOR_NC}"
    read MODE
    echo -ne "${COLOR_NC}"
    if [[ "$MODE" != "1" && "$MODE" != "2" && "$MODE" != "3" ]]; then
        echo -e "${COLOR_RED}❌ Erro: Modo inválido${COLOR_NC}"
        exit 1
    fi
    
    # Selecionar dispositivo específico para modos móveis
    if [[ "$MODE" == "2" ]]; then
        show_devices MOBILE_DEVICES "Selecione o Modelo do Celular" 2
        echo -ne "${COLOR_YELLOW}╰─➤${COLOR_BLUE} Escolha o número do dispositivo: ${COLOR_NC}"
        read DEVICE_CHOICE
        echo -ne "${COLOR_NC}"
        
        # Encontrar o dispositivo selecionado
        SELECTED_DEVICE=""
        for key in "${!MOBILE_DEVICES[@]}"; do
            if [[ $key == "$DEVICE_CHOICE "* ]]; then
                SELECTED_DEVICE=${MOBILE_DEVICES[$key]}
                DEVICE_NAME=${key#* - }
                break
            fi
        done
        
        if [[ -z "$SELECTED_DEVICE" ]]; then
            echo -e "${COLOR_RED}❌ Erro: Dispositivo inválido${COLOR_NC}"
            exit 1
        fi
        
        # Perguntar orientação
        ask_orientation
        SELECTED_DEVICE=$(get_device_dimensions "$SELECTED_DEVICE" "$ORIENTATION")
        
    elif [[ "$MODE" == "3" ]]; then
        show_devices TABLET_DEVICES "Selecione o Modelo do Tablet" 2
        echo -ne "${COLOR_YELLOW}╰─➤${COLOR_BLUE} Escolha o número do dispositivo: ${COLOR_NC}"
        read DEVICE_CHOICE
        echo -ne "${COLOR_NC}"
        
        # Encontrar o dispositivo selecionado
        SELECTED_DEVICE=""
        for key in "${!TABLET_DEVICES[@]}"; do
            if [[ $key == "$DEVICE_CHOICE "* ]]; then
                SELECTED_DEVICE=${TABLET_DEVICES[$key]}
                DEVICE_NAME=${key#* - }
                break
            fi
        done
        
        if [[ -z "$SELECTED_DEVICE" ]]; then
            echo -e "${COLOR_RED}❌ Erro: Dispositivo inválido${COLOR_NC}"
            exit 1
        fi
        
        # Perguntar orientação
        ask_orientation
        SELECTED_DEVICE=$(get_device_dimensions "$SELECTED_DEVICE" "$ORIENTATION")
    else
        SELECTED_DEVICE="1366x768"
    fi
}

# Função para iniciar o Chrome com as configurações desejadas
start_chrome() {
    URL="http://localhost:$PORT"
    PROFILE_DIR="$HOME/.Murilo/config/google-chrome-dev-profile"

    # Cria o diretório do perfil se ele não existir
    mkdir -p "$PROFILE_DIR"

    echo -e "\n${COLOR_CYAN}🚀 Iniciando Chrome...${COLOR_NC}"

    # Define as flags adicionais com base no modo escolhido
    IFS='x' read -r width height <<< "$SELECTED_DEVICE"
    "$CHROME_EXECUTABLE" --app="$URL" --user-data-dir="$PROFILE_DIR" --window-size=$width,$height > /dev/null 2>&1 &

    echo -e "${COLOR_GREEN}✨ Chrome iniciado com sucesso!${COLOR_NC}"
    echo -e "${COLOR_BLUE}📌 URL:${COLOR_NC} $URL"
}

# Fluxo principal do script
show_banner
ask_port
ask_mode
start_chrome
