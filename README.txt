To run docker-compose for GeoImageNet, the geoimagenet-compose.sh wrapper script must be used.
This script will source the env.local file, apply the appropriate variable substitutions on all the configuration files ".template", and run docker-compose with all the command line arguments given to geoimagenet-compose.sh. See env.local.example for more details.

To launch all the containers, use the following command:
./geoimagenet-compose.sh up -d

If you need to locally override the configuration of a specific service or container, you can add a docker-compose.override.yml file within this folder.

If you get a 'No applicable error code, please check error log' error from the WPS processes, please make sure that the WPS databases exists in the
postgres instance. See scripts/create-wps-pgsql-databases.sh.

## Installation
When installing on a new server, the postgis database needs to be initialized.
Run the following command:
./geoimagenet-compose.sh exec api init_database