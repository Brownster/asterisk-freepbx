# asterisk docker file for unraid
FROM phusion/baseimage:0.9.15
MAINTAINER marc brown <>

# Set correct environment variables.
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Creates the user under which asterisk will run
ENV ASTERISKUSER asterisk
ENV ASTERISKVER 11.6
RUN groupadd -r $ASTERISKUSER && useradd -r -g $ASTERISKUSER $ASTERISKUSER \
	&& mkdir /var/lib/asterisk && chown $ASTERISKUSER:$ASTERISKUSER /var/lib/asterisk \
	&& usermod --home /var/lib/asterisk $ASTERISKUSER

# grab gosu for easy step-down from root
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* \
	&& curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.1/gosu' \
	&& chmod +x /usr/local/bin/gosu \
	&& apt-get purge -y

# installation of packets needed for installation
RUN apt-get update && apt-get install -y build-essential linux-headers-`uname -r` openssh-server lamp-server^ apache2 mysql-server\
  mysql-client bison flex php5 php5-curl php5-cli php5-mysql php-pear php-db php5-gd curl sox\
  libncurses5-dev libssl-dev libmysqlclient-dev mpg123 libxml2-dev libnewt-dev sqlite3\
  libsqlite3-dev pkg-config automake libtool autoconf git subversion unixodbc-dev uuid uuid-dev\
  libasound2-dev libogg-dev libvorbis-dev libcurl4-openssl-dev libical-dev libneon27-dev libsrtp0-dev\
  libspandsp-dev wget sox mpg123 libwww-perl php5 php5-json
 
# Getting the sources asterisk and freepbx
RUN curl -sf -o /tmp/asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/certified-asterisk/certified-asterisk-11.6-current.tar.gz \
	&& curl -sf -o /tmp/freepbx-12.0.3.tgz -L http://mirror.freepbx.org/freepbx-12.0.3.tgz \
	&& tar vxfz freepbx-12.0.3.tgz
  
#install pear DB
RUN pear uninstall db && pear install db-1.7.14

#google voice dependencies
RUN wget https://iksemel.googlecode.com/files/iksemel-1.4.tar.gz && tar -xzf iksemel-1.4.tar.gz -C /usr/src/iksemel \
	&& cd /usr/src/iksemel && ./configure && make && install

#install Jansson
#WORKDIR /usr/src/jansson
#RUN autoreconf -i && ./configure && make && make install

# gunzip asterisk
RUN mkdir /tmp/asterisk
RUN tar -xzf /tmp/asterisk.tar.gz -C /tmp/asterisk --strip-components=1
WORKDIR /tmp/asterisk

#installation asterisk
RUN cd /tmp/asterisk && ./configure && contrib/scripts/get_mp3_source.sh && make menuselect.makeopts 
RUN sed -i "s/BUILD_NATIVE//" menuselect.makeopts
RUN make && make install && make config

#asterisk extra sounds
WORKDIR /var/lib/asterisk/sounds
RUN wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz \
  && tar xfz asterisk-extra-sounds-en-wav-current.tar.gz && rm -f asterisk-extra-sounds-en-wav-current.tar.gz

# Wideband Audio download
RUN wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-g722-current.tar.gz \
  && tar xfz asterisk-extra-sounds-en-g722-current.tar.gz && rm -f asterisk-extra-sounds-en-g722-current.tar.gz

#installation PHP / PHP AGI
RUN apt-get install -y php5 php5-json \
	&& cd /tmp && wget http://sourceforge.net/projects/phpagi/files/latest/download \
	&& tar xvzf download \
	&& mv phpagi-2.20/* /var/lib/asterisk/agi-bin/  \
 	&& chmod ugo+x /var/lib/asterisk/agi-bin/*.php
 	
#necessary files and package for google tts
# sox - google tts agi - mpg 123
WORKDIR /tmp
RUN wget https://github.com/downloads/zaf/asterisk-googletts/asterisk-googletts-0.6.tar.gz \
	&& tar xvzf asterisk-googletts-0.6.tar.gz \
	&& cp asterisk-googletts-0.6/googletts.agi /var/lib/asterisk/agi-bin/

#Change ownership of asterisk files
RUN chown -R $ASTERISKUSER:$ASTERISKUSER /var/lib/asterisk \
	&& chown -R $ASTERISKUSER:$ASTERISKUSER /var/spool/asterisk \
	&& chown -R $ASTERISKUSER:$ASTERISKUSER /var/log/asterisk \
	&& chown -R $ASTERISKUSER:$ASTERISKUSER /var/run/asterisk \
	&& chown -R $ASTERISKUSER:$ASTERISKUSER /etc/asterisk
 
#mod to apache
RUN sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php5/apache2/php.ini \
  && cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig \
  && sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf \
  && service apache2 restart

#Prepare MySQL generate secure password
RUN export ASTERISK_DB_PW=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 - | cut -c2-18`

#Configure MySql database
RUN mysqladmin -u root create asterisk && mysqladmin -u root create asteriskcdrdb

#Set MySql Permissions
RUN mysql -u root -e "GRANT ALL PRIVILEGES ON asterisk.* TO asteriskuser@localhost IDENTIFIED BY '${ASTERISK_DB_PW}';" \
  && mysql -u root -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO asteriskuser@localhost IDENTIFIED BY '${ASTERISK_DB_PW}';" \
  && mysql -u root -e "flush privileges;"

#Install Freepbx
#./start_asterisk start
RUN ./install_amp --installdb --username=$ASTERISKUSER --password=${ASTERISK_DB_PW} \
  && amportal chown \
  && amportal a ma installall \
  && amportal a reload \
  && amportal a ma refreshsignatures \
  && amportal chown
  
#change freepbx port from 80 to 81
RUN sed s/0.0.0.0:80/0.0.0.0:81/ /etc/httpd/conf/httpd.con

#Mod Freepbx
RUN ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3 \
	&& amportal restart

#Make asterisk port open
EXPOSE 5060

CMD asterisk -f
