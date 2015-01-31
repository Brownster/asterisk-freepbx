#asterisk docker file for unraid 6
FROM phusion/baseimage:0.9.15
MAINTAINER marc brown <marc@22walker.co.uk>

# Set correct environment variables.
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV ASTERISKUSER asterisk
ENV ASTERISKVER 12
ENV FREEPBXVER 12.0.3
ENV ASTERISK_DB_PW hgftffjgjygfy67r457reew64
# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

#Add user
RUN groupadd -r $ASTERISKUSER && useradd -r -g $ASTERISKUSER $ASTERISKUSER \
	&& mkdir /var/lib/asterisk && chown $ASTERISKUSER:$ASTERISKUSER /var/lib/asterisk \
	&& usermod --home /var/lib/asterisk $ASTERISKUSER

# grab gosu for easy step-down from root
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* \
	&& curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.1/gosu' \
	&& chmod +x /usr/local/bin/gosu \
	&& apt-get purge -y

#Install packets that are needed
RUN apt-get update && apt-get install -y build-essential linux-headers-`uname -r` openssh-server apache2 mysql-server mysql-client bison flex php5 php5-curl php5-cli php5-mysql php-pear php-db php5-gd curl sox libncurses5-dev libssl-dev libmysqlclient-dev mpg123 libxml2-dev libnewt-dev sqlite3 libsqlite3-dev pkg-config automake libtool autoconf git subversion unixodbc-dev uuid uuid-dev libasound2-dev libogg-dev libvorbis-dev libcurl4-openssl-dev libical-dev libneon27-dev libsrtp0-dev libspandsp-dev wget sox mpg123 libwww-perl php5 php5-json libiksemel-dev lamp-server^

#Install Pear DB
RUN pear uninstall db && pear install db-1.7.14

#Get Asterisk, Jansson, pj project and freepbx
WORKDIR /temp/src
RUN wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-$ASTERISKVER-current.tar.gz \
  && git clone https://github.com/akheron/jansson.git \
  && git clone https://github.com/asterisk/pjproject.git \
  && wget http://mirror.freepbx.org/freepbx-$FREEPBXVER.tgz \
  && tar vxfz freepbx-$FREEPBXVER.tgz

#build pj project
WORKDIR /temp/src/pjproject
RUN ./configure --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr \
  && make dep \
  && make \
  && make install

#build jansson
WORKDIR /temp/src/jansson
RUN autoreconf -i \
  && ./configure \
  && make \
  && make install

#Build asterisk
WORKDIR /temp/src
RUN tar xvfz asterisk-$ASTERISKVER-current.tar.gz  \
  && cd asterisk-* \
  && ./configure \
  && contrib/scripts/get_mp3_source.sh \
  && make menuselect.makeopts \
  && sed -i "s/BUILD_NATIVE//" menuselect.makeopts \
  && make && make install && make config

#Extra sounds
# Wideband Audio download
WORKDIR /var/lib/asterisk/sounds
RUN wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz \
  && tar xfz asterisk-extra-sounds-en-wav-current.tar.gz \
  && rm -f asterisk-extra-sounds-en-wav-current.tar.gz \
  && wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-g722-current.tar.gz \
  && tar xfz asterisk-extra-sounds-en-g722-current.tar.gz \
  && rm -f asterisk-extra-sounds-en-g722-current.tar.gz
  
#installation PHP / PHP AGI, necessary files and package for google tts
#RUN wget http://sourceforge.net/projects/phpagi/files/latest/download \
#	&& tar xvzf download \
#	&& mv phpagi-2.20/* /var/lib/asterisk/agi-bin/  \
# 	&& chmod ugo+x /var/lib/asterisk/agi-bin/*.php \
#	&& wget https://github.com/downloads/zaf/asterisk-googletts/asterisk-googletts-0.6.tar.gz \
#	&& tar xvzf asterisk-googletts-0.6.tar.gz \
#	&& cp asterisk-googletts-0.6/googletts.agi /var/lib/asterisk/agi-bin/


#set permissions
RUN chown $ASRERISKUSER. /var/run/asterisk \
  && chown -R $ASTERISKUSER. /etc/asterisk \
  && chown -R $ASTERISKUSER. /var/{lib,log,spool}/asterisk \
  && chown -R $ASTERISKUSER. /usr/lib/asterisk \
  && rm -rf /var/www/html

#mod to apache
RUN sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php5/apache2/php.ini \
  && cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig \
  && sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf \
  && service apache2 restart

#Setup mysql
RUN mysqladmin -u root create asterisk \
  && mysqladmin -u root create asteriskcdrdb

#set permissions
mysql -u root -e "GRANT ALL PRIVILEGES ON asterisk.* TO asteriskuser@localhost IDENTIFIED BY '${ASTERISK_DB_PW}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO asteriskuser@localhost IDENTIFIED BY '${ASTERISK_DB_PW}';"
mysql -u root -e "flush privileges;"

#install free pbx
# WORKDIR /tmp/src
# RUN ./start_asterisk start
WORKDIR /tmp/src/freepbx-$FREEPBXVER
RUN ./install_amp --installdb --username=asteriskuser --password=$ASTERISK_DB_PW \
  && amportal chown \
  && amportal a ma installall \
  && amportal a reload \
  && amportal a ma refreshsignatures \
  && amportal chown 

RUN ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3 \
  && amportal restart

EXPOSE 5060

CMD asterisk -f
