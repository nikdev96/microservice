# Домашнее задание: Микросервисы: подходы

## Задача 1: Обеспечить разработку

### Сравнительная таблица CI/CD решений

| Критерий | GitHub Actions | GitLab CI/CD | Jenkins | TeamCity | CircleCI |
|----------|---------------|--------------|---------|----------|----------|
| Облачная система | Да | Да | Нет | Да | Да |
| Git интеграция | Native | Native | Плагины | Плагины | Да |
| Триггеры из VCS | Да | Да | Да | Да | Да |
| Запуск с параметрами | workflow_dispatch | Manual jobs | Да | Да | API triggers |
| Конфигурация как код | YAML | YAML | Jenkinsfile | GUI+Kotlin DSL | YAML |
| Шаблоны | Reusable workflows | Templates | Shared libraries | Build templates | Orbs |
| Безопасное хранение секретов | Secrets | CI/CD Variables | Credentials | Parameters | Contexts |
| Monorepo support | Paths filter | Rules/changes | Conditional | Build chains | Path filtering |
| Кастомные шаги | Actions | Scripts | Groovy/Scripts | Build steps | Commands |
| Docker для сборки | Container jobs | Docker executor | Docker agent | Да | Docker executor |
| Self-hosted runners | Да | GitLab Runner | Agents | Build agents | Runner |
| Параллельные сборки | Matrix builds | Parallel jobs | Parallel stages | Да | Parallelism |
| Бесплатный tier | 2000 мин/мес | 400 мин/мес | Open source | Trial only | 6000 мин/мес |
| Стоимость | $4/мес | $19/мес | Free (self) | $45/мес | $15/мес |

### Выбор: GitHub Actions

**Обоснование:**
- Нативная интеграция с GitHub
- Простая YAML конфигурация
- Богатый Marketplace (40,000+ actions)
- Бесплатный tier 2000 минут/месяц
- Поддержка всех требований из задания
- Self-hosted runners для собственных серверов
- Встроенная безопасность (Secrets, OIDC, Code scanning)

---

## Задача 2: Логи

### Сравнительная таблица систем логирования

| Критерий | Loki + Grafana | ELK Stack | Splunk | Datadog | Graylog |
|----------|----------------|-----------|--------|---------|---------|
| Сбор со всех хостов | Promtail | Beats/Logstash | Forwarder | Agent | Collector |
| Сбор из stdout | Docker driver | Docker driver | Docker plugin | Container logs | GELF |
| Гарантированная доставка | Buffering | At-least-once | Queue | Buffering | Buffer |
| Поиск и фильтрация | LogQL | Lucene query | SPL | Query language | Search |
| UI для разработчиков | Grafana Explore | Kibana | Splunk UI | Web UI | Web interface |
| Сохраняемые поиски | Saved queries | Saved searches | Saved searches | Saved views | Streams |
| Индексация | Labels only | Full-text | Full-text | Full-text | Full-text |
| Производительность | Высокая | Средняя | Высокая | Высокая | Средняя |
| Open Source | Да | Да/SSPL | Нет | Нет | Да |
| Стоимость | Free | Free / $$$ Cloud | $$$$ | $$$ SaaS | Free / $$ |

### Выбор: Loki + Grafana + Promtail

**Обоснование:**
- Легковесное решение (индексирует только метаданные)
- Низкое потребление ресурсов
- Простая интеграция с Grafana
- Open source (Apache 2.0)
- Единый UI с метриками
- На 70% дешевле ELK Stack

---

## Задача 3: Мониторинг

### Сравнительная таблица систем мониторинга

| Критерий | Prometheus + Grafana | Datadog | New Relic | Zabbix | Victoria Metrics |
|----------|---------------------|---------|-----------|--------|------------------|
| Сбор с хостов | Node Exporter | Agent | Agent | Agent | vmagent |
| Метрики ресурсов | CPU, RAM, HDD, Network | Да | Да | Да | Да |
| Per-service метрики | cAdvisor | Container | Container | Docker monitoring | Да |
| Custom метрики | Client libs | Custom metrics | Custom attributes | UserParameters | Да |
| Query language | PromQL | Query | NRQL | UI-based | PromQL compatible |
| Dashboard UI | Grafana | Built-in | Built-in | Basic | Grafana |
| Alerting | Alertmanager | Monitors | Alerts | Triggers | vmalert |
| Open Source | Да | Нет | Нет | Да | Да |
| Стоимость | Free | $$$ | $$$ | Free | Free |
| Service Discovery | K8s, Consul, DNS | Auto | Auto | Manual | Да |

