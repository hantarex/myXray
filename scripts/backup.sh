#!/bin/bash

# Скрипт резервного копирования 3X-UI
# Создает полный бэкап базы данных, конфигов и сертификатов

set -e  # Выход при ошибке

# Конфигурация
PROJECT_DIR="/home/sham/PhpstormProjects/myXray"
BACKUP_DIR="${PROJECT_DIR}/backups"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
BACKUP_NAME="backup-${TIMESTAMP}.tar.gz"
RETENTION_DAYS=7  # Хранить бэкапы 7 дней

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция логирования
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка, что скрипт запущен из правильной директории
if [ ! -f "${PROJECT_DIR}/docker-compose.yml" ]; then
    log_error "docker-compose.yml not found in ${PROJECT_DIR}"
    log_error "Please run this script from the project directory"
    exit 1
fi

# Создание директории для бэкапов
mkdir -p "${BACKUP_DIR}"

log_info "Starting backup process..."
log_info "Backup will be saved to: ${BACKUP_DIR}/${BACKUP_NAME}"

# Создание временной директории
TEMP_DIR=$(mktemp -d)
log_info "Using temporary directory: ${TEMP_DIR}"

# Копирование файлов для бэкапа
log_info "Copying data directory..."
if [ -d "${PROJECT_DIR}/data" ]; then
    cp -r "${PROJECT_DIR}/data" "${TEMP_DIR}/"
else
    log_warn "data directory not found"
fi

log_info "Copying configuration files..."
cp "${PROJECT_DIR}/docker-compose.yml" "${TEMP_DIR}/" 2>/dev/null || log_warn "docker-compose.yml not found"
cp "${PROJECT_DIR}/.env" "${TEMP_DIR}/" 2>/dev/null || log_warn ".env not found"

# Информация о версии
log_info "Saving version information..."
cat > "${TEMP_DIR}/backup-info.txt" << EOF
Backup created: ${TIMESTAMP}
Project directory: ${PROJECT_DIR}
Docker Compose version: $(docker-compose --version 2>/dev/null || echo "unknown")
Hostname: $(hostname)
EOF

# Создание архива
log_info "Creating archive..."
cd "${TEMP_DIR}"
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}" .
cd - > /dev/null

# Очистка временной директории
rm -rf "${TEMP_DIR}"

# Проверка размера бэкапа
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}" | cut -f1)
log_info "Backup created successfully: ${BACKUP_NAME} (${BACKUP_SIZE})"

# Удаление старых бэкапов
log_info "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
find "${BACKUP_DIR}" -name "backup-*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
REMAINING_BACKUPS=$(ls -1 "${BACKUP_DIR}"/backup-*.tar.gz 2>/dev/null | wc -l)
log_info "Remaining backups: ${REMAINING_BACKUPS}"

# Список всех бэкапов
log_info "Available backups:"
ls -lh "${BACKUP_DIR}"/backup-*.tar.gz 2>/dev/null || log_warn "No backups found"

log_info "Backup completed successfully!"
