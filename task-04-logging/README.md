# Задача 4: Система логирования

Стек логирования с Vector, ElasticSearch и Kibana для сбора и визуализации логов микросервисов.

## Архитектура

```
┌──────────────┐
│ Микросервисы │
│ (Docker)     │
└──────┬───────┘
       │ Docker logs
       ▼
┌──────────────┐
│    Vector    │ ← Сборщик логов
│  (Collector) │
└──────┬───────┘
       │ Bulk API
       ▼
┌──────────────┐
│ElasticSearch │ ← Хранилище логов
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Kibana     │ ← UI (localhost:8081)
└──────────────┘
```

## Компоненты

### Vector
- Собирает логи из Docker контейнеров
- Парсит JSON и текстовые логи
- Обогащает логи метаданными (service_type, environment)
- Фильтрует debug логи
- Отправляет в ElasticSearch

### ElasticSearch
- Хранит логи в индексах по дням: `microservices-logs-YYYY.MM.DD`
- Single-node режим для разработки
- Аутентификация включена

### Kibana
- Web UI на порту 8081
- Credentials: `admin` / `qwerty123456`
- Визуализация и поиск по логам

## Быстрый старт

### 1. Убедиться что основные сервисы запущены

```bash
cd /Users/nikita/lessons/micro1
docker compose ps
```

Должны работать: `api-gateway`, `security-service`, `uploader-service`, `minio`

### 2. Запустить стек логирования

```bash
cd /Users/nikita/lessons/micro1/task-04-logging
docker compose up -d
```

### 3. Дождаться готовности всех сервисов

```bash
docker compose ps
docker compose logs -f
```

Ждем пока все сервисы станут healthy (может занять 1-2 минуты).

### 4. Создать пользователя admin в Kibana

```bash
# Создаем роль admin в ElasticSearch
docker compose exec elasticsearch curl -X POST "http://localhost:9200/_security/role/admin_role" \
  -u elastic:qwerty123456 \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["all"],
    "indices": [
      {
        "names": ["*"],
        "privileges": ["all"]
      }
    ]
  }'

# Создаем пользователя admin
docker compose exec elasticsearch curl -X POST "http://localhost:9200/_security/user/admin" \
  -u elastic:qwerty123456 \
  -H "Content-Type: application/json" \
  -d '{
    "password": "qwerty123456",
    "roles": ["admin_role", "kibana_admin", "superuser"],
    "full_name": "Admin User"
  }'
```

### 5. Открыть Kibana

Браузер: http://localhost:8081

**Credentials**: `admin` / `qwerty123456`

При первом входе может потребоваться elastic/qwerty123456, затем можно будет войти как admin.

## Настройка Kibana

### Создание Index Pattern

1. Открыть Kibana → Management → Stack Management
2. Kibana → Index Patterns
3. Create index pattern
4. Index pattern name: `microservices-logs-*`
5. Time field: `@timestamp` или `timestamp`
6. Create index pattern

### Создание Dashboard

1. Analytics → Discover - для поиска логов
2. Analytics → Dashboard - для создания визуализаций

**Полезные фильтры**:
- `service_type: "gateway"` - логи API Gateway
- `service_type: "authentication"` - логи Security Service
- `log_level: "error"` - только ошибки
- `container_name: "uploader-service"` - логи Uploader

## Генерация тестовых логов

```bash
# Запросы к API для генерации логов
cd /Users/nikita/lessons/micro1

# Успешный логин
curl -X POST http://localhost/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'

# Неуспешный логин (генерирует error лог)
curl -X POST http://localhost/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"wrong","password":"wrong"}'

# Загрузка файла без токена (401 error)
curl -X POST http://localhost/upload -F "file=@test.txt"

# Загрузка файла с токеном (success)
curl -X POST http://localhost/upload \
  -H "Authorization: Bearer valid-token-12345" \
  -F "file=@test.txt"
```

## Проверка работы Vector

```bash
# Логи Vector
docker compose logs vector

# Проверка что логи попадают в ElasticSearch
docker compose exec elasticsearch curl -X GET "http://localhost:9200/microservices-logs-*/_search?size=10" \
  -u elastic:qwerty123456 \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match_all": {}
    },
    "sort": [
      {
        "@timestamp": {
          "order": "desc"
        }
      }
    ]
  }'
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
docker compose logs -f vector
docker compose logs -f elasticsearch
docker compose logs -f kibana
```

## Troubleshooting

### ElasticSearch не стартует

- Проверить логи: `docker compose logs elasticsearch`
- Увеличить vm.max_map_count (на Linux):
  ```bash
  sudo sysctl -w vm.max_map_count=262144
  ```

### Vector не отправляет логи

- Проверить что сеть microservices существует:
  ```bash
  docker network ls | grep microservices
  ```
- Проверить конфигурацию: `docker compose logs vector`

### Kibana не доступна на 8081

- Проверить что порт не занят: `lsof -i :8081`
- Проверить статус: `docker compose ps kibana`

## Полезные команды

```bash
# Количество логов в ElasticSearch
docker compose exec elasticsearch curl -X GET "http://localhost:9200/_cat/indices/microservices-logs-*?v" \
  -u elastic:qwerty123456

# Удалить старые индексы
docker compose exec elasticsearch curl -X DELETE "http://localhost:9200/microservices-logs-2025.12.13" \
  -u elastic:qwerty123456

# Статистика по логам
docker compose exec elasticsearch curl -X GET "http://localhost:9200/microservices-logs-*/_stats" \
  -u elastic:qwerty123456
```

## Интеграция с основным стеком

Этот стек логирования работает независимо от основных микросервисов в `/Users/nikita/lessons/micro1/docker-compose.yml`.

Vector подключается к сети `microservices` и собирает логи из всех контейнеров.

## Требования задачи

✅ **Vector** - сбор логов из контейнеров
✅ **ElasticSearch** - хранилище логов с индексацией
✅ **Kibana** - UI на порту 8081
✅ **Credentials** - admin/qwerty123456
✅ **Dashboard** - создается вручную через UI

## Следующие шаги

1. Запустить стек и дождаться готовности всех сервисов
2. Создать пользователя admin в ElasticSearch
3. Открыть Kibana и создать index pattern
4. Создать dashboard с визуализациями
5. Сделать скриншоты для документации
