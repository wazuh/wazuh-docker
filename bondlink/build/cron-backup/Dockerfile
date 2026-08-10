FROM alpine:latest
ARG S3_ENV_PATH
RUN apk add --no-cache aws-cli bash sed

COPY ./config/crontab /root/crontab.tmpl
RUN sed "s|__S3_ENV_PATH__|${S3_ENV_PATH}|" /root/crontab.tmpl > /var/spool/cron/crontabs/root && \
    rm /root/crontab.tmpl

# Fixed: this ENTRYPOINT was commented out in the 4.10 source, so the
# container fell back to alpine's default `/bin/sh` and exited immediately —
# combined with `restart: always` it crash-looped forever and the daily
# backup never actually ran.
ENTRYPOINT ["crond", "-f", "-d", "8"]
