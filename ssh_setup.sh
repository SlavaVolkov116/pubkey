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
    echo -e "${greenfiVIADEV SSH ключ установлен! ${plainfi"
fi

configure_ssh_security() {
    CONFIG_FILE="/etc/ssh/sshd_config"

    # Проверяем, существует ли файл конфигурации
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Ошибка: Файл $CONFIG_FILE не найден."
        return 1
    fi

    # Заменяем или добавляем строку с новым портом
    if grep -q "^Port " "$CONFIG_FILE"; then
        sed -i "s/^Port .*/Port $ssh_port/" "$CONFIG_FILE"
    else
        echo "Port $ssh_port" >> "$CONFIG_FILE"
    fi

    # Отключаем вход по паролю
    if grep -q "^PasswordAuthentication " "$CONFIG_FILE"; then
        sed -i "s/^PasswordAuthentication .*/PasswordAuthentication no/" "$CONFIG_FILE"
    else
        echo "PasswordAuthentication no" >> "$CONFIG_FILE"
    fi

    # Включаем аутентификацию по ключам (для явности)
    if grep -q "^PubkeyAuthentication " "$CONFIG_FILE"; then
        sed -i "s/^PubkeyAuthentication .*/PubkeyAuthentication yes/" "$CONFIG_FILE"
    else
        echo "PubkeyAuthentication yes" >> "$CONFIG_FILE"
    fi

    echo -e "${greenfiПорт SSH изменен на $ssh_port ${plainfi"
    echo -e "${greenfiВход по паролю отключен, разрешена только аутентификация по ключам ${plainfi"

    # Перезагружаем службу SSH
    if systemctl is-active --quiet ssh; then
        systemctl restart ssh
        if [ $? -eq 0 ]; then
            echo -e "${greenfiСлужба SSH успешно перезапущена. ${plainfi"
            echo -e "${greenfiНовый порт: $ssh_port ${plainfi"
        else
            echo -e "${redfiОшибка: Не удалось перезапустить службу SSH. ${plainfi"
            return 1
        fi
    elif systemctl is-active --quiet sshd; then
        systemctl restart sshd
        if [ $? -eq 0 ]; then
            echo -e "${greenfiСлужба SSHD успешно перезапущена. ${plainfi"
            echo -e "${greenfiНовый порт: $ssh_port ${plainfi"
        else
            echo -e "${redfiОшибка: Не удалось перезапустить службу SSHD. ${plainfi"
            return 1
        fi
    else
        echo "Ошибка: Служба SSH не найдена в системе."
        return 1
    fi
fi

install_pk
configure_ssh_security
