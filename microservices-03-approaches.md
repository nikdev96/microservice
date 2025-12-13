# Домашнее задание: Микросервисы: подходы

## Задача 1: Обеспечить разработку

### Требования

- Облачная система
- Git система контроля версий
- Отдельный репозиторий для каждого сервиса
- Запуск сборки по событиям из VCS
- Запуск сборки по кнопке с параметрами
- Привязка настроек к каждой сборке
- Шаблоны для различных конфигураций
- Безопасное хранение секретов
- Несколько конфигураций из одного репозитория
- Кастомные шаги при сборке
- Собственные Docker-образы для сборки
- Возможность развернуть агентов сборки на собственных серверах
- Параллельный запуск сборок и тестов

### Сравнительная таблица CI/CD решений

| Критерий | GitHub Actions | GitLab CI/CD | Jenkins | TeamCity | CircleCI |
|----------|---------------|--------------|---------|----------|----------|
| **Облачная система** | ✅ GitHub.com | ✅ GitLab.com | ❌ Self-hosted | ✅ Cloud/Self | ✅ Cloud |
| **Git интеграция** | ✅ Native GitHub | ✅ Native GitLab | ✅ Плагины | ✅ Плагины | ✅ Интеграция |
| **Отдельные репо** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Триггеры из VCS** | ✅ Webhooks | ✅ Webhooks | ✅ Webhooks | ✅ Webhooks | ✅ Webhooks |
| **Запуск с параметрами** | ✅ workflow_dispatch | ✅ Manual jobs | ✅ Параметры | ✅ Custom params | ✅ API triggers |
| **Конфигурация как код** | ✅ YAML | ✅ .gitlab-ci.yml | ✅ Jenkinsfile | ⚠️ GUI+Kotlin DSL | ✅ .circleci/config.yml |
| **Шаблоны** | ✅ Reusable workflows | ✅ Templates/Includes | ✅ Shared libraries | ✅ Build templates | ✅ Orbs |
| **Секреты** | ✅ Secrets | ✅ CI/CD Variables | ✅ Credentials | ✅ Parameters | ✅ Contexts |
| **Monorepo support** | ✅ Paths filter | ✅ Rules/changes | ✅ Conditional | ✅ Build chains | ✅ Path filtering |
| **Кастомные шаги** | ✅ Actions | ✅ Scripts | ✅ Groovy/Scripts | ✅ Build steps | ✅ Commands |
| **Docker для сборки** | ✅ Container jobs | ✅ Docker executor | ✅ Docker agent | ✅ Docker support | ✅ Docker executor |
| **Self-hosted runners** | ✅ | ✅ GitLab Runner | ✅ Agents | ✅ Build agents | ✅ Runner |
| **Параллельные сборки** | ✅ Matrix builds | ✅ Parallel jobs | ✅ Parallel stages | ✅ Parallel | ✅ Parallelism |
| **Бесплатный tier** | ✅ 2000 мин/мес | ✅ 400 мин/мес | ✅ Open source | ❌ Trial only | ✅ 6000 мин/мес |
| **Стоимость (paid)** | $4/мес (20000 мин) | $19/мес (10000 мин) | Free (self) | $45/мес (3 agents) | $15/мес (25000 мин) |

### Рекомендуемое решение: **GitHub Actions**

#### Обоснование выбора

**Соответствие требованиям:**

✅ **Облачная система** - GitHub.com с глобальной инфраструктурой

✅ **Git контроль версий** - нативная интеграция с GitHub

✅ **Отдельные репозитории** - каждый сервис в своем репо с отдельным workflow

✅ **Триггеры из VCS** - автоматический запуск при push/PR/tag:
```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
```

✅ **Запуск по кнопке с параметрами**:
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment'
        required: true
        default: 'staging'
        type: choice
        options: [dev, staging, production]
      version:
        description: 'Version tag'
        required: true
```

✅ **Привязка настроек** - каждый workflow в `.github/workflows/`

✅ **Шаблоны конфигураций** - reusable workflows:
```yaml
jobs:
  deploy:
    uses: company/workflows/.github/workflows/deploy.yml@v1
    with:
      environment: production
```

✅ **Безопасное хранение секретов** - GitHub Secrets с шифрованием, scope на уровне environment

✅ **Monorepo поддержка** - path filtering:
```yaml
on:
  push:
    paths:
      - 'services/auth/**'
```

✅ **Кастомные шаги** - GitHub Actions Marketplace (40,000+ actions)

✅ **Docker для сборки**:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: node:18
```

