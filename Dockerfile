FROM phusion/baseimage:0.9.15
MAINTAINER Marc Brown <info@nowhere.nk>
# Set correct environment variables.
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV FREEPBXVER 12.0.3
ENV ASTERISK_DB_PW hgftffjgjygfy67r457reew64

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

#Change uid & gid to match Unraid
#RUN usermod -u 99 nobody && \
#    usermod -g 100 nobody && \
#    usermod -d /home nobody && \
#    chown -R nobody:users /home

RUN apt-get update -y

RUN apt-get install -y build-essential linux-headers-`uname -r` openssh-server apache2 mysql-server\
  mysql-client bison flex php5 php5-curl php5-cli php5-mysql php-pear php-db php5-gd curl sox\
  libncurses5-dev libssl-dev libmysqlclient-dev mpg123 libxml2-dev libnewt-dev sqlite3\
  libsqlite3-dev pkg-config automake libtool autoconf git subversion unixodbc-dev uuid uuid-dev\
  libasound2-dev libogg-dev libvorbis-dev libcurl4-openssl-dev libical-dev libneon27-dev libsrtp0-dev\
  libspandsp-dev libiksemel-dev lamp-server^ tar ncurses-dev xinetd wget gtk+-2.0 -y

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
  && autoreconf -i \
  && ./configure \
  && make \
  && make install


# ENV AUTOBUILD_UNIXTIME 1418234402

# Download asterisk.
# Currently Certified Asterisk 11.6 cert 6.
RUN curl -sf -o /tmp/asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/certified-asterisk/certified-asterisk-11.6-current.tar.gz

# gunzip asterisk
RUN mkdir /tmp/asterisk
RUN tar -xzf /tmp/asterisk.tar.gz -C /tmp/asterisk --strip-components=1
WORKDIR /tmp/asterisk

# make asterisk.
ENV rebuild_date 2015-01-29
# Configure
RUN ./configure --libdir=/usr/lib64 1> /dev/null --prefix=/opt/asterisk --disable-asteriskssl
# Remove the native build option
RUN make menuselect.makeopts
RUN sed -i "s/BUILD_NATIVE//" menuselect.makeopts
# Continue with a standard make.
RUN make 1> /dev/null
RUN make install 1> /dev/null
RUN make config 1> /dev/null
RUN ldconfig

WORKDIR /var/lib/asterisk/sounds
RUN wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz \
  && tar xfz asterisk-extra-sounds-en-wav-current.tar.gz \
  && rm -f asterisk-extra-sounds-en-wav-current.tar.gz \
  && wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-g722-current.tar.gz \
  && tar xfz asterisk-extra-sounds-en-g722-current.tar.gz \
  && rm -f asterisk-extra-sounds-en-g722-current.tar.gz

WORKDIR /
# add asterisk user
RUN useradd -m asterisk \
  # && chown asterisk. /var/run/asterisk \
  && chown -R asterisk. /etc/asterisk \
  && chown -R asterisk. /var/lib/asterisk \
  && chown -R asterisk. /var/spool/asterisk \
  && chown -R asterisk. /var/log/asterisk \
  #&& chown -R asterisk. /usr/lib/asterisk \
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
  && mysql -u root -e "GRANT ALL PRIVILEGES ON asterisk.* TO asteriskuser@localhost IDENTIFIED BY '${ASTERISK_DB_PW}';" \
  && mysql -u root -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO asteriskuser@localhost IDENTIFIED BY '${ASTERISK_DB_PW}';" \
  && mysql -u root -e "flush privileges;"

#install free pbx and required mod to moh
WORKDIR /tmp/src
RUN wget http://mirror.freepbx.org/freepbx-$FREEPBXVER.tgz \
  && tar vxfz freepbx-$FREEPBXVER.tgz \
  && cd /tmp/src/freepbx \
  && asterisk start   
#&& ./start_asterisk start \
  && ./install_amp --installdb --username=asteriskuser --password=$ASTERISK_DB_PW \
  && amportal chown \
  && amportal a ma installall \
  && amportal a reload \
  && amportal a ma refreshsignatures \
  && amportal chown 
  && ln -s /var/lib/asterisk/moh /var/lib/asterisk/mohmp3 \
  && amportal restart


CMD asterisk -f
