#!/bin/bash

# Aaron Mansheim, Drexel University, 2014
cd `dirname $0`
DIR=`pwd`


# Update xml namespace URL in schemas/mods-3-4.xml which is inside
#    services/WEB-INF/lib/persistence-3.4-SNAPSHOT.jar
#    to match http://www.loc.gov/standards/mods/v3/mods-3-4.xsd
#    which has it as "http://www.loc.gov/mods/xml.xsd" -- note, this fix might not scale!
#    NOT "https://cdr.lib.unc.edu/static/schemas/mods-3-4/xml.xsd"
jar xf /opt/repository/tomcat/webapps/services/WEB-INF/lib/persistence-3.4-SNAPSHOT.jar \
    schemas/mods-3-4.xsd
perl -p -i -e '
        s{\Qhttps://cdr.lib.unc.edu/static/schemas/mods-3-4/xml.xsd}
         {http://www.loc.gov/mods/xml.xsd};
        s{\Qhttps://cdr.lib.unc.edu/static/schemas/mods-3-4/xlink.xsd}
         {http://www.loc.gov/standards/xlink/xlink.xsd}' \
    schemas/mods-3-4.xsd
jar uf /opt/repository/tomcat/webapps/services/WEB-INF/lib/persistence-3.4-SNAPSHOT.jar \
    schemas/mods-3-4.xsd
jar uf /opt/repository/tomcat/webapps/admin/WEB-INF/lib/persistence-3.4-SNAPSHOT.jar \
    schemas/mods-3-4.xsd
rm schemas/mods-3-4.xsd
rmdir schemas

# Update stagesConfig.json
cp stagesConfig.json /opt/repository/stagesConfig.json
chown vagrant:vagrant /opt/repository/stagesConfig.json
# Update stages.json
cp stages.json /var/www/html/static/stages.json # dest owned by root

# Restart Tomcat
cd /opt/repository/bin
./tomcat.sh stop # must run as root
sleep 60 # Help prevent messages in Catalina.out about processes that will cause memory leaks?
./tomcat.sh start # Takes roughly 90 seconds

sudo -u vagrant -i /vagrant/pkg2cdr_vagrant.sh
