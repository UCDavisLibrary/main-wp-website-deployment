# Website Deployment
This repository contains files for deploying the main UC Davis Library website (library.ucdavis.edu) to a server or locally. 

## Site Architecture
library.ucdavis.edu is a custom Wordpress installation composed of several services and git repositories:
- Third-party Services
  - [Wordpress](https://developer.wordpress.org/)
  - [Wordpress CLI](https://wp-cli.org/)
  - [Mysql](https://www.mysql.com/)
  - [Elasticsearch](https://www.elastic.co/elasticsearch/) and [Kibana](https://www.elastic.co/kibana/)
  - [Adminer (local development only)](https://www.adminer.org/)
- Custom Git Repositories
  - [Primary Theme](https://github.com/UCDavisLibrary/ucdlib-theme-wp)
  - [Additional Plugins](https://github.com/UCDavisLibrary/ucdlib-wp-plugins)
  - [ES Indexer](https://github.com/UCDavisLibrary/main-wp-website/tree/stage/elastic-search)
  - [Data init and backup services](https://github.com/UCDavisLibrary/main-wp-website-deployment/tree/stage/init)

## Local Development

### Initial Setup
- Clone this repository
  - `git clone`
- Checkout the branch you want to work on, e.g.:
  - `git checkout sandbox`
- In the same parent folder in which you performed step 1, clone all git repositories for this deployment. They are defined in config.sh as `ALL_GIT_REPOSITORIES`. IMPORTANT: Make sure you checkout to the branches you wish to work on for each repository.
- Setup the `./repositories` folder by running `./cmds/init-local-dev.sh`. 
- Grab service account so the `init` container can access website snapshot bucket
  - Install `gcloud` cli and `gsutils` if you don't already have it (https://cloud.google.com/storage/docs/gsutil_install)
  - Login and set project id
    - `gcloud auth login`
    - `gcloud config set project digital-ucdavis-edu`
  - Copy service account keys: 
    - `./cmds/init-keys.sh`
- Create your local docker-compose file by running:
  - `./cmds/generate-deployment-files.sh`
- Start an `.env` file in the `local-dev` directory (created in the previous step). The most relevant parameters are:
  - `BACKUP_ENV`: set to something like `sandbox`, `dev`, `prod`, etc. Specifies which Google Cloud bucket to pull data from. Defaults to `sandbox`
  - `SERVER_URL`: where your local wp instance will live. defaults to `http://localhost:3000`
  - `HOST_PORT`: host port for the wp instance. defaults to `3000`
  - `WORDPRESS_DEBUG`: turns on the php debugger. Defaults to `1`(on)
  - `WORDPRESS_CONFIG_EXTRA`: An opportunity to pass additional values to your wp-config file. To turn on all debugging for development, set to: `define( 'WP_ENVIRONMENT_TYPE', 'local' );define('SCRIPT_DEBUG', true);`
  - `RUN_INIT`: Run data hydration on cold start
- Run the JS watch processes at least once to generate bundles (see section below)

Your development environment should now have all the necessary pieces in place. The next section goes over how to start everything up.

### Making Changes in Local Development
- Make sure you followed all the steps in the local-dev inital setup section above.
- By default, the site loads the dev public and editor js bundles, which are created by two watch processes in the `ucdlib-assets` plugin. With the watch processes on, any changes you make to the JS/SCSS src will be immediately updated in the bundled site code. To start these up, navigate to `repositories/main-wp-website/ucdlib-wp-plugins/ucdlib-assets` and run:
  - `cd src/public; npm run watch`
  - `cd src/editor; npm run watch`
- Bring the site up by starting the docker compose stack:
  - `cd website-local-dev; docker compose up`
- Code directories are mounted as volumes so changes to your host filesystem are reflected in container.

### Checking in your code

#### Loading a new snapshot
If you need to update your snapshot or use a different one entirely:
1. Drop the existing docker volumes: `docker compose down -v`
2. Make sure your `BACKUP_ENV` config is pointing to the bucket you want to use
3. Restart the stack: `docker compose up`
  

## Usage

### Env File
Here are some common parameters:
| Param | Description |
| ----- | ----------- |
| SERVER_URL | Your wordpress site url/blog address i.e. `https://stage.library.ucdavis.edu` or `http://localhost:3000`| 
| WORDPRESS_DEBUG | Set to `1` to turn wp's php debug mode. Nice for local development. |
| WORDPRESS_CONFIG_EXTRA | Set arbitrary `wp-config` values. `WORDPRESS_CONFIG_EXTRA=define('SCRIPT_DEBUG', true);` will turn on the React debug tool. |
| HOST_PORT | Port where site is hosted. Defaults to `8000` |
| WORDPRESS_DB_DATABASE | Name of mysql database used by site. defaults to `wordpress` |
| WORDPRESS_DB_PASSWORD | Password of mysql database used by site. defaults to `wordpress` |
| WORDPRESS_DB_USER | User of mysql database used by site. defaults to `wordpress` |
| MYSQL_ROOT_PASSWORD | Root password for db. defaults to `wordpress` |
| BACKUP_ENV | Google bucket to write nightly backups to |
| DATA_ENV | Google bucket to pull data from if db/uploads folder are empty |
| UCD_CAS_ENSURE_USERS | Takes a comma-separated list of kerberos ids. guarantees specified users admin access to site |

Here is a good env for local development:
```
WORDPRESS_DEBUG=1
WORDPRESS_CONFIG_EXTRA=define( 'WP_ENVIRONMENT_TYPE', 'local' );define('SCRIPT_DEBUG', true);
DATA_ENV=stage
UCD_CAS_ENSURE_USERS=yourKerberos
```


