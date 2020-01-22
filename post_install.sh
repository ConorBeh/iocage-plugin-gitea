#!/bin/sh

# Enable service
sysrc gitea_enable=YES 2>/dev/null
sysrc mysql_enable=YES 2>/dev/null

# Start/stop service to generate configs
service gitea start 2>/dev/null
sleep 5
service gitea stop 2>/dev/null
sleep 5
service mysql-server start 2>/dev/null

# Remove default config to allow use of the web installer, set permissions
rm /usr/local/etc/gitea/conf/app.ini
chown -R git:git /usr/local/etc/gitea/conf
chown -R git:git /usr/local/share/gitea

# Set up MySQL database
# Set variables for username and database name
DB="gitea"
USER="gitea"

# Save the config values and generate a random password 
echo "$DB" > /root/dbname
echo "$USER" > /root/dbuser
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/dbpassword
PASS=`cat /root/dbpassword`

# Configure MySQL

mysql --protocol=socket -u root <<-EOF
CREATE DATABASE ${DB};
ALTER USER 'root'@'localhost' IDENTIFIED BY '${PASS}';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

#mysql -u root <<-EOF
#UPDATE mysql.user SET Password=PASSWORD('${PASS}') WHERE User='root';
#DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
#DELETE FROM mysql.user WHERE User='';
#DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
#CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${PASS}';
#GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'localhost' WITH GRANT OPTION;
#GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
#FLUSH PRIVILEGES;
#EOF

# Start service
service gitea start
sleep 5
# Make sure we get the installer
rm /usr/local/etc/gitea/conf/app.ini 2>/dev/null

# Send database name, login, and password to PLUGIN_INFO
echo "MySQL Database Name: $DB" > /root/PLUGIN_INFO
echo "MySQL Database User: $USER" >> /root/PLUGIN_INFO
echo "MySQL Database Password: $PASS" >> /root/PLUGIN_INFO

# Output database name, login, and password to UI and remind user where to find it again
echo "MySQL Database Name: $DB" 
echo "MySQL Database User: $USER" 
echo "MySQL Database Password: $PASS" 
echo "To view this information again, click Post Install Notes"



