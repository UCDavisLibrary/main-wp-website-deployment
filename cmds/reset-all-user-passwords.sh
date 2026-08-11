#! /bin/bash

###
# Resets the WordPress password for every user in the given environment's
# docker compose cluster, using the WP CLI. Each user gets a new random
# password and no email notification is sent.
# Usage: ./cmds/reset-all-user-passwords.sh <environment>
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

DEPLOYMENT_DIR="../compose/main-website-$ENVIRONMENT"
if [ ! -d "$DEPLOYMENT_DIR" ]; then
  echo "Deployment directory does not exist: $DEPLOYMENT_DIR"
  exit 1
fi

cd "$DEPLOYMENT_DIR"

USER_IDS=$(docker compose exec -T wordpress wp user list --field=ID --allow-root)

for USER_ID in $USER_IDS; do
  NEW_PASSWORD=$(openssl rand -base64 32)
  docker compose exec -T wordpress wp user update "$USER_ID" --user_pass="$NEW_PASSWORD" --skip-email --allow-root
  echo "Reset password for user $USER_ID"
done

echo "Done. Passwords reset for all users in $ENVIRONMENT."
