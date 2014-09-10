#!/bin/bash

# Aaron Mansheim, Drexel University, 2014

cd `dirname $0`
DIR=`pwd`

VAGRANT_HOME=/home/vagrant/
PROJECT_DIR=$VAGRANT_HOME/originals/SixtyFun/_0/home/ajm475/Music/
OP_67_MVT_1=IMSLP298641-PMLP01586-LvBeethoven_Symphony_No.5_mvt1.ogg
OP_67_MVT_1_DEST=$PROJECT_DIR/$OP_67_MVT_1
VAGRANT_DIR=/vagrant/
OP_67_MVT_1_SRC=$VAGRANT_DIR/$OP_67_MVT_1

INGEST_UUID=uuid:a53e2d9f-3ded-4891-b31a-40e5e74d95ea

cd $VAGRANT_HOME

mkdir -p $PROJECT_DIR
chown vagrant:vagrant $PROJECT_DIR
cp $OP_67_MVT_1_SRC $OP_67_MVT_1_DEST
chown vagrant:vagrant $OP_67_MVT_1_DEST

curl --insecure https://localhost/spoof/index.jsp \
    --data 'submit=Set%20Spoofed%20Values' --data 'REMOTE_USER=Administrator' \
    --data 'memberships=unc:app:lib:cdr:admin' \
    --data 'memberships=unc:app:lib:cdr:adminltd' \
    --cookie-jar cookie-jar
cp cookie-jar cookie-jar~
curl --insecure https://localhost/admin/ingest/$INGEST_UUID \
    --cookie cookie-jar~ --cookie-jar cookie-jar \
    --form 'file=@/vagrant/SixtyFun.cdr.xml;filename=SixtyFun.cdr.xml' \
    --form 'type=http://cdr.unc.edu/METS/profiles/Simple'
cp cookie-jar cookie-jar~
curl --insecure https://localhost/admin/list/$INGEST_UUID \
    --cookie cookie-jar~ --cookie-jar cookie-jar
rm cookie-jar~ cookie-jar

