#!/bin/bash

# start apache
service apache2 start
# start mysql
/etc/init.d/mysql start
# start asterisk
service asterisk start
# start amp
amportal reload
amportal chown
amportal a ma refreshsignatures
amportal a reload
amportal a ma update framework


