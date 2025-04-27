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

# Función para mostrar mensajes
mostrar_mensaje() {
    if [ "$USAR_WHIPTAIL" = true ]; then
        whiptail --title "Chaotic AUR" --msgbox "$1" 10 70
    else
        mensaje "$1"
    fi
}

# Función para preguntar sí/no
preguntar() {
    if [ "$USAR_WHIPTAIL" = true ]; then
        whiptail --title "Chaotic AUR" --yesno "$1" 10 70
        return $?
    else
        mensaje "$1 [s/n]"
        read -r RESPUESTA
        case "$RESPUESTA" in
            [Ss]*)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi
}

# Función para editar pacman.conf
editar_pacman_conf() {
    mensaje "Comprobando si Chaotic AUR ya está configurado en pacman.conf..."

    if grep -q "chaotic-aur" /etc/pacman.conf; then
        mostrar_mensaje "Chaotic AUR ya está configurado en pacman.conf"
        return 0
    fi

    # Crear archivo temporal con los cambios
    TEMP_FILE=$(mktemp)

    # Verificar si hay una sección [multilib]
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        mensaje "Se encontró sección [multilib]. Añadiendo Chaotic AUR después de ella..."
        # Añadir Chaotic AUR después de la sección multilib
        awk '/^\[multilib\]/{p=1} /^$/{if(p==1) {print "\n# Chaotic AUR\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist"; p=0}} {print}' /etc/pacman.conf > "$TEMP_FILE"
    else
        mensaje "No se encontró sección [multilib]. Añadiendo Chaotic AUR al final del archivo..."
        # Añadir al final del archivo
        cp /etc/pacman.conf "$TEMP_FILE"
        echo -e "\n# Chaotic AUR\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> "$TEMP_FILE"
    fi

    # Mostrar diferencias
    if command -v diff &> /dev/null; then
        mensaje "Cambios que se realizarán en pacman.conf:"
        diff /etc/pacman.conf "$TEMP_FILE" || true
    fi

    # Confirmar cambios
    if preguntar "¿Deseas aplicar estos cambios a /etc/pacman.conf?"; then
        mensaje "Aplicando cambios a pacman.conf..."
        sudo cp "$TEMP_FILE" /etc/pacman.conf
        sudo chmod 644 /etc/pacman.conf
        mensaje "Cambios aplicados correctamente a pacman.conf"
    else
        mensaje "Cambios no aplicados a pacman.conf"
        rm "$TEMP_FILE"
        return 1
    fi

    # Limpiar
    rm "$TEMP_FILE"
    return 0
}

# Función principal para instalar Chaotic AUR
instalar_chaotic_aur() {
    mensaje "Verificando requisitos para Chaotic AUR..."

    # Verificar si pacman-key está disponible
    if ! command -v pacman-key &> /dev/null; then
        error "pacman-key no está disponible. Asegúrate de tener instalado archlinux-keyring."
        if preguntar "¿Deseas instalar archlinux-keyring?"; then
            sudo pacman -S --noconfirm archlinux-keyring || {
                error "No se pudo instalar archlinux-keyring. Abortando."
                return 1
            }
        else
            return 1
        fi
    fi

    mensaje "Instalando llave de Chaotic AUR..."

    # Descargar e instalar la llave
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || {
        error "Error al recibir la llave. Intentando método alternativo..."
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver hkp://keyserver.ubuntu.com:80 || {
            error "No se pudo recibir la llave. Abortando."
            return 1
        }
    }

    sudo pacman-key --lsign-key 3056513887B78AEB || {
        error "No se pudo firmar la llave. Abortando."
        return 1
    }

    # Instalar el keyring de Chaotic AUR
    if [ -f "/etc/pacman.d/chaotic-mirrorlist" ]; then
        mensaje "El archivo chaotic-mirrorlist ya existe."
    else
        # Verificar si wget está instalado
        if ! command -v wget &> /dev/null; then
            mensaje "Instalando wget primero..."
            sudo pacman -S --noconfirm wget || {
                error "No se pudo instalar wget. Abortando."
                return 1
            }
        fi

        # Descargar mirrorlist
        mensaje "Descargando mirrorlist de Chaotic AUR..."
        sudo wget -q "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst" -O "/tmp/chaotic-mirrorlist.pkg.tar.zst" || {
            error "No se pudo descargar el mirrorlist. Abortando."
            return 1
        }

        sudo pacman -U --noconfirm "/tmp/chaotic-mirrorlist.pkg.tar.zst" || {
            error "No se pudo instalar el mirrorlist. Abortando."
            return 1
        }

        # Limpiar
        rm -f "/tmp/chaotic-mirrorlist.pkg.tar.zst"
    }

    # Modificar pacman.conf
    if editar_pacman_conf; then
        mensaje "Actualizando base de datos de pacman..."
        sudo pacman -Sy || {
            error "Error al actualizar la base de datos de pacman."
            return 1
        }

        mostrar_mensaje "Chaotic AUR instalado y configurado correctamente.\n\nAhora puedes instalar paquetes de Chaotic AUR con:\nsudo pacman -S nombre-paquete"
        return 0
    else
        advertencia "Se ha instalado la llave de Chaotic AUR pero no se ha modificado pacman.conf."
        return 1
    fi
}

# Función principal
main() {
    # Preguntar al usuario si desea instalar Chaotic AUR
    if preguntar "¿Deseas instalar y configurar Chaotic AUR? (Un repositorio no oficial con más paquetes precompilados)"; then
        instalar_chaotic_aur
    else
        mensaje "Instalación de Chaotic AUR omitida."
    fi
}

# Verificar si se ejecuta como root
if [ "$(id -u)" -eq 0 ]; then
    error "Este script no debe ejecutarse como root/sudo."
    exit 1
fi

# Ejecutar el script
main