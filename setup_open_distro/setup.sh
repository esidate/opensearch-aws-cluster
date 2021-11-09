#!/bin/bash

# sudo apt-get install -y apache2-utils
# sudo htpasswd -c -b /etc/nginx/conf.d/.htpasswd $NGINX_BASIC_AUTH_USER $NGINX_BASIC_AUTH_PASS

sudo apt-get install -y nginx
sudo cp -f rev-proxy.conf /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl --no-pager reload nginx
systemctl --no-pager status nginx.service

sudo ufw app list
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw allow 5044
sudo ufw --force enable
sudo ufw status

# Generate certificates
# Root CA
openssl genrsa -out root-ca-key.pem 2048
openssl req -new -x509 -sha256 -key root-ca-key.pem -out root-ca.pem -subj "/CN=A/OU=UNIT/O=ORG/L=TORONTO/ST=ONTARIO/C=CA"

# Admin cert
openssl genrsa -out admin-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out admin-key.pem
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=A/OU=UNIT/O=ORG/L=TORONTO/ST=ONTARIO/C=CA"
openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out admin.pem

# Node cert
openssl genrsa -out node-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in node-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out node-key.pem
openssl req -new -key node-key.pem -out node.csr -subj "/CN=N/OU=UNIT/O=ORG/L=TORONTO/ST=ONTARIO/C=CA"
openssl x509 -req -in node.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out node.pem

# Cleanup
rm admin-key-temp.pem admin.csr node-key-temp.pem node.csr

Generate password
export ADMIN_PASS=$(echo "slakdjsakdjsaldjsalkd")

(
    echo "cat <<EOF >internal_users.yml"
    cat internal_users_template.yml
    echo "EOF"
) >temp.yml
. temp.yml

rm -f temp.yml
