FROM phusion/baseimage:0.9.16

MAINTAINER aptalca

VOLUME ["/config"]

EXPOSE 80

RUN export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive && \
apt-get update && \
apt-get install -y \
software-properties-common \
python-software-properties && \
add-apt-repository -y ppa:iconnor/zoneminder && \
apt-get update && \
apt-get install -y \
wget \
apache2 \
mysql-server \
php5 \
php5-gd \
libapache2-mod-php5 \
usbutils \
vlc \
libvlc-dev \
libvlccore-dev && \
service apache2 restart && \
service mysql restart && \
apt-get install -y \
zoneminder \
libvlc-dev \
libvlccore-dev vlc && \
mysql -uroot < /usr/share/zoneminder/db/zm_create.sql && \
mysql -uroot -e "grant select,insert,update,delete,create,alter,index,lock tables on zm.* to 'zmuser'@localhost identified by 'zmpass';" && \
a2enconf zoneminder && \
a2enmod rewrite && \
a2enmod cgi && \
chown -R www-data:www-data /usr/share/zoneminder/ && \
sed  -i 's/\;date.timezone =/date.timezone = \"America\/New_York\"/' /etc/php5/apache2/php.ini && \
service apache2 restart && \
service mysql restart && \
rm -r /etc/init.d/zoneminder && \
mkdir -p /etc/my_init.d

ADD zoneminder /etc/init.d/zoneminder
ADD firstrun.sh /etc/my_init.d/firstrun.sh

RUN chmod +x /etc/init.d/zoneminder && \
chmod +x /etc/my_init.d/firstrun.sh && \
mkdir /etc/apache2/conf.d && \
ln -s /etc/zm/apache.conf /etc/apache2/conf.d/zoneminder.conf && \
ln -s /etc/zm/apache.conf /etc/apache2/conf-enabled/zoneminder.conf && \
adduser www-data video && \
service apache2 restart && \
cd /usr/src && \
wget http://www.charliemouse.com:8080/code/cambozola/cambozola-0.936.tar.gz && \
tar -xzvf cambozola-0.936.tar.gz && \
cp cambozola-0.936/dist/cambozola.jar /usr/share/zoneminder && \
cp /etc/zm/apache.conf /root/apache.conf && \
cp /etc/zm/zm.conf /root/zm.conf && \
update-rc.d -f apache2 remove && \
update-rc.d -f mysql remove && \
update-rc.d -f zoneminder remove
