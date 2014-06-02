## iRODS 4.0 Vagrant VM

This project allows users to set up a VM running a basic `community` iRODS 4.0 install using <a href="http://www.vagrantup.com/
">Vagrant</a> and <a href="https://www.virtualbox.org">VirtualBox</a>.

This gives users a reproducible iRODS environment to do work against.


# Installation

* Install VirtualBox following the instructions at the VirtualBox site listed above.

* Install Vagrant following the instructions at the Vagrant site listed above.

* Clone the code in this repo.

* Run 'vagrant up' in a terminal from inside the cloned repo. 


# Starting up iRODS

* In a terminal in the cloned directory, run 'vagrant ssh'. This will ssh into the running VM.

* Run 'irodsctl start' to start up iRODS and use the `i-commands`.


# Usage outside of Vagrant

To apply the scripts directly to an Ubuntu system, without Vagrant, you could do this:

    git clone $IRODS_VAGRANT_URL
    sudo adduser vagrant
    sudo passwd -l vagrant
    sudo mkdir -p /vagrant
    sudo cp irods-vagrant/* /vagrant # Don't need files [RVw]* though
    sudo --login sh -c 'cd /vagrant && . ./irods.sh'

    sudo --login sh -c 'cd /vagrant && . ./tls.sh'

    sudo --login sh -c 'cd /vagrant && . ./cw_in.sh'

    sh /vagrant/cw_run.sh

This last command assumes that you have graphics on the system.
If not, you could put your ssh public key in user vagrant's
`~/.ssh/authorized_keys` and do this:

    ssh -X vagrant@$IRODS_HOST 'sh /vagrant/cw_run.sh'


# Notes

* Your local port 1247 will be forwarded to port 1247 in the VM.

* The iRODS username is 'rods'. The password is 'rods'. The zone is 'tempZone'.

* iRODS is running when the VM is created. This behavior is a change from the iRODS 3.3 Vagrant VM.

* Don't run this VM in production.

* Don't store any sensitive information in this VM.
