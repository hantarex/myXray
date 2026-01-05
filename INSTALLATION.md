# Подробная инструкция по установке

## Предварительные требования

### 1. Установка Docker

**Ubuntu/Debian:**

```bash
# Удаление старых версий
sudo apt remove docker docker-engine docker.io containerd runc

# Установка зависимостей
sudo apt update
sudo apt install ca-certificates curl gnupg lsb-release -y

# Добавление официального GPG ключа Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Добавление репозитория
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# Проверка
docker --version
```

**CentOS/RHEL:**

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. Установка Docker Compose (если не установлен)

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

## Пошаговая установка 3X-UI

### Шаг 1: Подготовка системы

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
# или
sudo yum update -y  # CentOS/RHEL

# Установка необходимых утилит
sudo apt install git curl wget nano -y
```

### Шаг 2: Настройка проекта

```bash
# Переход в директорию проекта
cd /home/sham/PhpstormProjects/myXray

# Настройка переменных окружения
cp .env.example .env
nano .env
```

**Важные параметры в .env**:

- `PANEL_PASSWORD`: Установите СИЛЬНЫЙ пароль (минимум 20 символов)
- `DOMAIN`: Ваш домен (если есть)
- `EMAIL`: Email для Let's Encrypt (если будете использовать SSL)

### Шаг 3: Настройка файрвола

**UFW (Ubuntu/Debian):**

```bash
# Включение UFW
sudo ufw enable

# Разрешение SSH (ВАЖНО! Сначала SSH, иначе потеряете доступ)
sudo ufw allow 22/tcp

# Разрешение портов для 3X-UI
sudo ufw allow 2053/tcp  # Панель управления
sudo ufw allow 443/tcp   # VLESS
sudo ufw allow 8443/tcp  # VMess
sudo ufw allow 8080/tcp  # Trojan
sudo ufw allow 9443/tcp  # Shadowsocks

# Или используйте скрипт
sudo ./scripts/firewall-setup.sh

# Проверка правил
sudo ufw status
```

**Firewalld (CentOS/RHEL):**

```bash
sudo firewall-cmd --permanent --add-port=2053/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=9443/tcp
sudo firewall-cmd --reload
```

### Шаг 4: Запуск контейнера

```bash
# Запуск в фоновом режиме
docker-compose up -d

# Проверка статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f 3x-ui
```

Ожидайте вывод:

```
3x-ui    | x-ui started successfully
3x-ui    | Panel port: 2053
3x-ui    | Panel username: admin
3x-ui    | Panel password: admin
```

### Шаг 5: Первый вход в панель

1. Откройте браузер и перейдите: `http://ВАШ_IP:2053`
2. Войдите с дефолтными учетными данными:
   - Username: `admin`
   - Password: `admin`

⚠️ **СРАЗУ ПОСЛЕ ВХОДА ИЗМЕНИТЕ ПАРОЛЬ!**

### Шаг 6: Базовая настройка панели

1. **Изменение пароля**:
   - Settings → Panel Settings
   - Panel Username: (оставьте или измените)
   - Panel Password: (установите сильный пароль)
   - Save

2. **Настройка панели**:
   - Panel Port: 2053 (или измените)
   - Panel Path: `/` (или добавьте секретный путь, например `/secret-admin`)
   - Time Zone: Europe/Moscow
   - Save & Restart Panel

3. **Включение автообновления базы**:
   - Settings → Xray Settings
   - Enable Auto Update: ON
   - Update Interval: 24 (часов)

### Шаг 7: Добавление первого пользователя (Inbound)

1. Перейдите в **Inbounds**
2. Нажмите **Add Inbound**
3. Заполните параметры:

**Для VLESS (рекомендуется)**:

```
Remark: VLESS-TCP-XTLS
Protocol: VLESS
Listen IP: 0.0.0.0
Port: 443
Total Flow (GB): 100 (или 0 для безлимита)
Expiry Time: 30 (дней)
Client:
  - UUID: (сгенерируется автоматически)
  - Email: user@example.com
  - Flow: xtls-rprx-vision (для лучшей производительности)
Stream Settings:
  - Network: TCP
  - Security: Reality или TLS
```

4. **Save**

5. После создания нажмите на QR-код или ссылку для подключения

## Настройка SSL/TLS (опционально)

