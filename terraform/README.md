# Развертывание микросервисов на GCP

## Предварительные требования

1. **Google Cloud SDK (gcloud)** установлен и настроен
   ```bash
   # Установка (macOS)
   brew install --cask google-cloud-sdk

   # Или скачайте с https://cloud.google.com/sdk/docs/install
   ```

2. **Terraform** установлен
   ```bash
   # Установка (macOS)
   brew install terraform
   ```

3. **GCP проект** создан и настроен
   ```bash
   # Авторизация
   gcloud auth login
   gcloud auth application-default login

   # Установка проекта по умолчанию
   gcloud config set project YOUR_PROJECT_ID

   # Включение необходимых API
   gcloud services enable compute.googleapis.com
   ```

## Быстрый старт

### 1. Настройка переменных

Создайте файл `terraform.tfvars`:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Отредактируйте `terraform.tfvars`:

```hcl
project_id      = "your-gcp-project-id"
region          = "us-central1"
machine_type    = "e2-medium"
ssh_user        = "ubuntu"
ssh_public_key  = "ssh-rsa AAAAB3Nza... your-email@example.com"
```

Чтобы получить ваш публичный SSH ключ:
```bash
cat ~/.ssh/id_rsa.pub
```

Если у вас нет SSH ключа, создайте его:
```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

### 2. Развертывание инфраструктуры

```bash
cd terraform

# Инициализация Terraform
terraform init

# Просмотр плана
terraform plan

# Применение конфигурации
terraform apply
```

После успешного применения вы получите:
```
Outputs:

instance_ip = "34.123.45.67"
instance_name = "microservices-instance"
ssh_command = "ssh ubuntu@34.123.45.67"
```

### 3. Развертывание приложения

Из корневой директории проекта:

```bash
cd ..
./deploy-to-gcp.sh <INSTANCE_IP>
```

Где `<INSTANCE_IP>` - IP адрес из вывода Terraform.

### 4. Проверка работы

После развертывания сервисы будут доступны:

- **API Gateway**: http://<INSTANCE_IP>
- **Traefik Dashboard**: http://<INSTANCE_IP>:8080
- **MinIO Console**: http://<INSTANCE_IP>:9001

Тестирование:

```bash
# Получение токена
curl -X POST http://<INSTANCE_IP>/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'

# Загрузка файла
curl -X POST http://<INSTANCE_IP>/upload \
  -H "Authorization: Bearer valid-token-12345" \
  -F "file=@test.txt"
```

## Управление

### Подключение к VM

```bash
ssh ubuntu@<INSTANCE_IP>
```

### Просмотр логов

```bash
ssh ubuntu@<INSTANCE_IP>
cd /opt/microservices
docker compose logs -f
```

### Перезапуск сервисов

```bash
ssh ubuntu@<INSTANCE_IP>
cd /opt/microservices
docker compose restart
```

### Обновление приложения

Просто запустите скрипт развертывания снова:

```bash
./deploy-to-gcp.sh <INSTANCE_IP>
```

## Удаление ресурсов

Когда закончите работу, удалите все ресурсы чтобы избежать расходов:

```bash
cd terraform
terraform destroy
```

## Стоимость

Примерная стоимость при использовании машины e2-medium в us-central1:

- **VM (e2-medium)**: ~$24/месяц при постоянной работе (~$0.033/час)
- **Внешний IP**: ~$3/месяц
- **Диск 30GB**: ~$1.20/месяц

**Итого**: ~$28/месяц или ~$0.04/час

Для экономии - останавливайте VM когда не используете:
```bash
gcloud compute instances stop microservices-instance --zone=us-central1-a
```

Запуск:
```bash
gcloud compute instances start microservices-instance --zone=us-central1-a
```

## Troubleshooting

### Проблема: SSH не работает

```bash
# Добавьте SSH ключ через gcloud
gcloud compute config-ssh
```

### Проблема: Firewall блокирует порты

```bash
# Проверьте правила firewall
gcloud compute firewall-rules list

# Создайте правила вручную если нужно
gcloud compute firewall-rules create allow-http-alt \
  --allow tcp:80,tcp:443,tcp:8080,tcp:9000,tcp:9001 \
  --target-tags microservices
```

### Проблема: Docker не установлен

```bash
# Подключитесь к VM и проверьте логи startup script
ssh ubuntu@<INSTANCE_IP>
sudo cat /var/log/startup-script.log
sudo journalctl -u google-startup-scripts.service
```

## Безопасность

⚠️ **Важно для продакшена:**

1. Ограничьте доступ к портам только с вашего IP:
   ```hcl
   source_ranges = ["YOUR_IP/32"]
   ```

2. Используйте HTTPS с настоящими сертификатами

3. Измените дефолтные пароли и токены

4. Настройте Cloud Armor для DDoS защиты

5. Используйте Secret Manager для хранения credentials
