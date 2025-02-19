#! /bin/bash

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Please provide a version number"
  exit 1
fi

DEPTH=$2
if [ -z "$DEPTH" ]; then
  DEPTH=ALL
fi

cork-kube build exec \
  --project main-wp-website \
  --version $VERSION \
  --override-tag local-dev \
  --depth $DEPTH \
  --no-cache-from
