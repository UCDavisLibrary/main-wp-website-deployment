#! /bin/bash

###
# Does some initial setup for local dev
###

set -e
CMDS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $CMDS_DIR

./get-gc-reader-key.sh
./install-private-packages.sh
./generate-dev-bundles.sh
./get-env.sh local-dev
