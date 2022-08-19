#!/bin/bash
# Запрашиваем имя нового клиента
sudo read -p "Введите название папки для нового пользователя:" NewUser
# Создаем для него папку
sudo mkdir /etc/openvpn/clients/$NewUser
# Генерируем сертификат пользователя
sudo cd /etc/openvpn/easy-rsa/
sudo ./easyrsa build-client-full $NewUser nopass
# Копируем сертификаты в папку пользователя
sudo cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/clients/$NewUser
sudo cp /etc/openvpn/easy-rsa/pki/ta.key /etc/openvpn/clients/$NewUser
sudo cp /etc/openvpn/easy-rsa/pki/issued/$NewUser.crt /etc/openvpn/clients/$NewUser
sudo cp /etc/openvpn/easy-rsa/pki/private/$NewUser.key /etc/openvpn/clients/$NewUser
# Переходим в папку для дальнейшей генерации в ней ключа
sudo cd /etc/openvpn/clients/$NewUser
# Узнаем наш внешний ip адрес и вводим его
ip -br a
sudo read -p "Введите внешний ip адрес:" YourIP
# Создаем конфигурационный файл пользователя
sudo cat > /etc/openvpn/clients/$NewUser/$NewUser.conf <<EOF
client
dev tun
proto udp
remote $YourIP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert $NewUser.crt
key $NewUser.key
remote-cert-tls server
tls-auth ta.key 1
cipher AES-256-GCM
auth-nocache
verb 3
EOF
echo "Файлы клиентского сертификата находятся здесь /etc/openvpn/clients/$NewUser"