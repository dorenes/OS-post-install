#!/bin/bash

# Importar funciones
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/init.sh" --functions-only

# Comprobar si yay está instalado
mensaje "Comprobando si yay está instalado..."
if ! command -v yay &> /dev/null; then
    advertencia "Yay no está instalado. Instalando yay..."

    # Asegurarnos de tener base-devel
    mensaje "Instalando dependencias necesarias..."
    sudo pacman -S --needed --noconfirm base-devel || {
        error "No se pudo instalar base-devel. Abortando."
        exit 1
    }

    # Crear directorio temporal y clonar yay
    mensaje "Clonando repositorio de yay..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || {
        error "No se pudo crear directorio temporal. Abortando."
        exit 1
    }

    git clone https://aur.archlinux.org/yay.git || {
        error "No se pudo clonar el repositorio de yay. Abortando."
        rm -rf "$TEMP_DIR"
        exit 1
    }

    cd yay || {
        error "No se pudo acceder al directorio de yay. Abortando."
        rm -rf "$TEMP_DIR"
        exit 1
    }

    mensaje "Compilando e instalando yay..."
    makepkg -si --noconfirm || {
        error "No se pudo compilar e instalar yay. Abortando."
        rm -rf "$TEMP_DIR"
        exit 1
    }

    # Limpiar directorio temporal
    cd "$HOME" || true
    rm -rf "$TEMP_DIR"

    mensaje "Yay instalado correctamente."
    exit 0
else
    mensaje "Yay ya está instalado."
    exit 0
fi
