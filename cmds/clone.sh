#! /bin/bash

###
# Shallow clone repositories defined in config.sh
# WARNING: Used for gcloud builds.  This wipes
# respositories folders and starts fresh every time
###

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..
source config.sh

if [ -d $REPOSITORY_DIR ] ; then
  rm -rf $REPOSITORY_DIR
fi
mkdir -p $REPOSITORY_DIR

# Client
$GIT_CLONE $WEBSITE_REPO_URL.git \
  --branch $WEBSITE_TAG \
  --depth 1 \
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME

cd $REPOSITORY_DIR/$WEBSITE_REPO_NAME
git submodule update --init --recursive
cd $ROOT_DIR/..