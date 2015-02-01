#!/bin/bash

chef_binary=/usr/bin/chef-solo

# Are we on a vanilla system?
if ! test -f "$chef_binary"; then
    export DEBIAN_FRONTEND=noninteractive
    # Upgrade headlessly (this is only safe-ish on vanilla systems)
    apt-get update &&
    apt-get -o Dpkg::Options::="--force-confnew" \
        --force-yes -fuy dist-upgrade &&
    # Install chef
    apt-get install -y chef
fi

export USER=$1
export PASSWORD=$2
export CERTIFICATE_NAME=$3
export MONTHLY_BANDWIDTH=$4

"$chef_binary" -c solo.rb -j solo.json