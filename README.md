# Xray VPN с панелью управления 3X-UI

Готовое решение для развёртывания VPN-сервера на базе Xray с удобной веб-панелью управления 3X-UI.

## Что включено

- **3X-UI**: Веб-панель управления с русским интерфейсом
- **Xray-core**: Встроенный в 3X-UI
- **Поддерживаемые протоколы**: VLESS, VMess, Trojan, Shadowsocks
- **Docker Compose**: Простое развёртывание одной командой
- **Автообновления**: Опциональный Watchtower

## Быстрый старт

### Требования

- Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- Docker 20.10+
- Docker Compose 1.29+
- Минимум 512 MB RAM (рекомендуется 1 GB)
- 10 GB свободного места

### Установка

1. **Настройка переменных окружения:**

```bash
cp .env.example .env
nano .env  # Измените PANEL_PASSWORD и другие настройки
```

2. **Запуск:**

```bash
docker-compose up -d
```

3. **Проверка статуса:**

```bash
docker-compose ps
docker-compose logs -f 3x-ui
```

4. **Доступ к панели:**

```
URL: http://ВАШ_IP:2053
Логин: admin
Пароль: admin (ИЗМЕНИТЕ СРАЗУ ПОСЛЕ ВХОДА!)
```

## Первоначальная настройка

После первого входа:

1. **Измените пароль администратора**: Settings → Panel Settings
2. **Настройте порт панели**: По умолчанию 2053
3. **Добавьте пользователей**: Inbounds → Add Inbound
4. **Настройте протоколы**: См. [INSTALLATION.md](./INSTALLATION.md)

## Безопасность

⚠️ **КРИТИЧЕСКИ ВАЖНО**:

- Измените пароль admin сразу после первого входа
- Используйте сложные пароли (20+ символов)
- Настройте файрвол (см. [SECURITY.md](./SECURITY.md))
- Рассмотрите использование SSL/TLS сертификатов
- Регулярно создавайте резервные копии

## Документация

- [Подробная установка](./INSTALLATION.md)
- [Безопасность](./SECURITY.md)
- [Решение проблем](./TROUBLESHOOTING.md)
- [Протоколы](./docs/protocols/)

## Управление

### Основные команды

```bash
# Запуск
docker-compose up -d

# Остановка
docker-compose down

# Перезапуск
docker-compose restart

# Просмотр логов
docker-compose logs -f

# Обновление
docker-compose pull
docker-compose up -d

# Резервное копирование
./scripts/backup.sh

# Восстановление
./scripts/restore.sh backups/backup-2025-12-25.tar.gz
```

## Порты

По умолчанию используются следующие порты:

- **2053**: Веб-панель 3X-UI
- **443**: VLESS (рекомендуется)
- **8443**: VMess
- **8080**: Trojan
- **9443**: Shadowsocks

Откройте эти порты в файрволе!

## Настройка файрвола

### Автоматическая настройка

```bash
sudo ./scripts/firewall-setup.sh
```

### Ручная настройка (UFW)

```bash
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 2053/tcp    # Панель
sudo ufw allow 443/tcp     # VLESS
sudo ufw allow 8443/tcp    # VMess
sudo ufw allow 8080/tcp    # Trojan
sudo ufw allow 9443/tcp    # Shadowsocks
sudo ufw enable
```

## Резервное копирование

### Создание бэкапа

```bash
./scripts/backup.sh
```

Бэкапы сохраняются в `./backups/` с автоматической очисткой старых (>7 дней).

### Восстановление

```bash
./scripts/restore.sh backups/backup-YYYY-MM-DD-HHMMSS.tar.gz
```

### Автоматизация через cron

```bash
# Редактирование crontab
crontab -e

# Добавить строку (бэкап каждый день в 3:00)
0 3 * * * /home/sham/PhpstormProjects/myXray/scripts/backup.sh
```

## Структура проекта

```
.
├── docker-compose.yml          # Главный файл оркестрации
├── .env                        # Переменные окружения (секретные данные)
├── .env.example                # Шаблон для .env
├── .gitignore                  # Исключения для git
├── README.md                   # Главная документация
├── INSTALLATION.md             # Детальная инструкция
├── SECURITY.md                 # Рекомендации по безопасности
├── TROUBLESHOOTING.md          # Решение проблем
├── data/                       # Данные 3X-UI
│   ├── x-ui.db                 # База данных (создается автоматически)
│   └── cert/                   # SSL сертификаты
├── scripts/                    # Вспомогательные скрипты
│   ├── backup.sh               # Резервное копирование
│   ├── restore.sh              # Восстановление
│   └── firewall-setup.sh       # Настройка файрвола
└── docs/                       # Дополнительная документация
    └── protocols/              # Описание протоколов
```

## Поддержка

- Документация 3X-UI: https://github.com/MHSanaei/3x-ui
- Документация Xray: https://xtls.github.io/

## Лицензия

MIT License
