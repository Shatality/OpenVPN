#!/bin/bash
# Устанавливаем свой часовой пояс
sudo timedatectl set-timezone Europe/Berlin
# Устанавливаем OpenVPN
yes | sudo apt install openvpn easy-rsa
sudo mkdir /etc/openvpn/easy-rsa
# Копируем в эту папку все необходимые скрипты easy-rsa
sudo cp -R /usr/share/easy-rsa /etc/openvpn/
# СОЗДАЕМ ЦЕНТР СЕРТИФИКАЦИИ
cd /etc/openvpn/easy-rsa/
Эта команда создаст папку pki и и необходимые файлы для генерации сертификатов
sudo /etc/openvpn/easy-rsa/easyrsa init-pki
# Следующая команда создаёт ключ центра сертификации, для него понадобится придумать пароль:
sudo /etc/openvpn/easy-rsa/easyrsa build-ca
# Вводим пароль для CA, им мы будем подписывать клиентские сертификаты
# Жмем Enter
# Далее надо создать ключи Диффи-Хафмана, которые используются при обмене ключами между клиентом и сервером. Для этого выполните:
sudo /etc/openvpn/easy-rsa/easyrsa gen-dh
# Для использования TLS-авторизации создаем дополнительный сертификат:
sudo cd /etc/openvpn/easy-rsa
sudo openvpn --genkey --secret ta.key
sudo mv ta.key /etc/openvpn/easy-rsa/pki
# Для отзыва уже подписанных сертификатов нам понадобится сертификат отзыва. Для его создания выполните команду:
sudo /etc/openvpn/easy-rsa/easyrsa gen-crl
# СОЗДАЕМ СЕРТИФИКАТЫ ДЛЯ СЕРВЕРА
# Для создания сертификатов, которые будут использоваться сервером надо выполнить команду:
sudo cd /etc/openvpn/easy-rsa
sudo ./easyrsa build-server-full server nopass
# Вводим пароль CA
# Теперь все полученные ключи надо скопировать в папку /etc/openvpn
sudo cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/ca.crt
sudo cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/dh.pem
sudo cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
sudo cp /etc/openvpn/easy-rsa/pki/ta.key /etc/openvpn/ta.key
sudo cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/server.crt
sudo cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/server.key
# КОНФИГУРАЦИОННЫЙ ФАЙЛ СЕРВЕРА
# Создаем конфигурационный файл сервера
cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
crl-verify crl.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
tls-auth ta.key 0
cipher AES-256-GCM
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
verb 3
explicit-exit-notify 1
EOF
# Запускаем сервер
sudo systemctl start openvpn@server
# НАСТРОЙКА ПЕРЕСЫЛКИ ПАКЕТОВ
# Включаем ip forwarding
sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
# Применить изменения без перезапуска системы
sudo sysctl -p /etc/sysctl.conf
# НАСТРОЙКА БРАНДМАУЭРА
ip -br a
# Теперь мы видим адрес и имя внешнего интерфейса
sudo iptables -I FORWARD -i tun0 -o eth0 -j ACCEPT
sudo iptables -I FORWARD -i eth0 -o tun0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A INPUT -p tcp --dport=22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport=80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport=443 -j ACCEPT
sudo iptables -A INPUT -p udp -m udp --dport 1194 -j ACCEPT
sudo iptables -A OUTPUT -p udp -m udp --sport 1194 -j ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -p icmp -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -P INPUT DROP
# Устанавливаем iptables
yes | sudo apt install iptables
# Создаем папку для генерации ключей для клиентов
sudo mkdir /etc/openvpn/clients
