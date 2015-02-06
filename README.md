# FREEPBX dockerfile 

https://registry.hub.docker.com/u/brownster/freepbx12021/

# to run
sudo docker run --name freepbx -v /place/to/put/backup:/etc/freepbxbackup --publish-all=true -d -t brownster/freepbx12021

EXPOSED ports 80 5060 and 10000-10099, so freepbx rtp settings will need editing to reduce the range from 10000-20000 to 10000-10099

Mount point /etc/freepbxbackup to allow easy backup of freepbx out of container.


Things to include in next build:

Changing rtp port range:

nano /etc/asterisk/rtp.conf
;
; RTP Configuration
;
[general]
;
; RTP start and RTP end configure start and end addresses
; These are the addresses where your system will RECEIVE audio and video stream$
; If you have connections across a firewall, make sure that these are open.
;
rtpstart=10000
rtpend=10099

4 ports required for each concurrent phone call.  


nano /etc/httpd/conf/httpd.conf
Change Listen 0.0.0.0:80 to Listen 0.0.0.0:8009
