# FREEPBX dockerfile 

This Dockerfile builds and runs OK it is though still a work in progress!

There is still the issue to resolve with freepbx on first run of the container:

Issue 1, - complaining .htaccess files are disabled - more info at http://wiki.freepbx.org/display/F2/Webserver+Overrides

So once you have have your freepbx docker running with either:

sudo docker run --name freepbx -v /place/to/put/backup:/etc/freepbxbackup --net=host -d -t brownster/freepbx12021

or this if using unraid:

sudo docker run --name freepbx \
-v /mnt/user/appdata/freepbx/backup:/freepbx/backup \
-v source=/mnt/user/appdata/freepbx/etc/asterisk,target=/etc/asterisk \
-v source=/mnt/user/appdata/freepbx/etc/apache2,/etc/apache2 \
-v source=/mnt/user/appdata/freepbx/var/www,/var/www/ \
-v source=/mnt/user/appdata/freepbx/var/lib/mysql,/var/lib/mysql \
-v source=/mnt/user/appdata/freepbx/var/lib/mysql/var/spool/asterisk,/var/spool/asterisk \
-v source=/mnt/user/appdata/freepbx/var/lib/mysql/var/lib/asterisk,/var/lib/asterisk \
-net=host -d -t brownster/freepbx12021




Run the following commands starting from the docker host cmd line:

sudo docker exec -it freepbx bash

vi /etc/apache2/apache2.conf and hit Return / Enter.

At Directory /var/www/ you'll see a line like the following:

"AllowOverride None" - change this to "AllowOverride ALL".

service apache2 start

/etc/init.d/mysql start

amportal reload

After that freepbx we browse to:

http://ip adress of docker host:8009/html/admin/config.php

- once you have updated the modules of freepbx you are good to go.

You can find the current built version at (now old):

https://registry.hub.docker.com/u/brownster/freepbx12021/

A basic run example:
sudo docker run --name freepbx -v /place/to/put/backup:/etc/freepbxbackup --net=host -d -t brownster/freepbx12021

EXPOSED ports 80 tcp 5060 tcp and 10000-20000 udp

Mount point /etc/freepbxbackup to allow easy backup of freepbx out of the container.

on first run set passwords and then install freepbx modules required and upgrade

TO BUILD FROM DOCKERFILE:

git clone https://github.com/Brownster/NZB-INSTALL-SCRIPT.git freepbx

cd freepbx

sudo docker build -t yourdockerrepo/freepbx .

you can then push the image to your docker repo.

if you make any changes whilst using freepbx use commit to save your changes.


Things to do:

1, issue stated above to be resolved so freepbx starts cleanly
