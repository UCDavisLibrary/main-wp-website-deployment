#! /bin/bash

$PROJECT_DIR='../..'
$THEME_REPO_NAME='ucdlib-theme-wp'
$PLUGIN_REPO_NAME='ucdlib-wp-plugins'

NPM=npm
NPM_PRIVATE_PACKAGES=(
  $PROJECT_DIR/$THEME_REPO_NAME/src/public
  $PROJECT_DIR/$THEME_REPO_NAME/src/editor
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-assets/src/public
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-assets/src/editor
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-locations/src/public
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-locations/src/editor
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-migration/src/editor
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-search/src/public
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-directory/src/editor
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-directory/src/public
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-special/src/editor
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-special/src/public
)
JS_BUNDLES=(
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-assets/src/public
  $PROJECT_DIR/$PLUGIN_REPO_NAME/ucdlib-assets/src/editor
)
