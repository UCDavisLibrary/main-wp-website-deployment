#! /bin/bash

GOOGLE_CLOUD_BUCKET=website-v3-content
GOOGLE_CLOUD_PROJECT=digital-ucdavis-edu
UPLOADS_TAR_FILE=uploads.tar.gz
UPLOADS_DIR=/uploads
UCD_THEME=ucdlib-theme-wp/theme
alias mysql="mysql --user=$WORDPRESS_DB_USER --host=$WORDPRESS_DB_HOST --password=$WORDPRESS_DB_PASSWORD $WORDPRESS_DB_DATABASE"


# wait for db to start up
wait-for-it $WORDPRESS_DB_HOST:${WORDPRESS_DB_PORT}


if [[ -z RUN_INIT || -z SERVER_ENV ]]; then
  # mysql check
  ACTIVE_THEME=$(echo 'select option_value from wp_options WHERE option_name="stylesheet";' | mysql )
fi


# set host and update links in db
 
#mysql < wp-db.sql
# THESE TWO ITEMS modifiy the siteurl and home parameters.
# Similar to the wpcld commands  wp option update siteurl $host and wp option update home $host
#mysql -e 'update wp_options set option_value="https://rc.library.ucdavis.edu" where option_name="siteurl";'
#mysql -e 'update wp_options set option_value="https://rc.library.ucdavis.edu" where option_name="home";'
# These commands update the post content to replace any explicit links.
#mysql -e 'UPDATE wp_posts SET post_content = REPLACE(post_content, 'www.library.ucdavis.edu', 'rc.library.ucdavis.edu');'
#mysql -e 'UPDATE wp_posts SET guid = REPLACE(guid, 'www.library.ucdavis.edu', 'rc.library.ucdavis.edu');'
# This command updates all ACF data with explicit hosts.
#mysql -e 'UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'www.library.ucdavis.edu', 'rc.library.ucdavis.edu');'



# check uploads folder
UPLOADS_FILE_COUNT=$(ls -1q $UPLOADS_DIR | wc -l)

if [[ $UPLOADS_FILE_COUNT == 0 ]]; then
  echo "Uploads folder is empty, attempting to pull content for google cloud bucket"
  
  # WHY??? 
  gcloud auth login --quiet --cred-file=${GOOGLE_APPLICATION_CREDENTIALS}
  gcloud config set project $GOOGLE_CLOUD_PROJECT

  echo "Downloading: gs://${GOOGLE_CLOUD_BUCKET}/${SERVER_ENV}/${UPLOADS_TAR_FILE}"
  gsutil cp "gs://${GOOGLE_CLOUD_BUCKET}/${SERVER_ENV}/${UPLOADS_TAR_FILE}" $UPLOADS_DIR/$UPLOADS_TAR_FILE
  echo "Extracting: tar -zxvf $UPLOADS_DIR/$UPLOADS_TAR_FILE -C $UPLOADS_DIR"
  cd $UPLOADS_DIR
  tar -zxvf $UPLOADS_DIR/$UPLOADS_TAR_FILE -C .
  rm $UPLOADS_DIR/$UPLOADS_TAR_FILE

  # Check if zip file contained a 'uploads' folder, if so move up one directory
  UPLOADS_FILE_COUNT=$(ls -1q $UPLOADS_DIR | wc -l)
  FILE_NAME=$(ls -1q)
  if [[ $UPLOADS_FILE_COUNT == 1 && $FILE_NAME == 'uploads' ]]; then
    mv uploads/* .
    rm -r uploads
  fi
fi

echo "Init container is finished and exiting (this is supposed to happen)"