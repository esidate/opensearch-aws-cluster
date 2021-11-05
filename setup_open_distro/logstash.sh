#!/bin/bash

sudo docker network create opensearch-net
sudo docker run -it --rm --name opensearch-logstash --net opensearch-net opensearchproject/logstash-oss-with-opensearch-output-plugin:7.13.2 \
    -e 'input { beats { port => 5044 } } output { if [@metadata][pipeline] { opensearch { hosts => ["https://opensearch-node:9200"] manage_template => false index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}" pipeline => "%{[@metadata][pipeline]}" user => "admin" password => "admin" ssl => true ssl_certificate_verification => false } } else { opensearch { ["https://opensearch-node:9200"] manage_template => false index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}" user => "admin" password => "admin" ssl => true ssl_certificate_verification => false } } }'
