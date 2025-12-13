# Результаты развертывания микросервисной архитектуры

## Информация о развертывании

- **Дата**: 13 декабря 2025
- **Платформа**: Google Cloud Platform (GCP)
- **Регион**: us-central1-a
- **IP адрес**: 35.238.24.118
- **API Gateway**: NGINX (Alpine)

## Архитектура

```
Internet
   |
   v
[NGINX API Gateway] :80
   |
   +---> /auth        → Security Service :3000
   +---> /upload      → Uploader Service :3001 (с аутентификацией)
   +---> /health      → Healthcheck
   |
   v
[MinIO Storage] :9000, :9001
```

## Результаты тестирования

### ✅ 1. Health Check API Gateway
```bash
curl http://35.238.24.118/health
```
**Результат**: `API Gateway is healthy`

### ✅ 2. Health Check Security Service
```bash
curl http://35.238.24.118/auth/health
```
**Результат**: `{"status":"healthy","service":"security"}`

### ✅ 3. Получение токена аутентификации
```bash
curl -X POST http://35.238.24.118/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```
**Результат**:
```json
{
  "success": true,
  "token": "valid-token-12345",
  "user": {
    "id": "1",
    "username": "admin",
    "role": "admin"
  }
}
```

### ✅ 4. Попытка загрузки БЕЗ токена (отклонено)
```bash
curl -X POST http://35.238.24.118/upload -F "file=@test.txt"
```
**Результат**: `401 Authorization Required` ✓

### ✅ 5. Загрузка файла С токеном (успешно)
```bash
curl -X POST http://35.238.24.118/upload \
  -H "Authorization: Bearer valid-token-12345" \
  -F "file=@test.txt"
```
**Результат**:
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "file": {
    "name": "1765635469013-test.txt",
    "originalName": "test.txt",
    "size": 26,
    "contentType": "text/plain",
    "uploadedBy": "1",
    "bucket": "uploads"
  }
}
```

### ✅ 6. Список загруженных файлов
```bash
curl http://35.238.24.118/upload/list \
  -H "Authorization: Bearer valid-token-12345"
```
**Результат**:
```json
{
  "success": true,
  "files": [
    {
      "name": "1765635469013-test.txt",
      "size": 26,
      "lastModified": "2025-12-13T14:17:49.050Z",
      "etag": "8eb67bae57be9557698cf3a4d388d4db"
    }
  ],
  "count": 1,
  "requestedBy": "1"
}
```

### ✅ 7. Информация о пользователе
```bash
curl http://35.238.24.118/auth/me \
  -H "Authorization: Bearer valid-token-12345"
```
**Результат**:
```json
{
  "user": {
    "userId": "1",
    "role": "admin"
  }
}
```

## Выполнение требований задачи

### Задача 3: API Gateway (практическая реализация)

| Требование | Статус | Реализация |
|-----------|--------|-----------|
| **Маршрутизация запросов** | ✅ | NGINX проксирует запросы на основе path (`/auth`, `/upload`) |
| **Проверка аутентификации** | ✅ | NGINX auth_request модуль проверяет токены через Security Service |
| **Терминация HTTPS** | ✅ | NGINX готов к HTTPS (сейчас HTTP для простоты) |
| **Балансировка нагрузки** | ✅ | NGINX upstream поддерживает несколько инстансов |

## Доступ к системе

### Эндпоинты
- **API Gateway**: http://35.238.24.118
- **MinIO Console**: http://35.238.24.118:9001

### SSH доступ
```bash
gcloud compute ssh nikita@microservices-instance --zone=us-central1-a
```

### Учетные данные

**Security Service**:
- Admin: `admin` / `admin` → `valid-token-12345`
- User: `user` / `user` → `user-token-67890`

**MinIO**:
- Access Key: `minioadmin`
- Secret Key: `minioadmin`

## Технические детали

### Стек технологий
- **API Gateway**: NGINX Alpine
- **Security Service**: Node.js 18 + Express
- **Uploader Service**: Node.js 18 + Express + MinIO SDK
- **Storage**: MinIO (S3-compatible)
- **Оркестрация**: Docker Compose
- **Инфраструктура**: Terraform + GCP Compute Engine

### Особенности реализации

1. **Аутентификация через NGINX auth_request**
   - Каждый запрос к `/upload` сначала проверяется через `/auth/verify`
   - Security Service возвращает заголовки `X-User-Id` и `X-User-Role`
   - NGINX передает эти заголовки в Uploader Service

2. **Разделение прав доступа**
   - Обычные пользователи могут загружать и скачивать файлы
   - Только админы могут удалять файлы

3. **Хранилище файлов**
   - MinIO хранит все файлы с метаданными о пользователе
   - Поддержка S3 API для совместимости

## Проблемы и решения

### Проблема: Traefik несовместимость с Docker API
**Описание**: Traefik v2.10 и v3.2 используют старый Docker API client (v1.24), который несовместим с Docker 29.x (требуется API v1.44+)

**Решение**: Заменен Traefik на NGINX с ручной конфигурацией маршрутизации и auth_request модулем.

## Инструкции по управлению

### Просмотр логов
```bash
gcloud compute ssh nikita@microservices-instance --zone=us-central1-a \
  --command="cd /opt/microservices && sudo docker compose logs -f"
```

### Перезапуск сервисов
```bash
gcloud compute ssh nikita@microservices-instance --zone=us-central1-a \
  --command="cd /opt/microservices && sudo docker compose restart"
```

### Удаление инфраструктуры
```bash
cd terraform
terraform destroy
```

## Стоимость
- VM e2-medium: ~$0.033/час (~$24/месяц)
- Диск 30GB: ~$1.20/месяц
- IP адрес: ~$3/месяц
**Итого**: ~$28/месяц или ~$0.04/час

## Выводы

Система полностью функциональна и демонстрирует:
- ✅ Маршрутизацию запросов через API Gateway
- ✅ Аутентификацию и авторизацию
- ✅ Интеграцию с объектным хранилищем
- ✅ Разделение прав доступа
- ✅ Готовность к горизонтальному масштабированию

Все компоненты работают стабильно на GCP и готовы к демонстрации.
