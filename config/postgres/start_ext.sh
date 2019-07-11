#!/bin/bash

echo "
export HOSTNAME=${HOSTNAME}
" >> /env_ext.sh

/start.sh
