#!/usr/bin/env bash

# script to be employed with 'postgis_backups' to run annotation flush on the cron job instead of backups
# override /backup.sh with this file in the docker container
# to change cron interval, override file /backups-cron with desired configuration
#
# see for reference: https://github.com/kartoza/docker-pg-backup/blob/master/backups.sh

source /pgenv.sh
source /env_ext.sh

TABLE_NAME=public.annotation
CHECK_HOST=geoimagenet.ca

# Start by backuping the db, then flush its content
/backups.sh

if [[ "${HOSTNAME}" = "${CHECK_HOST}" ]]; then
    echo "Flush running in ${PGDATABASE} for ${TABLE_NAME}" >> /var/log/cron.log
    psql -U ${PGUSER} -d ${PGDATABASE} -c "TRUNCATE TABLE ${TABLE_NAME} CASCADE;"
else
    echo "WARNING! Flush was requested, but HOSTNAME (${HOSTNAME}) != '${CHECK_HOST}'" >> /var/log/cron.log
fi
