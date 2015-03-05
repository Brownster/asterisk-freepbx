# FREEPBX dockerfile 

Believe it or not this actually seems to work now - But still a work in progress!

There is an auto build of this docker file which you can find here:

https://registry.hub.docker.com/u/brownster/docker-freepbx/

I had a couple of issue to resolve with freepbx on first run of the container:

Issue 1, - complaining of access.....
FIX-vi /etc/apache2/apache2.conf and hit Return / Enter.

At Directory /var/www/ you'll see a line like the following:

"AllowOverride None" - change this to "AllowOverride ALL".

*** issue 2 and 3 should be resolved if building from docker file ***

ISSUE 2, - issue with framework...
FIX - From container command line:
  amportal a ma update framework
  
Issue 3, unsigned module
FIX: 
amportal chown
amportal a ma refreshsignatures
amportal a reload

After that freepbx seems to be happy.

from another machine just type:

http:/yourhostip:8009

or form the same machine as docker is running

http://localhost:8009 or whaterever value you gave $FREEPBXPORT if you built the docker image yourself

You can find the current version at:

https://registry.hub.docker.com/u/brownster/docker-freepbx/

A older working version can still be found at:

https://registry.hub.docker.com/u/brownster/freepbx12021/

# To Run
sudo docker run --name freepbx -v /place/to/put/backup:/etc/freepbxbackup --net=host -d -t brownster/docker-freepbx

EXPOSED ports 8009 tcp 5060 tcp and 10000-20000 udp

Mount point /etc/freepbxbackup to allow easy backup of freepbx out of the container.

Things to include in next build:

1, issues stated above to be resolved so freepbx starts cleanly