✅ **Self-hosted runners** - агенты на своих серверах (Linux/Windows/macOS)

✅ **Параллельные сборки** - matrix strategy:
```yaml
strategy:
  matrix:
    service: [auth, api, frontend]
    node: [16, 18, 20]
```

#### Преимущества

1. **Интеграция с экосистемой GitHub**
   - Pull Request checks
   - Status badges
   - GitHub Pages deploy
   - GitHub Packages registry

2. **Простота использования**
   - YAML конфигурация
   - Визуальный редактор workflow
   - Встроенная документация

3. **Масштабируемость**
   - Автоскейлинг runners
   - Глобальная CDN
   - Параллелизм до 256 jobs

4. **Безопасность**
   - OIDC для бесключевой авторизации
   - Code scanning (CodeQL)
   - Dependency review
   - Secret scanning

5. **Экономичность**
   - 2000 минут/месяц бесплатно для приватных репо
   - Unlimited для публичных
   - Flexible pricing

#### Пример конфигурации для микросервиса

```yaml
name: Build and Deploy Microservice

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:
    inputs:
      environment:
        required: true
        type: choice
        options: [dev, staging, production]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16, 18, 20]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm ci
      - run: npm test
      - run: npm run lint

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: ${{ inputs.environment || 'staging' }}
      url: https://${{ inputs.environment }}.example.com
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Kubernetes
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG }}
        run: |
          kubectl set image deployment/my-service \
            app=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:sha-${GITHUB_SHA::7}
```

#### Альтернативные варианты

**GitLab CI/CD** - если уже используется GitLab:
- Более тесная интеграция с GitLab
- Built-in Container Registry
- Auto DevOps

**Jenkins** - для enterprise с legacy:
- Максимальная гибкость
- Огромная экосистема плагинов
- Полный контроль (self-hosted)

---

## Задача 2: Логи

### Требования

- Сбор логов в центральное хранилище со всех хостов
- Минимальные требования к приложениям, сбор из stdout
- Гарантированная доставка логов
- Поиск и фильтрация по записям
- UI с доступом для разработчиков
- Сохраняемые поиски

### Сравнительная таблица систем логирования

| Критерий | ELK Stack | Loki + Grafana | Splunk | Datadog | Graylog |
|----------|-----------|----------------|--------|---------|---------|
| **Компоненты** | Beats/Logstash + Elasticsearch + Kibana | Promtail + Loki + Grafana | Forwarder + Splunk | Agent + Datadog | Collector + Graylog |
| **Сбор со всех хостов** | ✅ Filebeat/Fluentd | ✅ Promtail | ✅ Universal Forwarder | ✅ Agent | ✅ Sidecar/Beats |
| **Сбор из stdout** | ✅ Docker logging driver | ✅ Docker driver | ✅ Docker plugin | ✅ Container logs | ✅ GELF |
| **Гарантированная доставка** | ✅ At-least-once | ✅ Buffering | ✅ Queue | ✅ Buffering | ✅ Buffer |
| **Поиск и фильтрация** | ✅ Lucene query | ✅ LogQL | ✅ SPL | ✅ Query language | ✅ Search |
| **UI для разработчиков** | ✅ Kibana | ✅ Grafana Explore | ✅ Splunk UI | ✅ Web UI | ✅ Web interface |
| **Сохраняемые поиски** | ✅ Saved searches | ✅ Saved queries | ✅ Saved searches | ✅ Saved views | ✅ Streams |
| **Индексация** | ✅ Full-text | ⚠️ Labels only | ✅ Full-text | ✅ Full-text | ✅ Full-text |
| **Производительность** | Средняя (тяжелый) | Высокая (легкий) | Высокая | Высокая | Средняя |
| **Масштабируемость** | ✅ Horizontal | ✅ Horizontal | ✅ Distributed | ✅ Cloud | ✅ Cluster |
| **Open Source** | ✅ Apache 2.0/SSPL | ✅ Apache 2.0 | ❌ Commercial | ❌ SaaS | ✅ GPL |
| **Стоимость** | Free (self) / $$$ (Elastic Cloud) | Free (self) | $$$$ Enterprise | $$$ SaaS | Free / $$ Enterprise |
| **Сложность установки** | Средняя | Низкая | Высокая | Очень низкая | Средняя |

### Рекомендуемое решение: **Loki + Grafana + Promtail**

#### Обоснование выбора

**Соответствие требованиям:**

✅ **Централизованное хранилище** - Loki агрегирует логи со всех источников

