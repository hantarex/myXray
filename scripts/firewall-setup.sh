#!/bin/bash

# Скрипт настройки файрвола для 3X-UI

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Определение системы файрвола
if command -v ufw &> /dev/null; then
    FIREWALL="ufw"
    log_info "Detected firewall: UFW"
elif command -v firewall-cmd &> /dev/null; then
    FIREWALL="firewalld"
    log_info "Detected firewall: firewalld"
else
    log_error "No supported firewall found (UFW or firewalld)"
    exit 1
fi

# Конфигурация портов
PANEL_PORT=2053
VLESS_PORT=443
VMESS_PORT=8443
TROJAN_PORT=8080
SHADOWSOCKS_PORT=9443

log_warn "This script will configure firewall rules for 3X-UI"
log_info "Ports to be opened:"
log_info "  - Panel: ${PANEL_PORT}/tcp"
log_info "  - VLESS: ${VLESS_PORT}/tcp"
log_info "  - VMess: ${VMESS_PORT}/tcp"
log_info "  - Trojan: ${TROJAN_PORT}/tcp"
log_info "  - Shadowsocks: ${SHADOWSOCKS_PORT}/tcp"

read -p "Continue? (yes/no): " CONFIRM
if [ "${CONFIRM}" != "yes" ]; then
    log_info "Cancelled."
    exit 0
fi

# Настройка UFW
if [ "${FIREWALL}" = "ufw" ]; then
    log_info "Configuring UFW..."

    # Базовая политика
    ufw default deny incoming
    ufw default allow outgoing

    # SSH (КРИТИЧНО!)
    log_warn "Enabling SSH port 22 (CRITICAL - do not lose access!)"
    ufw allow 22/tcp

    # Панель управления
    log_info "Opening panel port ${PANEL_PORT}/tcp"
    ufw allow ${PANEL_PORT}/tcp

    # VPN протоколы
    log_info "Opening VPN protocol ports..."
    ufw allow ${VLESS_PORT}/tcp
    ufw allow ${VMESS_PORT}/tcp
    ufw allow ${TROJAN_PORT}/tcp
    ufw allow ${SHADOWSOCKS_PORT}/tcp

    # Включение UFW
    log_info "Enabling UFW..."
    ufw --force enable

    # Статус
    log_info "Firewall status:"
    ufw status numbered
fi

# Настройка firewalld
if [ "${FIREWALL}" = "firewalld" ]; then
    log_info "Configuring firewalld..."

    # SSH
    firewall-cmd --permanent --add-service=ssh

    # Панель
    firewall-cmd --permanent --add-port=${PANEL_PORT}/tcp

    # VPN протоколы
    firewall-cmd --permanent --add-port=${VLESS_PORT}/tcp
    firewall-cmd --permanent --add-port=${VMESS_PORT}/tcp
    firewall-cmd --permanent --add-port=${TROJAN_PORT}/tcp
    firewall-cmd --permanent --add-port=${SHADOWSOCKS_PORT}/tcp

    # Применение правил
    firewall-cmd --reload

    # Статус
    log_info "Firewall status:"
    firewall-cmd --list-all
fi

log_info "Firewall configured successfully!"
log_warn "IMPORTANT: Make sure you can still access SSH before closing this session!"
log_info "Test SSH access from another terminal before logging out."
