#! /bin/bash

set -e

CLUSTER_NAME="wp-${BRANCH_NAME}"

if [[ ! -d "/opt/${CLUSTER_NAME}" ]]; then
  echo "Docker compose cluster /opt/${CLUSTER_NAME} is does not exist, skipping deployment"
  exit 0
fi

echo "USER:$USER";
echo "BRANCH_NAME:${BRANCH_NAME}";
echo "CLUSTER_NAME:${CLUSTER_NAME}";

cd /opt/${CLUSTER_NAME}
git reset HEAD --hard
git checkout ${BRANCH_NAME}
git pull

docker-compose pull
docker-compose down
docker-compose up -d
docker image prune -f