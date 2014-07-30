#!/bin/bash



ERASE_EXISTING=true # DESTRUCTIVE when set to "true"! (quotes are optional)
TRUST_EXISTING=true



BASEURL=http://www2.lib.unc.edu/software

CDR=cdr-20131111083629
CDR_FILE=$CDR.ova
CDR_BASEURL=$BASEURL/cdr

CWB_FILE=curators-workbench-linux.gtk.x86_64-jre.tar.gz
CWB_VN=4.1.5
CWB_BASEURL=$BASEURL/workbench/$CWB_VN/products

XDO_FILE=xdotool-2.20110530.1-1.x86_64.rpm

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
    # Enable X11 tunneling via ssh -Y
    VBoxManage guestcontrol $CDR exec --image /usr/bin/sudo \
            --username vagrant --password vagrant --wait-stdout \
            -- yum -y install xorg-x11-xauth

    # Set up Curator's Workbench
    VBoxManage guestcontrol $CDR copyto `pwd`/$CWB_FILE /home/vagrant/$CWB_FILE \
            --username vagrant --password vagrant
    VBoxManage guestcontrol $CDR exec --image /bin/tar \
            --username vagrant --password vagrant --wait-stderr \
            -- -C /home/vagrant -zxf /home/vagrant/$CWB_FILE

    # Set up automated test of Curator's Workbench GUI
    VBoxManage guestcontrol $CDR createdir /home/vagrant/vagrant \
            --username vagrant --password vagrant
    VBoxManage guestcontrol $CDR copyto `pwd`/$XDO_FILE /home/vagrant/vagrant/$XDO_FILE \
            --username vagrant --password vagrant
    VBoxManage guestcontrol $CDR copyto `pwd`/tls.sh /home/vagrant/vagrant/tls.sh \
            --username vagrant --password vagrant
    VBoxManage guestcontrol $CDR copyto `pwd`/cw_in.sh /home/vagrant/vagrant/cw_in.sh \
            --username vagrant --password vagrant
    VBoxManage guestcontrol $CDR copyto `pwd`/cw_run.sh /home/vagrant/cw_run.sh \
            --username vagrant --password vagrant
    VBoxManage guestcontrol $CDR exec --image /usr/bin/sudo \
            --username vagrant --password vagrant --wait-stdout \
            -- mv /home/vagrant/vagrant/tls.sh /vagrant/tls.sh
    VBoxManage guestcontrol $CDR exec --image /usr/bin/sudo \
            --username vagrant --password vagrant --wait-stdout \
            -- mv /home/vagrant/vagrant/cw_in.sh /vagrant/cw_in.sh
    VBoxManage guestcontrol $CDR exec --image /usr/bin/sudo \
            --username vagrant --password vagrant --wait-stdout \
            -- chmod u+x /vagrant/tls.sh
    VBoxManage guestcontrol $CDR exec --image /usr/bin/sudo \
            --username vagrant --password vagrant --wait-stdout \
            -- chmod u+x /vagrant/cw_in.sh
    VBoxManage guestcontrol $CDR exec --image /bin/chmod \
            --username vagrant --password vagrant --wait-stdout \
            -- u+x /home/vagrant/cw_run.sh
    VBoxManage guestcontrol $CDR exec --image /usr/bin/sudo \
            --username vagrant --password vagrant --wait-stdout \
            -- mv /home/vagrant/vagrant/$XDO_FILE /vagrant/$XDO_FILE
fi


ssh -Y -i ~/.vagrant.d/insecure_private_key vagrant@$IP 'sudo su - root -c "cd /vagrant && IRODS_USER=vagrant IRODS_USER_HOME=/home/vagrant IRODS_HOME=/opt/iRODS ./tls.sh"'
ssh -Y -i ~/.vagrant.d/insecure_private_key vagrant@$IP 'sudo su - root -c "cd /vagrant && IRODS_HOME=/opt/iRODS ./cw_in.sh"'
ssh -Y -i ~/.vagrant.d/insecure_private_key vagrant@$IP 'ERASE_EXISTING=true ./cw_run.sh'
