FROM nginx:latest

RUN apt-get update && apt-get install -y openssl apache2-utils

COPY ./config/run.sh /run.sh

RUN chmod 755 /run.sh
