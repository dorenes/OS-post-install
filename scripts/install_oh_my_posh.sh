#!/bin/bash

# Directorio principal
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Importar funciones si está disponible
if [ -f "$SCRIPT_DIR/init.sh" ]; then
    source "$SCRIPT_DIR/init.sh" --functions-only
else
    # Definir funciones básicas si no podemos importarlas
    VERDE='\033[0;32m'
    ROJO='\033[0;31m'
    AMARILLO='\033[0;33m'
    NC='\033[0m' # No Color

    mensaje() {
        echo -e "${VERDE}[INFO]${NC} $1"
    }

    error() {
        echo -e "${ROJO}[ERROR]${NC} $1"
    }

    advertencia() {
        echo -e "${AMARILLO}[AVISO]${NC} $1"
    }
fi

# Verificar si whiptail está disponible
if command -v whiptail &> /dev/null; then
    USAR_WHIPTAIL=true
else
    USAR_WHIPTAIL=false
fi

# Verificar si yay está disponible
if command -v yay &> /dev/null; then
    USAR_AUR=true
else
    USAR_AUR=false
fi

instalar_oh_my_posh() {
    mensaje "Instalando Oh My Posh..."

    # Verificar si curl está instalado
    if ! command -v curl &> /dev/null; then
        mensaje "Instalando curl primero..."
        sudo pacman -S --noconfirm curl || {
            error "No se pudo instalar curl. Abortando."
            return 1
        }
    fi

    # Verificar si wget está instalado
    if ! command -v wget &> /dev/null; then
        mensaje "Instalando wget primero..."
        sudo pacman -S --noconfirm wget || {
            error "No se pudo instalar wget. Abortando."
            return 1
        }
    fi

    # Método 1: Instalar desde AUR si está disponible
    if [ "$USAR_AUR" = true ]; then
        mensaje "Intentando instalar Oh-My-Posh desde AUR..."
        yay -S --noconfirm oh-my-posh-bin || {
            advertencia "No se pudo instalar desde AUR, intentando método alternativo..."
            instalar_oh_my_posh_manual
        }
    else
        # Método 2: Instalación manual
        instalar_oh_my_posh_manual
    fi

    # Configurar Oh My Posh para Bash
    if [ -f "$HOME/.bashrc" ]; then
        mensaje "Configurando Oh My Posh para Bash..."
        if ! grep -q "oh-my-posh" "$HOME/.bashrc"; then
            echo 'eval "$(oh-my-posh init bash)"' >> "$HOME/.bashrc"
            mensaje "Oh My Posh configurado para Bash."
        else
            mensaje "Oh My Posh ya estaba configurado para Bash."
        fi
    fi

    mensaje "Instalando temas de Oh My Posh..."
    # Crear directorio para temas si no existe
    mkdir -p "$HOME/.poshthemes"

    # Descargar temas
    wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O "$HOME/.poshthemes/themes.zip"
    unzip -o "$HOME/.poshthemes/themes.zip" -d "$HOME/.poshthemes"
    chmod u+rw "$HOME/.poshthemes/*.json"
    rm "$HOME/.poshthemes/themes.zip"

    # Añadir tema propio
    cp "$SCRIPT_DIR/theme/oh-my-posh/custom.omp.json" "$HOME/.poshthemes"

    # Configurar un tema predeterminado
    if [ -f "$HOME/.bashrc" ]; then
        sed -i 's/eval "$(oh-my-posh init bash)"/eval "$(oh-my-posh init bash --config ~/.poshthemes\/custom.json)"/' "$HOME/.bashrc"
    fi

    source "$HOME/.bashrc"

    mensaje "Oh My Posh instalado correctamente con el tema custom."
    mensaje "Para probar otros temas, edita tu .bashrc y cambia custom.json por otro nombre de tema."
    mensaje "Los temas están disponibles en ~/.poshthemes/"
}

instalar_oh_my_posh_manual() {
    mensaje "Instalando Oh My Posh manualmente..."

    # Determinar arquitectura
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            ARCH="amd64"
            ;;
        armv7*)
            ARCH="arm"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        *)
            error "Arquitectura no soportada: $ARCH"
            return 1
            ;;
    esac

    # Descargar e instalar Oh My Posh
    sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-$ARCH -O /usr/local/bin/oh-my-posh
    sudo chmod +x /usr/local/bin/oh-my-posh

    # Verificar instalación
    if ! command -v oh-my-posh &> /dev/null; then
        error "La instalación manual de Oh My Posh falló."
        return 1
    fi

    mensaje "Oh My Posh instalado manualmente con éxito."
    return 0
}

# Función principal
main() {
    # Preguntar al usuario si desea instalar Oh My Posh
    if [ "$USAR_WHIPTAIL" = true ]; then
        whiptail --title "Oh My Posh" --yesno "¿Deseas instalar Oh My Posh? (Un personalizador de prompt bonito para tu terminal)" 10 60
        RESPUESTA=$?

        if [ $RESPUESTA -eq 0 ]; then
            instalar_oh_my_posh
        else
            mensaje "Instalación de Oh My Posh omitida."
        fi
    else
        mensaje "¿Deseas instalar Oh My Posh? (Un personalizador de prompt bonito para tu terminal) [s/n]"
        read -r RESPUESTA
        case "$RESPUESTA" in
            [Ss]*)
                instalar_oh_my_posh
                ;;
            *)
                mensaje "Instalación de Oh My Posh omitida."
                ;;
        esac
    fi
}

# Ejecutar el script
main