#!/bin/sh

print_err() {
    printf "* ERROR: $@\n" 1>&2
}
print_info() {
    printf "* INFO: $@\n" 1>&2
}

LOGFILE="/var/log/elk-setup.log"
sudo touch $LOGFILE
sudo chown $USER:$USER $LOGFILE

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

print_info "Update repository"
sudo apt-get update >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not install updates (Error Code: $ERROR)."
    exit
fi
print_info "Install default-jre"
sudo apt-get install -y default-jre >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not default-jre (Error Code: $ERROR)."
    exit
fi
java -version >>$LOGFILE 2>&1

print_info "Install default-jdk"
sudo apt-get install -y default-jdk >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not default-jdk (Error Code: $ERROR)."
    exit
fi
javac -version >>$LOGFILE 2>&1

print_info "Install nginx"
sudo apt-get install -y nginx >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not nginx (Error Code: $ERROR)."
    exit
fi

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - >>$LOGFILE 2>&1
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list >>$LOGFILE 2>&1
print_info "Update repository"
sudo apt-get update >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not install updates (Error Code: $ERROR)."
    exit
fi

print_info "Install elasticsearch"
sudo apt-get install -y elasticsearch >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not install elasticsearch (Error Code: $ERROR)."
    exit
fi

print_info "Configure elasticsearch.yml"
sudo cp -f elasticsearch.yml /etc/elasticsearch/elasticsearch.yml >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not copy elasticsearch.yml to /etc/elasticsearch/elasticsearch.yml (Error Code: $ERROR)."
    exit
fi

print_info "Enable elasticsearch"
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not enable elasticsearch in systemctl (Error Code: $ERROR)."
    exit
fi

print_info "Start elasticsearch"
sudo systemctl start elasticsearch.service >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not start elasticsearch (Error Code: $ERROR)."
    exit
fi

print_info "Install kibana"
sudo apt-get install -y kibana >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not install kibana (Error Code: $ERROR)."
    exit
fi

print_info "Enable kibana"
sudo systemctl enable kibana >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not enable kibana in systemctl (Error Code: $ERROR)."
    exit
fi

print_info "Start kibana"
sudo systemctl start kibana.service >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not start kibana (Error Code: $ERROR)."
    exit
fi

print_info "Configure nginx"
sudo cp -f rev-proxy.conf /etc/nginx/sites-available/default >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not copy rev-proxy.conf to /etc/nginx/sites-available/default (Error Code: $ERROR)."
    exit
fi

sudo nginx -t >>$LOGFILE 2>&1
print_info "Reload nginx"
sudo systemctl reload nginx >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not reload Nginx (Error Code: $ERROR)."
    exit
fi

print_info "Install logstash"
sudo apt-get install -y logstash >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not install logstash (Error Code: $ERROR)."
    exit
fi

print_info "Configure logstash"

sudo cp -f 02-beats-input.conf /etc/logstash/conf.d/02-beats-input.conf >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not copy 02-beats-input.conf to /etc/logstash/conf.d/02-beats-input.conf (Error Code: $ERROR)."
    exit
fi

sudo cp -f 30-elasticsearch-output.conf /etc/logstash/conf.d/30-elasticsearch-output.conf >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not copy 30-elasticsearch-output.conf to /etc/logstash/conf.d/30-elasticsearch-output.conf (Error Code: $ERROR)."
    exit
fi

sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t >>$LOGFILE 2>&1

print_info "Enable logstash"
sudo systemctl enable logstash

print_info "Start logstash"
sudo systemctl start logstash.service

sudo ufw app list >>$LOGFILE 2>&1
sudo ufw allow 'Nginx Full' >>$LOGFILE 2>&1
sudo ufw allow ssh >>$LOGFILE 2>&1
sudo ufw allow 5044 >>$LOGFILE 2>&1v
sudo ufw --force enable >>$LOGFILE 2>&1

sudo ufw status >>$LOGFILE 2>&1
curl -4 icanhazip.com >>$LOGFILE 2>&1

systemctl --no-pager status nginx.service >>$LOGFILE 2>&1
systemctl --no-pager status elasticsearch.service >>$LOGFILE 2>&1
systemctl --no-pager status kibana.service >>$LOGFILE 2>&1
systemctl --no-pager status logstash.service >>$LOGFILE 2>&1
