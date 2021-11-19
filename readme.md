# Website Deployment
This repository contains files for deploying the main UC Davis Library website (library.ucdavis.edu) to a server or locally.

## Site Architecture
library.ucdavis.edu is a custom Wordpress installation composed of several services and git repositories:
- Third-party Services
  - Wordpress
  - Wordpress CLI
  - Mysql
  - Elasticsearch
  - Adminer (local development)
- Custom Git Repositories
  - [Primary Theme](https://github.com/UCDavisLibrary/ucdlib-theme-wp)
  - Plugins
    - Hours and Locations
    - Directory+
    - Special Collections

## Local Development

### Initial Setup
1. Clone this repository
   1. `git clone`
2. Checkout the branch you want to work on, e.g.:
   1. `git checkout dev`
3. In the same parent folder in which you performed step 1, clone all git repositories for this deployment. They are defined in config.sh in the Repositories section. IMPORATANT: Make sure you checkout to the branches you wish to work on for each repository.
4. Setup the `./repositories` folder by running `./cmds/init-local-dev.sh`. 
5. Grab service account so the `init` container can access website snapshot bucket
   1. Install `gcloud` cli and `gsutils` if you don't already have it (https://cloud.google.com/storage/docs/gsutil_install)
   2. Login and set project id
     1. `gcloud auth login`
     2. `gcloud config set project digital-ucdavis-edu`
   3. Copy service account to root folder: `gsutil cp gs://website-v3-content/main-website-content-reader-key.json main-website-content-reader-key.json`
6. Create a `.env` file in `local-dev` and set the following contig
  1. `SERVER_ENV`: set to something like `sandbox`, `dev`, `prod`, etc.  Will controll things like where to fetch snapshot from
  2. TODO: steve

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


