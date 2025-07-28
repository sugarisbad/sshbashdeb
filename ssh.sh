#!/bin/bash

# Проверка, что скрипт запущен с правами root
if [ "$(id -u)" -ne 0 ]; then
    echo "Этот скрипт должен быть запущен с правами root (sudo)." >&2
    exit 1
fi

# Создание резервной копии sources.list
cp /etc/apt/sources.list /etc/apt/sources.list.bak
echo "Резервная копия /etc/apt/sources.list создана."

# Замена зеркала на deb.debian.org (можно изменить на другое, например, mirror.yandex.ru)
cat << EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian/ bookworm main contrib non-free
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free
EOF

# Обновление списка пакетов
echo "Обновление списка пакетов..."
apt update
if [ $? -eq 0 ]; then
    echo "Список пакетов успешно обновлен."
else
    echo "Ошибка при обновлении списка пакетов. Проверьте интернет-соединение или зеркало." >&2
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
systemctl enable ssh
systemctl start ssh

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

echo "Настройка завершена. Попробуйте подключиться: ssh user@<IP-адреса-сервера>"
