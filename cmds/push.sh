#! /bin/bash

###
# Push docker image and $CONTAINER_CACHE_TAG (currently $CONTAINER_CACHE_TAG) tag to docker hub
###

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..
source config.sh

docker tag $WEBSITE_IMAGE_NAME_TAG $WEBSITE_IMAGE_NAME:$CONTAINER_CACHE_TAG
docker tag $UTILS_IMAGE_NAME_TAG $UTILS_IMAGE_NAME:$CONTAINER_CACHE_TAG
docker tag $INDEXER_IMAGE_NAME_TAG $INDEXER_IMAGE_NAME:$CONTAINER_CACHE_TAG

for image in "${ALL_DOCKER_BUILD_IMAGE_TAGS[@]}"; do
  docker push $image || true
done

for image in "${ALL_DOCKER_BUILD_IMAGES[@]}"; do
  docker push $image:$CONTAINER_CACHE_TAG || true
done