✅ **Минимальные требования** - сбор из stdout через Docker logging driver:
```yaml
# docker-compose.yml
services:
  app:
    logging:
      driver: loki
      options:
        loki-url: "http://loki:3100/loki/api/v1/push"
        loki-batch-size: "400"
```

✅ **Гарантированная доставка** - Promtail с disk buffering

✅ **Поиск и фильтрация** - LogQL:
```logql
{service="api"} |= "error" | json | status_code >= 500
```

✅ **UI для разработчиков** - Grafana Explore с RBAC:
```yaml
# Grafana datasource
apiVersion: 1
datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
```

✅ **Сохраняемые поиски** - Grafana dashboards и saved queries

#### Архитектура решения

```
┌──────────────┐
│ Microservice │
│   (stdout)   │
└──────┬───────┘
       │
       ▼
┌──────────────┐      ┌──────────┐      ┌──────────┐
│   Promtail   │─────▶│   Loki   │◀─────│  Grafana │
│  (collector) │      │ (storage)│      │   (UI)   │
└──────────────┘      └──────────┘      └──────────┘
```

#### Преимущества

1. **Легковесность**
   - Индексирует только метаданные (labels), не весь текст
   - Низкое потребление ресурсов
   - Быстрый поиск по labels

2. **Простота**
   - Минимальная конфигурация
   - Легко деплоить
   - Нативная интеграция с Grafana

3. **Экономичность**
   - Open source (Apache 2.0)
   - Низкие требования к storage
   - Дешевле чем ELK на 70%

4. **Интеграция**
   - Единый UI с метриками (Grafana)
   - Correlation логов и метрик
   - Kubernetes-native

#### Пример конфигурации

**Promtail config:**
```yaml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: containers
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
    relabel_configs:
      - source_labels: [__meta_docker_container_name]
        target_label: container
      - source_labels: [__meta_docker_container_label_com_docker_compose_service]
        target_label: service
```

**Loki config:**
```yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2024-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/cache
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

limits_config:
  retention_period: 744h  # 31 days
```

**Docker Compose:**
```yaml
version: '3'

services:
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yml:/etc/loki/config.yml
      - loki-data:/loki
    command: -config.file=/etc/loki/config.yml

  promtail:
    image: grafana/promtail:latest
    volumes:
      - ./promtail-config.yml:/etc/promtail/config.yml
      - /var/run/docker.sock:/var/run/docker.sock
    command: -config.file=/etc/promtail/config.yml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  loki-data:
  grafana-data:
```

#### Альтернативные варианты

**ELK Stack** - для full-text search:
- Мощный поиск по содержимому
- Rich query language
- Большая экосистема

**Datadog** - для enterprise с бюджетом:
- Managed solution
- Логи + метрики + APM в одном
- AI-powered insights

---

## Задача 3: Мониторинг

### Требования

- Сбор метрик со всех хостов
- Метрики ресурсов: CPU, RAM, HDD, Network
- Метрики потребляемых ресурсов для каждого сервиса
- Специфичные метрики сервисов
- UI с запросами и агрегацией
- UI для настройки dashboards

### Сравнительная таблица систем мониторинга

| Критерий | Prometheus + Grafana | Datadog | New Relic | Zabbix | Victoria Metrics |
|----------|---------------------|---------|-----------|--------|------------------|
| **Сбор с хостов** | ✅ Node Exporter | ✅ Agent | ✅ Agent | ✅ Agent | ✅ vmagent |
| **Метрики ресурсов** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Per-service метрики** | ✅ cAdvisor | ✅ Container | ✅ Container | ✅ Docker monitoring | ✅ |
| **Custom метрики** | ✅ Client libs | ✅ Custom metrics | ✅ Custom attributes | ✅ UserParameters | ✅ |
| **Query language** | ✅ PromQL | ✅ Query | ✅ NRQL | ⚠️ UI-based | ✅ PromQL compatible |
| **Агрегация** | ✅ PromQL | ✅ Aggregation | ✅ NRQL | ✅ Calculated items | ✅ MetricsQL |
| **Dashboard UI** | ✅ Grafana | ✅ Built-in | ✅ Built-in | ⚠️ Basic | ✅ Grafana |
| **Alerting** | ✅ Alertmanager | ✅ Monitors | ✅ Alerts | ✅ Triggers | ✅ vmalert |
| **Retention** | ⚠️ 15d default | ✅ 15 months | ✅ Configurable | ✅ Configurable | ✅ Unlimited |
| **Масштабируемость** | ⚠️ Федерация | ✅ SaaS | ✅ SaaS | ⚠️ Proxy | ✅ Кластер |
| **Open Source** | ✅ Apache 2.0 | ❌ SaaS | ❌ SaaS | ✅ GPL | ✅ Apache 2.0 |
| **Стоимость** | Free | $$$ ($15/host) | $$$ ($25/user) | Free | Free |
| **Service Discovery** | ✅ K8s, Consul, DNS | ✅ Auto | ✅ Auto | ⚠️ Manual | ✅ |

