# Настройка протокола VMess

VMess - классический протокол V2Ray с собственным шифрованием.

## Преимущества

- Широкая поддержка клиентами
- Надежное шифрование
- Гибкие настройки
- Проверенный временем

## Создание VMess Inbound в 3X-UI

1. Перейдите в **Inbounds**
2. Нажмите **Add Inbound**
3. Заполните:

```
Remark: VMess-WebSocket (или любое имя)
Protocol: VMess
Listen IP: 0.0.0.0
Port: 8443
Total Flow (GB): 100 (или 0 для безлимита)
Expiry Time: 30 (дней)

Client Settings:
  UUID: (автогенерируется)
  Email: user@example.com
  alterId: 0 (AEAD, рекомендуется)

Stream Settings:
  Network: WebSocket или TCP
  Security: TLS (рекомендуется) или none

  # Для WebSocket:
  Path: /ray (или любой путь)
  Host: your-domain.com (опционально)

  # Для TLS:
  Certificate: путь к fullchain.pem
  Key: путь к privkey.pem
```

4. **Save**

## Подключение клиента

После создания Inbound:

1. Нажмите на иконку QR-кода
2. Отсканируйте в клиенте

Или скопируйте ссылку:

```
vmess://BASE64_ENCODED_CONFIG
```

## Рекомендации

### Выбор Network

**WebSocket:**

- Лучше обходит блокировки
- Можно использовать с CDN (Cloudflare)
- Может быть медленнее TCP

**TCP:**

- Быстрее WebSocket
- Проще настройка
- Легче блокировать

### Выбор порта

Рекомендуемые порты:

- **8443**: Альтернативный HTTPS
- **2053, 2083, 2087, 2096**: Cloudflare порты
- **443**: Стандартный HTTPS (если не используется VLESS)

### alterId

- **0**: AEAD шифрование (рекомендуется)
- **64**: Старый метод (не рекомендуется)

**Важно**: Всегда используйте alterId = 0 (AEAD)

## Использование с Cloudflare CDN

VMess + WebSocket + TLS + Cloudflare = отличная маскировка

### Шаг 1: Настройка домена

1. Добавьте домен в Cloudflare
2. Создайте A-запись, указывающую на IP сервера
3. Включите оранжевое облачко (Proxy)

### Шаг 2: Настройка Inbound

```
Protocol: VMess
Port: 443 (или 8443, 2053, 2083, 2087, 2096)
Network: WebSocket
Path: /secretpath
Host: your-domain.com
TLS: ON
```

### Шаг 3: Cloudflare настройки

1. SSL/TLS → Full (strict)
2. Network → WebSockets: ON
3. Firewall: настройте правила (опционально)

## Клиенты

### Windows

- **v2rayN**: https://github.com/2dust/v2rayN/releases

### Android

- **v2rayNG**: https://play.google.com/store/apps/details?id=com.v2ray.ang

### iOS

- **Shadowrocket**: App Store (платный)
- **Quantumult X**: App Store (платный)

### macOS

- **V2rayU**: https://github.com/yanue/V2rayU/releases

### Linux

- **v2ray**: https://github.com/v2fly/v2ray-core

## Оптимизация

### Для максимальной скорости

```
Network: TCP
Security: none или TLS
alterId: 0
```

### Для максимальной маскировки

```
Network: WebSocket
Security: TLS
Path: /random-path-here
Host: popular-domain.com
+ Cloudflare CDN
```

## Сравнение с VLESS

| Параметр | VMess | VLESS |
|----------|-------|-------|
| Скорость | Средняя | Высокая |
| Шифрование | Двойное (VMess + TLS) | Одинарное (TLS) |
| Накладные расходы | Выше | Ниже |
| Поддержка клиентами | Отличная | Хорошая |
| Рекомендуется для | Совместимость | Производительность |

## Решение проблем

### Клиент не подключается

1. Проверьте UUID
2. Проверьте alterId (должен совпадать на клиенте и сервере)
3. Если используется TLS, проверьте сертификаты
4. Проверьте путь WebSocket (Path)

### Медленная скорость

1. Используйте TCP вместо WebSocket
2. Отключите Cloudflare (оранжевое облачко)
3. Проверьте нагрузку на сервер

### "invalid user" ошибка

- UUID не совпадает
- Inbound отключен
- Истек срок действия или превышен лимит трафика

## Безопасность

### Рекомендации

- Всегда используйте TLS
- Установите alterId = 0
- Используйте случайный Path для WebSocket
- Регулярно меняйте UUID
- Ограничьте количество одновременных подключений

### Обнаружение

VMess с TLS сложно обнаружить, но:

- TCP трафик легче блокировать
- WebSocket + Cloudflare = максимальная защита
- Регулярно меняйте Path и Host

## Дополнительные ресурсы

- [Документация VMess](https://www.v2ray.com/en/configuration/protocols/vmess.html)
- [V2Ray Github](https://github.com/v2fly/v2ray-core)
