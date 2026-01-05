#!/bin/bash

# Скрипт автоматической установки SSL сертификатов для 3X-UI через acme.sh
# Использует Let's Encrypt и standalone режим

set -e  # Выход при ошибке

# === Конфигурация ===
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERT_DIR="${PROJECT_DIR}/data/cert"
LOG_FILE="${PROJECT_DIR}/ssl-setup.log"
ENV_FILE="${PROJECT_DIR}/.env"
ACME_HOME="${HOME}/.acme.sh"
ACME_BIN="${ACME_HOME}/acme.sh"

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === Функции логирования ===
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1" | tee -a "$LOG_FILE"
}

# === Функция проверки root ===
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Этот скрипт должен быть запущен с правами root"
        log_info "Используйте: sudo $0"
        exit 1
    fi
    log_info "Проверка root прав: OK"
}

# === Функция проверки зависимостей ===
check_dependencies() {
    log_step "Проверка зависимостей..."

    local missing_deps=()

    # Проверка docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi

    # Проверка docker compose
    if ! command -v docker &> /dev/null && ! docker compose version &> /dev/null; then
        missing_deps+=("docker compose")
    fi

    # Проверка curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Отсутствуют зависимости: ${missing_deps[*]}"
        log_info "Установите их перед запуском скрипта"
        exit 1
    fi

    log_info "Все зависимости установлены: OK"
}

# === Функция проверки .env файла ===
check_env_file() {
    log_step "Проверка .env файла..."

    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env файл не найден: $ENV_FILE"
        log_info "Скопируйте .env.example в .env и заполните DOMAIN и EMAIL"
        exit 1
    fi

    log_info ".env файл найден: OK"
}

# === Функция загрузки переменных окружения ===
load_env_vars() {
    log_step "Загрузка переменных окружения..."

    # Загрузка .env
    set -a
    source "$ENV_FILE"
    set +a

    # Проверка DOMAIN
    if [ -z "$DOMAIN" ] || [ "$DOMAIN" = "your-domain.com" ]; then
        log_error "DOMAIN не настроен в .env файле"
        log_info "Откройте $ENV_FILE и укажите ваш домен"
        exit 1
    fi

    # Проверка EMAIL
    if [ -z "$EMAIL" ] || [ "$EMAIL" = "your-email@example.com" ]; then
        log_error "EMAIL не настроен в .env файле"
        log_info "Откройте $ENV_FILE и укажите ваш email"
        exit 1
    fi

    log_info "DOMAIN: $DOMAIN"
    log_info "EMAIL: $EMAIL"
    log_info "Переменные окружения загружены: OK"
}

# === Функция проверки DNS ===
check_dns() {
    log_step "Проверка DNS настроек..."

    # Получаем внешний IP сервера
    local server_ip
    server_ip=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null)

    if [ -z "$server_ip" ]; then
        log_warn "Не удалось определить внешний IP сервера"
        log_warn "Пропускаем проверку DNS"
        return 0
    fi

    log_info "IP сервера: $server_ip"

    # Проверяем DNS
    local domain_ip
    if command -v dig &> /dev/null; then
        domain_ip=$(dig +short "$DOMAIN" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)
    elif command -v nslookup &> /dev/null; then
        domain_ip=$(nslookup "$DOMAIN" | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)
    else
        log_warn "dig и nslookup не найдены. Пропускаем проверку DNS"
        return 0
    fi

    if [ -z "$domain_ip" ]; then
        log_error "Не удалось разрешить домен $DOMAIN"
        log_info "Убедитесь, что DNS A-запись настроена правильно"
        exit 1
    fi

    log_info "IP домена: $domain_ip"

    if [ "$server_ip" != "$domain_ip" ]; then
        log_error "Домен $DOMAIN указывает на $domain_ip, но сервер имеет IP $server_ip"
        log_info "Обновите DNS A-запись, чтобы домен указывал на этот сервер"
        exit 1
    fi

    log_info "DNS настройки корректны: OK"
}

# === Функция установки acme.sh ===
install_acme_sh() {
    if [ -f "$ACME_BIN" ]; then
        log_info "acme.sh уже установлен"
        return 0
    fi

    log_step "Установка acme.sh..."

    curl -s https://get.acme.sh | sh -s email="$EMAIL" 2>&1 | tee -a "$LOG_FILE"

    if [ ! -f "$ACME_BIN" ]; then
        log_error "Не удалось установить acme.sh"
        exit 1
    fi

    log_info "acme.sh установлен: OK"
}

