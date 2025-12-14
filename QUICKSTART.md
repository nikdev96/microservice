# Микросервисы: принципы и подходы

Домашнее задание по микросервисной архитектуре с практической реализацией на GCP.

## Ответы на задания

### Задание 2: Принципы микросервисной архитектуры

Документ: [microservices-02-principles.md](microservices-02-principles.md)

- Задача 1: Выбор API Gateway - **NGINX/Traefik**
- Задача 2: Выбор брокера сообщений - **Apache Kafka**
- Задача 3: Практическая реализация API Gateway на GCP

### Задание 3: Подходы к организации инфраструктуры

Документ: [README.md](README.md)

- Задача 1: CI/CD - **GitHub Actions**
- Задача 2: Логирование - **Loki + Grafana** (теория)
- Задача 3: Мониторинг - **Prometheus + Grafana** (теория)
- Задача 4: Логирование - **Vector + ElasticSearch + Kibana** (практика)
- Задача 5: Мониторинг - **Prometheus + Grafana** (практика)

---

## Работающая система на GCP

URL: http://34.31.7.74

### Доступные сервисы

| Сервис | URL | Учетные данные |
|--------|-----|----------------|
| API Gateway | http://34.31.7.74 | - |
| MinIO Console | http://34.31.7.74:9001 | minioadmin / minioadmin |
| Kibana (логи) | http://34.31.7.74:8081 | - |
| Grafana (метрики) | http://34.31.7.74:8082 | admin / qwerty123456 |
| Prometheus | http://34.31.7.74:9090 | - |

---

## Быстрый старт

### Тестирование API

```bash
# Аутентификация
curl -X POST http://34.31.7.74/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'

# Загрузка файла
curl -X POST http://34.31.7.74/upload \
  -H "Authorization: Bearer valid-token-12345" \
  -F "file=@test.txt"

# Список файлов
curl http://34.31.7.74/upload/list \
  -H "Authorization: Bearer valid-token-12345"
```

### Просмотр логов

Kibana: http://34.31.7.74:8081

1. Откройте Discover
2. Создайте Index Pattern: `microservices-logs-*`
3. Просматривайте логи в реальном времени

### Просмотр метрик

Grafana: http://34.31.7.74:8082 (admin / qwerty123456)

Dashboard "Microservices Request Distribution" показывает:
- Requests Rate by Service
- Container CPU Usage
- Container Memory Usage
- Network I/O by Service
- Request Distribution (Pie Chart)
- System Load Average

Prometheus: http://34.31.7.74:9090

---

## Развертывание на GCP

### 1. Создание инфраструктуры

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Отредактируйте terraform.tfvars (project_id, ssh_public_key)

terraform init
terraform apply
```

### 2. Деплой всех сервисов

```bash
./deploy-to-gcp.sh <VM_IP>
```

Скрипт автоматически развертывает:
1. Основные микросервисы (NGINX, Security, Uploader, MinIO)
2. Стек логирования (Vector + ElasticSearch + Kibana)
3. Стек мониторинга (Prometheus + Grafana + Node Exporter + cAdvisor)

---

## Структура проекта

```
.
├── README.md                       # Ответы на задание 3
├── QUICKSTART.md                   # Этот файл
├── microservices-02-principles.md  # Ответы на задание 2
├── docker-compose.yml              # Основные микросервисы
├── nginx.conf                      # Конфигурация API Gateway
├── deploy-to-gcp.sh                # Скрипт развертывания
├── security-service/               # Сервис аутентификации
├── uploader-service/               # Сервис загрузки файлов
├── task-04-logging/                # Стек логирования
│   ├── docker-compose.yml
│   ├── vector.toml
│   └── README.md
├── task-05-monitoring/             # Стек мониторинга
│   ├── docker-compose.yml
│   ├── prometheus.yml
│   ├── grafana-provisioning/
│   └── README.md
└── terraform/                      # Инфраструктура GCP
    ├── main.tf
    ├── variables.tf
    └── terraform.tfvars.example
```

---

## Документация

- [Задание 2: Принципы микросервисной архитектуры](microservices-02-principles.md)
- [Задание 3: Подходы к организации инфраструктуры](README.md)
- [Стек логирования](task-04-logging/README.md)
- [Стек мониторинга](task-05-monitoring/README.md)
- [Terraform на GCP](terraform/README.md)
