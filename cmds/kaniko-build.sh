#! /bin/bash

###
# Main build process to cutting production images
# Docs: https://github.com/GoogleContainerTools/kaniko
# And Here: https://cloud.google.com/build/docs/speeding-up-builds
# And Here: https://cloud.google.com/build/docs/kaniko-cache
#
# Note: we want to be able to pre our builds outside of cloudbuild.yaml
# file, thus we call the kaniko container, which takes little prep
# for gcr permissions.
###

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..
source config.sh

WEBSITE_REPO_HASH=$(git -C $REPOSITORY_DIR/$WEBSITE_REPO_NAME log -1 --pretty=%h)
CACHE_TIME=720h

# Helpfull for debugging build locally
# docker run --rm -it -v $(pwd):/workspace \
#   -v $(pwd)/main-website-content-writer-key.json:/kaniko/config.json:ro \
#   -v $(pwd):/workspace \
#   -e GOOGLE_APPLICATION_CREDENTIALS=/kaniko/config.json \
#   --entrypoint sh \
#   gcr.io/kaniko-project/executor:debug

##
# Website
##
docker run --rm -v $(pwd):/workspace \
  -v $(pwd)/main-website-content-writer-key.json:/kaniko/config.json:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/kaniko/config.json \
  gcr.io/kaniko-project/executor:latest \
  --cache=true \
  --cache-ttl=720h \
  --snapshotMode=redo \
  --cache-copy-layers=false \
  --destination=$WEBSITE_IMAGE_NAME_TAG \
  --build-arg=BUILDKIT_INLINE_CACHE=1 \
  --build-arg=GOOGLE_KEY_FILE_CONTENT="${GOOGLE_KEY_FILE_CONTENT}" \
  --build-arg=WEBSITE_TAG=${WEBSITE_TAG} \
  --build-arg=BUILD_NUM=${BUILD_NUM} \
  --build-arg=BUILD_TIME=${BUILD_TIME} \
  --build-arg=APP_VERSION=${APP_VERSION} \
  --context=/workspace/$REPOSITORY_DIR/$WEBSITE_REPO_NAME \
  --dockerfile=/workspace/$REPOSITORY_DIR/$WEBSITE_REPO_NAME/Dockerfile

##
# Init/Data back and hydration helper
##
docker run --rm -v $(pwd):/workspace \
  -v $(pwd)/main-website-content-writer-key.json:/kaniko/config.json:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/workspace/main-website-content-writer-key.json \
  gcr.io/kaniko-project/executor:latest \
  --cache=true \
  --cache-ttl=720h \
  --destination=$UTILS_IMAGE_NAME_TAG \
  --build-arg=BUILDKIT_INLINE_CACHE=1 \
  --build-arg=BASE_IMAGE=${WEBSITE_IMAGE_NAME_TAG} \
  --context=$UTILS_DIR \
  --dockerfile=$UTILS_DIR/Dockerfile

##
# Elastic Search Indexer
##
docker run --rm -v $(pwd):/workspace \
  -v $(pwd)/main-website-content-writer-key.json:/kaniko/config.json:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/workspace/main-website-content-writer-key.json \
  gcr.io/kaniko-project/executor:latest \
  --cache=true \
  --cache-ttl=720h \
  --destination=$INDEXER_IMAGE_NAME_TAG \
  --build-arg=BUILDKIT_INLINE_CACHE=1 \
  --context=$INDEXER_DIR \
  --dockerfile=$INDEXER_DIR/Dockerfile
