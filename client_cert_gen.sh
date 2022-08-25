#!/bin/bash
# Запрашиваем имя нового клиента
read -p "Введите название папки для нового пользователя:" NewUser
# Создаем для него папку
mkdir /etc/openvpn/clients/$NewUser
# Генерируем сертификат пользователя
cd /etc/openvpn/easy-rsa/
./easyrsa build-client-full $NewUser nopass
# Копируем сертификаты в папку пользователя
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/clients/$NewUser
cp /etc/openvpn/easy-rsa/pki/ta.key /etc/openvpn/clients/$NewUser
cp /etc/openvpn/easy-rsa/pki/issued/$NewUser.crt /etc/openvpn/clients/$NewUser
cp /etc/openvpn/easy-rsa/pki/private/$NewUser.key /etc/openvpn/clients/$NewUser
# Переходим в папку для дальнейшей генерации в ней ключа
cd /etc/openvpn/clients/$NewUser
# Узнаем наш внешний ip адрес и вводим его
ip -br a
read -p "Введите внешний ip адрес:" YourIP
# Присваиваем значения переменным, они потом добавятся в конфигурационный файл клиента
UsrCert="$(head -84 $NewUser.crt | tail +65)"
CatCA="$(cat ca.crt)"
CatUsrKey="$(cat $NewUser.key)"
CatTA="$(cat ta.key)"
# Создаем конфигурационный файл пользователя
cat > /etc/openvpn/clients/$NewUser/$NewUser.ovpn <<EOF
client
dev tun
proto udp
remote $YourIP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth-nocache
verb 3
mute-replay-warnings
<ca>
$CatCA
</ca>
<cert>
$UsrCert
</cert>
<key>
$CatUsrKey
</key>
key-direction 1
<tls-auth>
$CatTA
</tls-auth>
EOF
echo "Файлы клиентского сертификата находятся здесь /etc/openvpn/clients/$NewUser"
