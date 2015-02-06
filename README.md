# FREEPBX dockerfile 

https://registry.hub.docker.com/u/brownster/freepbx12021/

# to run
sudo docker run --name freepbx -v /place/to/put/backup:/etc/freepbxbackup --publish-all=true -d -t brownster/freepbx12021
