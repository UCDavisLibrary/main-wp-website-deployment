#! /bin/bash

##
# Generate docker-compose deployment and local development files based on
# config.sh parameters
##

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/../templates

source ../config.sh

WEBSITE_IMAGE_NAME_ESCAPED=$(echo $WEBSITE_IMAGE_NAME | sed 's/\//\\\//g')

# generate local development dc file
content=$(cat local-dev.yaml)
WEBSITE_TAG='local-dev'
for key in $(compgen -v); do
  if [[ $key == "COMP_WORDBREAKS" || $key == "content" ]]; then
    continue;
  fi
  escaped=$(printf '%s\n' "${!key}" | sed -e 's/[\/&]/\\&/g')
  content=$(echo "$content" | sed "s/{{$key}}/${escaped}/g") 
done
if [ ! -d "../local-dev" ]; then
  mkdir ../local-dev
fi

echo "$content" > ../local-dev/docker-compose.yaml