# Решение проблем (Troubleshooting)

## Проблемы с установкой

### Docker не устанавливается

**Симптомы:** Ошибки при установке Docker

**Решение:**

```bash
# Проверка версии ОС
lsb_release -a

# Для Ubuntu < 20.04 или Debian < 10 нужны другие инструкции
# См. официальную документацию: https://docs.docker.com/engine/install/
```

### Docker Compose command not found

**Симптомы:** `docker-compose: command not found`

**Решение:**

```bash
# Проверка установки
which docker-compose

# Если не установлен:
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Или используйте docker compose (v2, встроенный плагин):
docker compose version
```

## Проблемы с запуском контейнера

### Контейнер не запускается

**Симптомы:** `docker-compose ps` показывает статус `Exited` или `Restarting`

**Диагностика:**

```bash
# Проверка логов
docker-compose logs 3x-ui

# Проверка статуса
docker-compose ps
```

**Возможные причины и решения:**

#### 1. Порт уже занят

**Лог:** `Error starting userland proxy: listen tcp 0.0.0.0:2053: bind: address already in use`

```bash
# Проверка, что занимает порт
sudo netstat -tulpn | grep 2053
# или
sudo ss -tulpn | grep 2053

# Убить процесс (замените PID на реальный)
sudo kill -9 PID

# Или измените порт в docker-compose.yml
```

#### 2. Недостаточно прав доступа

**Лог:** `Permission denied`

```bash
# Добавление пользователя в группу docker
sudo usermod -aG docker $USER

# Выход и повторный вход, или:
newgrp docker

# Проверка прав на директории
ls -la data/
chmod 700 data/
```

#### 3. Недостаточно места на диске

**Лог:** `no space left on device`

```bash
# Проверка места
df -h

# Очистка Docker
docker system prune -a --volumes

# ВНИМАНИЕ: Это удалит неиспользуемые образы, контейнеры и volumes!
```

### Контейнер запущен, но панель недоступна

**Симптомы:** Контейнер в статусе `Up`, но http://IP:2053 не открывается

**Диагностика:**

```bash
# 1. Проверка, что контейнер действительно работает
docker-compose ps

# 2. Проверка логов
docker-compose logs -f 3x-ui

# 3. Проверка портов
sudo netstat -tulpn | grep 2053

# 4. Проверка файрвола
sudo ufw status
# Должен быть разрешен порт 2053

# 5. Проверка с локального хоста
curl http://localhost:2053
```

**Решения:**

**Проблема: Файрвол блокирует**

```bash
# Разрешение порта
sudo ufw allow 2053/tcp
```

**Проблема: Неправильный IP**

```bash
# Проверка IP сервера
ip addr show
# или
hostname -I

# Используйте правильный внешний IP
```

**Проблема: Провайдер блокирует порт**

```bash
# Попробуйте другой порт в docker-compose.yml
# Измените 2053 на, например, 8080 или 443
```

## Проблемы с подключением клиентов

### Клиент не может подключиться

**Симптомы:** Клиент показывает ошибку подключения или таймаут

**Диагностика:**

```bash
# 1. Проверка, что сервер слушает нужный порт (например, 443 для VLESS)
sudo netstat -tulpn | grep 443

# 2. Проверка файрвола
sudo ufw status | grep 443

# 3. Проверка логов Xray
docker-compose logs 3x-ui | grep -i error

# 4. Проверка конфигурации Inbound в панели
# Убедитесь, что порт и протокол совпадают с клиентом
```

**Возможные причины:**

#### 1. Неправильная конфигурация клиента

- Проверьте, что порт, UUID, протокол совпадают
- Попробуйте заново импортировать конфигурацию через QR-код

#### 2. Порт заблокирован провайдером

```bash
# Проверка доступности порта с другого сервера
nc -zv ВАШ_IP 443

# Если недоступен, попробуйте другие порты:
# 8443, 2053, 2083, 2087, 2096 (обычно не блокируются)
```

#### 3. Истек срок действия пользователя

- В панели: Inbounds → проверьте Expiry Time
- Продлите срок или увеличьте лимит трафика

#### 4. Исчерпан лимит трафика

- В панели: Inbounds → проверьте Total Flow
- Увеличьте лимит или сбросьте счетчик

### Медленная скорость подключения

**Возможные причины:**

#### 1. Неоптимальный протокол

- VLESS с XTLS-Reality - самый быстрый
- VMess AEAD - медленнее, но надежнее
- Попробуйте изменить протокол

#### 2. Перегруженный сервер

```bash
# Проверка нагрузки
top
# или
htop

# Проверка использования сети
iftop
# или
nethogs
```

#### 3. Ограничения VPS провайдера

- Проверьте, нет ли лимитов пропускной способности в вашем тарифе
- Попробуйте другой VPS

## Проблемы с панелью управления

### Забыл пароль от панели

**Решение:**

```bash
# Сброс пароля (метод 1: через контейнер)
docker-compose exec 3x-ui x-ui resetuser

# Метод 2: Удаление базы данных (ПОТЕРЯЕТЕ ВСЕ НАСТРОЙКИ!)
docker-compose down
rm data/x-ui.db
docker-compose up -d
# Дефолтные учетные данные: admin/admin
```

### Панель не сохраняет настройки

**Симптомы:** После перезапуска настройки сбрасываются

