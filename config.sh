#! /bin/bash

######### DEPLOYMENT CONFIG ############
# Setup your application deployment here
########################################

# Grab build number is mounted in CI system
if [[ -f /config/.buildenv ]]; then
  source /config/.buildenv
else
  BUILD_NUM=-1
fi

# Main version number we are tagging the app with. Always update
# this when you cut a new version of the app!
APP_VERSION=v4.0.0.${BUILD_NUM}
APP_TAG=sandbox

# Repository tags/branchs
# Tags should always be used for production deployments
# Branches can be used for development deployments
WEBSITE_TAG=sandbox

# Submodules
# only used for init-local-dev checkout
WP_PLUGINS_SUB_TAG=sandbox
WP_THEME_SUB_TAG=sandbox

CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [[ -f "$CONFIG_DIR/main-website-content-reader-key.json" ]]; then
  GOOGLE_KEY_FILE_CONTENT="$(cat $CONFIG_DIR/main-website-content-reader-key.json)"
else
  echo "Warning: no developer key found"
fi

MYSQL_TAG=5.7
ADMINER_TAG=4
ELASTIC_SEARCH_TAG=7.16.3

##
# Container
##

# Container Registery
CONTAINER_REG_ORG=gcr.io/digital-ucdavis-edu

if [[ -z $BRANCH_NAME ]]; then
  CONTAINER_CACHE_TAG=$(git rev-parse --abbrev-ref HEAD)
else
  CONTAINER_CACHE_TAG=$BRANCH_NAME
fi

# set localhost/local-dev used by
# local development docker-compose file
if [[ ! -z $LOCAL_BUILD ]]; then
  CONTAINER_REG_ORG='localhost/local-dev'
fi


# Container Images
WEBSITE_IMAGE_NAME=$CONTAINER_REG_ORG/main-wp-website
UTILS_IMAGE_NAME=$CONTAINER_REG_ORG/main-wp-website-utils
INDEXER_IMAGE_NAME=$CONTAINER_REG_ORG/main-wp-website-es-indexer
MYSQL_IMAGE_NAME=mysql
ADMINER_IMAGE_NAME=adminer
ELASTIC_SEARCH_IMAGE_NAME=docker.elastic.co/elasticsearch/elasticsearch
KIBANA_IMAGE_NAME=docker.elastic.co/kibana/kibana

WEBSITE_IMAGE_NAME_TAG=$WEBSITE_IMAGE_NAME:$WEBSITE_TAG
INDEXER_IMAGE_NAME_TAG=$INDEXER_IMAGE_NAME:$WEBSITE_TAG
MYSQL_IMAGE_NAME_TAG=$MYSQL_IMAGE_NAME:$MYSQL_TAG
ADMINER_IMAGE_NAME_TAG=$ADMINER_IMAGE_NAME:$ADMINER_TAG
UTILS_IMAGE_NAME_TAG=$UTILS_IMAGE_NAME:$APP_TAG
MONITORING_IMAGE_NAME_TAG=$MONITORING_IMAGE_NAME:$WEBSITE_TAG

ALL_DOCKER_BUILD_IMAGES=( $WEBSITE_IMAGE_NAME $UTILS_IMAGE_NAME $INDEXER_IMAGE_NAME )

ALL_DOCKER_BUILD_IMAGE_TAGS=(
  $WEBSITE_IMAGE_NAME_TAG
  $UTILS_IMAGE_NAME_TAG
  $INDEXER_IMAGE_NAME_TAG
)

##
# Repositories
##

GITHUB_ORG_URL=https://github.com/UCDavisLibrary

# Website
WEBSITE_REPO_NAME=main-wp-website
WEBSITE_REPO_URL=$GITHUB_ORG_URL/$WEBSITE_REPO_NAME

# Submodules of Website
# They all already exist in 'main-wp-website'
# Only listed here to simplify committing changes during local development
THEME_REPO_NAME=ucdlib-theme-wp
PLUGIN_REPO_NAME=ucdlib-wp-plugins
# THEME_REPO_URL=$GITHUB_ORG_URL/$THEME_REPO_NAME
# PLUGIN_REPO_URL=$GITHUB_ORG_URL/$PLUGIN_REPO_NAME


##
# Git
##
GIT=git
GIT_CLONE="$GIT clone"

ALL_GIT_REPOSITORIES=( $WEBSITE_REPO_NAME )

# directory we are going to cache our various git repos at different tags
# if using pull.sh or the directory we will look for repositories (can by symlinks)
# if local development
REPOSITORY_DIR=repositories

# init container image directory
UTILS_DIR=utils
INDEXER_DIR=$REPOSITORY_DIR/$WEBSITE_REPO_NAME/elastic-search

# wp directories
WP_UCD_THEME_DIR=/usr/src/wordpress/wp-content/themes/$THEME_REPO_NAME
WP_PLUGIN_DIR=/usr/src/wordpress/wp-content/plugins

# NPM
NPM=npm
NPM_PRIVATE_PACKAGES=(
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$THEME_REPO_NAME/src/public
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$THEME_REPO_NAME/src/editor
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-assets/src/public
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-assets/src/editor
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-locations/src/public
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-locations/src/editor
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-migration/src/editor
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-search/src/public
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-directory/src/editor
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-directory/src/public
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-special/src/editor
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-special/src/public
)
JS_BUNDLES=(
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-assets/src/public
  $REPOSITORY_DIR/$WEBSITE_REPO_NAME/$PLUGIN_REPO_NAME/ucdlib-assets/src/editor
)
