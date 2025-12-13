#!/bin/bash
set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Развертывание микросервисов на GCP ===${NC}"

# Проверка наличия VM IP
if [ -z "$1" ]; then
    echo -e "${YELLOW}Использование: $0 <VM_IP_ADDRESS>${NC}"
    echo "Сначала создайте VM с помощью Terraform:"
    echo "  cd terraform"
    echo "  terraform init"
    echo "  terraform apply"
    exit 1
fi

VM_IP=$1

echo -e "${GREEN}1. Копирование файлов на VM...${NC}"
scp -r -o StrictHostKeyChecking=no \
    docker-compose.yml \
    security-service \
    uploader-service \
    README.md \
    ubuntu@${VM_IP}:/opt/microservices/

echo -e "${GREEN}2. Запуск Docker Compose на VM...${NC}"
ssh -o StrictHostKeyChecking=no ubuntu@${VM_IP} << 'ENDSSH'
    cd /opt/microservices

    # Останов старых контейнеров если есть
    docker compose down 2>/dev/null || true

    # Запуск новых контейнеров
    docker compose up -d --build

    # Ожидание запуска сервисов
    echo "Ожидание запуска сервисов..."
    sleep 10

    # Проверка статуса
    docker compose ps

    echo ""
    echo "=== Сервисы запущены! ==="
    echo "Доступные эндпоинты:"
    echo "  - API Gateway: http://$(curl -s ifconfig.me)"
    echo "  - Traefik Dashboard: http://$(curl -s ifconfig.me):8080"
    echo "  - MinIO Console: http://$(curl -s ifconfig.me):9001"
ENDSSH

echo -e "${GREEN}=== Развертывание завершено! ===${NC}"
echo ""
echo "Доступ к сервисам:"
echo "  - API: http://${VM_IP}"
echo "  - Traefik Dashboard: http://${VM_IP}:8080"
echo "  - MinIO Console: http://${VM_IP}:9001"
echo ""
echo "Подключение по SSH:"
echo "  ssh ubuntu@${VM_IP}"
