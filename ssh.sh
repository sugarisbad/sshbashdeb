#!/bin/bash

# Проверка, что скрипт запущен с правами root
if [ "$(id -u)" -ne 0 ]; then
    echo "Этот скрипт должен быть запущен с правами root (sudo)." >&2
    exit 1
fi

# Проверка доступности Yandex зеркала
echo "Проверка доступности зеркала mirror.yandex.ru..."
if ! ping -c 2 mirror.yandex.ru &> /dev/null; then
    echo "Ошибка: Зеркало mirror.yandex.ru недоступно. Проверьте интернет-соединение." >&2
    exit 1
fi

# Создание резервной копии sources.list
cp /etc/apt/sources.list /etc/apt/sources.list.bak
echo "Резервная копия /etc/apt/sources.list создана: /etc/apt/sources.list.bak"

# Замена зеркала на Yandex
cat << EOF > /etc/apt/sources.list
deb http://mirror.yandex.ru/debian/ bookworm main contrib non-free
deb http://mirror.yandex.ru/debian/ bookworm-updates main contrib non-free
deb http://security.debian.org/debian-security bookworm-security main contrib non-free
EOF

echo "Используются Yandex-зеркала для репозиториев Debian."

# Обновление списка пакетов
echo "Обновление списка пакетов..."
apt update
if [ $? -eq 0 ]; then
    echo "Список пакетов успешно обновлен через Yandex-зеркало."
else
    echo "Ошибка при обновлении списка пакетов. Восстановите резервную копию:" >&2
    echo "mv /etc/apt/sources.list.bak /etc/apt/sources.list" >&2
    exit 1
fi

# Установка openssh-server
echo "Установка openssh-server..."
apt install -y openssh-server
if [ $? -eq 0 ]; then
    echo "openssh-server успешно установлен."
else
    echo "Ошибка при установке openssh-server." >&2
    exit 1
fi

# Запуск и включение SSH-сервера
systemctl enable --now ssh
echo "SSH-сервер включен в автозагрузку и запущен."

# Проверка статуса SSH
if systemctl is-active --quiet ssh; then
    echo "SSH-сервер запущен и работает."
else
    echo "Ошибка: SSH-сервер не запущен." >&2
    exit 1
fi

# Проверка, что порт 22 открыт
if ss -tuln | grep -q ":22"; then
    echo "Порт 22 открыт, SSH готов к использованию."
else
    echo "Ошибка: порт 22 не прослушивается." >&2
    exit 1
fi

echo -e "\nНастройка завершена успешно!"
echo "Попробуйте подключиться: ssh user@$(hostname -I | awk '{print $1}')"
echo "Для отката изменений используйте: mv /etc/apt/sources.list.bak /etc/apt/sources.list"
