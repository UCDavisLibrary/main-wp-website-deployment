#! /bin/bash

###
# Updates theme elements npm package to latest
###

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

source ./config.sh

for package in "${NPM_PRIVATE_PACKAGES[@]}"; do
  cd $package;
  if $NPM list | grep -q "@ucd-lib/theme-elements"; then
    $NPM i @ucd-lib/theme-elements@latest --save
  fi
  if $NPM list | grep -q "@ucd-lib/theme-sass"; then
    $NPM i @ucd-lib/theme-sass@latest --save
  fi
  cd $ROOT_DIR/..
done