### Рекомендуемое решение: **Prometheus + Grafana**

#### Обоснование выбора

**Соответствие требованиям:**

✅ **Сбор метрик со всех хостов** - Node Exporter на каждом хосте

✅ **Метрики ресурсов (CPU, RAM, HDD, Network)**:
```promql
# CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# Disk usage
100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)

# Network traffic
rate(node_network_receive_bytes_total[5m])
```

✅ **Метрики потребления каждого сервиса** - cAdvisor для containers:
```promql
# Container CPU
rate(container_cpu_usage_seconds_total{name="api-service"}[5m])

# Container Memory
container_memory_usage_bytes{name="api-service"}
```

✅ **Специфичные метрики** - instrumentation библиотеки:
```javascript
// Node.js example
const client = require('prom-client');

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});
```

✅ **UI с запросами** - Grafana Explore + PromQL

✅ **Dashboard builder** - Grafana с drag-and-drop

#### Архитектура решения

```
┌──────────────┐    ┌──────────────┐
│ Node Exporter│    │   cAdvisor   │
│ (host metrics)│    │ (containers) │
└──────┬───────┘    └──────┬───────┘
       │                   │
       │  /metrics         │  /metrics
       │                   │
       ▼                   ▼
   ┌────────────────────────────┐
   │       Prometheus           │
   │   (scrape & storage)       │
   └────────────┬───────────────┘
                │
                │ PromQL API
                ▼
          ┌───────────┐
          │  Grafana  │
          │   (UI)    │
          └───────────┘
```

#### Преимущества

1. **Industry Standard**
   - CNCF graduated project
   - Огромное сообщество
   - Множество exporters (200+)

2. **Pull-based модель**
   - Service discovery
   - Health checks из коробки
   - Нет агентов на приложениях

3. **Мощный query язык**
   - PromQL для сложных запросов
   - Агрегация и математика
   - Alerting rules

4. **Интеграция**
   - Kubernetes native
   - Готовые dashboards (10,000+)
   - Экспорт в другие системы

5. **Экосистема**
   - Alertmanager для уведомлений
   - Pushgateway для batch jobs
   - Blackbox exporter для probing

#### Пример конфигурации

**Prometheus config:**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - "alerts/*.yml"

scrape_configs:
  # Node Exporter - метрики хостов
  - job_name: 'node'
    static_configs:
      - targets:
        - 'node-exporter:9100'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance

  # cAdvisor - метрики контейнеров
  - job_name: 'cadvisor'
    static_configs:
      - targets:
        - 'cadvisor:8080'

  # Application metrics
  - job_name: 'services'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
```

**Docker Compose:**
```yaml
version: '3'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning

volumes:
  prometheus-data:
  grafana-data:
```

**Alert rules:**
```yaml
# alerts/rules.yml
groups:
  - name: host
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value }}%"

      - alert: HighMemoryUsage
        expr: 100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"

  - name: services
    rules:
      - alert: ServiceDown
        expr: up{job="services"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate for {{ $labels.service }}"
```

#### Альтернативные варианты

**Victoria Metrics** - для больших масштабов:
- Более эффективное хранение
- Лучшая производительность
- PromQL совместимость

**Datadog** - для managed решения:
- Все в одном (логи + метрики + APM)
- AI anomaly detection
- Не требует управления

---

## Выводы

Для микросервисной архитектуры рекомендуется следующий стек:

### CI/CD: GitHub Actions
- Облачная система с отличной интеграцией
- Простая конфигурация
- Экономичная

### Логирование: Loki + Grafana
- Легковесное решение
- Простая интеграция с мониторингом
- Low cost

### Мониторинг: Prometheus + Grafana
- Industry standard для микросервисов
- Богатая экосистема
- Open source

Все три компонента интегрируются в единую observability платформу на базе Grafana, что обеспечивает:
- Единый UI для разработчиков
- Correlation между логами и метриками
- Низкая стоимость владения
- Простота поддержки
