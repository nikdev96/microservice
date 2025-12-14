# Микросервисы: принципы и подходы

Домашнее задание по микросервисной архитектуре с практической реализацией на GCP.

## 📋 Ответы на задания

### [Задание 2: Принципы микросервисной архитектуры](microservices-02-principles.md)

✅ **Задача 1:** Выбор API Gateway - **NGINX/Traefik**

✅ **Задача 2:** Выбор брокера сообщений - **Apache Kafka**

✅ **Задача 3:** Практическая реализация API Gateway на GCP

### [Задание 3: Подходы к организации инфраструктуры](README.md)

✅ **Задача 1:** CI/CD - **GitHub Actions**

✅ **Задача 2:** Логирование - **Vector + ElasticSearch + Kibana** (теория)

✅ **Задача 3:** Мониторинг - **Prometheus + Grafana** (теория)

✅ **Задача 4:** Логирование - **практическая реализация** (Vector + ElasticSearch + Kibana)

✅ **Задача 5:** Мониторинг - **практическая реализация** (Prometheus + Grafana)

---

## 🚀 Работающая система на GCP

**URL:** http://34.31.7.74

### Доступные сервисы

| Сервис | URL | Учетные данные |
|--------|-----|----------------|
| **API Gateway** | http://34.31.7.74 | - |
| **MinIO Console** | http://34.31.7.74:9001 | minioadmin / minioadmin |
| **Kibana (логи)** | http://34.31.7.74:8081 | Без аутентификации |
| **Grafana (метрики)** | http://34.31.7.74:8082 | admin / qwerty123456 |
| **Prometheus** | http://34.31.7.74:9090 | - |

### Архитектура

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

 Логирование         Мониторинг
┌──────────────┐  ┌──────────────┐
│ Vector       │  │ Prometheus   │
│   ↓          │  │   ↑          │
│ ElasticSearch│  │ Node Exporter│
│   ↓          │  │ cAdvisor     │
│ Kibana:8081  │  │   ↓          │
└──────────────┘  │ Grafana:8082 │
                  └──────────────┘
```

---

## 🧪 Тестирование API

### 1. Аутентификация

```bash
curl -X POST http://34.31.7.74/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

**Ответ:**
```json
{
  "success": true,
  "token": "valid-token-12345"
}
```

### 2. Загрузка файла

```bash
curl -X POST http://34.31.7.74/upload \
  -H "Authorization: Bearer valid-token-12345" \
  -F "file=@test.txt"
```

### 3. Список файлов

```bash
curl http://34.31.7.74/upload/list \
  -H "Authorization: Bearer valid-token-12345"
```

---

## 📊 Логирование (Задача 4)

**Kibana:** http://34.31.7.74:8081

### Возможности
- ✅ Сбор логов из всех контейнеров (stdout)
- ✅ Индексация в ElasticSearch: `microservices-logs-*`
- ✅ Автоматическая категоризация (error, warn, info, debug)
- ✅ Обогащение метаданными (service, service_type, environment)
- ✅ Полнотекстовый поиск и фильтрация

### Как использовать

1. Откройте http://34.31.7.74:8081
2. Перейдите в **Discover**
3. Создайте Index Pattern: `microservices-logs-*`
4. Просматривайте логи в реальном времени

### Примеры запросов

```
service:"security-service" AND log_level:"error"
service_type:"gateway"
message:*login*
```

**Документация:** [task-04-logging/README.md](task-04-logging/README.md)

---

## 📈 Мониторинг (Задача 5)

**Grafana:** http://34.31.7.74:8082 (admin / qwerty123456)

**Prometheus:** http://34.31.7.74:9090

### Собираемые метрики

1. **Системные метрики** (Node Exporter)
   - CPU usage, load average
   - Memory usage
   - Disk I/O
   - Network traffic

2. **Метрики контейнеров** (cAdvisor)
   - CPU по контейнеру
   - Memory по контейнеру
   - Network I/O
   - Filesystem usage

3. **Метрики сервисов**
   - NGINX (api-gateway)
   - Security Service
   - Uploader Service
   - MinIO

### Dashboard "Microservices Request Distribution"

