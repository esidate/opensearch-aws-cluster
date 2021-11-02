#!/bin/sh

LOGFILE="/var/log/elk-setup.log"
print_err() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2
}

sudo apt update >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not install updates (Error Code: $ERROR)."
    exit
fi

sudo apt install -y default-jre >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not default-jre (Error Code: $ERROR)."
    exit
fi
java -version >>$LOGFILE 2>&1

sudo apt install -y default-jdk >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not default-jdk (Error Code: $ERROR)."
    exit
fi
javac -version >>$LOGFILE 2>&1

sudo apt install -y nginx >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not nginx (Error Code: $ERROR)."
    exit
fi

sudo ufw app list >>$LOGFILE 2>&1
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw --force enable >>$LOGFILE 2>&1
sudo ufw status >>$LOGFILE 2>&1
systemctl status nginx >>$LOGFILE 2>&1
curl -4 icanhazip.com >>$LOGFILE 2>&1

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not install updates (Error Code: $ERROR)."
    exit
fi

sudo apt install -y elasticsearch >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not install elasticsearch (Error Code: $ERROR)."
    exit
fi

sudo cp -f elasticsearch.yml /etc/elasticsearch/elasticsearch.yml >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not copy elasticsearch.yml to /etc/elasticsearch/elasticsearch.yml (Error Code: $ERROR)."
    exit
fi

sudo systemctl enable elasticsearch >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not enable elasticsearch in systemctl (Error Code: $ERROR)."
    exit
fi

sudo systemctl start elasticsearch >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not start elasticsearch (Error Code: $ERROR)."
    exit
fi

sudo apt install -y kibana >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not install kibana (Error Code: $ERROR)."
    exit
fi

sudo systemctl enable kibana >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not enable kibana in systemctl (Error Code: $ERROR)."
    exit
fi

sudo systemctl start kibana >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not start kibana (Error Code: $ERROR)."
    exit
fi

sudo cp -f rev-proxy.conf /etc/nginx/sites-available/default >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not copy rev-proxy.conf to /etc/nginx/sites-available/default (Error Code: $ERROR)."
    exit
fi

sudo nginx -t >>$LOGFILE 2>&1
sudo systemctl reload nginx >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not reload Nginx (Error Code: $ERROR)."
    exit
fi

sudo apt install -y logstash >>$LOGFILE 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
    print_err "Could not install logstash (Error Code: $ERROR)."
    exit
fi

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

sudo systemctl enable logstash
sudo systemctl start logstash
