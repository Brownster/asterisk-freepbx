# FREEPBX dockerfile 

https://registry.hub.docker.com/u/brownster/freepbx12021/

# to run
sudo docker run --name freepbx -v /place/to/put/backup:/etc/freepbxbackup --publish-all=true -d -t brownster/freepbx12021

EXPOSED ports 80 5060 and 10000-10099, so freepbx rtp settings will need editing to reduce the range from 10000-20000 to 10000-10099
