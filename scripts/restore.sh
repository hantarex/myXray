#!/bin/bash

# Скрипт восстановления 3X-UI из бэкапа

set -e

# Конфигурация
PROJECT_DIR="/home/sham/PhpstormProjects/myXray"

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

# Проверка аргументов
if [ $# -ne 1 ]; then
    log_error "Usage: $0 <backup-file.tar.gz>"
    log_info "Example: $0 backups/backup-2025-12-25-120000.tar.gz"
    exit 1
fi

BACKUP_FILE="$1"

# Проверка существования бэкапа
if [ ! -f "${BACKUP_FILE}" ]; then
    log_error "Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

log_warn "WARNING: This will restore data from backup and OVERWRITE current data!"
log_info "Backup file: ${BACKUP_FILE}"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
    log_info "Restore cancelled."
    exit 0
fi

# Остановка контейнера
log_info "Stopping container..."
cd "${PROJECT_DIR}"
docker-compose down

# Создание бэкапа текущего состояния
log_info "Creating backup of current state..."
SAFETY_BACKUP="backups/pre-restore-$(date +%Y-%m-%d-%H%M%S).tar.gz"
mkdir -p backups
tar -czf "${SAFETY_BACKUP}" data/ .env docker-compose.yml 2>/dev/null || true
log_info "Safety backup created: ${SAFETY_BACKUP}"

# Создание временной директории
TEMP_DIR=$(mktemp -d)
log_info "Extracting backup to: ${TEMP_DIR}"

# Распаковка бэкапа
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# Восстановление данных
log_info "Restoring data directory..."
rm -rf "${PROJECT_DIR}/data"
if [ -d "${TEMP_DIR}/data" ]; then
    mv "${TEMP_DIR}/data" "${PROJECT_DIR}/"
else
    log_warn "data directory not found in backup"
    mkdir -p "${PROJECT_DIR}/data"
fi

# Восстановление конфигов (опционально)
if [ -f "${TEMP_DIR}/.env" ]; then
    log_info "Restoring .env file..."
    cp "${TEMP_DIR}/.env" "${PROJECT_DIR}/"
fi

if [ -f "${TEMP_DIR}/docker-compose.yml" ]; then
    log_info "Restoring docker-compose.yml..."
    cp "${TEMP_DIR}/docker-compose.yml" "${PROJECT_DIR}/"
fi

# Очистка
rm -rf "${TEMP_DIR}"

# Установка правильных прав
chmod 700 "${PROJECT_DIR}/data"

# Запуск контейнера
log_info "Starting container..."
docker-compose up -d

# Ожидание запуска
log_info "Waiting for container to start..."
sleep 5

# Проверка статуса
docker-compose ps

log_info "Restore completed successfully!"
log_info "Safety backup saved to: ${SAFETY_BACKUP}"
log_warn "If something went wrong, you can restore from safety backup:"
log_warn "$0 ${SAFETY_BACKUP}"
