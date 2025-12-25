# Настройка протокола VLESS

VLESS - самый современный и быстрый протокол Xray.

## Преимущества

- Максимальная производительность
- Минимальные накладные расходы
- Поддержка XTLS (еще быстрее)
- Поддержка Reality (максимальная маскировка)

## Создание VLESS Inbound в 3X-UI

1. Перейдите в **Inbounds**
2. Нажмите **Add Inbound**
3. Заполните:

```
Remark: VLESS-Reality (или любое имя)
Protocol: VLESS
Listen IP: 0.0.0.0
Port: 443
Total Flow (GB): 100 (или 0 для безлимита)
Expiry Time: 30 (дней)

Client Settings:
  UUID: (автогенерируется, или сгенерируйте: uuidgen)
  Email: user@example.com
  Flow: xtls-rprx-vision (рекомендуется)

Stream Settings:
  Network: TCP
  Security: Reality (рекомендуется) или TLS

  # Для Reality:
  Dest: www.microsoft.com:443 (сайт для маскировки)
  ServerNames: www.microsoft.com
  ShortIDs: (генерируется автоматически)
  PrivateKey: (генерируется автоматически)
```

4. **Save**

## Подключение клиента

После создания Inbound:

1. Нажмите на иконку QR-кода в строке Inbound
2. Отсканируйте QR-код в клиенте (v2rayN, v2rayNG, etc.)

Или скопируйте ссылку:

```
vless://UUID@SERVER_IP:443?security=reality&sni=www.microsoft.com...
```

## Рекомендации

- **Порт 443**: Стандартный HTTPS порт, редко блокируется
- **Flow: xtls-rprx-vision**: Максимальная скорость
- **Security: Reality**: Неотличим от обычного HTTPS трафика
- **Dest**: Выбирайте популярные сайты (google.com, microsoft.com, cloudflare.com)

## Reality Protocol

Reality делает ваш VPN трафик неотличимым от обычного HTTPS трафика к легитимному сайту.

### Как это работает

1. Клиент подключается к вашему серверу
2. Сервер маскируется под указанный легитимный сайт (Dest)
3. Даже при глубокой проверке пакетов (DPI) трафик выглядит как обычный HTTPS

### Выбор сайта для маскировки (Dest)

Рекомендуемые сайты:

- www.microsoft.com:443
- www.google.com:443
- www.cloudflare.com:443
- www.apple.com:443
- www.amazon.com:443

Критерии выбора:

- Популярный сайт с большим трафиком
- Использует HTTPS
- Не блокируется в вашей стране
- Имеет стабильную работу

## Клиенты

### Windows

- **v2rayN**: https://github.com/2dust/v2rayN/releases
  - Скачайте v2rayN-With-Core.zip
  - Распакуйте и запустите v2rayN.exe
  - Импорт: Сервера → Импортировать из буфера обмена или QR-код

### Android

- **v2rayNG**: https://play.google.com/store/apps/details?id=com.v2ray.ang
  - Откройте приложение
  - Нажмите + → Импортировать из буфера обмена или сканировать QR-код

### iOS

- **Shadowrocket** (платный): App Store
- **Streisand** (бесплатный): App Store

### macOS

- **V2rayU**: https://github.com/yanue/V2rayU/releases
- **Qv2ray**: https://github.com/Qv2ray/Qv2ray/releases

### Linux

```bash
# Установка v2ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# Конфигурация в /usr/local/etc/v2ray/config.json
# Запуск
sudo systemctl start v2ray
sudo systemctl enable v2ray
```

## Оптимизация производительности

### Flow настройки

- **xtls-rprx-vision**: Максимальная скорость, рекомендуется
- **xtls-rprx-direct**: Альтернатива
- **none**: Без XTLS (медленнее)

### TCP настройки

В Stream Settings → TCP Settings:

```json
{
  "header": {
    "type": "none"
  }
}
```

## Решение проблем

### Клиент не подключается

1. Проверьте, что порт 443 открыт в файрволе
2. Убедитесь, что UUID совпадает
3. Проверьте, что сайт маскировки (Dest) доступен
4. Попробуйте другой сайт для маскировки

### Медленная скорость

1. Убедитесь, что используется Flow: xtls-rprx-vision
2. Проверьте нагрузку на сервер (htop)
3. Попробуйте другой VPS провайдер

### Блокировка

Если VLESS блокируется:

1. Измените порт (попробуйте 8443, 2053, 2096)
2. Измените сайт маскировки
3. Используйте CDN (Cloudflare)

## Дополнительные ресурсы

- [Документация VLESS](https://xtls.github.io/config/features/vless.html)
- [Reality Protocol](https://github.com/XTLS/REALITY)
- [XTLS Vision](https://github.com/XTLS/Xray-core)
