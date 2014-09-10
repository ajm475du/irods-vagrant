#!/bin/bash


ERASE_EXISTING=true # DESTRUCTIVE when set to "true"! (quotes are optional)
TRUST_EXISTING=true


BASEURL=http://www2.lib.unc.edu/software

CDR=cdr-20131111083629
CDR_FILE=$CDR.ova
CDR_BASEURL=$BASEURL/cdr
CDR_SHA256SUM=$(printf '%s%s%s%s%s%s%s%s' \
    b6538682 11f9f056 7ff9f959 2f812138   \
    76149e3c 53ddbc11 750cb796 1a349d23)

SRC_DIR=`pwd`

unset BASEURL


#XDO_FILE=
## GUIs aren't really helping the testing.
# XDO_FILE=xdotool-2.20110530.1-1.x86_64.rpm

#HOSTONLYIF=
## The host-only network is not helping.
#HOSTONLYIF=vboxnet0
#HOSTONLY_SUBNET=192.168.56
#DHCPSERVER=HostInterfaceNetworking-$HOSTONLYIF


copyfilein () {
    local filename=$1
    local src_dir=$SRC_DIR
    local middle_dir=/home/vagrant/vagrant
    local dest_dir=/vagrant
    local vm=$CDR

    VBoxManage guestcontrol $vm copyto $src_dir/$filename $middle_dir/$filename \
            --username vagrant --password vagrant
    VBoxManage guestcontrol $vm exec --image /usr/bin/sudo \
            --username vagrant --password vagrant --wait-stdout \
            -- mv $middle_dir/$filename $dest_dir/$filename
}

copyexecin () {
    local filename=$1
    copyfilein $filename
    VBoxManage guestcontrol $CDR exec --image /bin/chmod \
            --username vagrant --password vagrant --wait-stdout \
            -- u+x $filename

}


if [ ! -e $CDR_FILE ]
then
    wget $CDR_BASEURL/$CDR_FILE
fi
echo "$CDR_SHA256SUM  $CDR_FILE" | sha256sum -c -

unset CDR_BASEURL



if [ "$ERASE_EXISTING" = true ]
then
    if [ -n "$( VBoxManage list vms | grep '"'$CDR'"' )" ]
    then
        VBoxManage controlvm $CDR poweroff
        VBoxManage unregistervm $CDR --delete
    fi
fi

#if [ -n "$HOSTONLYIF" -a "$ERASE_EXISTING" = true ]
#then
#    if [ -n "`VBoxManage list dhcpservers | grep $DHCPSERVER`" ]
#    then
#        VBoxManage dhcpserver remove --ifname $HOSTONLYIF
#    fi
#    
#    if [ -n "`VBoxManage list hostonlyifs | grep $HOSTONLYIF`" ]
#    then
#        VBoxManage hostonlyif remove $HOSTONLYIF
#    fi
#fi


VM=$(VBoxManage list vms | grep '"'$CDR'"')

#if [ -n "$HOSTONLYIF" ]
#then
#    IF=`VBoxManage list hostonlyifs | grep $HOSTONLYIF`
#    DHCP=`VBoxManage list dhcpservers | grep $DHCPSERVER`
#fi

if [ -z "$VM" ]
then
    VBoxManage import $CDR_FILE --vsys 0 --memory 2048
    GULLIBLE=false
else
    GULLIBLE=true
fi

if [ -z "$VM" ]  # -o  -n "$HOSTONLYIF" -a \( -z "$IF" -a -z "$DHCP" \) ]
then
    :
#    if [ -n "$HOSTONLYIF" ]
#    then
#        if [ -z "$IF" ]
#        then
#            VBoxManage hostonlyif create
#            VBoxManage hostonlyif ipconfig $HOSTONLYIF --ip $HOSTONLY_SUBNET.1
#        fi
        
#        if [ -z "$DHCP" ]
#        then
#            VBoxManage dhcpserver add --ifname $HOSTONLYIF \
#                    --ip $HOSTONLY_SUBNET.100 \
#                    --netmask 255.255.255.0 \
#                    --lowerip $HOSTONLY_SUBNET.101 \
#                    --upperip $HOSTONLY_SUBNET.255 \
#                    --enable
#        fi
#    fi
elif [ "$TRUST_EXISTING" = true ]
then
    GULLIBLE=true
else
    echo "vm $CDR already exists!"
    exit 1
fi
unset VM TRUST_EXISTING

#if [ -n "$HOSTONLYIF" ]
#then
#    unset IF DHCP
#    VBoxManage modifyvm $CDR --nic1 nat \
#            --nic2 hostonly --hostonlyadapter2 $HOSTONLYIF
#fi

VBoxManage modifyvm $CDR --natpf1 delete ssh
VBoxManage modifyvm $CDR --natpf1 delete tcp8443
VBoxManage modifyvm $CDR --natpf1 ssh,tcp,,50022,,22
VBoxManage modifyvm $CDR --natpf1 tls,tcp,,50443,,443
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
    # Provide package to be imported.
    VBoxManage guestcontrol $CDR createdir /home/vagrant/vagrant \
            --username vagrant --password vagrant
    
    VBoxManage guestcontrol $CDR exec --image /usr/bin/sudo \
            --username vagrant --password vagrant --wait-stdout \
            -- yum -y install xorg-x11-xauth

#    if [ -n "$XDO_FILE" ]
#    then
#        # Enable automated testing of GUIs.
#        copyfilein "$XDO_FILE"
#    fi
    
    copyfilein "SixtyFun.cdr.xml"
    copyfilein "stages.json"
    copyfilein "stagesConfig.json"
    copyfilein "IMSLP298641-PMLP01586-LvBeethoven_Symphony_No.5_mvt1.ogg"
    copyexecin "pkg2cdr_inside.sh"
    copyexecin "pkg2cdr_vagrant.sh"
    echo Are the files there?
    sleep 240
    
    # Why in the world doesn't the following work? http://virtualbox.org/ticket/11231
    #VBoxManage guestcontrol $CDR copyto /home/ajm475/originals /home/vagrant/originals \
    #        --username vagrant --password vagrant --recursive
    # I'll just have to scp -r it or else zip & copyto & unzip
fi

ssh-keygen -f "$HOME/.ssh/known_hosts" -R [localhost]:50022
ssh -p 50022 -o StrictHostKeyChecking=no -Y -i ~/.vagrant.d/insecure_private_key vagrant@localhost \
	'sudo -u root -i /vagrant/pkg2cdr_inside.sh'
