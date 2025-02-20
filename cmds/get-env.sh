#! /bin/bash

###
# Downloads env from google cloud secret manager and places in specified deployment directory
# Usage: ./cmds/get-env.sh [-f] <deployment-dir>
# -f: force overwrite of existing .env file
# deployment-dir: required. e.g. local-dev gets placed in compose/main-website-local-dev/.env
###

set -e
CMDS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $CMDS_DIR

FORCE_OVERWRITE=false

while getopts ":f" opt; do
  case ${opt} in
    f )
      FORCE_OVERWRITE=true
      ;;
    \? )
      echo "Invalid option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

DEPLOYMENT_DIR=$1

if [ -z "$DEPLOYMENT_DIR" ]; then
  echo "Deployment directory is required."
  exit 1
fi

DEPLOYMENT_DIR="../compose/main-website-$DEPLOYMENT_DIR"

if [ ! -d "$DEPLOYMENT_DIR" ]; then
  echo "Deployment directory does not exist: $DEPLOYMENT_DIR"
  exit 1
fi

ENV_FILE="$DEPLOYMENT_DIR/.env"

if [ -f "$ENV_FILE" ] && [ "$FORCE_OVERWRITE" = false ]; then
  echo ".env file already exists. Use -f to force overwrite."
  exit 1
fi

gcloud --project=digital-ucdavis-edu secrets versions access latest --secret=main-website-env > "$ENV_FILE"

echo ".env file has been downloaded to $DEPLOYMENT_DIR"
