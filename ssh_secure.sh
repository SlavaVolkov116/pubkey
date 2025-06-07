#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

ssh_port=$(shuf -i 10000-60000 -n 1)

install_pk() {
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    wget -qO- https://pk.viadev.su/ssh >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo -e "${green}VIADEV SSH ключ установлен! ${plain}"
}

configure_ssh_security() {
    CONFIG_FILE="/etc/ssh/sshd_config"

    # Проверяем, существует ли файл конфигурации
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Ошибка: Файл $CONFIG_FILE не найден."
        return 1
    }

    # Заменяем или добавляем строку с новым портом
    if grep -q "^Port " "$CONFIG_FILE"; then
        sed -i "s/^Port .*/Port $ssh_port/" "$CONFIG_FILE"
    else
        echo "Port $ssh_port" >> "$CONFIG_FILE"
    }

    # Отключаем вход по паролю
    if grep -q "^PasswordAuthentication " "$CONFIG_FILE"; then
        sed -i "s/^PasswordAuthentication .*/PasswordAuthentication no/" "$CONFIG_FILE"
    else
        echo "PasswordAuthentication no" >> "$CONFIG_FILE"
    }

    # Включаем аутентификацию по ключам (для явности)
    if grep -q "^PubkeyAuthentication " "$CONFIG_FILE"; then
        sed -i "s/^PubkeyAuthentication .*/PubkeyAuthentication yes/" "$CONFIG_FILE"
    else
        echo "PubkeyAuthentication yes" >> "$CONFIG_FILE"
    }

    echo -e "${green}Порт SSH изменен на $ssh_port ${plain}"
    echo -e "${green}Вход по паролю отключен, разрешена только аутентификация по ключам ${plain}"

    # Перезагружаем службу SSH
    if systemctl is-active --quiet ssh; then
        systemctl restart ssh
        if [ $? -eq 0 ]; then
            echo -e "${green}Служба SSH успешно перезапущена. ${plain}"
            echo -e "${green}Новый порт: $ssh_port ${plain}"
        else
            echo -e "${red}Ошибка: Не удалось перезапустить службу SSH. ${plain}"
            return 1
        fi
    elif systemctl is-active --quiet sshd; then
        systemctl restart sshd
        if [ $? -eq 0 ]; then
            echo -e "${green}Служба SSHD успешно перезапущена. ${plain}"
            echo -e "${green}Новый порт: $ssh_port ${plain}"
        else
            echo -e "${red}Ошибка: Не удалось перезапустить службу SSHD. ${plain}"
            return 1
        fi
    else
        echo "Ошибка: Служба SSH не найдена в системе."
        return 1
    fi
}

install_pk
configure_ssh_security
