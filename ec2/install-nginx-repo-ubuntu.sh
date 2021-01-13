#! /bin/bash

## Install NGINX (Repo) - Ubuntu
## PAOCLOUD COMPANY LIMITED
## Website : www.paocloud.co.th , Email : technical@paocloud.co.th

echo "
deb [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ focal nginx
deb-src http://nginx.org/packages/mainline/ubuntu/ focal nginx
" > /etc/apt/sources.list.d/nginx.list

wget http://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key

sudo apt update

sudo apt -y install nginx

sudo systemctl start nginx
sudo systemctl enable nginx

wget https://statics.paocloud.co.th/terraform/nginx/nginx.conf
wget https://statics.paocloud.co.th/terraform/nginx/owasp.conf
wget https://statics.paocloud.co.th/terraform/nginx/owasp-server.conf
wget https://statics.paocloud.co.th/terraform/nginx/tls.conf
wget https://statics.paocloud.co.th/terraform/nginx/default.conf

sudo cp nginx.conf /etc/nginx/

sudo cp owasp.conf /etc/nginx/conf.d/
sudo cp owasp-server.conf /etc/nginx/conf.d/
sudo cp tls.conf /etc/nginx/conf.d/

sudo rm -f /etc/nginx/conf.d/default.conf

sudo mkdir -p /etc/nginx/vhost/
sudo cp default.conf /etc/nginx/vhost/

sudo nginx -t

sudo systemctl restart nginx
