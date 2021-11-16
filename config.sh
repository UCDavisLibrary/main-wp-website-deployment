#! /bin/bash

######### DEPLOYMENT CONFIG ############
# Setup your application deployment here
########################################

# Repository tags/branchs
# Tags should always be used for production deployments
# Branches can be used for development deployments
THEME_TAG=main

# set local-dev tags used by 
# local development docker-compose file
if [[ ! -z $LOCAL_BUILD ]]; then
  THEME_TAG='local-dev'
fi

##
# Container
##

# Container Registery
CONTAINER_REG_ORG=gcr.io/ucdlib-pubreg
CONTAINER_CACHE_TAG="latest"

# Container Images
THEME_IMAGE_NAME=$CONTAINER_REG_ORG/wp-v3-theme

THEME_IMAGE_NAME_TAG=$THEME_IMAGE_NAME:$THEME_TAG

##
# Repositories
##

GITHUB_ORG_URL=https://github.com/UCDavisLibrary

# Theme
THEME_REPO_NAME=ucdlib-theme-wp
THEME_REPO_URL=$GITHUB_ORG_URL/$THEME_REPO_NAME


##
# Git
##
ALL_GIT_REPOSITORIES=( $THEME_REPO_NAME )