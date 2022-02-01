#! /bin/bash

###
# Main build process to cutting production images
###

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..
source config.sh

# Use buildkit to speedup local builds
# Not supported in google cloud build yet
if [[ -z $CLOUD_BUILD ]]; then
  export DOCKER_BUILDKIT=1
fi

WEBSITE_REPO_HASH=$(git -C $REPOSITORY_DIR/$WEBSITE_REPO_NAME log -1 --pretty=%h)

##
# Website
##
docker build \
  -t $WEBSITE_IMAGE_NAME_TAG \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --cache-from=$WEBSITE_IMAGE_NAME:$CONTAINER_CACHE_TAG \
  --build-arg GOOGLE_KEY_FILE_CONTENT="${GOOGLE_KEY_FILE_CONTENT}" \
  --build-arg WEBSITE_TAG=${WEBSITE_TAG} \
  --build-arg BUILD_NUM=${BUILD_NUM} \
  --build-arg BUILD_TIME=${BUILD_TIME} \
  --build-arg APP_VERSION=${APP_VERSION} \
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME

##
# Init/Data hydration helper
## 
docker build \
  -t $INIT_IMAGE_NAME_TAG \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --cache-from=$INIT_IMAGE_NAME:$CONTAINER_CACHE_TAG \
  $INIT_DIR