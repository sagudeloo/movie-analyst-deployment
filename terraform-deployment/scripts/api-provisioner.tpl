#!/bin/bash

export PROJECT_REPO="${project_repo}"
export PORT="${port}"
export DB_HOST="${db_host}"
export DB_NAME="${db_name}"
export DB_USER="${db_user}"
export DB_PASS="${db_pass}"
export HOME=~/

# Set debug to look the every command executed in the script
set -o xtrace

PROJECT_NAME=$(basename $PROJECT_REPO '.git')

# Update machine packages
apt update 
apt upgrade -y

# Check if nodejs is already installed
# if it are not installed it will be install

if ! which nodejs > /dev/null; then
   apt install -y nodejs
fi

# Check if npm is already installed
# if it are not installed it will be install
if ! which npm > /dev/null; then
   apt install -y npm
fi

# # Check if nginx is already installed
# # if it are not installed it will be install
# if ! which nginx > /dev/null; then
#    apt install -y nginx
# fi

# Check if git is already installed
# if it are not installed it will be install
if ! which git > /dev/null; then
   apt install -y git
fi

# Clone de application repositories
git clone $PROJECT_REPO ~/$PROJECT_NAME || (git pull origin master ~/$PROJECT_NAME)

# Installing the application dependencies
npm install ~/$PROJECT_NAME

# # Nginx configuration
# if ! cmp --silent ~/nginx-config/default /etc/nginx/sites-available/default ; then
#    mv -f ~/nginx-config/default /etc/nginx/sites-available/
# fi

# # Start up or reload nginx
# if systemctl is-active --quiet nginx ; then
#    systemctl reload nginx
# else
#    systemctl enable --now nginx
# fi

# Install and setup pm2 in global enviroment
npm list -g pm2 || npm install -g pm2@latest
pm2 update
ls /etc/systemd/system/pm2-root.service || pm2 startup

# Start the application 
pm2 start ~/$PROJECT_NAME/server.js --name $PROJECT_NAME || echo "Application already running."
pm2 save

# Unset debug to look the every command executed in the script
set +o xtrace