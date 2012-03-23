#!/bin/bash

# $id: server_initialize.sh
# @author bis5 <bis5@bis5.mydns.jp>
# @since 2012.2.29
# @target RHEL6.x and RHEL6.x like distributions (centos, fedora, etc...)

# init valiables
TMP=/dev/shm/init
mkdir $TMP
SUPPRESS="Auto Installation Success! You may do these action:"

# yum repository
cd /etc/yum.repos.d
echo '[epel]
name=EPEL RPM Repository for Red Hat Enterprize Linux
baseurl=http://ftp.riken.jp/Linux/fedora/epel/6/$basearch/
gpgcheck=1
enabled=0' > ./epel.repo
echo '[rpmforge]
name=RPMForge RPM Repository for Red Hat Enterprize Linux
baseurl=http://ftp.riken.jp/Linux/dag/redhat/el6/en/$basearch/rpmforge/
gpgcheck=1
enabled=0' > ./rpmforge.repo
cd $TMP
wget http://dag.wieers.com/rpm/packages/RPM-GPG-KEY.dag.txt
rpm --import RPM-GPG-KEY.dag.txt
wget http://ftp.riken.jp/Linux/fedora/rprl/RPM-GPG-KEY-EPEL-6
rpm --import RPM-GPG-KEY-EPEL-6

# network interface(eth0) as dhcp
if [ -f /etc/sysconfig/network-scripts/ifcfg-eth0 ]; then
FILE=`cat /etc/sysconfig/network-scripts/ifcfg-eth0|sed "s/ONBOOT=no/ONBOOT=yes/"`
else
FILE='DEVICE=eth0
ONBOOT=yes'
fi
echo $FILE > /etc/sysconfig/network-scripts/ifcfg-eth0
echo "BOOTPROTO=dhcp" >> /etc/sysconfig/network-scripts/ifcfg-eth0
/etc/rc.d/init.d/network restart
chkconfig network on

# update all
yum -y update

# vim setting
yum -y install vim-enhanced
echo "alias vi='/usr/bin/vim'" >> /etc/profile

# ntp server
yum -y install ntp
/etc/rc.d/init.d/ntpd start
chkconfig ntpd on

# ssh server
FILE=`cat /etc/ssh/sshd_config | sed "s/\#PermitRootLogin no/PermitRootLogin no/"`
echo $FILE > /etc/ssh/sshd_config
/etc/rc.d/init.d/sshd start
chkconfig sshd on

# php, mysql(install only)
yum -y install php php-mbstring php-pear mysql-server
/etc/rc.d/init.d/mysqld start
chkconfig mysqld on
echo "Please Update Root User Password for MySQL Server !" >&2

# phpmyadmin fro epel
yum -y --enablerepo=epel phpMyAdmin php-mysql php-mcrypt

# apache httpd
yum -y install httpd mod_ssl
/etc/rc.d/init.d/httpd start
chkconfig httpd on
SUPPRESS="$SUPPRESS\n* Update Apache HTTPD configuration"

# Ruby Version Manager
bash -s stable < <(curl -s https://raw.github.com/waynesseguin/rvm/master/binscripts/rvm-installer)
source ~/.bash_profile
yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel
rvm install 1.9.3
rvm default 1.9.3
rvm use 1.9.3
gem install passenger
yum install -y libcurl-devel httpd-devel
passenger-install-apache2-module
RUBY=`ls -d /usr/local/rvm/gems/ruby-*|sed /global/d`
PASSENGER="$RUBY/gems/"`ls "$RUBY/gems/"|grep passenger`
echo "LoadModule passenger_module $PASSENGER/ext/apache2/mod_passenger.so
PassengerRoot $PASSENGER
PassengerRuby `ls -d /usr/local/rvm/wrappers/ruby-*|sed /global/d`/ruby">/etc/httpd/conf.d/passenger.conf
service httpd reload
SUPPRESS="$SUPPRESS\n* Check passenger_module setting"

# version management
yum -y install subversion git-all mercurial 

# munin
yum -y --enablerepo=epel munin munin-node
chkconfig munin-node on
SUPPRESS="$SUPPRESS\n* Check munin configuration"

# finish message
echo $SUPPRESS
echo "\nIf finished your all jobs, please restart this server!"

# clean up
cd
rm -rf $TMP
