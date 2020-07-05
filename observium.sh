#!/bin/bash

#------colors----------
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
blue='\033[0;34m'  
purple='\033[1;35m'
cyan='\033[1;36m'  
off="\033[0m"
user=$( echo $USER )
#----------------------



function redhat() {

echo -e "${yellow}[+]-Installing Packets ..${off}"

yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install http://yum.opennms.org/repofiles/opennms-repo-stable-rhel7.noarch.rpm
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm

echo -e "${blue}[+]-Adding yum-utils ..${off}"

yum install yum-utils

 
command -v dhcpstarv >/dev/null 2>&1 || { echo -e "${red}[-] need to install PHP 7.2.. ";sleep 1 ; yum-config-manager --enable remi-php72 ;}

sleep 2
echo -e "${blue}[+]-UPDATING ..${off}"
yum update

echo -e "${blue}[+]-CREATION of observium package in the /opt  ..${off}"

cd /opt
wget http://www.observium.org/observium-community-latest.tar.gz
tar zxvf observium-community-latest.tar.gz

echo -e "${yellow}[+]-Restarting erver ..${off}"
systemctl enable mariadb
systemctl start mariadb

./discovery.php -u

cp /opt/observium/config.php /opt/observium/config.php.old
echo -e "<?php" >> /opt/observium/config.php
echo -e "$config['db_extension'] = 'mysqli';" >> /opt/observium/config.php
echo -e "$config['db_host']      = 'localhost';" >> /opt/observium/config.php
echo -e "$config['db_user']      = 'admin';" >> /opt/observium/config.php
echo -e "$config['db_pass']      = '123';" >> /opt/observium/config.php
echo -e "$config['db_name']      = 'observium';" >> /opt/observium/config.php
echo -e "$config['install_dir'] = "/opt/observium";" >> /opt/observium/config.php
echo -e "$config['snmp']['community'] = array("public");" >> /opt/observium/config.php
echo -e "$config['auth_mechanism'] = "mysql";" >> /opt/observium/config.php

echo -e "$config['fping'] = "/usr/sbin/fping";" >> /opt/observium/config.php
echo -e " $config['enable_billing']       = 1;" >> /opt/observium/config.php
echo -e "$config['collectd_dir']         = "/var/lib/collectd/rrd/";" >> /opt/observium/config.php
echo -e "$config['snmp']['community'] = array("TaCommunautéPrivée"); " >> /opt/observium/config.php

sleep 1 
echo -e "${blue}[+]- add port 80 to clients server   ..${off}"
sleep 3 

firewall-cmd --add-port=80/tcp,161/udp --permanent
firewall-cmd --reload

mkdir -p /opt/observium/rrd
echo -e "${blue}[+]- Add privilege to be apache user${off}"
chown apache:apache /opt/observium/rrd

echo -e "<VirtualHost *>" >> /etc/httpd/conf.d/observium.conf
echo -e "DocumentRoot /opt/observium/html/" >> /etc/httpd/conf.d/observium.conf
echo -e "   CustomLog /opt/observium/logs/access_log combined" >> /etc/httpd/conf.d/observium.conf
echo -e "   ErrorLog /opt/observium/logs/error_log" >> /etc/httpd/conf.d/observium.conf
echo -e "   <Directory "/opt/observium/html/">" >> /etc/httpd/conf.d/observium.conf
echo -e "      AllowOverride All" >> /etc/httpd/conf.d/observium.conf
echo -e "      Options FollowSymLinks MultiViews" >> /etc/httpd/conf.d/observium.conf
echo -e "      Require all granted" >> /etc/httpd/conf.d/observium.conf
echo -e "   </Directory>" >> /etc/httpd/conf.d/observium.conf
echo -e "</VirutalHost>" >> /etc/httpd/conf.d/observium.conf

mkdir -p /opt/observium/logs
chown apache:apache /opt/observium/logs
./opt/observium.adduser.php admin admin 10

systemctl restart httpd
systemctl enable httpd
echo -e "${blue}[+]-install SNMP packets to cummunicate with server ! ${off}"
sleep 2
yum -y install net-snmp net-snmp-utils
systemctl enable snmpd
systemctl start snmpd

#--- activate SNMP tunel ----
firewall-cmd --permanent --zone=public --add-service=snmp
firewall-cmd --reload


php /opt/observium/discovery.php -h all
php /opt/observium/poller.php -h all

systemctl reload crond

}

