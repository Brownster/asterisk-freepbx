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
# Add start.sh
ADD start.sh /root/

# Add VOLUME to allow backup of FREEPBX
VOLUME ["/etc/freepbxbackup"]

# open up ports needed  by freepbs and asterisk 5060 sip reg 80 web port 10000-10099 rtp   
EXPOSE 5060
EXPOSE 80
EXPOSE 10000/udp 10001/udp 10002/udp 10003/udp 10004/udp 10005/udp 10006/udp 10007/udp 10008/udp 10009/udp 10010/udp \
10011/udp 10012/udp 10013/udp 10014/udp 10015/udp 10016/udp 10017/udp 10018/udp 10019/udp 10020/udp \
10021/udp 10022/udp 10023/udp 10024/udp 10025/udp 10026/udp 10027/udp 10028/udp 10029/udp 10030/udp \
10031/udp 10032/udp 10033/udp 10034/udp 10035/udp 10036/udp 10037/udp 10038/udp 10039/udp 10040/udp \
10041/udp 10042/udp 10043/udp 10044/udp 10045/udp 10046/udp 10047/udp 10048/udp 10049/udp 10050/udp \
10051/udp 10052/udp 10053/udp 10054/udp 10055/udp 10056/udp 10057/udp 10058/udp 10059/udp 10060/udp \
10061/udp 10062/udp 10063/udp 10064/udp 10065/udp 10066/udp 10067/udp 10068/udp 10069/udp 10070/udp \
10071/udp 10072/udp 10073/udp 10074/udp 10075/udp 10076/udp 10077/udp 10078/udp 10079/udp 10080/udp \
10081/udp 10082/udp 10083/udp 10084/udp 10085/udp 10086/udp 10087/udp 10088/udp 10089/udp 10090/udp \
10091/udp 10092/udp 10093/udp 10094/udp 10095/udp 10096/udp 10097/udp 10098/udp 10099/udp

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
RUN mkdir /etc/asterisk
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
  && chown -R $ASTERISKUSER. /var/log/asterisk \
  && chown -R $ASTERISKUSER. /var/spool/asterisk \
  && chown -R $ASTERISKUSER. /var/run/asterisk \
  && chown -R $ASTERISKUSER. /var/lib/asterisk \
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
   && amportal reload 1>/dev/null \
   && asterisk -rx "core restart now" \
   && amportal a ma refreshsignatures 1>/dev/null \
   && amportal chown \
   && amportal reload \
   && asterisk -rx "core restart now"

CMD asterisk -f
