To run docker-compose for GeoImageNet, the geoimagenet-compose.sh wrapper script must be used.
This script will source the env.local file, apply the appropriate variable substitutions on all the configuration files ".template", and run docker-compose with all the command line arguments given to geoimagenet-compose.sh. See env.local.example for more details.

To launch all the containers, use the following command:
./geoimagenet-compose.sh up -d

If you need to locally override the configuration of a specific service or container, you can add a docker-compose.override.yml file within this folder.

If you get a 'No applicable error code, please check error log' error from the WPS processes, please make sure that the WPS databases exists in the
postgres instance. See scripts/create-wps-pgsql-databases.sh.

Some other infos that can help to build a local setup :
- generate a self-signed certificate : openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
- add the path of the generated key.pem and cert.pem files in env.local (SSL_CERTIFICATE and SSL_PRIVATE_KEY)
- in the env.local file, adjust the HOST_FQDN variable depending of your setup (ex.: using Vagrant, use the IP address defined in your Vagrantfile)
- add these 2 lines of codes to the twitcher.ini.template file since we're using a self-signed certificate :
       twitcher.ssl_verify = false
       twitcher.ows_proxy_ssl_verify = false

## Installation
When installing on a new server, the postgis database needs to be initialized.
Run the following command:
./geoimagenet-compose.sh exec api init_database

## Versioning

We use bump2version: `pip install bump2version`. Bump version using `make VERSION=<target_tag> bump`.

