#!/bin/bash
# Importar funciones comunes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/init.sh" --functions-only

mensaje "Instalando SDKMAN..."
curl -s "https://get.sdkman.io" | bash

# Agregar al .bashrc si no está ya
if ! grep -q "sdkman-init.sh" ~/.bashrc; then
    echo 'source "$HOME/.sdkman/bin/sdkman-init.sh"' >> ~/.bashrc
    mensaje "SDKMAN configurado en .bashrc"
fi