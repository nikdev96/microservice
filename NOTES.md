# Заметки по проекту микросервисов

## Текущий статус

### Выполнено ✅

#### Задание 2: Принципы микросервисной архитектуры
- ✅ Задача 1: Сравнительный анализ API Gateway (выбран NGINX)
- ✅ Задача 2: Сравнительный анализ брокеров сообщений (рекомендован Apache Kafka)
- ✅ Задача 3: Практическая реализация API Gateway на GCP
  - NGINX API Gateway с auth_request
  - Security Service (аутентификация)
  - Uploader Service (загрузка в MinIO)
  - MinIO объектное хранилище
  - Развернуто на GCP (удалено 13.12.2025 в 21:40)

**Репозиторий:** https://github.com/nikdev96/microservice
**Ветка main:** основной код и документация

#### Задание 3: Подходы к организации инфраструктуры
- ✅ Задача 1: CI/CD система (выбран GitHub Actions)
- ✅ Задача 2: Система логирования (выбран Loki + Grafana)
- ✅ Задача 3: Система мониторинга (выбран Prometheus + Grafana)

**Ветка task-03-approaches:** теоретическая часть
**Файл:** microservices-03-approaches.md

### В работе 🔄

#### Задание 3 (практическая часть)
- ⏸️ Задача 4: Vector + ElasticSearch + Kibana
  - Требование: доступ через localhost:8081
  - Credentials: admin/qwerty123456
  - Создана директория: task-04-logging/

- ⏸️ Задача 5: Prometheus + Grafana
  - Требование: dashboard распределения запросов
  - Доступ: localhost:8081
  - Credentials: admin/qwerty123456
  - Создана директория: task-05-monitoring/

## Структура проекта

```
micro1/
├── docker-compose.yml              # Основная система (задание 2)
├── nginx.conf                      # API Gateway конфиг
├── security-service/               # Сервис аутентификации
├── uploader-service/               # Сервис загрузки файлов
├── terraform/                      # GCP инфраструктура
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars (не в git)
├── screenshots/                    # Скриншоты работы
├── microservices-02-principles.md  # Задание 2 - ответы
├── microservices-03-approaches.md  # Задание 3 - теория
├── DEPLOYMENT-RESULTS.md           # Отчет о развертывании
├── task-04-logging/               # TODO: Vector + ES + Kibana
└── task-05-monitoring/            # TODO: Prometheus + Grafana
```

## Git ветки

- **main** - основная ветка с заданием 2
- **task-03-approaches** - задание 3 (теория готова, практика в процессе)

## Технологии

### Задание 2 (развернуто)
- NGINX - API Gateway
- Node.js + Express - микросервисы
- MinIO - S3-compatible storage
- Docker Compose - оркестрация
- Terraform - IaC для GCP
- GCP Compute Engine - VM (e2-medium)

### Задание 3 (план)
**Логирование:**
- Vector - log collector
- ElasticSearch - хранение
- Kibana - визуализация

**Мониторинг:**
- Prometheus - сбор метрик
- Node Exporter - метрики хостов
- cAdvisor - метрики контейнеров
- Grafana - дашборды

## TODO для продолжения

### Задача 4: Логирование
1. Создать docker-compose.yml в task-04-logging/
2. Компоненты:
   - Vector (collector)
   - ElasticSearch (storage)
   - Kibana (UI) на порту 8081
3. Настроить сбор логов из существующих сервисов
4. Создать дашборд в Kibana
5. Credentials: admin/qwerty123456

### Задача 5: Мониторинг
1. Создать docker-compose.yml в task-05-monitoring/
2. Компоненты:
   - Prometheus (metrics storage)
   - Node Exporter (host metrics)
   - cAdvisor (container metrics)
   - Grafana (UI) на порту 8081
3. Инструментировать существующие сервисы
4. Создать dashboard распределения запросов
5. Credentials: admin/qwerty123456

### Интеграция
- Объединить все в единый docker-compose
- Или держать отдельные стеки для демонстрации
- Задокументировать в microservices-03-approaches.md

## GCP Infrastructure

**Проект:** original-future-476512-f0
**Регион:** us-central1-a
**SSH Key:** уже настроен в terraform.tfvars

### Для повторного развертывания:
```bash
cd terraform
terraform init
terraform apply
# IP будет в outputs

cd ..
./deploy-to-gcp.sh <VM_IP>
```

### Стоимость
- VM e2-medium: ~$24/мес (~$0.033/час)
- Диск 30GB: ~$1.20/мес
- IP: ~$3/мес
**Итого:** ~$28/мес

## Учетные данные

### Security Service (задание 2)
- Admin: admin/admin (token: valid-token-12345)
- User: user/user (token: user-token-67890)

### MinIO (задание 2)
- minioadmin/minioadmin

### Kibana (задание 3-4)
- admin/qwerty123456

### Grafana (задание 3-5)
- admin/qwerty123456

## Полезные команды

### Docker
```bash
# Запуск
docker compose up -d

# Логи
docker compose logs -f

# Остановка
docker compose down

# Пересборка
docker compose up -d --build
```

### Git
```bash
# Текущая ветка
git branch

# Переключение
git checkout task-03-approaches

# Коммит
git add .
git commit -m "message"
git push
```

### Terraform
```bash
cd terraform

# Развернуть
terraform apply

# Удалить (СДЕЛАНО 13.12.2025 21:40)
terraform destroy
```

## Ссылки

- **Репозиторий:** https://github.com/nikdev96/microservice
- **Задание 2:** https://github.com/netology-code/micros-homeworks/blob/main/11-microservices-02-principles.md
- **Задание 3:** https://github.com/netology-code/micros-homeworks/blob/main/11-microservices-03-approaches.md

## История

- **13.12.2025 14:12** - Развернуто задание 2 на GCP (35.238.24.118)
- **13.12.2025 21:22** - Добавлен скриншот MinIO
- **13.12.2025 21:33** - Создана новая ветка task-03-approaches
- **13.12.2025 21:35** - Выполнена теоретическая часть задания 3
- **13.12.2025 21:40** - Удалена GCP инфраструктура (terraform destroy)
- **13.12.2025 21:42** - Созданы директории для задач 4 и 5

## Следующие шаги

1. Реализовать задачу 4 (Vector + ElasticSearch + Kibana)
2. Реализовать задачу 5 (Prometheus + Grafana)
3. Обновить microservices-03-approaches.md практическими примерами
4. Добавить скриншоты Kibana и Grafana
5. Сделать PR из ветки task-03-approaches в main
6. Опционально: развернуть на GCP для демонстрации
