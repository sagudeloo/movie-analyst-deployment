#/bin/sh

# Set debug to look the every command executed in the script
set -o xtrace

# Update machine packages
sudo apt update
sudo apt upgrade -y

# Check if mysql server is already installed
# if it are not installed it will be install
if ! which mysql-server > /dev/null; then
   # configure the mysql root password before de instalation
   echo "mysql-server mysql-server/root_password password $MYSQL_PASSWORD" | sudo debconf-set-selections
   echo "mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD" | sudo debconf-set-selections
   sudo apt install -y mysql-server mysql-client
fi

sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/# port/port/g' /etc/mysql/mysql.conf.d/mysqld.cnf

mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
mysql -uroot -p$MYSQL_PASSWORD -e "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;"
mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'; FLUSH PRIVILEGES;"

sudo /etc/init.d/mysql force-reload

# Unset debug to look the every command executed in the script
set +o xtrace