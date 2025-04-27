#!/bin/bash

# Importar funciones
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/init.sh" --functions-only

# Comprobar si whiptail está instalado
mensaje "Comprobando si whiptail está instalado..."
if ! command -v whiptail &> /dev/null; then
    advertencia "Whiptail no está instalado. Instalando whiptail..."
    sudo pacman -S --noconfirm libnewt || {
        error "No se pudo instalar whiptail. El script continuará en modo texto."
        exit 1
    }
    mensaje "Whiptail instalado correctamente."
    exit 0
else
    mensaje "Whiptail ya está instalado."
    exit 0
fi
