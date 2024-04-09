# GeoImageNet Compose

## General information

To run docker-compose for GeoImageNet, the `geoimagenet-compose.sh` wrapper script must be used.
This script will source the `env.local` file, apply the appropriate variable substitutions on all the template configuration files (ending with `.template`), and run docker-compose with all the command line arguments given to `geoimagenet-compose.sh`. See `env.local.example` for more details on the configuration values.

If you need to locally override the configuration of a specific service or container, you can add a `docker-compose.override.yml` file within this folder.


## Installation

### Local development

When developing locally, use the following:

- generate a self-signed certificate : `openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes`
- add the path of the generated `key.pem` and `cert.pem` files in `env.local` (as `SSL_CERTIFICATE` and `SSL_PRIVATE_KEY` respectively)
- in the `env.local` file, adjust the `HOST_FQDN` variable depending of your setup (ex.: using Vagrant, use the IP address defined in your Vagrantfile)
- set these 2 configuration lines in twitcher.ini.template file since we're using a self-signed certificate :
```
    twitcher.ssl_verify = false
    twitcher.ows_proxy_ssl_verify = false
```
- set the following configuration in docker-compose.override.yml:

```
version: "3"
services:
  api:
    environment:
      - GEOIMAGENET_API_ALLOW_CORS=true
      - GEOIMAGENET_API_MAGPIE_VERIFY_SSL=false
  geoserver:
    ports:
      - 8600:8080
  postgis:
    ports:
      - "5432:5432"
    environment:
      - ALLOW_IP_RANGE=0.0.0.0/0
```

- when you want to connect geoserver, use the url http://{your-ip}:8600/geoserver to bypass twitcher (the default username and password are `admin` and `geoserver`).


### One time commands before first launch

Make sure to configure `env.local` for your environment (see `env.local.example` for more details)

If you get an error similar to this one: 

```
ERROR: for geoserver_setup  Cannot start service geoserver_setup: error while mounting volume '/var/lib/docker/volumes/geoimagenet_compose_image_data/_data': failed to mount local volume: mount /nas:/var/lib/docker/volumes/geoimagenet_compose_image_data/_data, flags: 0x1000: no such file or directory
```

Make sure all docker bind volumes exist locally before running `up`. The following command will create all the directories for the default configuration:

```
sudo mkdir -p /nas /data/ml/models /data/ml/jobs /data/ml/datasets /data/db_gis_data /data/mongodb_backups /data/mongodb_persist /data/geoserver/data_dir /data/postgis_backups
```

When installing on a new server, the postgis database needs to be initialized.
For the annotations database, run the following command:

```
./geoimagenet-compose.sh run --rm migrations upgrade head
```

and for magpie:

```
./geoimagenet-compose.sh run --rm magpie gunicorn -b 0.0.0.0:2001 --paste config/magpie.ini --workers 1
```

The magpie container should print out information about database migrations and creating permissions.
Once you see the following message, it's ok to stop the container: 

```
[MainThread][magpie.app] Starting Magpie app...
```


## Starting the platform

To launch all the containers, use the following command:

```
./geoimagenet-compose.sh up -d
```

Note: The frontend for the platform has to perform a Webpack build at startup, so a 2-3 minutes wait time is normal before the container is responsive.

## Versioning

We use bump2version: `pip install bump2version`. Bump version using `make VERSION=<target_tag> bump`.

## Known potential bugs

PostGIS can sometimes stop working correctly. The cause is not clear, but it often happens when it's image is pulled 
unnecessarily.Therefore, you should always pull the specific images you intend to pull when updating a specific component. 

Ex:

```
# Bad
./geoimagenet-compose.s pull

# Good
./geoimagenet-compose.s pull ml frontend
```

When this bug does manifest, the images and annotations will no longer be visible on the platform.

You will also find the following message in the PostGIS logs:

`(psycopg2.errors.UndefinedFile) could not access file "$libdir/postgis-2.5": No such file or directory`

The following workaround will help you get the platform operational again : 

```
# Make sure PostGIS and magpie backups exists. This information will be in the docker-compose.yml, or overwritten in the
# docker-compose-override.yml. The following instruction take the default locations into account.
 
# Take down the platform
./geoimagenet-compose.sh down
 
# Erase the current PostGIS data volume's content
sudo rm -rf /data/db_gis_data/*
 
# Erase the PostGIS image
docker rmi kartoza/postgis:9.6-2.4
 
# Initialize the PostGIS image and re-start the platform
./geoimagenet-compose.sh run --rm migrations upgrade head
./geoimagenet-compose.sh up -d
 
# Restore the PostGIS backups. These include the Magpie database that contains user information.
# If there's an error message when restoring the gis DB, you can ignore it if it's about not being able
# to remove the PostGIS extension.

# ***Don't forget to change the first part of each command for the appropriate backup file***
cat /data/postgis_backups/2020/May/geoimagenet_magpie.07-May-2020.dmp | docker exec -i postgis sh -c "PGPASSWORD=docker pg_restore -h localhost -U docker -d magpie -c"
cat /data/postgis_backups/2020/May/geoimagenet_gis.07-May-2020.dmp | docker exec -i postgis sh -c "PGPASSWORD=docker pg_restore -h localhost -U docker -d gis -c"
```
