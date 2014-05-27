#!/bin/sh

IRODS_HOME=/var/lib/irods/iRODS
JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
VAGRANT_USER=vagrant
VAGRANT_USER_HOME=/home/vagrant

set -v

apt-get -q -y install openjdk-7-jre apache2 xdotool
keytool -noprompt -importcert -keystore $JAVA_HOME/jre/lib/security/cacerts -file $IRODS_HOME/server/config/chain.pem -trustcacerts -alias 'debian:rack54.cs.pem' -storepass changeit

if [ ! -e /vagrant/curators-workbench-linux.gtk.x86_64-jre.tar.gz ]
then
    chown ${VAGRANT_USER}:${VAGRANT_USER} ${VAGRANT_USER_HOME}/curators-workbench-linux.gtk.x86_64-jre.tar.gz
    cd /vagrant
    wget http://www2.lib.unc.edu/software/workbench/4.1.5/products/curators-workbench-linux.gtk.x86_64-jre.tar.gz
    cd -
fi
su -c 'tar zxvf /vagrant/curators-workbench-linux.gtk.x86_64-jre.tar.gz' - ${VAGRANT_USER}

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

