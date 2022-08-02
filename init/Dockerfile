FROM debian:buster

# Prep work for gsutils
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg curl cron 
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -


RUN apt-get update && apt-get install -y mariadb-client \
    wait-for-it google-cloud-sdk \
    php-cli php-mysql jq && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x /usr/local/bin/wp

COPY run.sh /run.sh
COPY backup.sh /backup.sh

# Give init the ability to run wp-cli scripts
RUN mkdir /etc/wordpress
COPY wp-config.php /etc/wordpress/wp-config.php
COPY wp-cli.yml /etc/wordpress/wp-cli.yml
ENV WP_CLI_CONFIG_PATH=/etc/wordpress/wp-cli.yml
RUN wp --allow-root core download

COPY backup-cron /etc/cron.d/backup
COPY backup_entrypoint.sh /backup_entrypoint.sh
RUN chmod 0644 /etc/cron.d/backup

CMD [ "/run.sh" ]
