#!/bin/bash
# Importar funciones comunes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/init.sh" --functions-only

mensaje "Instalando Docker..."
if ! pacman -Qi docker &> /dev/null; then
    sudo pacman -S --noconfirm docker
else
    mensaje "Docker ya está instalado."
fi

# Configurar Docker para que se inicie con el sistema
sudo systemctl enable docker.service
sudo systemctl start docker.service

# Añadir usuario actual al grupo docker
sudo usermod -aG docker $USER
mensaje "Para usar Docker sin sudo, tendrás que cerrar sesión y volver a iniciarla"