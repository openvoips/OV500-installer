#Mysql Configuraition 
OV500_DATABASE_NAME="switch"
OV500_DB_USER="ovswitch"
DATETIME=$(date '+%Y%m%d%H%M%S')


#Generate random password
genpasswd() {
	length=$1
	digits=({1..9})
	lower=({a..z})
	upper=({A..Z})
	CharArray=(${digits[*]} ${lower[*]} ${upper[*]})
	ArrayLength=${#CharArray[*]}
	password=""
	for i in `seq 1 $length`
	do
	        index=$(($RANDOM%$ArrayLength))
	        char=${CharArray[$index]}
	        password=${password}${char}
	done
	echo $password
}

OV500USER_MYSQL_PASSWORD=`echo "$(genpasswd 20)" | sed s/./*/5`
#Fetch OS Distribution
get_linux_distribution (){ 
	V1=`cat /etc/*release | head -n1 | tail -n1 | cut -c 14- | cut -c1-18`
	V2=`cat /etc/*release | head -n7 | tail -n1 | cut -c 14- | cut -c1-14`
	if [[ $V1 = "Debian GNU/Linux 9" ]]; then
			DIST="DEBIAN"
			echo -e 'Ooops!!! Quick Installation does not support your distribution \nPlease use manual steps or contact OV500 Sales Team \nat openvoips@gmail.com.'
			exit 1
	else if [[ $V2 = "CentOS Linux 7" ]]; then
			DIST="CENTOS"
			yum install net-tools -y	
			
			clear   
			SERVERIPADDRESS=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
			echo "***"			
			echo "This server timezone is configured in IST Asia/Kolkata"
			echo "You server IP address is "
			echo $SERVERIPADDRESS
			echo "*** The IP is correct - [YES/NO]"
			echo "*** " 
			 
			read ACCEPT                
			  if [ "$ACCEPT" != "yes" ] && [ "$ACCEPT" != "Yes" ] && [ "$ACCEPT" != "YES" ]; then
					while [ "$ACCEPT" != "yes" ] && [ "$ACCEPT" != "Yes" ] && [ "$ACCEPT" != "YES" ] && [ "$ACCEPT" != "no" ] && [ "$ACCEPT" != "No" ] && [ "$ACCEPT" != "NO" ]; do
						echo "Enter the server IP address  "
						read SERVERIPADDRESS
						echo "You server IP address is "
						echo $SERVERIPADDRESS
						echo "*** The IP is correct - [YES/NO]"
						echo "*** "
						read ACCEPT
					done

					while [ "$ACCEPT" != "yes" ] && [ "$ACCEPT" != "Yes" ] && [ "$ACCEPT" != "YES" ]; do
						echo "Enter the server IP address  "
						read SERVERIPADDRESS
						echo "You server IP address is "
						echo $SERVERIPADDRESS
						echo "*** The IP is correct - [YES/NO]"
						echo "*** "
						read ACCEPT
					done
					
			else
					echo "Hey!!! Good"
     					 

			fi
			
		else
			DIST="OTHER"
			echo -e 'Ooops!!! Quick Installation does not support your distribution \nPlease use manual steps or contact OV500 Sales Team \nat openvoips@gmail.com.'
			exit 1
		fi
	fi
}

#Install Prerequisties
install_prerequisties (){

echo "This is Install Prerequisties "

	if [ $DIST = "CENTOS" ]; then
			setenforce 0
			rm -rf /etc/localtime
			ln -s /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
			yum groupinstall "Development tools" -y

			#Enable epel and freeswitch repository
			yum install epel-release  -y
			#rpm -Uvh http://files.freeswitch.org/freeswitch-release-1-6.noarch.rpm


			yum update -y
			yum install -y wget curl git bind-utils ntpdate systemd net-tools whois sendmail sendmail-cf mlocate iptables-devel net-snmp-devel iptables*

			yum install -y wget curl git bind-utils ntpdate systemd net-tools whois sendmail sendmail-cf mlocate vim


			yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
			yum -y install epel-release yum-utils
			yum-config-manager --disable remi-php54
			yum-config-manager --enable remi-php73
			yum install -y php php-fpm php-mysql php-cli php-json php-readline php-xml php-curl php-gd php-json php-mbstring php-mysql php-opcache php-pdo

			yum install -y kernel-devel kernel-headers libunistring-devel flex gcc hiredis-* libevent* *pcap* json-glib glib* glib2 glib2-devel xmlrpc-c-devel gcc-c++ alsa-lib-devel autoconf automake bison broadvoice-devel bzip2 curl-devel  libdb4-devel e2fsprogs-devel erlang flite-devel g722_1-devel gdbm-devel gnutls-devel ilbc2-devel ldns-devel libcodec2-devel libcurl-devel libedit-devel libidn-devel libjpeg-devel libmemcached-devel libogg-devel libsilk-devel libsndfile-devel libtheora-devel libtool libvorbis-devel libxml2-devel lzo-devel mongo-c-driver-devel ncurses ncurses-devel openssl-devel opus-devel pcre-devel perl perl-ExtUtils-Embed pkgconfig portaudio-devel python-devel soundtouch-devel speex-devel sqlite sqlite-devel unbound-devel unixODBC unixODBC-devel libuuid-devel which zlib-devel ImageMagick ImageMagick-devel iftop htop tcpdump ngrep psmisc readline* lua lua-devel  postgresql-devel yasm nor nasm

			yum install -y luarocks && luarocks install lua-cjson
			yum -y install python-devel json-devel json-c-devel
			yum update -y

			yum -y install mariadb mariadb-devel mariadb-server

			yum install -y httpd libxml2 libxml2-devel openssl openssl-devel gettext-devel fileutils php php-zip pxp-xml
			
			systemctl start httpd
			systemctl enable httpd
			systemctl start php-fpm
			systemctl enable php-fpm
			systemctl stop firewalld
			systemctl disable firewalld
			systemctl enable iptables
			systemctl start iptables
        fi
}

#Download OV500 Source
get_ov500_source (){
	rm -rf /usr/local/src/OV500
        cd /usr/local/src
        git clone -b master https://github.com/openvoips/OV500.git
}

#Download Freeswitch Source and installation with dependency 
install_freeswitch(){

    yum -y install http://repo.okay.com.mx/centos/7/x86_64/release/okay-release-1-1.noarch.rpm
    yum -y install http://www.nosuchhost.net/~cheese/fedora/packages/epel-7/x86_64/cheese-release-7-1.noarch.rpm
	sed -i "s#gpgcheck=1#gpgcheck=0#g" /etc/yum.repos.d/okay.repo
	yum install -y git alsa-lib-devel autoconf automake bison broadvoice-devel bzip2 curl-devel db-devel e2fsprogs-devel flite-devel g722_1-devel gcc-c++ gdbm-devel gnutls-devel ilbc2-devel ldns-devel libcodec2-devel libcurl-devel libedit-devel libidn-devel libjpeg-devel libmemcached-devel libogg-devel libsilk-devel libsndfile-devel libtheora-devel libtiff-devel libtool libuuid-devel libvorbis-devel libxml2-devel lua-devel lzo-devel mongo-c-driver-devel ncurses-devel net-snmp-devel openssl-devel opus-devel pcre-devel perl perl-ExtUtils-Embed pkgconfig portaudio-devel postgresql-devel python26-devel python-devel soundtouch-devel speex-devel sqlite-devel unbound-devel unixODBC-devel wget which yasm zlib-devel libks libks-devel signalwire-client-c signalwire-client-c-level
	yum install -y spandsp spandsp-devel
	yum install -y sofia-sip
	yum install -y sofia-sip-devel
	yum install -y libavformat-devel libswscale-devel ffmpeg
	cd /usr/local/src 
	wget https://files.freeswitch.org/releases/freeswitch/freeswitch-1.8.1.tar.bz2
	tar -xvjf freeswitch-1.8.1.tar.bz2
	mv /usr/local/src/freeswitch-1.8.1  /usr/local/src/freeswitch
	cd /usr/local/src/freeswitch
	
	./bootstrap.sh -j
	
	echo 'applications/mod_commands
applications/mod_conference
applications/mod_callcenter
applications/mod_curl 
applications/mod_db 
applications/mod_dptools 
applications/mod_enum
applications/mod_esf 
applications/mod_expr
applications/mod_fifo 
applications/mod_fsv
applications/mod_hash 
applications/mod_httapi 
applications/mod_sms 
applications/mod_spandsp 
applications/mod_test 
applications/mod_valet_parking 
applications/mod_voicemail 
codecs/mod_amr 
codecs/mod_b64 
codecs/mod_g723_1
codecs/mod_g729
codecs/mod_h26x 
 
dialplans/mod_dialplan_asterisk 
dialplans/mod_dialplan_xml 
endpoints/mod_loopback 
endpoints/mod_rtc 
endpoints/mod_skinny
endpoints/mod_sofia
endpoints/mod_verto 
event_handlers/mod_cdr_csv
event_handlers/mod_json_cdr 
event_handlers/mod_cdr_sqlite 
event_handlers/mod_event_socket 
formats/mod_local_stream
formats/mod_native_file
formats/mod_png
#formats/mod_shout
formats/mod_sndfile 
formats/mod_tone_stream 
languages/mod_lua 
#languages/mod_v8 
loggers/mod_console 
loggers/mod_logfile
loggers/mod_syslog 
say/mod_say_en
xml_int/mod_xml_cdr
xml_int/mod_xml_curl
xml_int/mod_xml_rpc
xml_int/mod_xml_scgi
#mod_freetdm|https://github.com/freeswitch/freetdm.git -b master
#../../contrib/mod/xml_int/mod_xml_odbc'>/usr/local/src/freeswitch/modules.conf


	sed -i "s#\#xml_int/mod_xml_curl#xml_int/mod_xml_curl#g" /usr/local/src/freeswitch/modules.conf
	sed -i "s#\#applications/mod_curl#applications/mod_curl#g" /usr/local/src/freeswitch/modules.conf
	sed -i "s#\#event_handlers/mod_json_cdr#event_handlers/mod_json_cdr#g" /usr/local/src/freeswitch/modules.conf
	sed -i "s#\#applications/mod_voicemail#applications/mod_voicemail#g" /usr/local/src/freeswitch/modules.conf
 
	# Compile the Source
	./configure -C --prefix=/home/OV500
	# Install Freeswitch with sound files		
	make all install cd-sounds-install cd-moh-install
	make && make install
	# Create symbolic links for Freeswitch executables
	rm -rf /usr/local/bin/freeswitch
	rm -rf /usr/local/bin/fs_cli
	ln -s /home/OV500/bin/freeswitch /usr/local/bin/freeswitch
	ln -s /home/OV500/freeswitch/bin/fs_cli /usr/local/bin/fs_cli		

} 

#Download kamailio Source and installation with dependency including rtpproxy
install_kamailio_rtpproxy(){

	yum install -y libxml2 libxml2-devel openssl openssl-devel gettext-devel fileutils rtpproxy  jansson* python python-devel

	cd /usr/local/src/
	rm -rf /usr/local/src/kamailio
	wget https://www.kamailio.org/pub/kamailio/4.4.6/src/kamailio-4.4.6_src.tar.gz
	tar -xf kamailio-4.4.6_src.tar.gz
	mv kamailio-4.4.6 kamailio

	cd /usr/local/src/kamailio
	make include_modules="db_mysql dialplan dispatcher exec" exclude_modules="python acc_radius app_java app_lua app_mono app_perl app_python auth_ephemeral auth_identity auth_radius carrierroute cdp cdp_avp cnxcc cpl-c crypto db2_ldap db_berkeley db_cassandra db_mongodb db_oracle db_perlvdb db_postgres db_sqlite db_unixodbc dialplan dnssec erlang evapi geoip geoip2 gzcompress h350 http_async_client ims_auth ims_charging ims_dialog ims_icscf ims_isc ims_qos ims_registrar_pcscf ims_registrar_scscf ims_usrloc_pcscf ims_usrloc_scscf iptrtpproxy jansson janssonrpc-c json jsonrpc-c kazoo lcr ldap log_systemd memcached mi_xmlrpc misc_radius ndb_cassandra ndb_mongodb ndb_redis osp outbound peering purple regex rls sctp snmpstats xhttp_pi xmlops xmlrpc xmpp" cfg prefix="/home/OV500/LB"
	make
	make install

}

#OV500 GUI installation with HTTPD Webserver
install_gui (){

	cd /usr/local/src/OV500
	date=$(date '+%Y%m%d%H%M%S')
	mv /home/OV500/portal /home/OV500/portal$DATETIME
	cp -rf /usr/local/src/OV500/portal /home/OV500/
	
	sed -i "s/;request_terminate_timeout = 0/request_terminate_timeout = 300/" /etc/php-fpm.d/www.conf
	sed -i "s#short_open_tag = Off#short_open_tag = On#g" /etc/php.ini
	sed -i "s#;cgi.fix_pathinfo=1#cgi.fix_pathinfo=1#g" /etc/php.ini
	sed -i "s/max_execution_time = 30/max_execution_time = 3000/" /etc/php.ini
	sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 20M/" /etc/php.ini
	sed -i "s/post_max_size = 8M/post_max_size = 20M/" /etc/php.ini
	sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini
	systemctl restart php-fpm
	systemctl restart httpd

	rm -rf /home/OV500/portal/application/config/database.php

	echo "<?php
	defined('BASEPATH') OR exit('No direct script access allowed');
	\$active_group = 'default';
	\$query_builder = TRUE;
	\$db['default'] = array( 
	'dsn' => 'mysql:host=localhost;dbname=switch',
	'hostname' => '', 
	'username' => 'ovswitch', 
	'password' => '${OV500USER_MYSQL_PASSWORD}', 
	'database' => '', 
	'dbdriver' => 'pdo', 
	'dbprefix' => '', 
	'pconnect' => TRUE, 
	'db_debug' => TRUE, 
	'cache_on' => FALSE, 
	'cachedir' => '', 
	'char_set' => 'utf8', 
	'dbcollat' => 'utf8_general_ci',
	'swap_pre' => '', 
	'encrypt' => FALSE, 
	'compress' => FALSE, 
	'stricton' => FALSE, 
	'failover' => array() 
	);
	\$db['cdrdb'] = array(
	'dsn' => 'mysql:host=localhost;dbname=switchcdr',
	'hostname' => '',
	'username' => 'ovswitch', 
	'password' => '${OV500USER_MYSQL_PASSWORD}',
	'database' => '',
	'dbdriver' => 'pdo',
	'dbprefix' => '',
	'pconnect' => FALSE,
	'db_debug' => FALSE,
	'cache_on' => FALSE,
	'cachedir' => '',
	'char_set' => 'utf8',
	'dbcollat' => 'utf8_general_ci',
	'swap_pre' => '',
	'encrypt' => FALSE,
	'compress' => FALSE,
	'stricton' => FALSE,
	'failover' => array(),
	'save_queries' => TRUE
	);">/home/OV500/portal/application/config/database.php

	rm -rf /home/OV500/portal/api/config.php

	echo "<?php
	error_reporting(0);
	ini_set('memory_limit', '1024M');
	date_default_timezone_set('Asia/Kolkata');
	define('CDR_DSN', 'mysql:dbname=switchcdr;host=localhost');
	define('CDR_DSN_LOGIN', 'ovswitch');
	define('CDR_DSN_PASSWORD','${OV500USER_MYSQL_PASSWORD}');
	define('SWITCH_DSN', 'mysql:dbname=switch;host=localhost');
	define('SWITCH_DSN_LOGIN', 'ovswitch', );
	define('SWITCH_DSN_PASSWORD','${OV500USER_MYSQL_PASSWORD}');
	define('LOGPATH', 'log/');
	define('LOGWRITE', '0');
	define('DBLOGWRITE', '1');">/home/OV500/portal/api/config.php
	ln -s /home/OV500/portal /var/www/html/portal
	chown -Rf apache.apache /var/www/html/portal
	chown -Rf apache.apache /home/OV500/portal

}
#Dataabase SQL installation
install_db(){
echo "This is install_db "
echo '[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
# Settings user and group are ignored when systemd is used.
# If you need to run mysqld under a different user or group,
# customize your systemd unit file for mariadb according to the
# instructions in http://fedoraproject.org/wiki/Systemd




symbolic-links=0
sql_mode=''
port = 3306

innodb_file_per_table

key-buffer-size                = 248M
myisam-recover                 = FORCE,BACKUP
# SAFETY #
max-allowed-packet             = 248M
max-connect-errors             = 10000
skip-name-resolve
event_scheduler                = 1
# CACHES AND LIMITS #
tmp-table-size                 = 124M
max-heap-table-size            = 124M
query-cache-type               = 0
query-cache-size               = 0
max-connections                = 10000
thread-cache-size              = 248
open-files-limit               = 65535
table-definition-cache         = 4096
table-open-cache               = 500
 
innodb-flush-method            = O_DIRECT
innodb-log-files-in-group      = 2
 
innodb-flush-log-at-trx-commit = 0
innodb-file-per-table          = 1
innodb-buffer-pool-size        = 2G
innodb_stats_on_metadata = OFF




skip-networking=0
skip-bind-address

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d'>/etc/my.cnf



service mariadb restart 

	mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'ovswitch'@'localhost' IDENTIFIED BY '${OV500USER_MYSQL_PASSWORD}'"; 
	mysqladmin create switch
	mysqladmin create switchcdr
	mysqladmin create kamailio
	mysql  switch < /usr/local/src/OV500/config/database/switch.sql
	mysql  switchcdr < /usr/local/src/OV500/config/database/switchcdr.sql
	mysql  kamailio < /usr/local/src/OV500/config/database/kamailio.sql
}

#install SNGREP
install_sngrep(){
	echo '[irontec]
name=Irontec RPMs repository
baseurl=http://packages.irontec.com/centos/$releasever/$basearch/'>/etc/yum.repos.d/sngrep.repo
rpm --import http://packages.irontec.com/public.key
	yum install sngrep -y
}

#OV500 configuration
install_ov500_config(){

	mv  /home/OV500/LB/etc/kamailio  /home/OV500/LB/etc/kamailio$DATETIME
	cp -rf /usr/local/src/OV500/config/kamailio /home/OV500/LB/etc/
	
	sed -i 's/OV500LBIP/'$SERVERIPADDRESS'/g' /home/OV500/LB/etc/kamailio/kamailio.cfg


	sed -i 's/ovswitch123/'$OV500USER_MYSQL_PASSWORD'/g' /home/OV500/LB/etc/kamailio/kamailio.cfg

	sed -i 's/OV500FSIPADDRESS/'$SERVERIPADDRESS'/g' /home/OV500/LB/etc/kamailio/dispatcher.list
	
	cd /usr/local/src/OV500/config/freeswitch
	sed -i 's/LBSERVERIP/'$SERVERIPADDRESS'/g' /usr/local/src/OV500/config/freeswitch/autoload_configs/acl.conf.xml
	sed -i 's/OV500FSIPADDRESS/'$SERVERIPADDRESS'/g' /usr/local/src/OV500/config/freeswitch/vars.xml
	cp -rf autoload_configs/acl.conf.xml /home/OV500/etc/freeswitch/autoload_configs/acl.conf.xml
	cp -rf autoload_configs/lua.conf.xml /home/OV500/etc/freeswitch/autoload_configs/lua.conf.xml
	cp -rf autoload_configs/modules.conf.xml /home/OV500/etc/freeswitch/autoload_configs/modules.conf.xml
	cp -rf autoload_configs/switch.conf.xml /home/OV500/etc/freeswitch/autoload_configs/switch.conf.xml
	cp -rf autoload_configs/xml_cdr.conf.xml /home/OV500/etc/freeswitch/autoload_configs/xml_cdr.conf.xml
	cp -rf autoload_configs/xml_curl.conf.xml /home/OV500/etc/freeswitch/autoload_configs/xml_curl.conf.xml
	cp -rf vars.xml /home/OV500/etc/freeswitch/vars.xml
	cp -rf sip_profiles/internal.xml /home/OV500/etc/freeswitch/sip_profiles/internal.xml
	cp /usr/local/src/OV500/portal/api/lib/vm_user.lua /home/OV500/share/freeswitch/scripts/
	
	
	echo "[freeswitch]
Driver = MySQL
SERVER = localhost
PORT = 3306
DATABASE = switch
OPTION = 67108864
USER = ovswitch
PASSWORD = ${OV500USER_MYSQL_PASSWORD}
">/etc/odbc.conf


	echo "# sample configuration for iptables service
# you can edit this manually or use system-config-firewall
# please do not ask us to add additional ports/services to this default configuration
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT	 
-A INPUT -p udp -m udp --dport 5060:5061 -j ACCEPT
-A INPUT -p udp -m udp --dport 6000:65000 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10443 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10080 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
-A INPUT -j DROP
COMMIT">/etc/sysconfig/iptables

	service iptables restart

	echo '
<VirtualHost *:80>
	ServerAdmin demo@demo.com
	ServerName localhost
	DocumentRoot /var/www/html
	<Directory /var/www/html>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride All
		Require all granted
	</Directory>
	ErrorLog error.log
	CustomLog access.log combined
	RewriteEngine on
</VirtualHost>'>/etc/httpd/conf.d/ov.conf

	systemctl restart php-fpm
	systemctl restart httpd
	
	crontab -l > /home/OV500/cron_bkp
	echo "*/30  * * * *  /usr/bin/sh /home/OV500/xmlcdr.sh >/dev/null 2>&1
*/15 * * * *  /usr/bin/php  /var/www/html/portal/index.php Billing  quickservice >/dev/null 2>&1
1 4 * * * /usr/bin/php /var/www/html/portal/index.php Billing cron >/dev/null 2>&1" > /home/OV500/cron_bkp
	crontab /home/OV500/cron_bkp




echo '#!/usr/bin/sh
service iptables restart
service mariadb  restart
service php-fpm  restart
service httpd   restart
killall -9 /usr/bin/rtpproxy
/usr/bin/rtpproxy -L 100000 -u root -l  $SERVERIPADDRESS  -s udp:localhost:5899 -m 6000 -M 65000
killall -9 /home/OV500/LB/sbin/kamailio
/home/OV500/LB/sbin/kamailio
/home/OV500/bin/fs_cli -x "shutdown"
sleep 10
/home/OV500/bin/freeswitch -nc'> /home/OV500/ovservice.sh

chmod 777 /home/OV500/ovservice.sh
cp -rf /usr/local/src/OV500/config/xmlcdr.sh /home/OV500/

sh /home/OV500/ovservice.sh


}

#Installation Information Print
start_installation (){
	get_linux_distribution
	install_prerequisties
	get_ov500_source
	install_freeswitch
	install_kamailio_rtpproxy
	install_db
	install_gui
	install_ov500_config
	install_sngrep
	clear
	echo "******************************************************************************************"
	echo "******************************************************************************************"
	echo "******************************************************************************************"
	echo "**********                                                                      **********"
	echo "**********           Your OV500 is installed successfully                       **********"
	echo "                     Browse URL: http://${SERVERIPADDRESS}/portal"
	echo "                     Username: admin"     
	echo "                     Password: Ov500@786"	                                      
	echo ""
	echo "                     MySQL ovswitch password:"
	echo "                     ${OV500USER_MYSQL_PASSWORD}" 
	echo ""               
	echo "**********           IMPORTANT NOTE: Please reboot your server once.            **********"
	echo "**********                                                                      **********"
	echo "******************************************************************************************"
	echo "******************************************************************************************"
	echo "******************************************************************************************"

}

start_installation
