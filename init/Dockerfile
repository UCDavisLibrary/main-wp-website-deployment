FROM debian:buster

# Prep work for gsutils
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg curl cron
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -


RUN apt-get update && apt-get install -y mariadb-client \
  wait-for-it google-cloud-sdk

COPY run.sh /run.sh
COPY backup.sh /backup.sh

COPY backup-cron /etc/cron.d/backup
COPY backup_entrypoint.sh /backup_entrypoint.sh
RUN chmod 0644 /etc/cron.d/backup

CMD [ "/run.sh" ]