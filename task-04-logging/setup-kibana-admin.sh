#!/bin/bash

# Скрипт для создания пользователя admin в Kibana

set -e

echo "=== Настройка пользователя admin для Kibana ==="
echo

# Проверяем что ElasticSearch запущен
echo "[1/4] Проверка доступности ElasticSearch..."
until docker compose exec -T elasticsearch curl -s -u elastic:qwerty123456 http://localhost:9200/_cluster/health > /dev/null 2>&1; do
  echo "Ожидание запуска ElasticSearch..."
  sleep 5
done
echo "✓ ElasticSearch доступен"
echo

# Создаем роль admin
echo "[2/4] Создание роли admin_role..."
docker compose exec -T elasticsearch curl -X POST "http://localhost:9200/_security/role/admin_role" \
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
  }' || echo "Роль уже существует"
echo "✓ Роль создана"
echo

# Создаем пользователя admin
echo "[3/4] Создание пользователя admin..."
docker compose exec -T elasticsearch curl -X POST "http://localhost:9200/_security/user/admin" \
  -u elastic:qwerty123456 \
  -H "Content-Type: application/json" \
  -d '{
    "password": "qwerty123456",
    "roles": ["admin_role", "kibana_admin", "superuser"],
    "full_name": "Admin User",
    "email": "admin@microservices.local"
  }' || echo "Пользователь уже существует"
echo "✓ Пользователь создан"
echo

# Проверяем что Kibana доступна
echo "[4/4] Проверка доступности Kibana..."
until curl -s http://localhost:8081/api/status > /dev/null 2>&1; do
  echo "Ожидание запуска Kibana..."
  sleep 5
done
echo "✓ Kibana доступна"
echo

echo "=== Настройка завершена ==="
echo
echo "Kibana доступна по адресу: http://localhost:8081"
echo "Credentials: admin / qwerty123456"
echo
echo "Следующие шаги:"
echo "1. Откройте http://localhost:8081"
echo "2. Войдите используя admin / qwerty123456"
echo "3. Создайте index pattern: microservices-logs-*"
echo "4. Перейдите в Analytics → Discover для просмотра логов"
echo
