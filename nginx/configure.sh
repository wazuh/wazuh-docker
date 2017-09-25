#!/bin/bash

set -e

if [ ! -d /etc/pki/tls/certs ]; then
  echo "Generating SSL certificates"
  mkdir -p /etc/pki/tls/certs /etc/pki/tls/private
  openssl req -x509 -batch -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/private/kibana-access.key -out /etc/pki/tls/certs/kibana-access.pem >/dev/null
else
  echo "SSL certificates already present"
fi

if [ ! -f /etc/nginx/conf.d/kibana.htpasswd ]; then
  echo "Setting Nginx credentials"
  echo bar|htpasswd -i -c /etc/nginx/conf.d/kibana.htpasswd foo >/dev/null
else
  echo "Kibana credentials already configured"
fi

echo "Configuring NGINX"
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    return 301 https://\$host:$NGINX_PORT\$request_uri;
}

server {
    listen $NGINX_PORT default_server;
    listen [::]:$NGINX_PORT;
    ssl on;
    ssl_certificate /etc/pki/tls/certs/kibana-access.pem;
    ssl_certificate_key /etc/pki/tls/private/kibana-access.key;
    location / {
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/conf.d/kibana.htpasswd;
        proxy_pass http://kibana:5601/;
    }
}
EOF

echo "Starting Nginx"
nginx -g 'daemon off; error_log /dev/stdout info;'
