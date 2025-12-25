# Настройка протокола Shadowsocks

Shadowsocks - легкий и быстрый протокол для обхода блокировок.

## Преимущества

- Очень простая настройка
- Высокая скорость
- Низкое потребление ресурсов
- Широкая поддержка клиентами
- Хорошо изученный и надежный

## Принцип работы

Shadowsocks использует SOCKS5 прокси с шифрованием:

1. Клиент шифрует данные
2. Отправляет на сервер
3. Сервер расшифровывает и пересылает

Простой и эффективный.

## Создание Shadowsocks Inbound в 3X-UI

1. Перейдите в **Inbounds**
2. Нажмите **Add Inbound**
3. Заполните:

```
Remark: Shadowsocks-AEAD
Protocol: Shadowsocks
Listen IP: 0.0.0.0
Port: 9443
Total Flow (GB): 100 (или 0 для безлимита)
Expiry Time: 30 (дней)

Client Settings:
  Password: (сгенерируется автоматически)
  Email: user@example.com
  Method: aes-256-gcm (рекомендуется)

Stream Settings:
  Network: TCP
  Security: none (Shadowsocks имеет собственное шифрование)
```

4. **Save**

## Методы шифрования

Рекомендуемые методы (AEAD):

- **aes-256-gcm**: Баланс скорости и безопасности (рекомендуется)
- **aes-128-gcm**: Быстрее, немного менее безопасный
- **chacha20-poly1305**: Отлично для мобильных устройств

Старые методы (не рекомендуется):

- aes-256-cfb
- aes-128-cfb
- chacha20-ietf

**Важно**: Всегда используйте AEAD методы!

## Подключение клиента

После создания Inbound:

1. Нажмите на иконку QR-кода
2. Отсканируйте в клиенте

Формат ссылки:

```
ss://BASE64(method:password)@SERVER_IP:9443
```

Пример:

```
ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@1.2.3.4:9443
```

## Рекомендации

### Порты

- **9443**: Хороший выбор
- **8388**: Стандартный порт Shadowsocks
- **443**: Маскировка под HTTPS
- **8080**: Альтернатива

### Пароль

- Длинный случайный пароль (20+ символов)
- Генерация: `openssl rand -base64 24`
- Меняйте регулярно

### Плагины (опционально)

Shadowsocks поддерживает плагины для дополнительной обфускации:

- **v2ray-plugin**: Маскировка WebSocket/QUIC
- **simple-obfs**: Простая обфускация HTTP/TLS

В 3X-UI это можно настроить в Stream Settings.

## Клиенты

### Windows

- **Shadowsocks-Windows**: https://github.com/shadowsocks/shadowsocks-windows/releases
  - Официальный клиент
  - Простой интерфейс
  - Стабильная работа

### Android

- **Shadowsocks-Android**: https://play.google.com/store/apps/details?id=com.github.shadowsocks
  - Официальный клиент
  - Поддержка плагинов
  - Отлично работает

### iOS

- **Shadowrocket**: App Store (платный, $2.99)
  - Лучший клиент для iOS
  - Поддержка многих протоколов

- **Potatso Lite**: App Store (бесплатный)
  - Простой и легкий

### macOS

- **ShadowsocksX-NG**: https://github.com/shadowsocks/ShadowsocksX-NG/releases
  - Официальный клиент
  - Удобный интерфейс

### Linux

```bash
# Установка через pip
pip install shadowsocks

# Создание конфига /etc/shadowsocks/config.json
{
  "server": "YOUR_SERVER_IP",
  "server_port": 9443,
  "local_port": 1080,
  "password": "YOUR_PASSWORD",
  "timeout": 300,
  "method": "aes-256-gcm"
}

# Запуск
sslocal -c /etc/shadowsocks/config.json

# Или через systemd
sudo systemctl start shadowsocks-libev-local@config
```

## Сравнение с другими протоколами

