#! /bin/bash

###
# Does some initial setup for local dev
###

set -e
CMDS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $CMDS_DIR/..

./cmds/get-gc-reader-key.sh
./cmds/install-private-packages.sh
./cmds/generate-dev-bundles.sh
