#/bin/sh

# This funtions check if an application is avaliable in the enviroment
# and install it if it is not in the enviroment
function checkAndInstall(){
   if ! which $1 > /dev/null; then
      sudo apt install $1 -y
   fi
}

# Set debug to look the every command executed in the script
set -o xtrace

PROJECT_NAME=$(basename $PROJECT_REPO '.git')

# Update machine packages
sudo apt update 
sudo apt upgrade -y

# Check if nodejs is already installed
# if it are not installed it will be install
checkAndInstall nodejs

# Check if npm is already installed
# if it are not installed it will be install
checkAndInstall npm

# Check if nginx is already installed
# if it are not installed it will be install
checkAndInstall nginx

# Check if git is already installed
# if it are not installed it will be install
checkAndInstall git

# Clone de application repositories
git clone $PROJECT_REPO || (git pull origin master ~/$PROJECT_NAME)

# Installing the application dependencies
cd ~/$PROJECT_NAME
npm install
cd

# Nginx configuration
if ! cmp --silent ~/nginx-config/default /etc/nginx/sites-available/default ; then
   sudo mv -f ~/nginx-config/default /etc/nginx/sites-available/
fi

# Start up or reload nginx
if sudo systemctl is-active --quiet nginx ; then
   sudo systemctl reload nginx
else
   sudo systemctl enable --now nginx
fi

# Install and setup pm2 in global enviroment
sudo npm list -g pm2 || sudo npm install -g pm2@latest
pm2 update
ls /etc/systemd/system/pm2-vagrant.service || sudo env PATH=$PATH:/usr/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u vagrant --hp /home/vagrant

# Start the application 
cd ~/$PROJECT_NAME
pm2 start server.js --name $PROJECT_NAME || echo "Application already running."
pm2 save

# Unset debug to look the every command executed in the script
set +o xtrace