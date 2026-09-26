#!/bin/bash
set -e
echo "=== Instalador e1000e con bypass NVM checksum ==="

# Dependencias
apt-get install -y dkms build-essential linux-headers-$(uname -r) 2>/dev/null || \
apt-get install -y dkms build-essential pve-headers-$(uname -r) 2>/dev/null

# Copiar source al lugar correcto
SRCDIR="$(cd "$(dirname "$0")" && pwd)"
cp -r "$SRCDIR" /usr/src/e1000e-3.8.7 2>/dev/null || true

# Registrar, compilar e instalar
dkms add e1000e/3.8.7 2>/dev/null || true
dkms build e1000e/3.8.7
dkms install e1000e/3.8.7

# Cargar el módulo
modprobe -r e1000e 2>/dev/null || true
modprobe e1000e

# Verificar
sleep 2
if dmesg | grep -q "NIC Link is Up"; then
    echo ""
    echo "✓ NIC funcionando correctamente"
    dmesg | grep e1000e | tail -5
else
    echo ""
    echo "Módulo instalado. Verificá con: dmesg | grep e1000e"
fi
