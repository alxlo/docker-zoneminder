FROM resin/rpi-raspbian:jessie

MAINTAINER alxlo

VOLUME ["/config"]

EXPOSE 80

RUN export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive 

RUN apt-get update && \
apt-get upgrade && \
apt-get dist-upgrade

RUN echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list && \
echo "Package: * \nPin: origin http.debian.net \nPin-Priority: 1100\n"\ > /etc/apt/preferences.d/zoneminder && \
gpg --keyserver pgpkeys.mit.edu --recv-key  8B48AD6246925553 && \
gpg -a --export 8B48AD6246925553 | sudo apt-key add - && \
gpg --keyserver pgpkeys.mit.edu --recv-key  7638D0442B90D010 && \
gpg -a --export 7638D0442B90D010 | apt-key add - && \
apt-get update && \
apt-get upgrade && \
apt-get dist-upgrade

RUN apt-get install -y php5 mysql-server php-pear php5-mysql zoneminder libvlc-dev libvlccore-dev vlc supervisor && \
service mysql restart && \ 
mysql -uroot < /usr/share/zoneminder/db/zm_create.sql && \
mysql -uroot -e "grant select,insert,update,delete,create on zm.* to 'zmuser'@localhost identified by 'zmpass';" && \
chmod 740 /etc/zm/zm.conf && \
chown root:www-data /etc/zm/zm.conf

RUN a2enconf zoneminder && \
a2enmod rewrite && \
a2enmod cgi && \
adduser www-data video && \
rm -r /etc/init.d/zoneminder

COPY zoneminder /etc/init.d/zoneminder
RUN chmod +x /etc/init.d/zoneminder && \
chown -R www-data:www-data /usr/share/zoneminder/ 

COPY cambozola.jar /usr/share/zoneminder/www/cambozola.jar

RUN sed  -i 's/\;date.timezone =/date.timezone = \"Europe\/Berlin\"/' /etc/php5/apache2/php.ini 


RUN service apache2 restart && \
update-rc.d -f apache2 remove && \
update-rc.d -f mysql remove && \
update-rc.d -f zoneminder remove;

RUN mkdir /var/run/zm && \
chown -R www-data:www-data /var/run/zm

### raspbian image does not provid init.d or systemctl therefore we need something else

RUN mkdir -p /etc/my_init.d
COPY ./runfirst.sh /etc/my_init.d
RUN chmod +x /etc/my_init.d/runfirst.sh
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
