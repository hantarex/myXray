# Руководство по безопасности

## Критически важные меры безопасности

### 1. Изменение дефолтных паролей

⚠️ **ПЕРВЫМ ДЕЛОМ** после установки:

```bash
# В веб-панели 3X-UI:
# Settings → Panel Settings → Panel Password
# Установите пароль минимум 20 символов, включая:
# - Заглавные буквы (A-Z)
# - Строчные буквы (a-z)
# - Цифры (0-9)
# - Специальные символы (!@#$%^&*)
```

Пример сильного пароля: `Kp7$mN9!xQ2#vL4@wR6*`

### 2. Изменение порта панели управления

По умолчанию панель доступна на порту 2053. Измените его:

1. В панели: Settings → Panel Settings → Panel Port
2. Выберите нестандартный порт (например, 35712)
3. Обновите файрвол:

```bash
sudo ufw delete allow 2053/tcp
sudo ufw allow 35712/tcp
```

### 3. Добавление секретного пути к панели

Вместо прямого доступа к `http://IP:2053`, добавьте секретный путь:

1. Settings → Panel Settings → Panel Path
2. Установите: `/my-secret-admin-panel-xyz123`
3. Теперь доступ: `http://IP:2053/my-secret-admin-panel-xyz123`

### 4. Ограничение доступа к панели по IP

**Через UFW:**

```bash
# Запретить доступ ко всем
sudo ufw deny 2053/tcp

# Разрешить только с вашего IP
sudo ufw allow from ВАШ_IP to any port 2053 proto tcp
```

**Через nginx (если используете reverse proxy):**

```nginx
location /admin {
    allow ВАШ_IP;
    deny all;
    proxy_pass http://localhost:2053;
}
```

### 5. Настройка файрвола

**UFW (рекомендуется для Ubuntu/Debian):**

```bash
#!/bin/bash
# Базовая конфигурация UFW

# Политика по умолчанию
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH (КРИТИЧНО! Настройте перед включением UFW)
sudo ufw allow 22/tcp
# Или ограничьте по IP:
# sudo ufw allow from ВАШ_IP to any port 22 proto tcp

# Панель 3X-UI (ограничьте по IP!)
sudo ufw allow from ВАШ_IP to any port 2053 proto tcp

# VPN протоколы (открыты для всех клиентов)
sudo ufw allow 443/tcp    # VLESS
sudo ufw allow 8443/tcp   # VMess
sudo ufw allow 8080/tcp   # Trojan
sudo ufw allow 9443/tcp   # Shadowsocks

# Включение UFW
sudo ufw enable

# Проверка
sudo ufw status numbered
```

**Firewalld (CentOS/RHEL):**

```bash
# Создание зоны для VPN
sudo firewall-cmd --permanent --new-zone=vpn
sudo firewall-cmd --permanent --zone=vpn --add-port=443/tcp
sudo firewall-cmd --permanent --zone=vpn --add-port=8443/tcp
sudo firewall-cmd --permanent --zone=vpn --add-port=8080/tcp
sudo firewall-cmd --permanent --zone=vpn --add-port=9443/tcp

# Ограничение доступа к панели
sudo firewall-cmd --permanent --zone=trusted --add-source=ВАШ_IP
sudo firewall-cmd --permanent --zone=trusted --add-port=2053/tcp

sudo firewall-cmd --reload
```

### 6. Включение fail2ban

Защита от брутфорса SSH:

```bash
# Установка
sudo apt install fail2ban -y

# Конфигурация
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local

# В файле найдите [sshd] и убедитесь:
[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

# Перезапуск
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# Проверка
sudo fail2ban-client status sshd
```

### 7. SSL/TLS сертификаты

**Вариант 1: Let's Encrypt (рекомендуется)**

В панели 3X-UI:

1. Settings → Certificate Management
2. Введите домен и email
3. Apply Certificate

**Вариант 2: Собственный сертификат**

```bash
# Генерация самоподписанного сертификата (для тестов)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout data/cert/privkey.pem \
  -out data/cert/fullchain.pem

# Установка прав
chmod 600 data/cert/privkey.pem
chmod 644 data/cert/fullchain.pem
```

### 8. Регулярные обновления

**Автоматические обновления системы (Ubuntu/Debian):**

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

**Автоматические обновления Docker образов:**

Включено через Watchtower в docker-compose.yml

### 9. Мониторинг и логирование

**Настройка ротации логов:**

