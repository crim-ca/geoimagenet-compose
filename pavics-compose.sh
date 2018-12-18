#!/bin/bash

YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
NORMAL=$(tput sgr0)

# list of all variables to be substituted in templates

VARS='
  $USING_PAVICS_COMPOSE
  $HOST_FQDN
  $POSTGIS_DB
  $POSTGIS_USER
  $POSTGIS_PASSWORD
  $SSL_CERTIFICATE
  $SSL_PRIVATE_KEY
'

# we switch to the real directory of the script, so it still works when used from $PATH
# tip: ln -s /path/to/pavics-compose.sh ~/bin/
cd $(dirname $(readlink -f $0 || realpath $0))

# we source local configs, if present
# we don't use usual .env filename, because docker-compose uses it
[[ -f env.local ]] && source env.local

for i in $VARS
do
  v="${i#$}"
  if [[ -z "${!v}" ]]
  then
    echo "${RED}Error${NORMAL}: Required variable $v is not set. Check env.local file."
    exit
  fi
done

if [[ ! -f docker-compose.yml ]]
then
  echo "Error, this script must be ran from the folder containing the docker-compose.yml file"
  exit 1
fi

## check fails when root access is required to access this file.. workaround possible by going through docker daemon... but
# will add delay
# if [[ ! -f $SSL_CERTIFICATE ]]
# then
#   echo "Error, SSL certificate file $SSL_CERTIFICATE is missing"
#   exit 1
# fi

# we apply all the templates
find . -name '*.template' -print0 | 
  while IFS= read -r -d $'\0' FILE
  do
    DEST=${FILE%.template}
    cat $FILE | envsubst "$VARS" > $DEST
  done

docker-compose $*



