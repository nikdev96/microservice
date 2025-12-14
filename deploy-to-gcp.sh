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

echo -e "${GREEN}1. Настройка VM (директории и права)...${NC}"
ssh -o StrictHostKeyChecking=no nikita@${VM_IP} << 'ENDSSH'
    # Добавить пользователя в группу docker
    sudo usermod -aG docker nikita

    # Создать директории
    sudo mkdir -p /opt/microservices
    sudo chown -R nikita:nikita /opt/microservices

    # Перезапустить Docker для применения прав
    sudo systemctl restart docker

    echo "Ожидание запуска Docker..."
    sleep 5
ENDSSH

echo -e "${GREEN}2. Копирование основных файлов на VM...${NC}"
scp -r -o StrictHostKeyChecking=no \
    docker-compose.yml \
    nginx.conf \
    security-service \
    uploader-service \
    README.md \
    nikita@${VM_IP}:/opt/microservices/

echo -e "${GREEN}3. Копирование стека логирования на VM...${NC}"
scp -r -o StrictHostKeyChecking=no \
    task-04-logging \
    nikita@${VM_IP}:/opt/microservices/

echo -e "${GREEN}4. Копирование стека мониторинга на VM...${NC}"
scp -r -o StrictHostKeyChecking=no \
    task-05-monitoring \
    nikita@${VM_IP}:/opt/microservices/

echo -e "${GREEN}5. Запуск основных микросервисов на VM...${NC}"
ssh -o StrictHostKeyChecking=no nikita@${VM_IP} << 'ENDSSH'
    cd /opt/microservices

    # Останов старых контейнеров если есть
    docker compose down 2>/dev/null || true

    # Создание сети microservices если не существует
    docker network create microservices 2>/dev/null || true

    # Запуск основных сервисов
    docker compose up -d --build

    # Ожидание запуска
    echo "Ожидание запуска основных сервисов..."
    sleep 15

    # Проверка статуса
    docker compose ps
ENDSSH

echo -e "${GREEN}6. Запуск стека логирования (Vector + ElasticSearch + Kibana)...${NC}"
ssh -o StrictHostKeyChecking=no nikita@${VM_IP} << 'ENDSSH'
    cd /opt/microservices/task-04-logging

    # Запуск стека логирования
    docker compose up -d

    echo "Ожидание запуска стека логирования..."
    sleep 20

    # Проверка статуса
    docker compose ps
ENDSSH

echo -e "${GREEN}7. Запуск стека мониторинга (Prometheus + Grafana)...${NC}"
ssh -o StrictHostKeyChecking=no nikita@${VM_IP} << 'ENDSSH'
    cd /opt/microservices/task-05-monitoring

    # Запуск стека мониторинга
    docker compose up -d

    echo "Ожидание запуска стека мониторинга..."
    sleep 15

    # Проверка статуса
    docker compose ps

    echo ""
    echo "=== Все сервисы запущены! ==="
    echo "Доступные эндпоинты:"
    echo "  - API Gateway: http://$(curl -s ifconfig.me)"
    echo "  - MinIO Console: http://$(curl -s ifconfig.me):9001"
    echo "  - Kibana (логирование): http://$(curl -s ifconfig.me):8081"
    echo "  - Grafana (мониторинг): http://$(curl -s ifconfig.me):8082"
    echo "  - Prometheus: http://$(curl -s ifconfig.me):9090"
ENDSSH

echo -e "${GREEN}=== Развертывание завершено! ===${NC}"
echo ""
echo "Доступ к сервисам:"
echo "  - API Gateway: http://${VM_IP}"
echo "  - MinIO Console: http://${VM_IP}:9001"
echo "  - Kibana (логирование): http://${VM_IP}:8081 (admin/qwerty123456)"
echo "  - Grafana (мониторинг): http://${VM_IP}:8082 (admin/qwerty123456)"
echo "  - Prometheus: http://${VM_IP}:9090"
echo ""
echo "Тестирование API:"
echo "  curl -X POST http://${VM_IP}/auth/login -H 'Content-Type: application/json' -d '{\"username\":\"admin\",\"password\":\"admin\"}'"
echo ""
echo "Настройка Kibana:"
echo "  cd /opt/microservices/task-04-logging && ./setup-kibana-admin.sh"
echo ""
echo "Подключение по SSH:"
echo "  ssh ubuntu@${VM_IP}"
