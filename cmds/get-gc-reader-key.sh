#! /bin/bash

###
# download the google cloud reader key. needed to fetch data from gc bucket by init container
###

set -e
CMDS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $CMDS_DIR/..

mkdir -p ./secrets
gcloud --project=digital-ucdavis-edu secrets versions access latest --secret=main-website-content-reader-key > ./secrets/main-website-content-reader-key.json