# === Функция определения firewall ===
detect_firewall() {
    if command -v ufw &> /dev/null && ufw status &> /dev/null; then
        echo "ufw"
    elif command -v firewall-cmd &> /dev/null && systemctl is-active firewalld &> /dev/null; then
        echo "firewalld"
    else
        echo "none"
    fi
}

# === Функция открытия порта 80 ===
configure_firewall() {
    log_step "Настройка firewall..."

    local fw_type
    fw_type=$(detect_firewall)

    case "$fw_type" in
        ufw)
            log_info "Обнаружен UFW"
            if ufw status | grep -q "80/tcp.*ALLOW"; then
                log_info "Порт 80 уже открыт"
            else
                log_info "Открываем порт 80..."
                ufw allow 80/tcp comment "ACME verification" | tee -a "$LOG_FILE"
                log_info "Порт 80 открыт: OK"
            fi
            ;;
        firewalld)
            log_info "Обнаружен firewalld"
            if firewall-cmd --list-ports | grep -q "80/tcp"; then
                log_info "Порт 80 уже открыт"
            else
                log_info "Открываем порт 80..."
                firewall-cmd --permanent --add-port=80/tcp | tee -a "$LOG_FILE"
                firewall-cmd --reload | tee -a "$LOG_FILE"
                log_info "Порт 80 открыт: OK"
            fi
            ;;
        none)
            log_warn "Firewall не обнаружен или не активен"
            log_warn "Убедитесь, что порт 80 открыт вручную"
            ;;
    esac
}

# === Функция остановки контейнера ===
stop_container() {
    log_step "Остановка контейнера 3x-ui..."

    cd "$PROJECT_DIR"

    if docker compose ps | grep -q "3x-ui.*Up"; then
        docker compose stop 3x-ui 2>&1 | tee -a "$LOG_FILE"
        log_info "Контейнер остановлен: OK"
    else
        log_info "Контейнер уже остановлен"
    fi
}

# === Функция запуска контейнера ===
start_container() {
    log_step "Запуск контейнера 3x-ui..."

    cd "$PROJECT_DIR"
    docker compose start 3x-ui 2>&1 | tee -a "$LOG_FILE"

    log_info "Контейнер запущен: OK"
}

# === Функция получения сертификата ===
obtain_certificate() {
    log_step "Получение SSL сертификата от Let's Encrypt..."

    # Проверяем, не существует ли уже сертификат
    if "$ACME_BIN" --list | grep -q "$DOMAIN"; then
        log_info "Сертификат для $DOMAIN уже существует"
        log_info "Обновляем существующий сертификат..."
        "$ACME_BIN" --renew -d "$DOMAIN" --force 2>&1 | tee -a "$LOG_FILE" || {
            log_warn "Не удалось обновить. Пробуем получить новый..."
        }
    fi

    # Получаем сертификат через standalone режим
    log_info "Запрос сертификата для домена: $DOMAIN"
    "$ACME_BIN" --issue --standalone -d "$DOMAIN" --force 2>&1 | tee -a "$LOG_FILE" || {
        log_error "Не удалось получить сертификат"
        log_info "Проверьте логи: $LOG_FILE"
        log_info "Убедитесь, что порт 80 доступен извне"
        start_container  # Rollback
        exit 1
    }

    log_info "Сертификат получен: OK"
}

# === Функция установки сертификата ===
install_certificate() {
    log_step "Установка сертификата в $CERT_DIR..."

    # Создаём директорию если не существует
    mkdir -p "$CERT_DIR"

    # Устанавливаем сертификат с auto-renewal
    "$ACME_BIN" --install-cert -d "$DOMAIN" --server letsencrypt \
        --key-file "${CERT_DIR}/privkey.pem" \
        --fullchain-file "${CERT_DIR}/fullchain.pem" \
        --reloadcmd "cd $PROJECT_DIR && docker compose restart 3x-ui" \
        2>&1 | tee -a "$LOG_FILE"

    if [ ! -f "${CERT_DIR}/privkey.pem" ] || [ ! -f "${CERT_DIR}/fullchain.pem" ]; then
        log_error "Сертификаты не были скопированы в $CERT_DIR"
        start_container  # Rollback
        exit 1
    fi

    # Настройка прав доступа
    chmod 644 "${CERT_DIR}/fullchain.pem"
    chmod 600 "${CERT_DIR}/privkey.pem"

    log_info "Сертификаты установлены: OK"
    log_info "  - Приватный ключ: ${CERT_DIR}/privkey.pem"
    log_info "  - Полная цепочка: ${CERT_DIR}/fullchain.pem"
}