**Причина:** Проблемы с volume

```bash
# Проверка volume
docker-compose down
ls -la data/

# Если x-ui.db отсутствует или поврежден:
# Восстановление из бэкапа
./scripts/restore.sh backups/последний-бэкап.tar.gz

# Если бэкапа нет, пересоздание с правильными правами:
mkdir -p data
chmod 700 data
docker-compose up -d
```

### Ошибка "database is locked"

**Симптомы:** При сохранении настроек: "database is locked"

**Решение:**

```bash
# Перезапуск контейнера
docker-compose restart 3x-ui

# Если не помогло, проверка процессов, использующих базу
docker-compose exec 3x-ui fuser data/x-ui.db

# Крайний случай: пересоздание контейнера
docker-compose down
docker-compose up -d
```

## Проблемы с SSL/TLS

### Let's Encrypt не выдает сертификат

**Возможные причины:**

#### 1. Домен не указывает на сервер

```bash
# Проверка DNS
nslookup your-domain.com
dig your-domain.com

# A-запись должна указывать на IP вашего сервера
```

#### 2. Порт 80 недоступен

Let's Encrypt требует порт 80 для проверки:

```bash
# Временно разрешите порт 80
sudo ufw allow 80/tcp

# После получения сертификата можете закрыть
sudo ufw delete allow 80/tcp
```

#### 3. Лимит запросов Let's Encrypt

- Let's Encrypt имеет лимиты: 5 неудачных попыток в час
- Подождите час и попробуйте снова

### Ошибка "certificate has expired"

**Решение:**

```bash
# В панели: Settings → Certificate Management
# Нажмите "Renew Certificate"

# Или вручную с помощью certbot (если установлен)
sudo certbot renew
```

## Проблемы с производительностью

### Высокая нагрузка CPU

**Диагностика:**

```bash
# Проверка нагрузки
docker stats

# Если 3x-ui использует >80% CPU:
# 1. Проверьте количество активных подключений
# 2. Ограничьте количество пользователей
# 3. Добавьте лимиты на подключения в Inbounds
```

### Высокое использование памяти

```bash
# Проверка памяти
free -h

# Если недостаточно памяти:
# 1. Проверьте логи на утечки
docker-compose logs --tail=1000 3x-ui | grep -i "memory\|oom"

# 2. Перезапустите контейнер
docker-compose restart 3x-ui

# 3. Добавьте swap (если нет)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Проблемы с обновлением

### Ошибка при обновлении образа

**Симптомы:** `docker-compose pull` завершается с ошибкой

**Решение:**

```bash
# Проверка места на диске
df -h

# Очистка старых образов
docker image prune -a

# Повторная попытка
docker-compose pull
docker-compose up -d
```

### После обновления панель не работает

**Решение:**

```bash
# Откат к предыдущей версии
docker-compose down

# Указание конкретной версии в docker-compose.yml
# Вместо :latest используйте, например, :v2.3.0
image: ghcr.io/mhsanaei/3x-ui:v2.3.0

docker-compose up -d

# Проверка логов
docker-compose logs -f 3x-ui
```

## Диагностические команды

Полезные команды для диагностики:

```bash
# 1. Информация о системе
uname -a
cat /etc/os-release
free -h
df -h

# 2. Статус Docker
docker --version
docker-compose --version
docker ps -a
docker stats

# 3. Статус контейнера 3X-UI
docker-compose ps
docker-compose logs --tail=100 3x-ui

# 4. Сеть
ip addr show
ss -tulpn
ping -c 4 google.com

# 5. Файрвол
sudo ufw status verbose
# или
sudo firewall-cmd --list-all

# 6. Процессы
top -bn1 | head -20
ps aux | grep xray

# 7. Логи системы
sudo journalctl -u docker -n 50
sudo tail -100 /var/log/syslog

# 8. Тестирование портов
nc -zv localhost 2053
telnet localhost 2053
curl -v http://localhost:2053
```

## Сбор информации для поддержки

Если не можете решить проблему самостоятельно, соберите диагностическую информацию:

```bash
#!/bin/bash
# Скрипт для сбора диагностической информации

echo "=== System Information ===" > diagnostic.txt
uname -a >> diagnostic.txt
cat /etc/os-release >> diagnostic.txt

echo -e "\n=== Docker Version ===" >> diagnostic.txt
docker --version >> diagnostic.txt
docker-compose --version >> diagnostic.txt

echo -e "\n=== Container Status ===" >> diagnostic.txt
docker-compose ps >> diagnostic.txt

echo -e "\n=== Container Logs (last 100 lines) ===" >> diagnostic.txt
docker-compose logs --tail=100 3x-ui >> diagnostic.txt

echo -e "\n=== Network Ports ===" >> diagnostic.txt
sudo ss -tulpn >> diagnostic.txt

echo -e "\n=== Firewall Status ===" >> diagnostic.txt
sudo ufw status verbose >> diagnostic.txt 2>&1

echo -e "\n=== Disk Space ===" >> diagnostic.txt
df -h >> diagnostic.txt

echo "Diagnostic information saved to diagnostic.txt"
```

## Полезные ссылки

- [GitHub Issues 3X-UI](https://github.com/MHSanaei/3x-ui/issues)
- [Документация Xray](https://xtls.github.io/)
- [Docker Documentation](https://docs.docker.com/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/docker)
