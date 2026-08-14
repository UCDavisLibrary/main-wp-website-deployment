#! /bin/bash

###
# Lists the WordPress application passwords for every user in the given
# environment's docker compose cluster, using the WP CLI.
# Usage: ./cmds/list-all-application-passwords.sh <environment>
# environment: required. e.g. local-dev, prod
###

set -e
CMDS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $CMDS_DIR

ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
  echo "Environment is required, e.g. local-dev"
  exit 1
fi

DEPLOYMENT_DIR="../compose/ucdlib-intranet-$ENVIRONMENT"
if [ ! -d "$DEPLOYMENT_DIR" ]; then
  echo "Deployment directory does not exist: $DEPLOYMENT_DIR"
  exit 1
fi

cd "$DEPLOYMENT_DIR"

# Formats a unix timestamp as 'YYYY-MM-DD HH:MM:SS'. Supports both BSD (mac) and
# GNU (linux) date. Falls back to the raw timestamp if date is unavailable or fails,
# and never causes the overall script to exit.
format_epoch(){
  local epoch=$1
  local formatted=""
  if [ -z "$epoch" ]; then
    echo ""
    return
  fi
  if command -v date >/dev/null 2>&1; then
    if date -r 0 >/dev/null 2>&1; then
      formatted=$(date -r "$epoch" "+%Y-%m-%d %H:%M:%S" 2>/dev/null) || true
    else
      formatted=$(date -d "@$epoch" "+%Y-%m-%d %H:%M:%S" 2>/dev/null) || true
    fi
  fi
  echo "${formatted:-$epoch}"
}

USER_IDS=$(docker compose exec -T wordpress wp user list --field=ID --allow-root)

echo "user_id,user_login,uuid,app_id,name,created,last_used,last_ip"

for USER_ID in $USER_IDS; do
  USER_LOGIN=$(docker compose exec -T wordpress wp user get "$USER_ID" --field=user_login --allow-root)
  PASSWORDS=$(docker compose exec -T wordpress wp user application-password list "$USER_ID" --fields=uuid,app_id,name,created,last_used,last_ip --format=csv --allow-root | tail -n +2)
  if [ -n "$PASSWORDS" ]; then
    echo "$PASSWORDS" | while IFS=, read -r UUID APP_ID NAME CREATED LAST_USED LAST_IP; do
      echo "$USER_ID,$USER_LOGIN,$UUID,$APP_ID,$NAME,$(format_epoch "$CREATED"),$(format_epoch "$LAST_USED"),$LAST_IP"
    done
  fi
done
