#!/bin/bash

# Directorio principal
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Colores para mensajes
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[0;33m'
NC='\033[0m' # No Color

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

# Dar permisos de ejecución a los scripts
chmod +x "$SCRIPTS_DIR/install_whiptail.sh"
chmod +x "$SCRIPTS_DIR/install_git.sh"
chmod +x "$SCRIPTS_DIR/install_yay.sh"
chmod +x "$SCRIPTS_DIR/install_oh_my_posh.sh"
chmod +x "$SCRIPTS_DIR/install_chaotic_aur.sh"

# Comprobamos si se ejecuta como root
if [ "$(id -u)" -eq 0 ]; then
    error "Este script no debe ejecutarse como root/sudo."
    exit 1
fi

# Si el script se llama solo para importar funciones, salimos aquí
if [ "${1:-}" = "--functions-only" ]; then
    return 2>/dev/null || exit 0
fi

# Ejecución de scripts de comprobación previos (supongo que ya los tienes)
if [ -f "$SCRIPTS_DIR/install_whiptail.sh" ]; then
    "$SCRIPTS_DIR/install_whiptail.sh" || advertencia "No se pudo instalar whiptail. Continuando en modo texto."
fi

# Verificar si whiptail está disponible
if command -v whiptail &> /dev/null; then
    USAR_WHIPTAIL=true
else
    USAR_WHIPTAIL=false
    advertencia "Whiptail no está disponible. Utilizando interfaz de texto."
fi

# Comprobar git
if [ -f "$SCRIPTS_DIR/install_git.sh" ]; then
    "$SCRIPTS_DIR/install_git.sh" || {
        error "No se pudo instalar git. Abortando."
        exit 1
    }
fi

# Comprobar yay
if [ -f "$SCRIPTS_DIR/install_yay.sh" ]; then
    "$SCRIPTS_DIR/install_yay.sh" || {
        error "No se pudo instalar yay. Solo se instalarán paquetes oficiales."
        USAR_AUR=false
    } && USAR_AUR=true
fi

# Ejecutar script de instalación de Chaotic AUR
if [ -f "$SCRIPTS_DIR/install_chaotic_aur.sh" ]; then
    mensaje "Ejecutando script de instalación de Chaotic AUR..."
    "$SCRIPTS_DIR/install_chaotic_aur.sh"
fi

# Lista unificada de programas para instalar
# Formato: "nombre_paquete" "descripción" "repositorio (pacman/aur)"
PROGRAMAS=(
    "fastfetch" "Herramienta para mostrar información del sistema" "aur"
    "btop" "Monitor de procesos interactivo" "pacman"
    "firefox" "Navegador web" "pacman"
    "vlc" "Reproductor multimedia" "pacman"
    "wget" "Herramienta para descargar archivos" "pacman"
    "unzip" "Herramienta para descomprimir archivos" "pacman"
    "visual-studio-code-bin" "Editor de código" "aur"
    "intellij-idea-community-edition-jre" "IDE" "aur"
    "spotify" "Cliente de música" "aur"
    "pamac" "Administrador de paquetes" "pacman"
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

# Selección de programas
if [ "$USAR_WHIPTAIL" = true ]; then
    PROGRAMAS_SELECCIONADOS=()
    CHECKLIST=()

    for ((i=0; i<${#PROGRAMAS[@]}; i+=3)); do
        nombre="${PROGRAMAS[i]}"
        descripcion="${PROGRAMAS[i+1]}"
        repo="${PROGRAMAS[i+2]}"

        # Si es un paquete AUR y no se puede usar AUR, no lo agregamos a la lista
        if [ "$repo" = "aur" ] && [ "$USAR_AUR" != true ]; then
            continue
        fi

        descripcion_completa="$descripcion [$repo]"
        CHECKLIST+=("$nombre" "$descripcion_completa" "OFF")
    done

    SELECCION=$(whiptail --title "Selección de Programas" --checklist \
        "Seleccione los programas que desea instalar:" 20 78 15 \
        "${CHECKLIST[@]}" 3>&1 1>&2 2>&3)

    if [ $? -eq 0 ]; then
        # Convertir la selección en un array
        PROGRAMAS_SELECCIONADOS=()
        for prog in $SELECCION; do
            # Quitar comillas
            prog=$(echo $prog | tr -d '"')
            PROGRAMAS_SELECCIONADOS+=("$prog")
        done

        # Instalar programas seleccionados
        TOTAL=${#PROGRAMAS_SELECCIONADOS[@]}
        CONTADOR=0

        for programa in "${PROGRAMAS_SELECCIONADOS[@]}"; do
            CONTADOR=$((CONTADOR + 1))
            PORCENTAJE=$((CONTADOR * 100 / TOTAL))

            # Buscar el repositorio del programa
            REPOSITORIO=""
            for ((i=0; i<${#PROGRAMAS[@]}; i+=3)); do
                if [ "${PROGRAMAS[i]}" = "$programa" ]; then
                    REPOSITORIO="${PROGRAMAS[i+2]}"
                    break
                fi
            done

            # Comprobar si ya está instalado
            if [ "$REPOSITORIO" = "pacman" ]; then
                if ! pacman -Qi "$programa" &> /dev/null; then
                    mostrar_progreso "Instalando $programa desde repositorios oficiales... ($CONTADOR/$TOTAL)" $PORCENTAJE
                    sudo pacman -S --noconfirm "$programa" || {
                        whiptail --title "Aviso" --msgbox "No se pudo instalar $programa" 10 60
                    }
                else
                    mostrar_progreso "$programa ya está instalado. ($CONTADOR/$TOTAL)" $PORCENTAJE
                fi
            elif [ "$REPOSITORIO" = "aur" ] && [ "$USAR_AUR" = true ]; then
                if ! yay -Qi "$programa" &> /dev/null; then
                    mostrar_progreso "Instalando $programa desde AUR... ($CONTADOR/$TOTAL)" $PORCENTAJE
                    yay -S --noconfirm "$programa" || {
                        whiptail --title "Aviso" --msgbox "No se pudo instalar $programa" 10 60
                    }
                else
                    mostrar_progreso "$programa ya está instalado. ($CONTADOR/$TOTAL)" $PORCENTAJE
                fi
            fi
        done
    else
        whiptail --title "Aviso" --msgbox "No se seleccionaron programas." 10 60
    fi
else
    # Modo terminal tradicional
    mensaje "Instalando programas básicos..."
    for ((i=0; i<${#PROGRAMAS[@]}; i+=3)); do
        nombre="${PROGRAMAS[i]}"
        descripcion="${PROGRAMAS[i+1]}"
        repo="${PROGRAMAS[i+2]}"

        # Si es un paquete AUR y no se puede usar AUR, lo saltamos
        if [ "$repo" = "aur" ] && [ "$USAR_AUR" != true ]; then
            continue
        }

        if [ "$repo" = "pacman" ]; then
            if ! pacman -Qi "$nombre" &> /dev/null; then
                mensaje "Instalando $nombre ($descripcion)..."
                sudo pacman -S --noconfirm "$nombre" || advertencia "No se pudo instalar $nombre"
            else
                mensaje "$nombre ya está instalado."
            fi
        elif [ "$repo" = "aur" ] && [ "$USAR_AUR" = true ]; then
            if ! yay -Qi "$nombre" &> /dev/null; then
                mensaje "Instalando $nombre ($descripcion) desde AUR..."
                yay -S --noconfirm "$nombre" || advertencia "No se pudo instalar $nombre"
            else
                mensaje "$nombre ya está instalado."
            fi
        fi
    done
fi

# Ejecutar script de instalación de Oh My Posh
if [ -f "$SCRIPTS_DIR/install_oh_my_posh.sh" ]; then
    mensaje "Ejecutando script de instalación de Oh My Posh..."
    "$SCRIPTS_DIR/install_oh_my_posh.sh"
fi

# Mensaje final
mostrar_mensaje "¡Instalación básica completada!"