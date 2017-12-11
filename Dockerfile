#asterisk docker file for unraid 6
FROM phusion/baseimage:0.9.17
MAINTAINER marc brown <marc@22walker.co.uk> v0.4

# Set correct environment variables.
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV ASTERISKUSER asterisk
ENV ASTERISKVER 13.1
ENV FREEPBXVER 12.0.21
ENV ASTERISK_DB_PW pass123
ENV AUTOBUILD_UNIXTIME 1418234402
# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Add VOLUME to allow backup of FREEPBX
VOLUME ["/etc/freepbxbackup"]

# open up ports needed by freepbx and asterisk 5060 tcp sip reg 80 tcp web port 10000-20000 udp rtp stream  
# EXPOSE 5060
# EXPOSE 80
# EXPOSE 8009
# EXPOSE 10000-20000/udp

# Add start.sh
ADD start.sh /root/

#Install packets that are needed
RUN apt-get update && apt-get install -y build-essential curl libgtk2.0-dev linux-headers-`uname -r` openssh-server apache2 mysql-server mysql-client bison flex php5 php5-curl php5-cli php5-mysql php-pear php-db php5-gd curl sox libncurses5-dev libssl-dev libmysqlclient-dev mpg123 libxml2-dev libnewt-dev sqlite3 libsqlite3-dev pkg-config automake libtool autoconf git subversion unixodbc-dev uuid uuid-dev libasound2-dev libogg-dev libvorbis-dev libcurl4-openssl-dev libical-dev libneon27-dev libsrtp0-dev libspandsp-dev wget sox mpg123 libwww-perl php5 php5-json libiksemel-dev openssl lamp-server^ 1>/dev/null

# add asterisk user
RUN groupadd -r $ASTERISKUSER \
  && useradd -r -g $ASTERISKUSER $ASTERISKUSER \
  && mkdir /var/lib/asterisk \
  && chown $ASTERISKUSER:$ASTERISKUSER /var/lib/asterisk \
  && usermod --home /var/lib/asterisk $ASTERISKUSER \
  && rm -rf /var/lib/apt/lists/* \
#  && curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.1/gosu' \
#  && chmod +x /usr/local/bin/gosu \
  && apt-get purge -y \

#Install Pear DB
  && pear uninstall db 1>/dev/null \
  && pear install db-1.7.14 1>/dev/null

#build pj project
#build jansson
WORKDIR /temp/src/
RUN git clone https://github.com/asterisk/pjproject.git 1>/dev/null \
  && git clone https://github.com/akheron/jansson.git 1>/dev/null \
  && cd /temp/src/pjproject \
  && ./configure --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr 1>/dev/null \
  && make dep 1>/dev/null \
  && make 1>/dev/null \
  && make install 1>/dev/null \
  && cd /temp/src/jansson \
  && autoreconf -i 1>/dev/null \
  && ./configure 1>/dev/null \
  && make 1>/dev/null \
  && make install 1>/dev/null \
  
# Download asterisk.
# Currently Certified Asterisk 13.1.
  && curl -sf -o /tmp/asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/certified-asterisk/certified-asterisk-13.1-current.tar.gz 1>/dev/null \

# gunzip asterisk
  && mkdir /tmp/asterisk \
  && tar -xzf /tmp/asterisk.tar.gz -C /tmp/asterisk --strip-components=1 1>/dev/null
WORKDIR /tmp/asterisk

# make asterisk.
# ENV rebuild_date 2015-01-29
RUN mkdir /etc/asterisk \
# Configure
  && ./configure --with-ssl=/opt/local --with-crypto=/opt/local 1> /dev/null \
# Remove the native build option
  && make menuselect.makeopts 1>/dev/null \
#  && sed -i "s/BUILD_NATIVE//" menuselect.makeopts 1>/dev/null \
  && menuselect/menuselect --enable chan_sip.so --disable BUILD_NATIVE  --enable CORE-SOUNDS-EN-WAV --enable CORE-SOUNDS-EN-SLN16 --enable MOH-OPSOUND-WAV --enable MOH-OPSOUND-SLN16 menuselect.makeopts 1>/dev/null \
# Continue with a standard make.
  && make 1> /dev/null \
  && make install 1> /dev/null \
  && make config 1>/dev/null \
  && ldconfig \

  && cd /var/lib/asterisk/sounds \
  && wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz 1>/dev/null \
  && tar xfz asterisk-extra-sounds-en-wav-current.tar.gz 1>/dev/null \
  && rm -f asterisk-extra-sounds-en-wav-current.tar.gz 1>/dev/null \
  && wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-g722-current.tar.gz 1>/dev/null \
  && tar xfz asterisk-extra-sounds-en-g722-current.tar.gz 1>/dev/null \
  && rm -f asterisk-extra-sounds-en-g722-current.tar.gz \
  && chown $ASRERISKUSER. /var/run/asterisk \
  && chown -R $ASTERISKUSER. /etc/asterisk \
  && chown -R $ASTERISKUSER. /var/lib/asterisk \
  && chown -R $ASTERISKUSER. /var/www/ \
  && chown -R $ASTERISKUSER. /var/www/* \
  && chown -R $ASTERISKUSER. /var/log/asterisk \
  && chown -R $ASTERISKUSER. /var/spool/asterisk \
  && chown -R $ASTERISKUSER. /var/run/asterisk \
  && chown -R $ASTERISKUSER. /var/lib/asterisk \
  && chown $ASTERISKUSER:$ASTERISKUSER /etc/freepbxbackup \
  && rm -rf /var/www/html \

#mod to apache
#Setup mysql
  && sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php5/apache2/php.ini \
  && cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig \
  && sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf \
  && ed -s /etc/apache2/apache2.conf  <<< $'/Options Indexes FollowSymLinks/+1s/AllowOverride None/AllowOverride ALL/g\nw' \
  && service apache2 restart 1>/dev/null \
  && /etc/init.d/mysql start 1>/dev/null \
  && mysqladmin -u root create asterisk \
  && mysqladmin -u root create asteriskcdrdb \
  && mysql -u root -e "GRANT ALL PRIVILEGES ON asterisk.* TO $ASTERISKUSER@localhost IDENTIFIED BY '$ASTERISK_DB_PW';" \
  && mysql -u root -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO $ASTERISKUSER@localhost IDENTIFIED BY '$ASTERISK_DB_PW';" \
  && mysql -u root -e "flush privileges;"

WORKDIR /tmp
RUN wget http://mirror.freepbx.org/freepbx-$FREEPBXVER.tgz 1>/dev/null 2>/dev/null \
  && ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3 \
  && tar vxfz freepbx-$FREEPBXVER.tgz 1>/dev/null \
  && cd /tmp/freepbx \
  && /etc/init.d/mysql start 1>/dev/null \
  && /usr/sbin/asterisk 1>/dev/null \
  && ./install_amp --installdb --username=$ASTERISKUSER --password=$ASTERISK_DB_PW 1>/dev/null \
  && amportal chown \
  && amportal reload \
  && asterisk -rx "core restart now" \
  && amportal chown \
  && amportal reload 1>/dev/null \
  && asterisk -rx "core restart now" \
  && amportal a ma refreshsignatures 1>/dev/null \
  && amportal chown \
  && amportal reload \
  && asterisk -rx "core restart now" \
  && chown -R $ASTERISKUSER. /var/lib/asterisk/bin/retrieve_conf \

#clean up
  && find /temp -mindepth 1 -delete \
  && apt-get purge -y \
  && apt-get --yes autoremove \
  && apt-get clean all \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
   
CMD bash -C '/root/start.sh';'bash'
