#! /bin/bash

###
# Extracts site data (sql + uploads) from running containers and pushes to designated google cloud bucket
###

GOOGLE_CLOUD_BUCKET=website-v3-content
GOOGLE_CLOUD_PROJECT=digital-ucdavis-edu
GOOGLE_APPLICATION_CREDENTIALS=./main-website-content-writer-key.json

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

if [[ -z "$1" ]]; then
  echo "Enter the google cloud bucket as first argument"
  exit 0
fi

if [[ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
    echo "Google cloud credential key file doesn't exist"
    exit 0
fi

echo "Generating sqldump file"
docker-compose exec -T db bash -c 'mysqldump --password="$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" | gzip > /main-wp-website.sql.gz'

if [ -d "./snapshots" ]; then
  rm -rf ./snapshots
fi
mkdir ./snapshots

#docker-compose cp db:/main-wp-website.sql.gz ./snapshots/main-wp-website.sql.gz
docker cp "$(docker-compose ps -q db)":/main-wp-website.sql.gz ./snapshots/main-wp-website.sql.gz
docker-compose exec -T db bash -c 'rm /main-wp-website.sql.gz'
echo "sqldump file copied to 'snapshots' directory on host"

echo "Compressing wp media uploads directory"
docker-compose exec -T wordpress bash -c 'tar -C wp-content -czvf uploads.tar.gz uploads'
docker cp "$(docker-compose ps -q wordpress)":/var/www/html/uploads.tar.gz ./snapshots/uploads.tar.gz
docker-compose exec -T wordpress bash -c 'rm uploads.tar.gz'
echo "uploads file copied to 'snapshots' directory on host"

echo "uploading files to cloud bucket ${1}"
gcloud auth login --quiet --cred-file=${GOOGLE_APPLICATION_CREDENTIALS}
gcloud config set project $GOOGLE_CLOUD_PROJECT
gsutil cp ./snapshots/main-wp-website.sql.gz "gs://${GOOGLE_CLOUD_BUCKET}/${1}/main-wp-website.sql.gz"
gsutil cp ./snapshots/uploads.tar.gz "gs://${GOOGLE_CLOUD_BUCKET}/${1}/uploads.tar.gz" 