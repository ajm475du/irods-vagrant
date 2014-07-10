#!/bin/bash

BRIDGE_INTERFACE=eth0

BREAK_STUFF=false # DON'T set to 'true' (quotes optional) except to break stuff

CDR=cdr-20131111083629
CWB=curators-workbench-linux.gtk.x86_64-jre.tar.gz

if [ ! -e $CDR.ova ]
then
    wget http://www2.lib.unc.edu/software/cdr/$CDR.ova
fi

if [ ! -e $CWB ]
then
    wget http://www2.lib.unc.edu/software/workbench/4.1.5/products/$CWB
fi

if [ "$BREAK_STUFF" = true ]
then
    if [ -n "`VBoxManage list vms | grep $CDR`" ]
    then
        VBoxManage controlvm $CDR poweroff
        VBoxManage unregistervm $CDR --delete
    fi
fi

if [ -n "`VBoxManage list vms | grep $CDR`" ]
then
    echo "vm $CDR already exists!"
    exit 1
fi
  
VBoxManage import $CDR.ova \
  --vsys 0 --memory 2048
VBoxManage modifyvm $CDR --nic1 bridged \
  --bridgeadapter1 $BRIDGE_INTERFACE
VBoxManage startvm $CDR
STATUS=1
until [ "$STATUS" -eq 0 -a "$IP" != "No value set!" ]
do 
    sleep 5
    IP=$(VBoxManage guestproperty get $CDR /VirtualBox/GuestInfo/Net/0/V4/IP)
    STATUS=$?
done

IP=`echo $IP | cut -d ' ' -f 2`

scp $CWB vagrant@$IP:
ssh vagrant@$IP "tar zxf $CWB"
ssh vagrant@$IP 'sudo yum -y install xorg-x11-xauth'
ssh -X vagrant@$IP 'curators-workbench/Workbench &'