# === Функция проверки сертификатов ===
verify_certificates() {
    log_step "Проверка установленных сертификатов..."

    if [ ! -f "${CERT_DIR}/privkey.pem" ]; then
        log_error "Приватный ключ не найден: ${CERT_DIR}/privkey.pem"
        return 1
    fi

    if [ ! -f "${CERT_DIR}/fullchain.pem" ]; then
        log_error "Цепочка сертификатов не найдена: ${CERT_DIR}/fullchain.pem"
        return 1
    fi

    # Проверка что файлы не пустые
    if [ ! -s "${CERT_DIR}/privkey.pem" ]; then
        log_error "Приватный ключ пустой"
        return 1
    fi

    if [ ! -s "${CERT_DIR}/fullchain.pem" ]; then
        log_error "Цепочка сертификатов пустая"
        return 1
    fi

    log_info "Сертификаты проверены: OK"

    # Показываем информацию о сертификате
    local expiry_date
    expiry_date=$(openssl x509 -in "${CERT_DIR}/fullchain.pem" -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -n "$expiry_date" ]; then
        log_info "Срок действия сертификата: $expiry_date"
    fi

    return 0
}

# === Функция проверки cron ===
check_cron() {
    log_step "Проверка автоматического обновления..."

    if crontab -l 2>/dev/null | grep -q "acme.sh"; then
        log_info "Cron задача для auto-renewal настроена: OK"
    else
        log_warn "Cron задача не найдена"
        log_info "Устанавливаем cron задачу..."
        "$ACME_BIN" --install-cronjob 2>&1 | tee -a "$LOG_FILE"
    fi

    # Показываем информацию об обновлении
    log_info "Сертификаты будут автоматически обновляться acme.sh"
    log_info "Проверка обновлений: ежедневно"
    log_info "Обновление происходит за 60 дней до истечения"
}

# === Функция вывода инструкций ===
print_instructions() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  SSL Сертификаты успешно установлены!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    log_info "Следующие шаги:"
    echo ""
    echo -e "${YELLOW}1. Откройте админ-панель 3X-UI:${NC}"
    echo -e "   http://$DOMAIN:2053"
    echo ""
    echo -e "${YELLOW}2. Войдите с учётными данными из .env${NC}"
    echo ""
    echo -e "${YELLOW}3. Перейдите в: Panel Settings${NC}"
    echo ""
    echo -e "${YELLOW}4. В секции 'Panel Certificate' укажите:${NC}"
    echo -e "   Public Key Path:  /root/cert/fullchain.pem"
    echo -e "   Private Key Path: /root/cert/privkey.pem"
    echo ""
    echo -e "${YELLOW}5. Включите 'Certificate Path Effective' или 'Use HTTPS'${NC}"
    echo ""
    echo -e "${YELLOW}6. Сохраните и перезапустите панель${NC}"
    echo ""
    echo -e "${YELLOW}7. Откройте панель через HTTPS:${NC}"
    echo -e "   https://$DOMAIN:2053"
    echo ""
    echo -e "${GREEN}Дополнительная информация:${NC}"
    echo -e "  - Логи установки: $LOG_FILE"
    echo -e "  - Директория сертификатов: $CERT_DIR"
    echo -e "  - Подробная документация: ${PROJECT_DIR}/SSL.md"
    echo -e "  - Логи acme.sh: ~/.acme.sh/acme.sh.log"
    echo ""
    echo -e "${GREEN}Автообновление:${NC}"
    echo -e "  Сертификаты будут автоматически обновляться за 60 дней до истечения"
    echo -e "  Проверить статус: $ACME_BIN --info -d $DOMAIN"
    echo ""
}

# === Главная функция ===
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Установка SSL для 3X-UI через acme.sh${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Инициализация лог-файла
    echo "=== SSL Setup Log $(date) ===" > "$LOG_FILE"

    # Выполнение всех проверок и установки
    check_root
    check_dependencies
    check_env_file
    load_env_vars
    check_dns
    install_acme_sh
    configure_firewall
    stop_container

    # Основная часть установки
    if obtain_certificate && install_certificate; then
        start_container
        verify_certificates
        check_cron
        print_instructions

        log_info "Установка завершена успешно!"
        exit 0
    else
        log_error "Установка не удалась"
        start_container  # Rollback
        exit 1
    fi
}

# Запуск
main "$@"
