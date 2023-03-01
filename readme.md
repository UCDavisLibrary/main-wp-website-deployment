# Website Deployment
This repository contains files for deploying the main UC Davis Library website
(library.ucdavis.edu) to a server or locally.

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
- Build your local dev images by running:
  - `./cmds/build-local-dev.sh`

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

## Production Deployment

The production deployment depends on multiple VMs and docker constellations,
controlled with docker-compose files.  An [Overview
Diagram](https://docs.google.com/drawings/d/1nw_3TyurSa4UEb4Z_4ah-3_XTW7Po3O8c-WtRltKBRg/edit?usp=sharing)
gives a general description of the deployment setup.  All traffic to the website
is directed to an apache instance that acts as a routing service to the
underlying backend service.  The router does some coarse scale redirection;
maintains the SSL certificates, but mostly monitors which of two potential
backend services are currently operational. It does this by monitoring specific
ports from two VMs gold.library.ucdavis.edu and blue.library.ucdavis.edu.  For
the production server, we monitor port 80.  Note blue and gold are only
available within the libraries staff VPN.  The router
(router.library.ucdavis.edu) will dynamically switch between the backends based
on which is currently operational.  If both are operational, it will switch
between them, if neither, it will throw a 400 error.

| machine | specs |
| --- | --- |
| blue.library.ucdavis.edu | 8Gb, 250Gb, 8cpu |
| gold.library.ucdavis.edu | 8Gb, 250Gb, 8cpu |
| router.library.ucdavis.edu | 4Gb, 25Gb, 8cpu |

On a typical redeployment of the system, you should never need to worry about
the router configuration. Detailed configuration information is included in
[#16](https://github.com/UCDavisLibrary/main-wp-website-deployment/issues/16).
However, you are often very interested in what backend server is operational.

The router manages this by including a routing indicator in the clients cookies.
The example below shows that the ROUTEID is set to `v3.gold` where `v3` is the
major website version, and `gold` is the backend server.

```bash
curl -I https://library.ucdavis.edu
```

```txt
HTTP/1.1 200 OK
Cache-Control: max-age=0
Connection: Keep-Alive
Content-Encoding: gzip
Content-Length: 11954
Content-Type: text/html; charset=UTF-8
Date: Fri, 19 Aug 2022 18:50:52 GMT
Expires: Fri, 19 Aug 2022 18:50:52 GMT
Keep-Alive: timeout=5, max=100
Link: <https://library.ucdavis.edu/wp-json/>; rel="https://api.w.org/"
Link: <https://library.ucdavis.edu/wp-json/wp/v2/pages/111>; rel="alternate"; type="application/json"
Link: <https://library.ucdavis.edu/>; rel=shortlink
Server: Apache/2.4.54 (Debian)
Set-Cookie: ROUTEID=v3.gold; path=/
Vary: Accept-Encoding
X-Powered-By: PHP/7.4.30
```

The router will try and maintain the same connection with the backend if
possible, but if not it will reset this cookie, and switch to whatever backend
is working.

In our setup, there should never be two instances working, except for the few
minutes where a redeployment is in progress.  The general setup is relatively
straightforward.  The only major consideration, is that while you are preparing
your system, you need to make sure that you are *not* using the deployment port
(80), otherwise the router will include your setup prematurely.

The general steps are:
- disable editing on the current server (Not yet specified)
- backup the server
- Initialize new service
- - Updated images on new backend
- - Restore the backup you just made unto this new backend
- - Reindex your site.
- - bring the new backend wordpress down
- - Update the port
- - bring the new backend wordpress up
- Retire current service
- - Verify that both instances are working properly
- - stop the old instance
- renable editing on the new server (Not yet specified) 

Here are the steps to deploy to blue and gold. Each new deployment should target
the non-running instance, alternating between blue and gold.

### Deployment Steps

#### Updating Code and Images
Before deploying, we need to make sure we have the updated code ready to go and accessible by blue/gold.

First, the relevant submodules should be updated and tagged. For `ucdlib-wp-plugins` and/or `ucdlib-theme-wp`:
```bash
git checkout main
git merge stage --ff-only
git push
git tag v3.x.y
git push origin --tags
```

Next, the same sort of thing needs to happen on the primary repo `main-wp-website`
```bash
git checkout main
git merge stage --ff-only
git push
```
Go to github and verify you have the correct submodule hashes, and then:
```bash
git tag v3.x.y
git push origin --tags
```

Head on over to the deployment repo: `main-wp-website-deployment`
```bash
git checkout main
git merge stage
```

Update the version numbers in `config.sh` and run `./cmds/generate-deployment-files`. Finish merging, commit and tag.
```bash
git add --all
git commit
git push
git tag v3.x.y
git push origin --tags
```

Build your images with `./cmds/submit.sh`. You will get a slack update in `os-gcb-notifications` - verify the `TAG_NAME` property is what you expect.

#### Identify server
Since we switch between blue and gold servers, you are never really sure which
is in production, so you have to check the ROUTEID cookie with `curl -I https://library.ucdavis.edu`.

Fill in the following instructions with this value:

```bash
cur=gold # or blue
case $cur in "gold") new="blue";; "blue") new="gold";; *) new="BAD"; esac
curtag=v3.x.y
newtag=v3.x.y

alias dc=docker-compose # or 'docker compose' 
```

#### Disable editing

This is still TBD. One idea is to install the freeze plugin, and the
enable/disable it via the wp config file as in:

```bash
dc exec wordpress wp config set FREEZE_OFF false --raw
```
One problem with that solution is that it seems to turn off the API, although my
review of the software seems to indicate that shouldn't be the case.


#### Backup current system

Backing up the current system verifies that we have the latest possible changes
on the system.

```bash
d=/etc/library-website/${curtag};
ssh ${cur}.library.ucdavis.edu \{ cd $d\; ${dc} exec backup /util-cmds/backup.sh\; \}
```

#### Initialize new service

First, initialize your new service.  This example shows where you are simply
updating the production images, but the steps are required for any changes.
These commands simply drop any previous data, and get the latest required
versions.

```bash
  ssh ${new}.library.ucdavis.edu
  cd /etc/library-website
  cp -R ${curtag} ${newtag}/
  cd ${curtag}
  dc down -v 
  cd ../${newtag}
  git pull 
  git checkout ${newtag}
  dc pull
```

If you run into an error when pulling the images, one of the following might be your issue:
- docker is not authorized to pull images: `gcloud auth configure-docker`
- you are not logged into gcloud: `gcloud auth login`
- you have the wrong project set: `gcloud config set project digital-ucdavis-edu`

The first time bringing docker up and indexing, the port should be something
other than `80`. In `/etc/library-website/v3/.env`, modify `HOST_PORT` to be
something like `3003`.  This is also where you would set your system up so that
it's pulling the data you need. More than likely, this is the backup you just
performed.

```bash
dc up -d
```

You can follow along and monitor the logs to see that the initialization script worked
properly. 

The indexer can sometimes fail and exit on the first run, as the mysql database
is not ready in time.  If the indexer crashes, restart it with `docker compose
start indexer`

You can also explicitly get a reindex with: 

```bash
dc exec wordpress curl http://indexer:3000/reindex
```

Once the indexer finishes completely, you can make the new server discoverable
by the router by updating the `HOST_PORT=80` and creating an new wordpress
container.  Restarting the container doesn't acknowledge the change.

```bash
dc -rm -f -s wordpress;
dc up -d wordpress
```

### Retire current service

At this point, you can vist the production pages, and verify that both backends
are running.  This is okay, since you cannot write to the current server.  Once
you have convinced yourself that things look good, you can stop (but don't bring
down) the cur (now old) server.  You stop it, so if there is a big problem, you
can 

```bash
ssh ${cur}.library.ucdavis.edu
cd /etc/library-website/v3
dc stop
```

### New Backup

Backing up the new system fust verifies that we have the latest possible changes
on our new backup schedule

```bash
d=/etc/library-website/v3;
ssh ${new}.library.ucdavis.edu \{ cd $d\; ${dc} exec backup /util-cmds/backup.sh\; \}
```


### Enable editing

This is still TBD. 


