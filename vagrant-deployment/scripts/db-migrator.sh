#!/bin/sh

# This funtions check if an application is avaliable in the enviroment
# and install it if it is not in the enviroment
function checkAndInstall(){
   if ! which $1 > /dev/null; then
      sudo apt install -y $1
   fi
}

# Set debug to look the every command executed in the script
set -o xtrace

# Update machine packages
sudo apt update 
sudo apt upgrade -y

# Check if nginx is already installed
# if it are not installed it will be install
checkAndInstall mysql-client

mysql -u$DB_USER -h$DB_HOST -p$DB_PASS < ~/movie-analyst-api/data_model/table_creation_and_inserts.sql

# Unset debug to look the every command executed in the script
set +o xtrace