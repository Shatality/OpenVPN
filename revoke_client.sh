#!/bin/bash
# Откроем конфигурацию сервера OpenVPN и добавим туда директиву отвечающую за проверку отозванных сертификатов
# crl-verify crl.pem
# Переходим в директорию Easy-RSA
cd  /etc/openvpn/easy-rsa
# Cформируем список отозванных сертификатов:
./easyrsa gen-crl
# Посмотрим список пользователей чтобы выбрать кого-то для отзыва сертификата
echo "Список пользователей для отзыва сертификата:"
cd /etc/openvpn/clients ; ls -d */ | cut -f1 -d'/'
# Переходим обратно в директорию Easy-RSA
cd  /etc/openvpn/easy-rsa
# Для отзыва сертификата выполните (предварительно перейдя в директорию Easy-RSA):
read -p "Введите имя клиента для отзыва сертификата:" ClientName
./easyrsa revoke $ClientName
# После отзыва сертификата вам потребуется обновить список CRL, для этого еще раз выполните:
./easyrsa gen-crl
# Копируем файл отзыва в директорию с конфигурациоонным файлом сервера
cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
# Перезапускаем сервер
systemctl restart openvpn@server
# Удаляем директори
rm -rf /etc/openvpn/clients/$ClientName