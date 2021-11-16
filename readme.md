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

