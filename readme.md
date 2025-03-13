# Website Deployment
This repository contains files for deploying the main UC Davis Library website
(library.ucdavis.edu) to a server or locally.

## Local Development

### Initial Setup
Take the following steps to set up your local environment for the first time:
- Create a directory that will contain all of the repositories used by this project, and then git clone those repos:
  - This repository: [main-wp-website-deployment](https://github.com/UCDavisLibrary/main-wp-website-deployment)
  - The wordpress src code along with custom utilities: [main-wp-website](https://github.com/UCDavisLibrary/main-wp-website)
  - Custom plugins: [ucdlib-wp-plugins](https://github.com/UCDavisLibrary/ucdlib-wp-plugins)
  - Our custom theme: [ucdlib-theme-wp](https://github.com/UCDavisLibrary/ucdlib-theme-wp)
- Checkout the branch you want to work on for each repository
- Ensure you have `gcloud` cli.
  - If not, [install it](https://cloud.google.com/storage/docs/gsutil_install)
  - Login and set project id
    - `gcloud auth login`
    - `gcloud config set project digital-ucdavis-edu`
- `cd` into the deployment repo, and run the initialization script with `./cmds/init-local-dev.sh`
- Review the `env` file downloaded to `./compose/main-website-local-dev`, and delete all non-local dev configurations (a single env file is used for all deployments)
- OPTIONAL: If you need to use the backup utility (you probably won't), you will need a GC service account key that has WRITE privileges. Run `./cmds/get-gc-writer-key.sh`
- Build your local dev images by running:
  - `./cmds/build-local-dev.sh <version>` where `version` is a [registered build from cork-build-registry](https://github.com/ucd-library/cork-build-registry/blob/main/repositories/main-wp-website.json).

Your development environment should now have all the necessary pieces in place. The next section goes over how to start everything up.

### Making Changes in Local Development
- Make sure you followed all the steps in the local-dev inital setup section above.
- By default, the site loads the dev public and editor js bundles, which are created by two watch processes in the `ucdlib-assets` plugin. With the watch processes on, any changes you make to the JS/SCSS src will be immediately updated in the bundled site code. To start these up, navigate to `./main-wp-website/ucdlib-wp-plugins/ucdlib-assets` and run:
  - `cd src/public; npm run watch`
  - `cd src/editor; npm run watch`
- Bring the site up by starting the docker compose stack:
  - `cd main-wp-website-deployment/compose/main-website-local-dev; docker compose up`
- Code directories are mounted as volumes so changes to your host filesystem are reflected in container.
- If starting fresh, the most recent data will automatically be downloaded from the `DATA_ENV` environment. This will take a while, you can monitor the script by running `docker compose logs init -f`
  - If not starting fresh, and you want the most recent data, make sure your `DATA_ENV` config is pointing to the environment currently being run by production, and drop your volume with `docker compose down -v`
  - After it is done, you will likely need to restart the es indexer with `docker compose
start indexer`

## Production Deployment

### Server Environment

The production deployment depends on multiple VMs and docker compose clusters.  An [Overview
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


### Deployment Steps

#### Build Production Images
If you made any changes to the following repositories, you will need to check in and tag your code and update the appropriate registry files:
| Repository | Registry File | 
| ---------- | -------- |
| [main-wp-website](https://github.com/UCDavisLibrary/main-wp-website) | [main-wp-website.json](https://github.com/ucd-library/cork-build-registry/blob/main/repositories/main-wp-website.json) |
| [ucdlib-wp-plugins](https://github.com/UCDavisLibrary/ucdlib-wp-plugins) | [ucdlib-wp-plugins.json](https://github.com/ucd-library/cork-build-registry/blob/main/repositories/ucdlib-wp-plugins.json) |
| [ucdlib-theme-wp](https://github.com/UCDavisLibrary/ucdlib-theme-wp) | [ucdlib-theme-wp.json](https://github.com/ucd-library/cork-build-registry/blob/main/repositories/ucdlib-theme-wp.json) |

Then run `cmds/build.sh <main-wp-website version>`

#### Identify server
Since we switch between blue and gold servers, you are never really sure which
is in production, so you have to check the ROUTEID cookie with `curl -I https://library.ucdavis.edu`.

#### Backup current system

Even though backups should run nightly, manually backing up the current system verifies that we have the latest possible changes on the system.

```bash
ssh $blue_or_gold.library.ucdavis.edu
cd /etc/library-website/main-wp-website-deployment/compose/main-website-prod;
docker compose exec backup /util-cmds/backup.sh
```

#### Download new service images

```bash
# connect to new server
ssh $blue_or_gold.library.ucdavis.edu
cd /etc/library-website/main-wp-website-deployment/compose/main-website-prod;

# drop previous deployment volume
docker compose down -v

# get any changes to deployment files
git pull

# download images
docker compose pull
```

If you run into an error when pulling the images, one of the following might be your issue:
- docker is not authorized to pull images: `gcloud auth configure-docker us-west1-docker.pkg.dev`
- you are not logged into gcloud: `gcloud auth login`
- you have the wrong project set: `gcloud config set project digital-ucdavis-edu`

#### Load data in volume

The first time bringing docker up and indexing, the port must be something
other than `80`, otherwise you will have problems with the data load. In the env file, modify `HOST_PORT` to an inactive port.

Next, bring up the containers with `docker compose up -d`

You can follow along and monitor the logs to see that the initialization script worked
properly with `docker compose logs init -f`

For good measure, ensure the indexer has the most recent data with `docker compose wordpress curl http://indexer:3000/reindex`. You can follow along with `docker compose logs indexer -f`. You can consider it done when it starts logging that it is reporting its metrics to Google Cloud.

Once the indexer finishes completely, 
- Take down the cluser with `docker compose down`
- Update `HOST_PORT=80` in env file
- Bring the cluster back up with `docker compose up -d`

#### Test New Service
You will now have both instances running. To make sure that your new instance is functional,
- delete the `ROUTEID` cookie for the site in your browser.
- reload the page
- verify that the new `ROUTEID` cookie matches the new server environment (`blue` or `gold`)
Repeat the previous steps until you are connected to the new server.

If something is seriously wrong, you can quickly abort the deployment with `docker compose down`

Once you are connected to the new server, perform the following steps:
- Clear the page cache. `Hummingbird Pro -> Caching -> Clear Cache`

#### Retire current service
Only one server should be running for any prolonged period of time since page edits are localized to the server's database. 

Run `docker compose down` on the old server. The volume will be dropped in the next deployment.
