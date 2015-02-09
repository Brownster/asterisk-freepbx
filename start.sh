#!/bin/bash

# start apache
service apache2 start
# start mysql
/etc/init.d/mysql start
# start asterisk
/usr/sbin/asterisk
# start amp
amportal reload

#Experiment Get freepbx to start cleanly as i can
# amportal chown
# amportal a ma refreshsignatures
# amportal a reload
# amportal a ma update framework


