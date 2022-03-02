#! /bin/bash

if [[ $NIGHT_BACKUPS != "true" ]]; then
  echo "NIGHTLY_BACKUPS flag not set to 'true', backup container will not run."
  exit 0;
fi

if [[ ! -f /var/log/cron.log ]]; then
  crontab 0 3 * * * /etc/cron.d/backup
  touch /var/log/cron.log
fi

cron && tail -f /var/log/cron.log