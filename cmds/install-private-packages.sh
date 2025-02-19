#! /bin/bash

###
# Installs dependencies for all private NPM packages in theme and plugins
###

set -e
CMDS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $CMDS_DIR

source ./config.sh

for package in "${NPM_PRIVATE_PACKAGES[@]}"; do
  (cd $package && $NPM i)
done
