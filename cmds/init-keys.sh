#! /bin/bash

###
# download the reader/writ
###

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

gcloud secrets versions access latest --secret=main-website-content-reader-key > main-website-content-reader-key.json