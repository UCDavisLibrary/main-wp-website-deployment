#! /bin/bash

###
# Init the /repositories folder with symbolic links to folders that exist in the same parent
# directory as this main-wp-website-deployment folder.
# Note: This script does not checkout any repository, it simply cleans the /repositories folders
# and makes the symbolic links
###

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

source ./config.sh

if [ -d "./${REPOSITORY_DIR}" ]; then
  rm -rf ./$REPOSITORY_DIR
fi
mkdir ./$REPOSITORY_DIR

for repo in "${ALL_GIT_REPOSITORIES[@]}"; do
  ln -s ../../$repo ./$REPOSITORY_DIR/$repo
done

(
  cd $REPOSITORY_DIR/$WEBSITE_REPO_NAME
  git submodule update --init --recursive
  cd ucdlib-theme-wp && git checkout $WP_THEME_SUB_TAG
  cd ../ucdlib-wp-plugins && git checkout $WP_PLUGINS_SUB_TAG
)

ls -al $REPOSITORY_DIR