```bash
# Создание конфига для logrotate
sudo nano /etc/logrotate.d/docker-3x-ui

# Содержимое:
/home/sham/PhpstormProjects/myXray/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}

# Тест
sudo logrotate -d /etc/logrotate.d/docker-3x-ui
```

**Мониторинг неудачных попыток входа:**

В панели 3X-UI:

- Settings → Panel Settings → Enable Login Log: ON
- Регулярно проверяйте логи на подозрительную активность

### 10. Резервное копирование

**Автоматизация через cron:**

```bash
# Редактирование crontab
crontab -e

# Добавить строку (бэкап каждый день в 3:00)
0 3 * * * /home/sham/PhpstormProjects/myXray/scripts/backup.sh

# Проверка
crontab -l
```

**Хранение бэкапов:**

- Локально: минимум 7 дней
- Удалённо: копирование на другой сервер/облако

### 11. Ограничение трафика

В 3X-UI при создании пользователя:

- **Total Flow**: Ограничьте (например, 100 GB)
- **Expiry Time**: Установите срок действия
- **Max Connections**: Ограничьте количество одновременных подключений (например, 5)

### 12. Использование Reality Protocol

Для максимальной стелс-защиты используйте Reality:

1. При создании Inbound выберите Security: Reality
2. Укажите легитимный сайт для маскировки (например, www.microsoft.com)
3. Reality делает трафик неотличимым от обычного HTTPS

### 13. Отключение неиспользуемых протоколов

Если не используете какой-то протокол:

1. Удалите соответствующие Inbounds
2. Закройте порты в файрволе
3. Меньше открытых портов = меньше поверхность атаки

## Чек-лист безопасности

Используйте этот чек-лист после установки:

- [ ] Изменен дефолтный пароль admin
- [ ] Изменен порт панели (не 2053)
- [ ] Добавлен секретный путь к панели
- [ ] Настроен файрвол (UFW/firewalld)
- [ ] Доступ к панели ограничен по IP
- [ ] Настроен fail2ban для SSH
- [ ] Включены SSL/TLS сертификаты
- [ ] Настроены автоматические обновления
- [ ] Настроено логирование
- [ ] Настроено автоматическое резервное копирование
- [ ] Установлены лимиты трафика для пользователей
- [ ] Используется Reality или TLS для протоколов
- [ ] Отключены неиспользуемые протоколы
- [ ] SSH ключи настроены (вместо паролей)
- [ ] Root login через SSH отключен

## Расширенная защита

### Использование Cloudflare

Если используете домен:

1. Добавьте домен в Cloudflare
2. Включите Proxy (оранжевое облачко)
3. Настройте SSL/TLS: Full (strict)
4. Включите DDoS Protection

### Двухфакторная аутентификация

3X-UI поддерживает 2FA:

1. Settings → Panel Settings
2. Enable 2FA: ON
3. Отсканируйте QR-код в Google Authenticator

### Настройка SSH ключей

```bash
# На вашем локальном компьютере
ssh-keygen -t ed25519 -C "your_email@example.com"

# Копирование ключа на сервер
ssh-copy-id user@server_ip

# На сервере: отключение парольной аутентификации
sudo nano /etc/ssh/sshd_config

# Найти и изменить:
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes

# Перезапуск SSH
sudo systemctl restart sshd
```

## Реагирование на инциденты

Если заметили подозрительную активность:

```bash
# 1. Проверка активных подключений
docker-compose exec 3x-ui netstat -tnp

# 2. Проверка логов
docker-compose logs --tail=1000 3x-ui | grep -i "failed\|error\|unauthorized"

# 3. Временная блокировка всех подключений
sudo ufw deny 443/tcp
sudo ufw deny 8443/tcp
sudo ufw deny 8080/tcp
sudo ufw deny 9443/tcp

# 4. Смена всех паролей
# Через веб-панель измените пароли всех пользователей

# 5. Восстановление из бэкапа (если компрометация)
docker-compose down
./scripts/restore.sh backups/последний-известный-чистый-бэкап.tar.gz
docker-compose up -d

# 6. Разблокировка после устранения угрозы
sudo ufw allow 443/tcp
# и т.д.
```

## Рекомендации по выбору VPS

Для максимальной безопасности выбирайте VPS с:

- Расположением в юрисдикции с хорошими законами о конфиденциальности
- Поддержкой приватных платежей (криптовалюта)
- DDoS защитой
- Возможностью шифрования диска
- Регулярными обновлениями безопасности

## Полезные ссылки

- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Linux Server Security](https://github.com/imthenachoman/How-To-Secure-A-Linux-Server)
