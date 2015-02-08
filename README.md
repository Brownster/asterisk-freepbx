# FREEPBX dockerfile 

Believe it or not this actually seems to work now!

i had a couple of issue to resolve with freepbx on first run of the container:

Issue 1, - complaining of unsigned.....
FIX-vi /etc/apache2/sites-enabled/000-default" and hit Return / Enter.

At Directory /var/www/ you'll see a line like the following:

"AllowOverride None" - change this to "AllowOverride ALL".


ISSUE 2, - issue with framework...
FIX - From conttainer command line:
  amportal a ma update framework

After that freepbx seems to be happy.

You can find the current version at:

https://registry.hub.docker.com/u/brownster/freepbx12021/

# to run
sudo docker run --name freepbx -v /place/to/put/backup:/etc/freepbxbackup --net=host -d -t brownster/freepbx12021

EXPOSED ports 80 5060 and 10000-10099, so freepbx rtp settings will need editing to reduce the range from 10000-20000 to 10000-10099

Mount point /etc/freepbxbackup to allow easy backup of freepbx out of the container.



Things to include in next build:

1, issues stated above to be resolved so freepbx starts cleanly

2, Changing rtp port range in rtp.con to look something like:

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

3,Change apache listening port 
  Change Listen 0.0.0.0:80 to Listen 0.0.0.0:8009
