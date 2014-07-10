#!/bin/bash



ERASE_EXISTING=false # DESTRUCTIVE when set to "true"! (quotes are optional)
TRUST_EXISTING=true



BASEURL=http://www2.lib.unc.edu/software

CDR=cdr-20131111083629
CDR_FILE=$CDR.ova
CDR_BASEURL=$BASEURL/cdr

CWB_FILE=curators-workbench-linux.gtk.x86_64-jre.tar.gz
CWB_VN=4.1.5
CWB_BASEURL=$BASEURL/workbench/$CWB_VN/products

unset BASEURL CWB_VN



HOSTONLYIF=vboxnet0
HOSTONLY_SUBNET=192.168.56
DHCPSERVER=HostInterfaceNetworking-$HOSTONLYIF



if [ ! -e $CDR_FILE ]
then
    wget $CDR_BASEURL/$CDR_FILE
fi

if [ ! -e $CWB_FILE ]
then
    wget $CWB_BASEURL/$CWB_FILE
fi

unset CDR_BASEURL CWB_BASEURL



if [ "$ERASE_EXISTING" = true ]
then
    if [ -n "`VBoxManage list vms | grep $CDR`" ]
    then
        VBoxManage controlvm $CDR poweroff
        VBoxManage unregistervm $CDR --delete
    fi
    
    if [ -n "`VBoxManage list dhcpservers | grep $DHCPSERVER`" ]
    then
        VBoxManage dhcpserver remove --ifname $HOSTONLYIF
    fi
    
    if [ -n "`VBoxManage list hostonlyifs | grep $HOSTONLYIF`" ]
    then
        VBoxManage hostonlyif remove $HOSTONLYIF
    fi
fi



VM=`VBoxManage list vms | grep $CDR`
IF=`VBoxManage list hostonlyifs | grep $HOSTONLYIF`
DHCP=`VBoxManage list dhcpservers | grep $DHCPSERVER`
if [ -z "$VM" -o -z "$IF" -o -z "$DHCP" ]
then
    if [ -z "$VM" ]
    then
        VBoxManage import $CDR_FILE --vsys 0 --memory 2048
        GULLIBLE=false
    else
        GULLIBLE=true
    fi
    
    if [ -z "$IF" ]
    then
        VBoxManage hostonlyif create
        VBoxManage hostonlyif ipconfig $HOSTONLYIF --ip $HOSTONLY_SUBNET.1
    fi
    
    if [ -z "$DHCP" ]
    then
        VBoxManage dhcpserver add --ifname $HOSTONLYIF \
                --ip $HOSTONLY_SUBNET.100 \
                --netmask 255.255.255.0 \
                --lowerip $HOSTONLY_SUBNET.101 \
                --upperip $HOSTONLY_SUBNET.255 \
                --enable
    fi
elif [ "$TRUST_EXISTING" = true ]
then
    GULLIBLE=true
else
    echo "vm $CDR already exists!"
    exit 1
fi
unset VM IF DHCP TRUST_EXISTING

VBoxManage modifyvm $CDR --nic1 hostonly --hostonlyadapter1 $HOSTONLYIF \
        --nic2 nat
VBoxManage startvm $CDR

echo Waiting for VM "\"$CDR\"" to report its IP number...
STATUS=1
until [ "$STATUS" -eq 0 -a "$IP" != "No value set!" ]
do 
    sleep 5
    IP=$(VBoxManage guestproperty get $CDR /VirtualBox/GuestInfo/Net/0/V4/IP)
    STATUS=$?
done
unset STATUS
IP=`echo $IP | cut -d ' ' -f 2`

echo VM "\"$CDR\"" has IP number $IP.

if [ "$GULLIBLE" != true ]
then
    VBoxManage guestcontrol $CDR copyto `pwd`/$CWB_FILE /home/vagrant/$CWB_FILE \
            --username vagrant --password vagrant
    VBoxManage guestcontrol $CDR exec --image /bin/tar \
            --username vagrant --password vagrant --wait-stderr \
            -- -C /home/vagrant -zxf /home/vagrant/$CWB_FILE
    VBoxManage guestcontrol $CDR exec --image /usr/bin/sudo \
            --username vagrant --password vagrant --wait-stdout \
            -- yum -y install xorg-x11-xauth
fi

echo
echo The password is not a secret. Please type: vagrant
ssh -X vagrant@$IP 'nohup curators-workbench/Workbench 2>&1 >/dev/null &'

