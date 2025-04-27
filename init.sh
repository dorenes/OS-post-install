#!/bin/bash

# Directorio principal
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Colores para mensajes
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[0;33m'
NC='\033[0m' # No Color

# Crear directorio de scripts si no existe
mkdir -p "$SCRIPTS_DIR"

# Función para mostrar mensajes
mensaje() {
    echo -e "${VERDE}[INFO]${NC} $1"
}

error() {
    echo -e "${ROJO}[ERROR]${NC} $1"
}

advertencia() {
    echo -e "${AMARILLO}[AVISO]${NC} $1"
}

# Comprobamos si se ejecuta como root
if [ "$(id -u)" -eq 0 ]; then
    error "Este script no debe ejecutarse como root/sudo."
    exit 1
fi

# Dar permisos de ejecución a los scripts
chmod +x "$SCRIPTS_DIR/install_whiptail.sh"
chmod +x "$SCRIPTS_DIR/install_git.sh"
chmod +x "$SCRIPTS_DIR/install_yay.sh"

# Si el script se llama solo para importar funciones, salimos aquí
if [ "${1:-}" = "--functions-only" ]; then
    return 2>/dev/null || exit 0
fi

# Instalar whiptail
"$SCRIPTS_DIR/install_whiptail.sh" || advertencia "No se pudo instalar whiptail. Continuando en modo texto."

# Verificar si whiptail está disponible
if command -v whiptail &> /dev/null; then
    USAR_WHIPTAIL=true
else
    USAR_WHIPTAIL=false
    advertencia "Whiptail no está disponible. Utilizando interfaz de texto."
fi

# Instalar git
"$SCRIPTS_DIR/install_git.sh" || {
    error "No se pudo instalar git. Abortando."
    exit 1
}

# Instalar yay
"$SCRIPTS_DIR/install_yay.sh" || {
    error "No se pudo instalar yay. Solo se instalarán paquetes oficiales."
    USAR_AUR=false
} && USAR_AUR=true

# Lista de programas básicos para instalar
PROGRAMAS_PACMAN=(
    "fastfetch" "Herramienta para mostrar información del sistema"
    "btop" "Monitor de procesos interactivo"
    "firefox" "Navegador web"
    "vlc" "Reproductor multimedia"
    "wget" "Herramienta para descargar archivos"
    "unzip" "Herramienta para descomprimir archivos"
)

PROGRAMAS_AUR=(
    "visual-studio-code-bin" "Editor de código"
    "spotify" "Cliente de música"
)

# Función para mostrar progreso
mostrar_progreso() {
    local mensaje="$1"
    local porcentaje="$2"

    if [ "$USAR_WHIPTAIL" = true ]; then
        echo "$porcentaje" | whiptail --gauge "$mensaje" 8 60 0
    else
        mensaje "$mensaje ($porcentaje%)"
    fi
}

# Función para mostrar mensajes
mostrar_mensaje() {
    if [ "$USAR_WHIPTAIL" = true ]; then
        whiptail --title "Instalación Básica" --msgbox "$1" 10 60
    else
        mensaje "$1"
    fi
}

# Selección de programas oficiales
if [ "$USAR_WHIPTAIL" = true ]; then
    PROGRAMAS_SELECCIONADOS=()
    CHECKLIST=()

    for ((i=0; i<${#PROGRAMAS_PACMAN[@]}; i+=2)); do
        CHECKLIST+=("${PROGRAMAS_PACMAN[i]}" "${PROGRAMAS_PACMAN[i+1]}" "OFF")
    done

    SELECCION=$(whiptail --title "Selección de Programas Oficiales" --checklist \
        "Seleccione los programas que desea instalar:" 20 78 10 \
        "${CHECKLIST[@]}" 3>&1 1>&2 2>&3)

    if [ $? -eq 0 ]; then
        # Convertir la selección en un array
        PROGRAMAS_SELECCIONADOS=()
        for prog in $SELECCION; do
            # Quitar comillas
            prog=$(echo $prog | tr -d '"')
            PROGRAMAS_SELECCIONADOS+=("$prog")
        done

        # Instalar programas seleccionados desde pacman
        TOTAL=${#PROGRAMAS_SELECCIONADOS[@]}
        CONTADOR=0

        for programa in "${PROGRAMAS_SELECCIONADOS[@]}"; do
            CONTADOR=$((CONTADOR + 1))
            PORCENTAJE=$((CONTADOR * 100 / TOTAL))

            if ! pacman -Qi "$programa" &> /dev/null; then
                mostrar_progreso "Instalando $programa... ($CONTADOR/$TOTAL)" $PORCENTAJE
                sudo pacman -S --noconfirm "$programa" || {
                    whiptail --title "Aviso" --msgbox "No se pudo instalar $programa" 10 60
                }
            else
                mostrar_progreso "$programa ya está instalado. ($CONTADOR/$TOTAL)" $PORCENTAJE
            fi
        done
    else
        whiptail --title "Aviso" --msgbox "No se seleccionaron programas oficiales." 10 60
    fi

    # Selección de programas AUR si yay está instalado
    if [ "$USAR_AUR" = true ]; then
        PROGRAMAS_AUR_SELECCIONADOS=()
        CHECKLIST_AUR=()

        for ((i=0; i<${#PROGRAMAS_AUR[@]}; i+=2)); do
            CHECKLIST_AUR+=("${PROGRAMAS_AUR[i]}" "${PROGRAMAS_AUR[i+1]}" "OFF")
        done

        SELECCION_AUR=$(whiptail --title "Selección de Programas AUR" --checklist \
            "Seleccione los programas AUR que desea instalar:" 20 78 10 \
            "${CHECKLIST_AUR[@]}" 3>&1 1>&2 2>&3)

        if [ $? -eq 0 ]; then
            # Convertir la selección en un array
            PROGRAMAS_AUR_SELECCIONADOS=()
            for prog in $SELECCION_AUR; do
                # Quitar comillas
                prog=$(echo $prog | tr -d '"')
                PROGRAMAS_AUR_SELECCIONADOS+=("$prog")
            done

            # Instalar programas seleccionados desde AUR
            TOTAL=${#PROGRAMAS_AUR_SELECCIONADOS[@]}
            CONTADOR=0

            for programa in "${PROGRAMAS_AUR_SELECCIONADOS[@]}"; do
                CONTADOR=$((CONTADOR + 1))
                PORCENTAJE=$((CONTADOR * 100 / TOTAL))

                if ! yay -Qi "$programa" &> /dev/null; then
                    mostrar_progreso "Instalando $programa desde AUR... ($CONTADOR/$TOTAL)" $PORCENTAJE
                    yay -S --noconfirm "$programa" || {
                        whiptail --title "Aviso" --msgbox "No se pudo instalar $programa" 10 60
                    }
                else
                    mostrar_progreso "$programa ya está instalado. ($CONTADOR/$TOTAL)" $PORCENTAJE
                fi
            done
        else
            whiptail --title "Aviso" --msgbox "No se seleccionaron programas AUR." 10 60
        fi
    fi
else
    # Modo terminal tradicional
    mensaje "Instalando programas básicos desde repositorios oficiales..."
    for ((i=0; i<${#PROGRAMAS_PACMAN[@]}; i+=2)); do
        programa="${PROGRAMAS_PACMAN[i]}"
        descripcion="${PROGRAMAS_PACMAN[i+1]}"

        if ! pacman -Qi "$programa" &> /dev/null; then
            mensaje "Instalando $programa ($descripcion)..."
            sudo pacman -S --noconfirm "$programa" || advertencia "No se pudo instalar $programa"
        else
            mensaje "$programa ya está instalado."
        fi
    done

    if [ "$USAR_AUR" = true ]; then
        mensaje "Instalando programas desde AUR..."
        for ((i=0; i<${#PROGRAMAS_AUR[@]}; i+=2)); do
            programa="${PROGRAMAS_AUR[i]}"
            descripcion="${PROGRAMAS_AUR[i+1]}"

            if ! yay -Qi "$programa" &> /dev/null; then
                mensaje "Instalando $programa ($descripcion)..."
                yay -S --noconfirm "$programa" || advertencia "No se pudo instalar $programa"
            else
                mensaje "$programa ya está instalado."
            fi
        done
    fi
fi

# Mensaje final
mostrar_mensaje "¡Instalación básica completada!"