#!/bin/sh

IRODS_HOME=/var/lib/irods/iRODS
IRODS_CLIENT_USER=vagrant
IRODS_CLIENT_HOME=/home/vagrant
JAVA_HOME=$IRODS_CLIENT_HOME/curators-workbench

set -v

apt-get -q -y install openjdk-7-jre apache2 xdotool

if [ ! -e /vagrant/curators-workbench-linux.gtk.x86_64-jre.tar.gz ]
then
    cd /vagrant
    wget -q http://www2.lib.unc.edu/software/workbench/4.1.5/products/curators-workbench-linux.gtk.x86_64-jre.tar.gz
    cd -
fi
su -c 'tar zxf /vagrant/curators-workbench-linux.gtk.x86_64-jre.tar.gz' - ${IRODS_CLIENT_USER}

keytool -noprompt -importcert -keystore $JAVA_HOME/jre/lib/security/cacerts -file $IRODS_HOME/server/config/chain.pem -trustcacerts -alias 'debian:rack54.cs.pem' -storepass changeit

mkdir -p /var/www/html/static
cat <<END_Y > /var/www/html/static/stages.json
{
    "irods://newuser@localhost:1247/tempZone/home/newuser/staging/":{
        "name": "Shared iRODS Staging Area",
        "ingestCleanupPolicy": "DELETE_INGESTED_FILES"
    },
    "tag:mansheim.com,2014:/some_music/":{
        "name": "Repository of some music",
        "mappings":[
            "file:/mnt/repository/"
        ],
        "confirmFile":".tag_some_music",
        "ingestCleanupPolicy":"DO_NOTHING"
    }
}

END_Y

