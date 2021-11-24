# Website Deployment
This repository contains files for deploying the main UC Davis Library website (library.ucdavis.edu) to a server or locally.

## Site Architecture
library.ucdavis.edu is a custom Wordpress installation composed of several services and git repositories:
- Third-party Services
  - [Wordpress](https://developer.wordpress.org/)
  - [Wordpress CLI](https://wp-cli.org/)
  - [Mysql](https://www.mysql.com/)
  - [Elasticsearch](https://www.elastic.co/elasticsearch/)
  - [Adminer (local development only)](https://www.adminer.org/)
- Custom Git Repositories
  - [Primary Theme](https://github.com/UCDavisLibrary/ucdlib-theme-wp)
  - [Additional Plugins](https://github.com/UCDavisLibrary/ucdlib-wp-plugins)

## Local Development

### Initial Setup
1. Clone this repository
   1. `git clone`
2. Checkout the branch you want to work on, e.g.:
   1. `git checkout dev`
3. In the same parent folder in which you performed step 1, clone all git repositories for this deployment. They are defined in config.sh as `ALL_GIT_REPOSITORIES`. IMPORATANT: Make sure you checkout to the branches you wish to work on for each repository.
4. Setup the `./repositories` folder by running `./cmds/init-local-dev.sh`. 
5. Grab service account so the `init` container can access website snapshot bucket
   1. Install `gcloud` cli and `gsutils` if you don't already have it (https://cloud.google.com/storage/docs/gsutil_install)
   2. Login and set project id
     1. `gcloud auth login`
     2. `gcloud config set project digital-ucdavis-edu`
   3. Copy service account to root folder: `gsutil cp gs://website-v3-content/main-website-content-reader-key.json main-website-content-reader-key.json`
6. Create your local docker-compose file by running:
   1. `./cmds/generate-deployment-files.sh`
7. Start an `.env` file in the `local-dev` directory (created in the previous step) and set the following config
  1. `SERVER_ENV`: set to something like `sandbox`, `dev`, `prod`, etc. Specifies what data to pull. Defaults to `sandbox`
  2. `WORDPRESS_DEBUG`: turns on the php debugger. Defaults to `1`(on)
  3. `WORDPRESS_CONFIG_EXTRA`: An opportunity to pass additional values to your wp-config file. To turn on React debugging set this to: `WORDPRESS_CONFIG_EXTRA=define('SCRIPT_DEBUG', true);`
8. Build the `local-dev` tagged images:
   1. `./cmds/build-local-dev.sh`

### Making Changes in Local Development
- Make sure you followed all the steps in the local-dev inital setup section above.
- By default, the site loads the dev public and editor theme bundles, which are created by watch processes. With the watch processes on, any changes you make to the JS/SCSS src will be immediately updated in the bundled site code. To start these up, navigate to `repositories/ucdlib-theme-wp` and run:
  - `cd src/public; npm run watch`
  - `cd src/editor; npm run watch`
- By default, plugins run off their dist JS code. To use the watch process for a plugin, enable it in your `local-dev` env file by adding `UCD_PLUGIN_<PLUGIN_NAME>_ENV=dev` and then start its watch process.
- Bring the site up by starting the docker compose stack:
  - `cd website-local-dev; docker compose up`
- Code directories are mounted as volumes so changes to your host filesystem are reflected in container. However, changes to application packages (ex: package.json) will require rebuild of images (`./cmds/build-local-dev.sh`)

#### Loading a new snapshot
If you need to update your snapshot or use a different one entirely:
1. Drop the existing docker volumes: `docker compose down -v`
2. Make sure your `SERVER_ENV` config is pointing to the bucket you want to use
3. Restart the stack: `docker compose up`
  

## Usage

### Env File
Here are some common parameters:
| Param | Description |
| ----- | ----------- |
| WORDPRESS_DEBUG | Set to `1` to turn wp's php debug mode. Nice for local development. |
| WORDPRESS_CONFIG_EXTRA | Set arbitrary `wp-config` values. `WORDPRESS_CONFIG_EXTRA=define('SCRIPT_DEBUG', true);` will turn on the React debug tool. |
| HOST_PORT | Port where site is hosted. Defaults to `8000` |
| WORDPRESS_DB_DATABASE | Name of mysql database used by site. defaults to `wordpress` |
| WORDPRESS_DB_PASSWORD | Password of mysql database used by site. defaults to `wordpress` |
| WORDPRESS_DB_USER | User of mysql database used by site. defaults to `wordpress` |
| MYSQL_ROOT_PASSWORD | Root password for db. defaults to `wordpress` |
| SERVER_ENV | Directory with snapshot data in Google bucket |

