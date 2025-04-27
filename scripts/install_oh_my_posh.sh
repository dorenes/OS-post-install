#!/bin/bash

# Directorio principal
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

# Verificar si yay está disponible
if command -v yay &> /dev/null; then
    USAR_AUR=true
else
    USAR_AUR=false
fi

# Función principal de instalación
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
    chmod u+rw "$HOME/.poshthemes/"*.json
    rm "$HOME/.poshthemes/themes.zip"

    # Añadir tema propio si existe
    if [ -f "$SCRIPT_DIR/theme/oh-my-posh/custom.omp.json" ]; then
        cp "$SCRIPT_DIR/theme/oh-my-posh/custom.omp.json" "$HOME/.poshthemes/"
        mensaje "Tema personalizado copiado correctamente."

        # Configurar el tema personalizado
        if [ -f "$HOME/.bashrc" ]; then
            sed -i 's/eval "$(oh-my-posh init bash)"/eval "$(oh-my-posh init bash --config ~\/.poshthemes\/custom.omp.json)"/' "$HOME/.bashrc"
        fi
    else
        # Si no hay tema personalizado, usar uno predeterminado
        mensaje "No se encontró tema personalizado, usando tema predeterminado."
        if [ -f "$HOME/.bashrc" ]; then
            sed -i 's/eval "$(oh-my-posh init bash)"/eval "$(oh-my-posh init bash --config ~\/.poshthemes\/atomic.omp.json)"/' "$HOME/.bashrc"
        fi
    fi

    mensaje "Oh My Posh instalado correctamente."
    mensaje "Los temas están disponibles en ~/.poshthemes/"

    return 0
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

# Ejecutar la instalación directamente
instalar_oh_my_posh
exit $?