#!/usr/bin/env bash

if [ $(id -u) != '0' ]; then
  echo "You must run $0 as root!"
  exit 1
fi

cat << HOSTS_FILE >> /etc/hosts
192.168.33.10 node1 A
192.168.33.20 node2 B
192.168.33.30 node3 C
192.168.33.100 failover_ip Z
HOSTS_FILE

wget http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
yum -y localinstall mysql-community-release-el7-5.noarch.rpm
yum -y install mysql-server mysql

sudo sed -i "s/\[mysqld\]/\[mysqld\]\ngtid_mode=ON/" /etc/my.cnf
sudo sed -i "s/\[mysqld\]/\[mysqld\]\nenforce-gtid = 1/" /etc/my.cnf
sudo sed -i "s/\[mysqld\]/\[mysqld\]\nlog-bin/" /etc/my.cnf
sudo sed -i "s/\[mysqld\]/\[mysqld\]\nlog-slave-updates/" /etc/my.cnf
sudo sed -i "s/\[mysqld\]/\[mysqld\]\nbind-address = 0.0.0.0/" /etc/my.cnf
if [ "$2" = "slave" ]; then
  sudo sed -i "s/\[mysqld\]/\[mysqld\]\nmaster-info-repository=TABLE/" /etc/my.cnf
fi
sudo sed -i "s/\[mysqld\]/\[mysqld\]\nserver_id=$3/" /etc/my.cnf

sudo sed -i 's/= 127.0.0.1/= 0.0.0.0/' /etc/my.cnf

service mysqld start
# http://planet.mysql.com/entry/?id=5989175
mysqladmin -u root password password
mysql -uroot -ppassword -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION ;"

if [ "$2" = "slave" ]; then
  mysql -uroot -ppassword -e "CHANGE MASTER TO MASTER_HOST = '192.168.33.10',  MASTER_PORT = 3306, MASTER_USER = 'root', MASTER_PASSWORD = 'password',  MASTER_AUTO_POSITION = 1;"
  mysql -uroot -ppassword -e "START SLAVE;"
fi




if [ "$2" = "controller" ]; then
  yum -y install mysql-utilities
  mysqlfailover --master=root:password@192.168.33.10:3306 --slaves=root:password@192.168.33.20:3306,root:password@192.168.33.30:3306 --log=log.txt --daemon=start
fi
