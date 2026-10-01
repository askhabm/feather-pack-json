# feather-pack-json

Это репозиторий для GitHub Pages, который служит хранилищем `pack.json` для Feather.

Что здесь будет:
- `CNAME` — указывает GitHub Pages на `pack.iphonmods.online`
- `generate-pack-json.sh` — генерирует `pack.json` из локально сгенерированных PEM-файлов
- `README.md` — пошаговая инструкция

Важно:
- В этом репозитории не хранится реальный приватный ключ.
- Перед публикацией в продакшен нужно сгенерировать сертификат и затем закинуть его в `pack.json` локально.

## 1) Что должно быть на домене

Под домен должен указывать на GitHub Pages, например:
- `pack.iphonmods.online` → `askhabm.github.io`

После этого GitHub Pages будет отвечать по адресу:
- `https://pack.iphonmods.online/pack.json`

## 2) Какую структуру должен иметь pack.json

```json
{
  "cert": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----",
  "ca": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----",
  "key1": "-----BEGIN RSA PRIVATE KEY-----\n...",
  "key2": "...\n-----END RSA PRIVATE KEY-----",
  "info": {
    "issuer": {
      "commonName": "Feather Local CA"
    },
    "domains": {
      "commonName": "*.iphonmods.online"
    }
  }
}
```

`key1` и `key2` вместе должны образовывать весь PEM ключ.

## 3) Генерация самоподписанного сертификата

Запустите:

```bash
./generate-pack-json.sh
```

Скрипт создаст:
- `ca.crt`
- `ca.key`
- `server.key`
- `server.crt`
- `server.csr`
- `pack.json`

## 4) Публикация на GitHub Pages

1. В этом репозитории создайте `CNAME` со строкой:
   ```text
   pack.iphonmods.online
   ```
2. Включите GitHub Pages в Settings → Pages
3. Выберите branch `main`
4. Публикуйте

## 5) Что остается сделать в DNS

Укажите в DNS:

```text
pack  CNAME  askhabm.github.io
```

Если используете отдельный домен/поддомен у регистратора — создайте CNAME или A-запись в соответствии с его интерфейсом.

## 6) Что нужно поменять в Feather

В проекте Feather URL должен быть:

```swift
private let _serverPackUrl = "https://pack.iphonmods.online/pack.json"
```

В `Makefile` тоже:

```make
CERT_JSON_URL := https://pack.iphonmods.online/pack.json
```

## 7) Важное ограничение

Самоподписанный сертификат работает для разработки, но не является официальным CA-сертификатом. Для продакшн лучше использовать домен на LetsEncrypt или enterprise-SSL.

Если нужно, я могу следующим сообщением подготовить готовый `generate-pack-json.sh` и скрипт для автоматической генерации `pack.json` по вашему домену.
