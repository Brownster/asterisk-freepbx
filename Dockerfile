#asterisk docker file for unraid 6
FROM phusion/baseimage:0.9.15
MAINTAINER marc brown <marc@22walker.co.uk> v0.3

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

#Install packets that are needed
RUN apt-get update && apt-get install -y build-essential curl libgtk2.0-dev linux-headers-`uname -r` openssh-server apache2 mysql-server mysql-client bison flex php5 php5-curl php5-cli php5-mysql php-pear php-db php5-gd curl sox libncurses5-dev libssl-dev libmysqlclient-dev mpg123 libxml2-dev libnewt-dev sqlite3 libsqlite3-dev pkg-config automake libtool autoconf git subversion unixodbc-dev uuid uuid-dev libasound2-dev libogg-dev libvorbis-dev libcurl4-openssl-dev libical-dev libneon27-dev libsrtp0-dev libspandsp-dev wget sox mpg123 libwww-perl php5 php5-json libiksemel-dev lamp-server^

#Add user
# grab gosu for easy step-down from root
RUN groupadd -r $ASTERISKUSER \
  && useradd -r -g $ASTERISKUSER $ASTERISKUSER \
  && mkdir /var/lib/asterisk \
  && chown $ASTERISKUSER:$ASTERISKUSER /var/lib/asterisk \
  && usermod --home /var/lib/asterisk $ASTERISKUSER \
  && rm -rf /var/lib/apt/lists/* \
  && curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.1/gosu' \
  && chmod +x /usr/local/bin/gosu \
  && apt-get purge -y

#Install Pear DB
RUN pear uninstall db && pear install db-1.7.14

#build pj project
#build jansson
WORKDIR /temp/src/
RUN git clone https://github.com/asterisk/pjproject.git \
  && git clone https://github.com/akheron/jansson.git \
  && cd /temp/src/pjproject \
  && ./configure --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr \
  && make dep \
  && make \
  && make install \
  && cd /temp/src/jansson \
  && autoreconf -i 1>/dev/null \
  && ./configure 1>/dev/null \
  && make 1>/dev/null \
  && make install
  
# Download asterisk.
# Currently Certified Asterisk 13.1.
RUN curl -sf -o /tmp/asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/certified-asterisk/certified-asterisk-13.1-current.tar.gz 1>/dev/null

# gunzip asterisk
RUN mkdir /tmp/asterisk
RUN tar -xzf /tmp/asterisk.tar.gz -C /tmp/asterisk --strip-components=1
WORKDIR /tmp/asterisk

# make asterisk.
ENV rebuild_date 2015-01-29
# Configure
RUN ./configure 1> /dev/null
# Remove the native build option
RUN make menuselect.makeopts 1>/dev/null
RUN sed -i "s/BUILD_NATIVE//" menuselect.makeopts
# Continue with a standard make.
RUN make 1> /dev/null
RUN make install 1> /dev/null
RUN make config 1>/dev/null
RUN ldconfig  

 RUN cd /var/lib/asterisk/sounds \
  && wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz 1>/dev/null \
  && tar xfz asterisk-extra-sounds-en-wav-current.tar.gz \
  && rm -f asterisk-extra-sounds-en-wav-current.tar.gz \
  && wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-g722-current.tar.gz 1>/dev/null \
  && tar xfz asterisk-extra-sounds-en-g722-current.tar.gz \
  && rm -f asterisk-extra-sounds-en-g722-current.tar.gz \
  && chown $ASRERISKUSER. /var/run/asterisk \
  && chown -R $ASTERISKUSER. /etc/asterisk \
  && chown -R $ASTERISKUSER. /var/lib/asterisk \
  && chown -R $ASTERISKUSER. /var/www/ \
  && chown -R $ASTERISKUSER. /var/www/* \
# && chown -R $ASTERISKUSER. /var/www/html/admin/libraries \
  && chown -R $ASTERISKUSER. /var/log/asterisk \
  && chown -R $ASTERISKUSER. /var/spool/asterisk \
  && chown -R $ASTERISKUSER. /var/run/asterisk \
# && chown -R $ASTERISKUSER. /usr/lib/asterisk \
  && mkdir /etc/freepbxbackup \
  && chown $ASTERISKUSER:$ASTERISKUSER /etc/freepbxbackup \
  && rm -rf /var/www/html

#mod to apache
#Setup mysql
RUN sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php5/apache2/php.ini \
  && cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig \
  && sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf \
  && service apache2 restart \
  && /etc/init.d/mysql start \
  && mysqladmin -u root create asterisk \
  && mysqladmin -u root create asteriskcdrdb \
  && mysql -u root -e "GRANT ALL PRIVILEGES ON asterisk.* TO $ASTERISKUSER@localhost IDENTIFIED BY '$ASTERISK_DB_PW';" \
  && mysql -u root -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO $ASTERISKUSER@localhost IDENTIFIED BY '$ASTERISK_DB_PW';" \
  && mysql -u root -e "flush privileges;"

WORKDIR /tmp
RUN wget http://mirror.freepbx.org/freepbx-$FREEPBXVER.tgz 1>/dev/null \
  && ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3 \
  && tar vxfz freepbx-$FREEPBXVER.tgz \
  && cd /tmp/freepbx \
  && /etc/init.d/mysql start \
  && /usr/sbin/asterisk \
  && ./install_amp --installdb --username=$ASTERISKUSER --password=$ASTERISK_DB_PW \
  && amportal chown \
  && amportal reload \
  && asterisk -rx "core restart now" \
  && amportal chown \
#  && amportal a ma install framework 1>/dev/null \
#  && amportal a ma install core 1>/dev/null \
#  && amportal a ma install voicemail 1>/dev/null \
#  && amportal a ma install sipsettings 1>/dev/null \
#  && amportal a ma install infoservices 1>/dev/null \
#  && amportal a ma install featurecodeadmin 1>/dev/null \
#  && amportal a ma install logfiles 1>/dev/null \
#  && amportal a ma install callrecording 1>/dev/null \
#  && amportal a ma install cdr 1>/dev/null \
 # && amportal a ma install dashboard 1>/dev/null \
 

#  && amportal a ma installall 1>/dev/null \
#   && amportal a ma upgrade manager 1>/dev/null \
#   && amportal a ma install manager 1>/dev/null \
   && amportal reload 1>/dev/null \
   && asterisk -rx "core restart now" \
   && amportal a ma refreshsignatures 1>/dev/null \
   && amportal chown \
   && amportal reload \
   && asterisk -rx "core restart now"

# Add VOLUME to allow backup of FREEPBX
VOLUME ["/etc/freepbxbackup"]
  
EXPOSE 5060
EXPOSE 80
EXPOSE 10000 10001 10002 10003 10004 10005 10006 10007 10008 10009 10010 \
10011 10012 10013 10014 10015 10016 10017 10018 10019 10020 \
10021 10022 10023 10024 10025 10026 10027 10028 10029 10030 \
10031 10032 10033 10034 10035 10036 10037 10038 10039 10040 \
10041 10042 10043 10044 10045 10046 10047 10048 10049 10050 \
10051 10052 10053 10054 10055 10056 10057 10058 10059 10060 \
10061 10062 10063 10064 10065 10066 10067 10068 10069 10070 \
10071 10072 10073 10074 10075 10076 10077 10078 10079 10080 \
10081 10082 10083 10084 10085 10086 10087 10088 10089 10090 \
10091 10092 10093 10094 10095 10096 10097 10098 10099 \

CMD asterisk -f
