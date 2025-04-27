#!/bin/bash

# Importar funciones
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/init.sh" --functions-only

# Comprobar si git está instalado
mensaje "Comprobando si git está instalado..."
if ! command -v git &> /dev/null; then
    advertencia "Git no está instalado. Instalando git..."
    sudo pacman -S --noconfirm git || {
        error "No se pudo instalar git. Abortando."
        exit 1
    }
    mensaje "Git instalado correctamente."
    exit 0
else
    mensaje "Git ya está instalado."
    exit 0
fi