### Автоматическая установка через acme.sh (рекомендуется)

Для автоматической установки и настройки SSL сертификатов используйте наш скрипт:

1. **Настройте DNS:** убедитесь что ваш домен указывает на IP сервера
   ```bash
   nslookup your-domain.com  # Должен показать IP вашего сервера
   ```

2. **Настройте `.env`:** откройте `.env` и укажите DOMAIN и EMAIL
   ```bash
   nano .env
   # Заполните:
   # DOMAIN=your-domain.com
   # EMAIL=your-email@example.com
   ```

3. **Запустите скрипт установки:**
   ```bash
   sudo ./scripts/setup-ssl.sh
   ```

4. **Следуйте инструкциям** для включения HTTPS в панели

**Подробная документация:** [SSL.md](./SSL.md)

### Вариант 2: Встроенная функция 3X-UI

3X-UI имеет встроенную поддержку Let's Encrypt:

1. Settings → Certificate Management
2. Domain: введите ваш домен
3. Email: введите email
4. Apply Certificate (автоматически)

### Вариант 3: Собственный сертификат

Разместите сертификаты в `data/cert/`:

```bash
data/cert/
  ├── fullchain.pem  # Полная цепочка сертификатов
  └── privkey.pem    # Приватный ключ
```

Затем в настройках Inbound укажите пути к сертификатам.

## Проверка работоспособности

### 1. Проверка контейнера

```bash
# Статус контейнера
docker-compose ps

# Должен быть Up
# NAME      COMMAND     SERVICE   STATUS    PORTS
# 3x-ui     ...         3x-ui     Up

# Логи
docker-compose logs --tail=50 3x-ui
```

### 2. Проверка портов

```bash
# Проверка, что порты слушаются
sudo netstat -tulpn | grep -E '(2053|443|8443|8080|9443)'

# Или
sudo ss -tulpn | grep -E '(2053|443|8443|8080|9443)'
```

### 3. Проверка подключения

- Используйте клиент (v2rayN для Windows, v2rayNG для Android, etc.)
- Импортируйте конфигурацию через QR-код или ссылку
- Попробуйте подключиться
- Проверьте IP: https://2ip.ru

## Обслуживание

### Резервное копирование

```bash
# Создание бэкапа
./scripts/backup.sh

# Бэкапы сохраняются в ./backups/
# Формат: backup-YYYY-MM-DD-HHMMSS.tar.gz
```

### Восстановление

```bash
# Остановка контейнера
docker-compose down

# Восстановление
./scripts/restore.sh backups/backup-2025-12-25-120000.tar.gz

# Запуск
docker-compose up -d
```

### Обновление

```bash
# Создание бэкапа перед обновлением
./scripts/backup.sh

# Скачивание новых образов
docker-compose pull

# Пересоздание контейнеров
docker-compose up -d

# Проверка
docker-compose logs -f
```

## Клиенты для подключения

### Windows

- **v2rayN**: https://github.com/2dust/v2rayN/releases

### Android

- **v2rayNG**: https://play.google.com/store/apps/details?id=com.v2ray.ang
- **SagerNet**: https://github.com/SagerNet/SagerNet/releases

### iOS

- **Shadowrocket**: App Store (платный)
- **Streisand**: App Store (бесплатный)

### macOS

- **V2rayU**: https://github.com/yanue/V2rayU/releases
- **Qv2ray**: https://github.com/Qv2ray/Qv2ray/releases

### Linux

- **v2ray**: https://github.com/v2ray/v2ray-core/releases
- **Qv2ray**: https://github.com/Qv2ray/Qv2ray/releases

## Что дальше?

- Изучите [SECURITY.md](./SECURITY.md) для повышения безопасности
- Настройте регулярные бэкапы через cron
- Изучите различные протоколы в [docs/protocols/](./docs/protocols/)
- Настройте мониторинг трафика в панели

## Полезные команды

```bash
# Просмотр всех контейнеров
docker ps -a

# Просмотр использования ресурсов
docker stats

# Вход в контейнер
docker exec -it 3x-ui bash

# Просмотр логов с фильтром
docker-compose logs 3x-ui | grep error

# Перезапуск только одного сервиса
docker-compose restart 3x-ui

# Остановка и удаление всех контейнеров
docker-compose down -v
```
