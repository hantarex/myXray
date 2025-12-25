# Настройка протокола Trojan

Trojan - протокол, маскирующийся под обычный HTTPS трафик.

## Преимущества

- Отличная маскировка под HTTPS
- Сложно обнаружить
- Хорошая производительность
- Простая конфигурация

## Принцип работы

Trojan имитирует обычное HTTPS соединение:

1. Клиент подключается к серверу через TLS
2. Отправляет пароль (password)
3. Если пароль верный - туннелирует трафик
4. Если неверный - перенаправляет на легитимный сайт

Для DPI это выглядит как обычный HTTPS.

## Создание Trojan Inbound в 3X-UI

1. Перейдите в **Inbounds**
2. Нажмите **Add Inbound**
3. Заполните:

```
Remark: Trojan-TLS
Protocol: Trojan
Listen IP: 0.0.0.0
Port: 8080 (или 443)
Total Flow (GB): 100 (или 0 для безлимита)
Expiry Time: 30 (дней)

Client Settings:
  Password: (сгенерируется автоматически или введите свой)
  Email: user@example.com

Stream Settings:
  Network: TCP
  Security: TLS (обязательно!)

  # TLS Settings:
  Certificate: путь к fullchain.pem
  Key: путь к privkey.pem

  # Fallback (опционально):
  Fallback: https://www.example.com
```

4. **Save**

**Важно**: Trojan **ТРЕБУЕТ** TLS сертификат!

## Настройка SSL сертификата

### Вариант 1: Let's Encrypt через 3X-UI

1. Settings → Certificate Management
2. Domain: ваш домен
3. Email: ваш email
4. Apply Certificate

### Вариант 2: Ручная установка certbot

```bash
# Установка certbot
sudo apt install certbot -y

# Получение сертификата
sudo certbot certonly --standalone -d your-domain.com

# Сертификаты будут в:
# /etc/letsencrypt/live/your-domain.com/fullchain.pem
# /etc/letsencrypt/live/your-domain.com/privkey.pem

# Копирование в data/cert/
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem data/cert/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem data/cert/
sudo chmod 644 data/cert/fullchain.pem
sudo chmod 600 data/cert/privkey.pem
```

## Подключение клиента

После создания Inbound:

1. Нажмите на иконку QR-кода
2. Отсканируйте в клиенте

Формат ссылки:

```
trojan://PASSWORD@SERVER_IP:8080?security=tls&sni=your-domain.com
```

## Рекомендации

### Порты

- **443**: Стандартный HTTPS (оптимально)
- **8080**: Альтернатива
- **2053, 2083, 2087, 2096**: Cloudflare порты

### Пароль

- Используйте длинный случайный пароль
- Минимум 20 символов
- Генерация: `openssl rand -base64 24`

### Fallback

Настройте fallback на популярный сайт:

- https://www.microsoft.com
- https://www.google.com
- https://www.cloudflare.com

При неверном пароле клиент будет перенаправлен туда.

## Использование с Cloudflare

Trojan можно использовать через Cloudflare CDN:

### Настройка

1. Добавьте домен в Cloudflare
2. A-запись → IP сервера
3. Включите оранжевое облачко
4. SSL/TLS → Full (strict)

### Inbound настройки

```
Port: 443 (или 8443, 2053, 2083, 2087, 2096)
TLS: ON
SNI: your-domain.com
```

## Клиенты

### Windows

- **v2rayN**: Поддержка Trojan
- **Clash for Windows**: Отличная поддержка

### Android

- **v2rayNG**: Полная поддержка
- **Clash for Android**: Рекомендуется

### iOS

- **Shadowrocket**: Платный, отлично работает
- **Stash**: Альтернатива

### macOS

- **V2rayU**: Поддержка Trojan
- **ClashX Pro**: Рекомендуется

### Linux

```bash
# Установка Trojan-Go
wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip
unzip trojan-go-linux-amd64.zip
chmod +x trojan-go

# Конфигурация в config.json
./trojan-go -config config.json
```

## Сравнение с другими протоколами

| Параметр | Trojan | VLESS | VMess |
|----------|--------|-------|-------|
| Скорость | Высокая | Очень высокая | Средняя |
| Маскировка | Отличная | Отличная | Хорошая |
| Простота настройки | Средняя | Простая | Сложная |
| Требует TLS | Да | Нет | Опционально |
| Требует домен | Да | Нет | Опционально |

## Решение проблем

### "certificate verify failed"

1. Проверьте, что сертификат действителен
2. Убедитесь, что SNI совпадает с доменом в сертификате
3. Проверьте срок действия сертификата

```bash
# Проверка сертификата
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

### Клиент не подключается

1. Проверьте пароль
2. Убедитесь, что TLS включен
3. Проверьте порт в файрволе
4. Проверьте, что домен указывает на сервер

### Медленная скорость

1. Используйте порт 443
2. Отключите Cloudflare для тестирования
3. Проверьте нагрузку на сервер
4. Убедитесь, что TLS 1.3 используется

### Сертификат истек

```bash
# Обновление через certbot
sudo certbot renew

# Или в панели 3X-UI
# Settings → Certificate Management → Renew
```

## Оптимизация

### Максимальная производительность

```
Port: 443
Network: TCP
TLS: 1.3
ALPN: h2,http/1.1
```

### Максимальная безопасность

```
Длинный случайный пароль
Valid сертификат от Let's Encrypt
Fallback на популярный сайт
Регулярная смена паролей
```

## Безопасность

### Рекомендации

- Всегда используйте действительный SSL сертификат
- Используйте длинные случайные пароли
- Настройте fallback
- Регулярно обновляйте сертификаты
- Ограничьте количество подключений

### Обнаружение

Trojan очень сложно обнаружить:

- Трафик идентичен HTTPS
- Fallback скрывает сервер
- DPI не может отличить от обычного веб-трафика

## Автообновление сертификатов

### Через certbot

```bash
# Добавление в cron
sudo crontab -e

# Добавить строку (обновление раз в день)
0 3 * * * certbot renew --quiet && docker-compose restart 3x-ui
```

### Через 3X-UI

В панели автоматическое обновление уже настроено при использовании встроенного Certificate Management.

## Дополнительные ресурсы

- [Trojan Protocol](https://trojan-gfw.github.io/trojan/)
- [Trojan-Go](https://github.com/p4gefau1t/trojan-go)
- [Xray Trojan](https://xtls.github.io/config/protocols/trojan.html)
