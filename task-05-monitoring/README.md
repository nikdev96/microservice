# Задача 5: Система мониторинга

Стек мониторинга с Prometheus и Grafana для сбора метрик и визуализации состояния микросервисов.

## Архитектура

```
┌──────────────┐
│ Микросервисы │
│   + MinIO    │
└──────┬───────┘
       │ Metrics endpoints
       ▼
┌──────────────┐     ┌──────────────┐
│ Node Exporter│     │   cAdvisor   │
│ (Host metrics)     │ (Containers) │
└──────┬───────┘     └──────┬───────┘
       │                    │
       └────────┬───────────┘
                │ /metrics
                ▼
         ┌──────────────┐
         │  Prometheus  │ ← Time-series DB
         └──────┬───────┘
                │
                ▼
         ┌──────────────┐
         │   Grafana    │ ← UI (localhost:8082)
         └──────────────┘
```

## Компоненты

### Prometheus
- Сбор метрик из всех источников каждые 15 секунд
- Хранение временных рядов (retention: 7 дней)
- PromQL для запросов
- Targets:
  - Prometheus self-monitoring
  - Node Exporter (системные метрики)
  - cAdvisor (метрики контейнеров)
  - NGINX, Security, Uploader, MinIO (если есть /metrics)

### Node Exporter
- Метрики хоста: CPU, память, диск, сеть
- Load average, filesystem usage
- System uptime

### cAdvisor
- Метрики Docker контейнеров
- CPU, память, сеть, I/O по каждому контейнеру
- Распределение ресурсов

### Grafana
- Web UI на порту 8082
- Credentials: `admin` / `qwerty123456`
- Автоматически настроенный Prometheus datasource
- Готовый dashboard "Microservices Request Distribution"

## Быстрый старт

### 1. Убедиться что основные сервисы запущены

```bash
cd /Users/nikita/lessons/micro1
docker compose ps
```

Должны работать: `api-gateway`, `security-service`, `uploader-service`, `minio`

### 2. Запустить стек мониторинга

```bash
cd /Users/nikita/lessons/micro1/task-05-monitoring
docker compose up -d
```

### 3. Проверить статус сервисов

```bash
docker compose ps
docker compose logs -f
```

Ждем пока все сервисы станут healthy.

### 4. Открыть Grafana

Браузер: http://localhost:8082

**Credentials**: `admin` / `qwerty123456`

Dashboard "Microservices Request Distribution" будет автоматически создан.

## Использование

### Prometheus UI

http://localhost:9090

**Полезные запросы** (Prometheus → Graph):

```promql
# CPU usage по контейнерам
rate(container_cpu_usage_seconds_total{name=~"security-service|uploader-service|api-gateway"}[5m]) * 100

# Memory usage по контейнерам
container_memory_usage_bytes{name=~"security-service|uploader-service|api-gateway"}

# Network traffic по сервисам
rate(container_network_receive_bytes_total{name="security-service"}[5m])

# System load average
node_load1

# Disk usage
node_filesystem_avail_bytes{mountpoint="/"}
```

### Grafana Dashboards

1. **Microservices Request Distribution** (автоматически создан):
   - Requests rate by service
   - CPU usage per container
   - Memory usage per container
   - Network I/O by service
   - Request distribution (pie chart)
   - System load average

2. **Создание своих dashboards**:
   - Dashboards → New Dashboard
   - Add panel → Select metric from Prometheus
   - Visualize и Save

### Алерты (опционально)

Можно настроить алерты в Grafana:
1. Dashboard → Panel → Alert
2. Create alert rule
3. Configure notification channels (email, Slack, etc.)

## Генерация нагрузки для тестирования

```bash
# Скрипт для генерации запросов
for i in {1..100}; do
  # Login requests
  curl -X POST http://localhost/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin"}' &

  # Upload requests
  curl -X POST http://localhost/upload \
    -H "Authorization: Bearer valid-token-12345" \
    -F "file=@test.txt" &

  # List files
  curl http://localhost/upload/list \
    -H "Authorization: Bearer valid-token-12345" &

  sleep 0.1
done

wait
echo "Load test completed"
```

После этого в Grafana dashboard появятся графики распределения запросов.

## Проверка метрик

### Проверить что Prometheus собирает метрики

```bash
# Targets status
curl http://localhost:9090/api/v1/targets

# Query metrics
curl 'http://localhost:9090/api/v1/query?query=up'

# Node Exporter metrics
curl http://localhost:9100/metrics

# cAdvisor metrics
curl http://localhost:8080/metrics
```

## Управление

### Остановка

```bash
docker compose down
```

### Остановка с удалением данных

```bash
docker compose down -v
```

### Перезапуск

```bash
docker compose restart
```

### Просмотр логов

```bash
# Все логи
docker compose logs -f

# Конкретный сервис
docker compose logs -f prometheus
docker compose logs -f grafana
docker compose logs -f cadvisor
```

## Интеграция с основным стеком

Этот стек мониторинга работает независимо от основных микросервисов в `/Users/nikita/lessons/micro1/docker-compose.yml`.

Prometheus подключается к сети `microservices` и собирает метрики из всех контейнеров через:
- Docker socket (cAdvisor)
- HTTP endpoints /metrics (если доступны)
- Node Exporter для системных метрик

## Troubleshooting

### Prometheus не может scrape targets

- Проверить что сеть microservices существует:
  ```bash
  docker network ls | grep microservices
  ```
- Проверить targets в Prometheus UI: http://localhost:9090/targets
- Проверить логи: `docker compose logs prometheus`

### Grafana не показывает данные

- Проверить что Prometheus datasource настроен: Grafana → Configuration → Data Sources
- Проверить что есть данные в Prometheus: http://localhost:9090/graph
- Попробовать простой запрос: `up`

### cAdvisor не запускается на Mac

cAdvisor имеет ограничения на macOS. На production (Linux/GCP) работает нормально.
Для Mac можно закомментировать cAdvisor в docker-compose.yml.

## Метрики по требованиям задачи

✅ **Prometheus** - сбор и хранение метрик
✅ **Node Exporter** - метрики хоста
✅ **cAdvisor** - метрики контейнеров
✅ **Grafana** - визуализация на порту 8082
✅ **Dashboard** - распределение запросов по сервисам
✅ **Credentials** - admin/qwerty123456

## Полезные ссылки

- Prometheus: http://localhost:9090
- Grafana: http://localhost:8082
- Node Exporter: http://localhost:9100/metrics
- cAdvisor: http://localhost:8080

## Следующие шаги

1. Запустить стек и дождаться готовности
2. Открыть Grafana и проверить dashboard
3. Сгенерировать нагрузку для тестирования
4. Создать дополнительные dashboards при необходимости
5. Сделать скриншоты для документации
