#!/bin/bash

YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
NORMAL=$(tput sgr0)

# list of all variables to be substituted in templates
VARS='$PAVICS_FQDN $DOC_URL $MAGPIE_USER $MAGPIE_PW $MAGPIE_ADMIN_PW $SUPPORT_EMAIL'

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

TIMEWAIT_REUSE=$(/sbin/sysctl -n  net.ipv4.tcp_tw_reuse)
if [[ $TIMEWAIT_REUSE -eq 0 ]]
then
  echo "${YELLOW}Warning:${NORMAL} the sysctl net.ipv4.tcp_tw_reuse is not enabled"
  echo "         It it suggested to set it to 1, otherwise the pavicscrawler may fail"
fi

# we apply all the templates
find . -name '*.template' -print0 | 
  while IFS= read -r -d $'\0' FILE
  do
    DEST=${FILE%.template}
    cat $FILE | envsubst "$VARS" > $DEST
  done

# the PROXY_SECURE_PORT is a little trick to make the compose file invalid without the usage of this wrapper script
PROXY_SECURE_PORT=443 HOSTNAME=$PAVICS_FQDN docker-compose $*
ERR=$?

# execute post-compose function if exists and no error occurred
type post-compose 2>&1 | grep 'post-compose is a function' > /dev/null
if [[ $? -eq 0 ]]
then
  [[ $ERR -gt 0 ]] && { echo "Error occurred with docker-compose, not running post-compose"; exit $?; }
  post-compose $*
fi

# we restart the proxy after an up to make sure nginx continue to work if any container IP address changes
while [[ $# -gt 0 ]]
do
  [[ $1 == "up" ]] && { PROXY_SECURE_PORT=443 HOSTNAME=$PAVICS_FQDN docker-compose restart proxy; }
  shift
done