Автоматически созданный dashboard показывает:
- Requests Rate by Service
- Container CPU Usage
- Container Memory Usage
- Network I/O by Service
- Request Distribution (Pie Chart)
- System Load Average

### Примеры PromQL запросов

```promql
# CPU usage по контейнерам
rate(container_cpu_usage_seconds_total{name=~"security-service|uploader-service"}[5m]) * 100

# Memory usage
container_memory_usage_bytes{name=~"security-service|uploader-service"}

# Network traffic (распределение запросов)
sum by (name) (rate(container_network_receive_bytes_total{name=~"security-service|uploader-service|api-gateway"}[5m]))
```

**Документация:** [task-05-monitoring/README.md](task-05-monitoring/README.md)

---

## 🛠 Развертывание на GCP

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

### 3. Проверка

```bash
# Проверить все контейнеры
ssh nikita@<VM_IP> "cd /opt/microservices && docker compose ps"

# Логи основных сервисов
ssh nikita@<VM_IP> "cd /opt/microservices && docker compose logs -f"

# Логи стека логирования
ssh nikita@<VM_IP> "cd /opt/microservices/task-04-logging && docker compose logs -f"

# Логи стека мониторинга
ssh nikita@<VM_IP> "cd /opt/microservices/task-05-monitoring && docker compose logs -f"
```

---

## 📁 Структура проекта

```
.
├── README.md                       # Этот файл
├── microservices-02-principles.md  # Ответы на задание 2
├── microservices-03-approaches.md  # Ответы на задание 3 (все задачи)
├── docker-compose.yml              # Основные микросервисы
├── nginx.conf                      # Конфигурация API Gateway
├── deploy-to-gcp.sh                # Скрипт развертывания
│
├── security-service/               # Сервис аутентификации
├── uploader-service/               # Сервис загрузки файлов
│
├── task-04-logging/                # Стек логирования (Задача 4)
│   ├── docker-compose.yml
│   ├── vector.toml
│   └── README.md
│
├── task-05-monitoring/             # Стек мониторинга (Задача 5)
│   ├── docker-compose.yml
│   ├── prometheus.yml
│   ├── grafana-provisioning/
│   └── README.md
│
└── terraform/                      # Инфраструктура GCP
    ├── main.tf
    ├── variables.tf
    └── terraform.tfvars.example
```

---

## ✅ Результаты

### Задание 2

- ✅ Проанализировано 7 API Gateway решений
- ✅ Проанализировано 7 брокеров сообщений
- ✅ Развернута практическая реализация на GCP
- ✅ Работает аутентификация, загрузка файлов, авторизация

### Задание 3

- ✅ Выбран CI/CD (GitHub Actions)
- ✅ Выбрана система логирования (Vector + Loki/ElasticSearch + Grafana/Kibana)
- ✅ Выбрана система мониторинга (Prometheus + Grafana)
- ✅ **Практическая реализация логирования** (Vector + ElasticSearch + Kibana на порту 8081)
- ✅ **Практическая реализация мониторинга** (Prometheus + Grafana на порту 8082)
- ✅ Dashboard с распределением запросов по сервисам
- ✅ Все метрики собираются (CPU, RAM, HDD, Network)

---

## 💰 Стоимость GCP

- VM e2-medium: ~$24/мес
- Диск 30GB: ~$1.20/мес
- IP: ~$3/мес

**Итого:** ~$28/мес

---

## 🔗 Полезные ссылки

### Документация
- [Задание 2: Принципы микросервисной архитектуры](microservices-02-principles.md)
- [Задание 3: Подходы к организации инфраструктуры](README.md)
- [Стек логирования](task-04-logging/README.md)
- [Стек мониторинга](task-05-monitoring/README.md)
- [Terraform на GCP](terraform/README.md)

### Работающая система
- API Gateway: http://34.31.7.74
- Kibana: http://34.31.7.74:8081
- Grafana: http://34.31.7.74:8082 (admin/qwerty123456)
- Prometheus: http://34.31.7.74:9090
- MinIO Console: http://34.31.7.74:9001 (minioadmin/minioadmin)
