#! /bin/bash

GOOGLE_CLOUD_BUCKET=website-v3-content
GOOGLE_CLOUD_PROJECT=digital-ucdavis-edu
UPLOADS_TAR_FILE=uploads.tar.gz
UPLOADS_DIR=/uploads
MYSQL_DUMP_FILE=main-wp-website.sql.gz
THIS_WP_SERVER=http://localhost

shopt -s expand_aliases

# separate db host from port. wp conflates them in its host config variable.
if [[ $WORDPRESS_DB_HOST =~ ":" ]]; then
  WORDPRESS_DB_JUST_HOST=$(echo $WORDPRESS_DB_HOST | cut -d ":" -f1)
  WORDPRESS_DB_JUST_PORT=$(echo $WORDPRESS_DB_HOST | cut -d ":" -f2)
else
  WORDPRESS_DB_JUST_HOST=$WORDPRESS_DB_HOST
  WORDPRESS_DB_JUST_PORT=3306
fi
alias mysql="mysql --user=$WORDPRESS_DB_USER --host=$WORDPRESS_DB_JUST_HOST --port=$WORDPRESS_DB_JUST_PORT --password=$WORDPRESS_DB_PASSWORD $WORDPRESS_DB_DATABASE"

# wait for db to start up
wait-for-it $WORDPRESS_DB_JUST_HOST:$WORDPRESS_DB_JUST_PORT

if [[ -z RUN_INIT || -z SERVER_ENV ]]; then
  echo "Skipping db and media uploads hydration.";
  if [[ -z RUN_INIT ]]; then
    echo "No RUN_INIT flag found."
  else 
    echo "SERVER_ENV environmental variable is not set."
  fi
else

  # check database
  DB_HAS_DATA=$(echo "SELECT count(*) FROM information_schema.TABLES WHERE (TABLE_SCHEMA = '${WORDPRESS_DB_DATABASE}') AND (TABLE_NAME = 'wp_options')" | mysql -s )
  if [[ $DB_HAS_DATA = 0 ]]; then
    echo "No WP data found in db, attempting to pull content for google cloud bucket"

    gcloud auth login --quiet --cred-file=${GOOGLE_APPLICATION_CREDENTIALS}
    gcloud config set project $GOOGLE_CLOUD_PROJECT

    echo "Downloading: gs://${GOOGLE_CLOUD_BUCKET}/${SERVER_ENV}/${MYSQL_DUMP_FILE}"
    gsutil cp "gs://${GOOGLE_CLOUD_BUCKET}/${SERVER_ENV}/${MYSQL_DUMP_FILE}" /$MYSQL_DUMP_FILE

    echo "Loading sql dump file"
    zcat /$MYSQL_DUMP_FILE | mysql
    rm /$MYSQL_DUMP_FILE

    echo "Updating links from ${SERVER_ENV_URL} to ${THIS_WP_SERVER}:${HOST_PORT}"
    SERVER_ENV_URL=$(echo "SELECT option_value from wp_options WHERE option_name='siteurl' LIMIT 1" | mysql -s)
    mysql -e "update wp_options set option_value='${THIS_WP_SERVER}:${HOST_PORT}' where option_name='siteurl';"
    mysql -e "update wp_options set option_value='${THIS_WP_SERVER}:${HOST_PORT}' where option_name='home';"
    mysql -e "UPDATE wp_posts SET post_content = REPLACE(post_content, '${SERVER_ENV_URL}', '${THIS_WP_SERVER}:${HOST_PORT}');"
    mysql -e "UPDATE wp_posts SET guid = REPLACE(guid, '${SERVER_ENV_URL}', '${THIS_WP_SERVER}:${HOST_PORT}');"
    mysql -e "UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '${SERVER_ENV_URL}', '${THIS_WP_SERVER}:${HOST_PORT}');"

  else
    echo "WP data found in ${WORDPRESS_DB_JUST_HOST}:${WORDPRESS_DB_JUST_PORT}. Skipping hydration."

  fi


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
  else
    echo "Uploads folder has data. Skipping hydration."
  fi

fi

echo "Init container is finished and exiting (this is supposed to happen)"