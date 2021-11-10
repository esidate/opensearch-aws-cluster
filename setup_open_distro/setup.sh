#!/bin/bash

# sudo apt-get install -y apache2-utils
# sudo htpasswd -c -b /etc/nginx/conf.d/.htpasswd $NGINX_BASIC_AUTH_USER $NGINX_BASIC_AUTH_PASS

sudo apt-get -y update
sudo apt-get -y install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

sudo sh -c 'echo "vm.max_map_count=262144" >>/etc/sysctl.conf'
sudo sysctl -p

sudo apt-get -y install -y nginx
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

sudo docker network create opensearch-net
sudo docker run -it --rm --name opensearch-logstash --net opensearch-net -p "5044:5044" -d opensearchproject/logstash-oss-with-opensearch-output-plugin:7.13.2 \
    -e '
    input {
        beats {
            port => 5044
            }
        }
    output {
        if [@metadata][pipeline] {
            opensearch {
                hosts => ["https://opensearch-node:9200"]
                manage_template => false
                index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
                pipeline => "%{[@metadata][pipeline]}"
                user => "admin"
                password => "admin"
                ssl => true
                ssl_certificate_verification => false
            }
        } else {
            opensearch {
                hosts => ["https://opensearch-node:9200"]
                manage_template => false
                index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
                user => "admin"
                password => "admin"
                ssl => true
                ssl_certificate_verification => false
            }
        }
    }
    '

sudo docker-compose up -d
sudo docker-compose logs -f
# Generate password
# export ADMIN_PASS=$(echo "slakdjsakdjsaldjsalkd")

# (
#     echo "cat <<EOF >internal_users.yml"
#     cat internal_users_template.yml
#     echo "EOF"
# ) >temp.yml
# . temp.yml

# rm -f temp.yml
