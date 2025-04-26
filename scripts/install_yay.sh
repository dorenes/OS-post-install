#!/bin/bash

# Llamar al script para verificar e instalar yay si es necesario
./install_yay.sh

# Mostrar el menú con whiptail
OPTIONS=$(whiptail --title "Selecciona las opciones" --checklist \
"Selecciona las opciones:" 20 60 10 \
1 "VSCode" OFF \
2 "IntelliJ IDEA" OFF \
3 "Sublime Text" OFF \
4 "Postman" OFF \
5 "SDKman" OFF \
6 "nvm" OFF \
7 "Salir" OFF 3>&1 1>&2 2>&3)

clear  # Limpiar pantalla después del diálogo

# Comprobar si el usuario canceló
if [ -z "$OPTIONS" ]; then
    echo "No seleccionaste ninguna opción o cancelaste."
    exit
fi

# Usar IFS para separar las opciones seleccionadas
IFS=$'\n'   # Establecer el separador de campo como nueva línea
for opcion in $OPTIONS; do
    # Eliminar las comillas dobles alrededor de las opciones
    opcion=$(echo $opcion | tr -d '"')

    # Procesar las opciones seleccionadas
    case $opcion in
        1)
            echo "Instalando VSCode..."
            yay -S visual-studio-code-bin
            ;;
        2)
            echo "Instalando IntelliJ IDEA..."
            yay -S intellij-idea-community-edition
            ;;
        3)
            echo "Instalando Sublime Text..."
            yay -S sublime-text
            ;;
        4)
            echo "Instalando Postman..."
            yay -S postman
            ;;
        5)
            echo "Instalando SDKman..."
            yay -S sdkman
            ;;
        6)
            echo "Instalando nvm..."
            yay -S nvm
            ;;
        7)
            echo "Saliendo... ¡Hasta luego!"
            exit 0
            ;;
        *)
            echo "Opción desconocida: $opcion"
            ;;
    esac
    echo ""  # Línea en blanco entre outputs
done