### Выбор: Prometheus + Grafana

**Обоснование:**
- Industry standard для микросервисов
- CNCF graduated project
- Pull-based модель с service discovery
- Мощный язык запросов PromQL
- Богатая экосистема (200+ exporters)
- Open source с большим сообществом
- Готовые dashboards (10,000+)

---

## Задача 4: Логирование (практическая реализация)

**Реализовано:** Vector + ElasticSearch + Kibana

**Развертывание на GCP:** http://34.31.7.74:8081

### Компоненты

- **Vector 0.35.0** - сбор логов из Docker контейнеров
- **ElasticSearch 8.11.3** - хранение и индексирование
- **Kibana 8.11.3** - веб-интерфейс

### Возможности

- Автоматический сбор логов из stdout (api-gateway, security-service, uploader-service, minio)
- Обогащение метаданными (service, service_type, log_level, environment)
- Автоматическая категоризация по уровням (error, warn, info, debug)
- Индексация в ElasticSearch: `microservices-logs-YYYY.MM.DD`
- Полнотекстовый поиск и фильтрация

### Использование

1. Откройте Kibana: http://34.31.7.74:8081
2. Создайте Index Pattern: `microservices-logs-*`
3. Просматривайте логи в разделе Discover

Подробная документация: [task-04-logging/README.md](task-04-logging/README.md)

---

## Задача 5: Мониторинг (практическая реализация)

**Реализовано:** Prometheus + Grafana + Node Exporter + cAdvisor

**Развертывание на GCP:**
- Grafana: http://34.31.7.74:8082 (admin / qwerty123456)
- Prometheus: http://34.31.7.74:9090

### Компоненты

- **Prometheus 2.48.1** - сбор и хранение метрик (scrape interval: 15s, retention: 7 дней)
- **Grafana 10.2.3** - визуализация и dashboards
- **Node Exporter 1.7.0** - системные метрики хоста
- **cAdvisor 0.47.2** - метрики Docker контейнеров

### Собираемые метрики

**Системные метрики:**
- CPU usage, load average
- Memory usage
- Disk I/O
- Network traffic

**Метрики контейнеров:**
- CPU и Memory по каждому контейнеру
- Network I/O
- Filesystem usage

**Метрики сервисов:**
- NGINX (api-gateway)
- Security Service
- Uploader Service
- MinIO

### Dashboard "Microservices Request Distribution"

Включает панели:
1. Requests Rate by Service
2. Container CPU Usage
3. Container Memory Usage
4. Network I/O by Service
5. Request Distribution (Pie Chart)
6. System Load Average

Подробная документация: [task-05-monitoring/README.md](task-05-monitoring/README.md)

---

## Развертывание на GCP

### 1. Создание инфраструктуры

```bash
cd terraform
terraform init
terraform apply
```

### 2. Деплой всех сервисов

```bash
./deploy-to-gcp.sh <VM_IP>
```

Скрипт автоматически развертывает:
- Основные микросервисы (NGINX, Security, Uploader, MinIO)
- Стек логирования (Vector + ElasticSearch + Kibana)
- Стек мониторинга (Prometheus + Grafana + Node Exporter + cAdvisor)

### 3. Доступ к сервисам

| Сервис | URL | Учетные данные |
|--------|-----|----------------|
| API Gateway | http://34.31.7.74 | - |
| MinIO Console | http://34.31.7.74:9001 | minioadmin / minioadmin |
| Kibana | http://34.31.7.74:8081 | - |
| Grafana | http://34.31.7.74:8082 | admin / qwerty123456 |
| Prometheus | http://34.31.7.74:9090 | - |

---

## Выводы

Для микросервисной архитектуры рекомендуется следующий стек:

**CI/CD:** GitHub Actions
- Облачная система с отличной интеграцией
- Простая конфигурация
- Экономичная

**Логирование:** Vector + ElasticSearch + Kibana
- Развернуто на GCP: http://34.31.7.74:8081
- Автоматический сбор логов из всех сервисов
- Индексация и полнотекстовый поиск
- Обогащение метаданными

**Мониторинг:** Prometheus + Grafana
- Развернуто на GCP: http://34.31.7.74:8082
- Метрики системы, контейнеров и сервисов
- Dashboard с распределением запросов
- PromQL запросы и алерты

Все компоненты интегрируются в единую observability платформу, обеспечивая:
- Единый UI для разработчиков
- Correlation между логами и метриками
- Низкая стоимость владения
- Простота поддержки
