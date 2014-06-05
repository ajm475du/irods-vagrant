#!/bin/bash -x

IRODS_HOME=/var/lib/irods/iRODS
IRODS_USER=irods
IRODS_USER_HOME=/var/lib/irods
IRODS_CLIENT_USER=vagrant
IRODS_CLIENT_HOME=/home/vagrant

NEWUSER_PASSWORD=4MPAcwJeQ2Sg

set -v

cat $IRODS_USER_HOME/.bashrc >> $IRODS_CLIENT_HOME/.bashrc
mkdir -p $IRODS_CLIENT_HOME/.ssh
chown -R $IRODS_CLIENT_USER:$IRODS_CLIENT_USER $IRODS_CLIENT_HOME/.ssh
chmod 700 $IRODS_CLIENT_HOME/.ssh

su -c 'iadmin mkuser newuser rodsuser' - $IRODS_USER
useradd -M newuser -s /bin/false # no home dir, no shell
echo "newuser:${NEWUSER_PASSWORD}" | chpasswd

cat <<EOT > $IRODS_HOME/server/config/req.conf
[ req ]
distinguished_name=req_distinguished_name
prompt=no

[ req_distinguished_name ]
countryName=US
stateOrProvinceName=Pennsylvania
localityName=Philadelphia
organizationName=Drexel University
organizationalUnitName=AIG
commonName=rack54.cs.drexel.edu
emailAddress=ajm475@drexel.edu

EOT

chown ${IRODS_USER}:${IRODS_USER} $IRODS_HOME/server/config/req.conf

su -c 'openssl genrsa -out server.key 2>&1 | tr -d ".+"' - ${IRODS_USER}
su -c "openssl req -config $IRODS_HOME/server/config/req.conf -new -x509 -key server.key -out server.crt -days 365" - ${IRODS_USER}

su -c 'cp server.crt chain.pem' - ${IRODS_USER}
su -c 'openssl dhparam -2 -out dhparams.pem 2048 2>&1 | tr -d ".+"' - ${IRODS_USER}
su -c "cp server.key chain.pem dhparams.pem $IRODS_HOME/server/config" - ${IRODS_USER}

sed -i -e '12aexport irodsSSLDHParamsFile' $IRODS_HOME/irodsctl
sed -i -e '12airodsSSLDHParamsFile=$IRODS_HOME/server/config/dhparams.pem' $IRODS_HOME/irodsctl
sed -i -e '12aexport irodsSSLCertificateKeyFile' $IRODS_HOME/irodsctl
sed -i -e '12airodsSSLCertificateKeyFile=$IRODS_HOME/server/config/server.key' $IRODS_HOME/irodsctl
sed -i -e '12aexport irodsSSLCertificateChainFile' $IRODS_HOME/irodsctl
sed -i -e '12airodsSSLCertificateChainFile=$IRODS_HOME/server/config/chain.pem' $IRODS_HOME/irodsctl
su -c './iRODS/irodsctl restart' - ${IRODS_USER}

cp -r $IRODS_USER_HOME/.irods $IRODS_CLIENT_HOME
chown -R $IRODS_CLIENT_USER:$IRODS_CLIENT_USER $IRODS_CLIENT_HOME/.irods
sed -i -e "s/rods'/newuser'/" $IRODS_CLIENT_HOME/.irods/.irodsEnv

cat <<EOT > $IRODS_CLIENT_HOME/iinit.sh
#!/bin/sh
irodsSSLCACertificateFile=$IRODS_HOME/server/config/chain.pem
irodsSSLVerifyServer=cert # leniency
irodsAuthScheme=PAM
export irodsSSLCACertificateFile irodsSSLVerifyServer irodsAuthScheme
echo "${NEWUSER_PASSWORD}" | iinit
EOT

chown ${IRODS_CLIENT_USER}:${IRODS_CLIENT_USER} $IRODS_CLIENT_HOME/iinit.sh
chmod u+x $IRODS_CLIENT_HOME/iinit.sh

su -c "$IRODS_CLIENT_HOME/iinit.sh" - ${IRODS_CLIENT_USER}
su -c 'imkdir staging' - ${IRODS_CLIENT_USER}
