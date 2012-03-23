#!/bin/bash
unalias cp
useradd -g users -G wheel new_user
passwd new_user

cat /etc/sysconfig/network-scripts/ifcfg-eth0 | sed 's/ONBOOT="no"/ONBOOT="yes"/' > /dev/shm/ifcfg-eth0
echo 'BOOTPROTO=none
IPADDR=0.0.0.0
NETMASK=0.0.0.0
TYPE=Ethernet
GATEWAY=0.0.0.0
DNS1=0.0.0.0
DNS2=0.0.0.0'>>/dev/shm/ifcfg-eth0
cp /dev/shm/ifcfg-eth0 /etc/sysconfig/network-scripts/ -f
/etc/init.d/network restart

# iptables setting
iptables -F INPUT
iptables -F OUTPUT
iptables -F FORWARD
/etc/init.d/iptables save
cat /etc/sysconfig/iptables             |
sed 's/:OUTPUT.*$/&\n:SERVICE - [0:0]/' |
sed /COMMIT/d | sed /^#/d > /dev/shm/iptables
echo '
-A SERVICE -p tcp --dport 22 -j ACCEPT
-A SERVICE -p tcp --dport 80 -j ACCEPT
-A SERVICE -p tcp --dport 443 -j ACCEPT
-A SERVICE -p tcp --dport 465 -j ACCEPT
-A SERVICE -p tcp --dport 995 -j ACCEPT
-A SERVICE -p tcp --dport 3306 -j ACCEPT' >> /dev/shm/iptables
echo COMMIT >> /dev/shm/iptables
cp /dev/shm/iptables /etc/sysconfig
/etc/init.d/iptables restart

yum -y update

yum -y install httpd mysql-server ntp bind-utils vim-enhanced openssh-clients wget 

chkconfig httpd on
chkconfig mysqld on
chkconfig ntpd on

# ntpd setup
cat /etc/ntp.conf | sed 's/^server.*ntp.org/#&/g' > /dev/shm/ntp.conf
echo 'server ntp1.jst.mfeed.ad.jp
server ntp2.jst.mfeed.ad.jp
server ntp3.jst.mfeed.ad.jp' >> /dev/shm/ntp.conf
cp /dev/shm/ntp.conf /etc/
/etc/init.d/ntpd start

# mysql setup
/etc/init.d/mysqld start
mysql_secure_installation

cd /dev/shm
wget http://dag.wieers.com/rpm/packages/RPM-GPG-KEY.dag.txt
rpm --import RPM-GPG-KEY.dag.txt
echo '[rpmforge]
name=RPMforge RPM Repository for Red Hat Enterprise Linux
baseurl=http://ftp.riken.jp/Linux/dag/redhat/el6/en/$basearch/rpmforge/
gpgcheck=1
enabled=0' > /etc/yum.repos.d/rpmforge.repo

wget http://ftp.riken.jp/Linux/fedora/epel/RPM-GPG-KEY-EPEL-6
rpm --import RPM-GPG-KEY-EPEL-6
echo '[epel]
name=EPEL RPM Repository for Red Hat Enterprise Linux
baseurl=http://ftp.riken.jp/Linux/fedora/epel/6/$basearch/
gpgcheck=1
enabled=0' > /etc/yum.repos.d/epel.rep

yum -y install phpMyAdmin munin munin-node --enablerepo=epel

shutdown -r now