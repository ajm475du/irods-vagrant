#!/bin/sh

IRODS_HOME=${IRODS_HOME:-/var/lib/irods/iRODS}
IRODS_CLIENT_USER=vagrant
IRODS_CLIENT_HOME=/home/vagrant
JAVA_HOME=$IRODS_CLIENT_HOME/curators-workbench

set -v

DISTRIBUTOR=`lsb_release -is`
if [ "$DISTRIBUTOR" = "Ubuntu" ]
then
    # Includes apache2 in order to host stages.json
    apt-get -q -y install openjdk-7-jre apache2 xdotool
elif [ "$DISTRIBUTOR" = "CentOS" ]
then
    # Let's take this as an indication that we're
    # running in the virtual machine
    # http://www2.lib.unc.edu/software/cdr/cdr-20131111083629.ova
    # first made available November 11, 2013, and
    # last retrieved at this writing, July 14, 2014.
    # It has java: java-1.6.0-openjdk-1.6.0.0-1.42.1.11.14.el5_10.x86_64
    # It has apache2: httpd-2.2.3-83.el5.centos.x86_64
    cd /vagrant
    yum -q -y --nogpgcheck install xdotool-2.20110530.1-1.x86_64.rpm
    cd -
else
    echo Was prepared to run on Ubuntu or CentOS. Detected neither.
fi

if [ ! -e /vagrant/curators-workbench-linux.gtk.x86_64-jre.tar.gz ]
then
    cd /vagrant
    wget -q http://www2.lib.unc.edu/software/workbench/4.1.4/products/curators-workbench-linux.gtk.x86_64-jre.tar.gz
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

