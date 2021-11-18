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
APP_VERSION=v3.0.0-alpha.${BUILD_NUM}

# Repository tags/branchs
# Tags should always be used for production deployments
# Branches can be used for development deployments
WEBSITE_TAG=main

# set local-dev tags used by 
# local development docker-compose file
if [[ ! -z $LOCAL_BUILD ]]; then
  WEBSITE_TAG='local-dev'
fi

MYSQL_TAG=5.7
ADMINER_TAG=4

##
# Container
##

# Container Registery
CONTAINER_REG_ORG=gcr.io/digital-ucdavis-edu
CONTAINER_CACHE_TAG="latest"

# Container Images
WEBSITE_IMAGE_NAME=$CONTAINER_REG_ORG/main-wp-website
MYSQL_IMAGE_NAME=mysql
ADMINER_IMAGE_NAME=adminer

WEBSITE_IMAGE_NAME_TAG=$WEBSITE_IMAGE_NAME:$WEBSITE_TAG
MYSQL_IMAGE_NAME_TAG=$MYSQL_IMAGE_NAME:$MYSQL_TAG
ADMINER_IMAGE_NAME_TAG=$ADMINER_IMAGE_NAME:$ADMINER_TAG

ALL_DOCKER_BUILD_IMAGE_TAGS=(
  $WEBSITE_IMAGE_NAME_TAG
)

##
# Repositories
##

GITHUB_ORG_URL=https://github.com/UCDavisLibrary

# Website
WEBSITE_REPO_NAME=main-wp-website
WEBSITE_REPO_URL=$GITHUB_ORG_URL/$WEBSITE_REPO_NAME

# Submodules of Website
# Only listed here to simplify local development
THEME_REPO_NAME=ucdlib-theme-wp
THEME_REPO_URL=$GITHUB_ORG_URL/$THEME_REPO_NAME

##
# Git
##
GIT=git
GIT_CLONE="$GIT clone"

ALL_GIT_REPOSITORIES=( $WEBSITE_REPO_NAME $THEME_REPO_NAME)

# directory we are going to cache our various git repos at different tags
# if using pull.sh or the directory we will look for repositories (can by symlinks)
# if local development
REPOSITORY_DIR=repositories

# wp directories
WP_UCD_THEME_DIR=/var/www/html/wp-content/themes/$THEME_REPO_NAME