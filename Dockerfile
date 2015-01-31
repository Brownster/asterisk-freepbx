#asterisk docker file for unraid 6
FROM phusion/baseimage:0.9.15
MAINTAINER marc brown <marc@22walker.co.uk>

# Set correct environment variables.
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV ASTERISKUSER asterisk
ENV ASTERISKVER 11.6
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

#Get Asterisk
WORKDIR /temp/src
RUN wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz \
  && wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-1.4-current.tar.gz \
  && wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-12-current.tar.gz \
  && git clone https://github.com/akheron/jansson.git \
  && git clone https://github.com/asterisk/pjproject.git \
  && wget http://mirror.freepbx.org/freepbx-12.0.3.tgz \
  && tar vxfz freepbx-12.0.3.tgz

WORKDIR /temp/src/pjproject
RUN ./configure --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr \
  && make dep \
  && make \
  && make install