| Параметр | Shadowsocks | VLESS | VMess | Trojan |
|----------|-------------|-------|-------|--------|
| Скорость | Очень высокая | Очень высокая | Средняя | Высокая |
| Простота настройки | Очень простая | Простая | Средняя | Средняя |
| Маскировка | Базовая | Отличная | Хорошая | Отличная |
| Поддержка клиентами | Отличная | Хорошая | Отличная | Хорошая |
| Ресурсы | Минимальные | Низкие | Средние | Низкие |

## Использование с плагинами

### v2ray-plugin

Добавляет маскировку WebSocket/QUIC:

```
# На сервере в Stream Settings:
Plugin: v2ray-plugin
Plugin Opts: server;mode=websocket;path=/secretpath

# На клиенте:
Plugin: v2ray-plugin
Plugin Opts: mode=websocket;path=/secretpath
```

### simple-obfs

Простая обфускация под HTTP/TLS:

```
# На сервере:
Plugin: obfs-server
Plugin Opts: obfs=http

# На клиенте:
Plugin: obfs-local
Plugin Opts: obfs=http;obfs-host=www.bing.com
```

## Решение проблем

### Клиент не подключается

1. Проверьте пароль
2. Проверьте метод шифрования (должен совпадать)
3. Проверьте порт в файрволе
4. Проверьте, что Inbound активен

### Медленная скорость

1. Попробуйте другой метод шифрования:
   - chacha20-poly1305 для мобильных
   - aes-128-gcm для быстрейшей скорости
2. Проверьте нагрузку на сервер
3. Попробуйте другой порт

### "connection timeout"

1. Порт заблокирован файрволом
2. Порт заблокирован провайдером
3. Попробуйте другой порт (443, 80, 8080)

### "encryption error"

- Метод шифрования не совпадает на клиенте и сервере
- Обновите клиент до последней версии

## Оптимизация

### Для максимальной скорости

```
Method: aes-128-gcm
Port: 9443
TCP Fast Open: ON (если поддерживается)
```

### Для максимальной совместимости

```
Method: aes-256-gcm
Port: 8388 или 443
Plugin: none
```

### Для обхода блокировок

```
Method: aes-256-gcm
Port: 443 или 80
Plugin: v2ray-plugin с WebSocket
```

## Безопасность

### Рекомендации

- Используйте только AEAD методы (aes-256-gcm, chacha20-poly1305)
- Длинные случайные пароли
- Регулярно меняйте пароли
- Ограничьте количество одновременных подключений
- Используйте плагины для дополнительной обфускации

### Обнаружение

Базовый Shadowsocks:

- Относительно легко обнаружить DPI
- Характерные паттерны трафика

С плагинами:

- Сложнее обнаружить
- v2ray-plugin делает трафик похожим на WebSocket
- simple-obfs маскирует под HTTP/TLS

## Комбинирование с другими технологиями

### Shadowsocks + Cloudflare

Не рекомендуется напрямую, но можно:

1. Использовать v2ray-plugin с WebSocket
2. Настроить домен через Cloudflare
3. Использовать Cloudflare порты (8443, 2053, etc.)

### Shadowsocks + Docker

Уже используется через 3X-UI!

### Shadowsocks за Nginx

Можно настроить обратный прокси через Nginx для дополнительной маскировки.

## Когда использовать Shadowsocks

**Используйте Shadowsocks если:**

- Нужна максимальная простота настройки
- Важна высокая скорость
- Используете мобильные устройства
- Нужна широкая поддержка клиентами
- Блокировки не очень агрессивные

**Используйте другие протоколы если:**

- Нужна максимальная маскировка → VLESS Reality или Trojan
- Агрессивные блокировки → VLESS Reality
- Нужна интеграция с CDN → VMess WebSocket

## Дополнительные ресурсы

- [Shadowsocks Official](https://shadowsocks.org/)
- [Shadowsocks Github](https://github.com/shadowsocks)
- [Shadowsocks AEAD](https://shadowsocks.org/en/wiki/AEAD-Ciphers.html)
