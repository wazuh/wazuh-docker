#!/bin/bash
# Wazuh Docker Copyright (C) 2019 Wazuh Inc. (License GPLv2)

set -e

# Generating certificates.
if [ ! -d /etc/nginx/conf.d/ssl ]; then
  echo "Generating SSL certificates"
  mkdir -p /etc/nginx/conf.d/ssl/certs /etc/nginx/conf.d/ssl/private
  openssl req -x509 -batch -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/conf.d/ssl/private/kibana-access.key -out /etc/nginx/conf.d/ssl/certs/kibana-access.pem >/dev/null
else
  echo "SSL certificates already present"
fi

# Setting users credentials.
# In order to set NGINX_CREDENTIALS, before "docker-compose up -d" run (a or b):
#
# a) export NGINX_CREDENTIALS="user1:pass1;user2:pass2;" or
#    export NGINX_CREDENTIALS="user1:pass1;user2:pass2"
#
# b) Set NGINX_CREDENTIALS in docker-compose.yml:
#    NGINX_CREDENTIALS=user1:pass1;user2:pass2; or
#    NGINX_CREDENTIALS=user1:pass1;user2:pass2
#
if [ ! -f /etc/nginx/conf.d/kibana.htpasswd ]; then
  echo "Setting users credentials"
  if [ ! -z "$NGINX_CREDENTIALS" ]; then
    IFS=';' read -r -a users <<< "$NGINX_CREDENTIALS"
    for index in "${!users[@]}"
    do
      IFS=':' read -r -a credentials <<< "${users[index]}"
      if [ $index -eq 0 ]; then
        echo ${credentials[1]}|htpasswd -i -c /etc/nginx/conf.d/kibana.htpasswd ${credentials[0]} >/dev/null
      else
        echo ${credentials[1]}|htpasswd -i /etc/nginx/conf.d/kibana.htpasswd  ${credentials[0]} >/dev/null
      fi
    done
  else
    # NGINX_PWD and NGINX_NAME are declared in nginx/Dockerfile 
    echo $NGINX_PWD|htpasswd -i -c /etc/nginx/conf.d/kibana.htpasswd $NGINX_NAME >/dev/null
  fi
else
  echo "Kibana credentials already configured"
fi

if [ "x${NGINX_PORT}" = "x" ]; then
  NGINX_PORT=443
fi

if [ "x${KIBANA_HOST}" = "x" ]; then
  KIBANA_HOST="kibana:5601"
fi

echo "Configuring NGINX"
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    return 301 https://\$host:${NGINX_PORT}\$request_uri;
}

server {
    listen ${NGINX_PORT} default_server;
    listen [::]:${NGINX_PORT};
    ssl on;
    ssl_certificate /etc/nginx/conf.d/ssl/certs/kibana-access.pem;
    ssl_certificate_key /etc/nginx/conf.d/ssl/private/kibana-access.key;
    location / {
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/conf.d/kibana.htpasswd;
        proxy_pass http://${KIBANA_HOST}/;
        proxy_buffer_size          128k;
        proxy_buffers              4 256k;
        proxy_busy_buffers_size    256k;
    }
}
EOF

nginx -g 'daemon off;'
