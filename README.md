# Микросервисы: принципы

Домашнее задание по микросервисной архитектуре с практической реализацией API Gateway.

## Что сделано

### Задача 1: Выбор API Gateway

Проанализировал 7 популярных решений (Kong, Traefik, NGINX Plus, AWS API Gateway, Envoy, Tyk, KrakenD).

**Выбор:** Traefik/NGINX
- Автоматическая маршрутизация
- Встроенная аутентификация
- Let's Encrypt из коробки
- Простая интеграция с Docker/Kubernetes

### Задача 2: Выбор брокера сообщений

Сравнил 7 брокеров (RabbitMQ, Kafka, Redis Streams, NATS, SQS, Pulsar, ActiveMQ).

**Выбор:** Apache Kafka
- Throughput 1M+ сообщений/сек
- Надежное хранение с репликацией
- Возможность replay сообщений
- Кластеризация и multi-datacenter

### Задача 3: Практическая реализация

Развернул микросервисную систему с API Gateway на GCP.

## Архитектура

```
┌─────────┐
│ Client  │
└────┬────┘
     │
     ▼
┌─────────────┐
│  NGINX      │ ← API Gateway
│  Gateway    │
└──────┬──────┘
       │
   ┌───┴────┐
   │        │
   ▼        ▼
┌─────┐  ┌─────────┐
│Auth │  │Uploader │
└─────┘  └────┬────┘
              │
              ▼
         ┌────────┐
         │ MinIO  │
         └────────┘
```

**Компоненты:**
- **NGINX** - API Gateway с маршрутизацией и auth_request
- **Security Service** - аутентификация (Node.js + Express)
- **Uploader Service** - загрузка файлов (Node.js + MinIO SDK)
- **MinIO** - S3-совместимое хранилище

## Быстрый старт

### Локально (Docker)

```bash
docker compose up -d
```

### На GCP (рекомендуется)

```bash
# 1. Настройка Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars (укажите project_id и SSH ключ)

# 2. Развертывание
terraform init
terraform apply

# 3. Деплой приложения
cd ..
./deploy-to-gcp.sh <VM_IP>
```

## Использование

### Получить токен
```bash
curl -X POST http://<IP>/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

### Загрузить файл
```bash
curl -X POST http://<IP>/upload \
  -H "Authorization: Bearer valid-token-12345" \
  -F "file=@test.txt"
```

### Список файлов
```bash
curl http://<IP>/upload/list \
  -H "Authorization: Bearer valid-token-12345"
```

## Работающий инстанс

🌐 **Production на GCP:** http://35.238.24.118

**Credentials:**
- Admin: `admin` / `admin` (токен: `valid-token-12345`)
- User: `user` / `user` (токен: `user-token-67890`)
- MinIO: `minioadmin` / `minioadmin`

### Скриншот работающей системы

![MinIO Object Browser](screenshots/minio-object-browser.png)

*MinIO консоль с загруженным файлом через API Gateway*

## Структура проекта

```
.
├── microservices-02-principles.md  # Полный ответ на задание
├── DEPLOYMENT-RESULTS.md           # Отчет о развертывании
├── docker-compose.yml              # Оркестрация
├── nginx.conf                      # Конфигурация API Gateway
├── security-service/               # Сервис аутентификации
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── uploader-service/               # Сервис загрузки файлов
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
└── terraform/                      # Инфраструктура GCP
    ├── main.tf
    ├── variables.tf
    └── README.md
```

## Особенности реализации

### Аутентификация
NGINX использует `auth_request` модуль для проверки токенов:
1. Запрос к `/upload` → проверка через `/auth/verify`
2. Security Service возвращает `X-User-Id` и `X-User-Role`
3. NGINX передает заголовки в Uploader Service

### Авторизация
- Обычные пользователи: загрузка и скачивание
- Админы: + удаление файлов

### Масштабирование
```bash
docker compose up -d --scale uploader=3
```

## Управление GCP

```bash
# Логи
gcloud compute ssh nikita@microservices-instance --zone=us-central1-a \
  --command="cd /opt/microservices && sudo docker compose logs -f"

# Перезапуск
gcloud compute ssh nikita@microservices-instance --zone=us-central1-a \
  --command="cd /opt/microservices && sudo docker compose restart"

# Удаление
cd terraform && terraform destroy
```

## Стоимость GCP
- VM e2-medium: ~$24/месяц
- Диск 30GB: ~$1.20/месяц
- IP: ~$3/месяц

**Итого:** ~$28/месяц (~$0.04/час)

## Результаты тестирования

Все эндпоинты протестированы и работают корректно:

- ✅ Health checks всех сервисов
- ✅ Аутентификация (логин, проверка токена)
- ✅ Загрузка файлов с валидным токеном
- ✅ Отклонение запросов без токена (401 Unauthorized)
- ✅ Список и скачивание файлов
- ✅ Авторизация (только админ может удалять файлы)

Детальный отчет: [DEPLOYMENT-RESULTS.md](DEPLOYMENT-RESULTS.md)

## Проблемы и решения

**Проблема:** Traefik несовместим с Docker 29.x (требует API v1.24, доступен только v1.44)

**Решение:** Заменен на NGINX с ручной конфигурацией маршрутизации и auth_request.

## Документы

### Задание 2: Принципы микросервисной архитектуры
- [microservices-02-principles.md](microservices-02-principles.md) - полный ответ на все задачи ДЗ
- [DEPLOYMENT-RESULTS.md](DEPLOYMENT-RESULTS.md) - детальный отчет о развертывании
- [terraform/README.md](terraform/README.md) - инструкции по GCP

### Задание 3: Подходы к организации инфраструктуры
- [microservices-03-approaches.md](microservices-03-approaches.md) - CI/CD, логирование и мониторинг
  - Задача 1: GitHub Actions для CI/CD
  - Задача 2: Loki + Grafana для логов
  - Задача 3: Prometheus + Grafana для метрик