function debian() {

echo -e "${yellow}[+]-Installing Packets ..${off}"
apt-get update -y
apt-get upgrade -y

apt-get install snmp fping python-mysqldb rrdtool subversion whois mtr-tiny ipmitool graphviz imagemagick -y
echo -e "${yellow}[+]-Installing LAMP SERVER ..${off}"
apt-get install apache2 libapache2-mod-php7.0 -y

systemctl start apache2
systemctl enable apache2

apt-get install php7.0 php7.0-cli php7.0-mysql php7.0-mysqli php7.0-gd php7.0-mcrypt php7.0-json php-pear -y
apt-get install mariadb-server -y

systemctl start mysql
systemctl enable mysql

mysql_secure_installation$

mysql -u root -p

echo -e "${red}[+]-Creating Obseervium DATABASE ${off}"
sleep 2 





echo -e "${blue}[+]-dowwnloading OBSERVIUM .. ${off}"
wget http://www.observium.org/observium-community-latest.tar.gz

echo -e "${blue}[+]-Instaling .. ${off}"
tar -xvzf observium-community-latest.tar.gz
cp -ar observium /var/www/html/
cd /var/www/html/observium
cp config.php.default config.php

./discovery.php -u
mkdir rrd logs
chown -R www-data:www-data /var/www/html/observium
echo -e "    <VirtualHost *:80>" >>/etc/apache2/sites-available/observium.conf
echo -e "     ServerAdmin admin@example.com" >>/etc/apache2/sites-available/observium.conf
echo -e "     ServerName example.com" >>/etc/apache2/sites-available/observium.conf
echo -e "    DocumentRoot /var/www/html/observium/html" >>/etc/apache2/sites-available/observium.conf
echo -e "    <Directory />" >>/etc/apache2/sites-available/observium.conf
echo -e "     Options FollowSymLinks" >>/etc/apache2/sites-available/observium.conf
echo -e "     AllowOverride None" >>/etc/apache2/sites-available/observium.conf
echo -e "    </Directory>" >>/etc/apache2/sites-available/observium.conf
echo -e "    <Directory /var/www/html/observium/html/>" >>/etc/apache2/sites-available/observium.conf
echo -e "     Options Indexes FollowSymLinks MultiViews" >>/etc/apache2/sites-available/observium.conf
echo -e "     AllowOverride All" >>/etc/apache2/sites-available/observium.conf
echo -e "     Require all granted" >>/etc/apache2/sites-available/observium.conf
echo -e "    </Directory>" >>/etc/apache2/sites-available/observium.conf
echo -e "     ErrorLog  /var/log/apache2/error.log" >>/etc/apache2/sites-available/observium.conf
echo -e "     LogLevel warn" >>/etc/apache2/sites-available/observium.conf
echo -e "     CustomLog  /var/log/apache2/access.log combined" >>/etc/apache2/sites-available/observium.conf
echo -e "     ServerSignature On" >>/etc/apache2/sites-available/observium.conf
echo -e "    </VirtualHost>" >>/etc/apache2/sites-available/observium.conf

a2ensite observium
a2dissite 000-default

a2enmod rewrite
phpenmod mcrypt

systemctl restart apache2
echo -e "${blue}[+]-Creation user admin .. ${off}"
sleep 3
/var/www/html/observium/adduser.php admin yourpassword 10
apt-get install ufw -y
ufw enable
ufw allow 80
systemctl restart cron
}

function banner() {
echo -e "${yellow}"
cat banner.txt
echo -e "${off}"

}

#-------------------------------------------------------- MAIN --------------------------------------------------------------------


while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`

    case $PARAM in
     -h | --help)
        banner
     echo -e "${blue}+------------------------------------------------------------------------------------+${off}
-h  | --help :${blue} Help menu.${off}
-d  | --debian-installer:${blue} Install observium in debian systems.${off}
-r  | --redhat-installer:${blue} red hat distribution .${off}

${blue}+------------------------------------------------------------------------------------+${off}
"   exit
    ;;

     -d | --debian-installer)
     banner
     debian
     ;;

     -r | --redhat-installer)
     banner
     redhat
     ;;
        *)
            echo -e "${red}[-]- ERROR: unknown parameter \"$PARAM\" ${off}"
         
            exit 1
            ;;
    esac
    shift
done
