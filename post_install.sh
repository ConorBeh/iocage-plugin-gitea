#!/bin/sh

# Enable service
sysrc gitea_enable=YES 2>/dev/null

# Start/stop service to generate configs
service gitea start 2>/dev/null
sleep 5
service gitea stop 2>/dev/null
sleep 5

# Remove default config to allow use of the web installer, set permissions
rm /usr/local/etc/gitea/conf/app.ini
chown -R git:git /usr/local/etc/gitea/conf
chown -R git:git /usr/local/share/gitea

# Start service
service gitea start
sleep 5
# Installer only comes up if there is no config so we nuke it once more to be sure
rm /usr/local/etc/gitea/conf/app.ini 2>/dev/null

# Setup Postgres
sysrc -f /etc/rc.conf postgresql_enable="YES"

# Start the service
service postgresql initdb 2>/dev/null
sleep 5
service postgresql start 2>/dev/null
sleep 5

USER="gitea"
DB="gitea"

# Save the config values
echo "$DB" > /root/dbname
echo "$USER" > /root/dbuser
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/dbpassword
PASS=`cat /root/dbpassword`

# create user
psql -d template1 -U postgres -c "CREATE USER ${USER} CREATEDB SUPERUSER;" 2>/dev/null

# Create production database & grant all privileges on database
psql -d template1 -U postgres -c "CREATE DATABASE ${DB} OWNER ${USER};" 2>/dev/null

# Set a password on the postgres account
psql -d template1 -U postgres -c "ALTER USER ${USER} WITH PASSWORD '${PASS}';" 2>/dev/null

# Connect as superuser and enable pg_trgm extension
psql -U postgres -d ${DB} -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" 2>/dev/null

# Fix permission for postgres 
echo "listen_addresses = '*'" >> /var/db/postgres/data11/postgresql.conf 2>/dev/null
echo "host  all  all 0.0.0.0/0 md5" >> /var/db/postgres/data11/pg_hba.conf 2>/dev/null

# Restart postgresql after config change
service postgresql restart 2>/dev/null
sleep 5

# Save database information
echo "Host: localhost or 127.0.0.1" > /root/PLUGIN_INFO
echo "Database Type: PostgresSQL" >> /root/PLUGIN_INFO
echo "Database Name: $DB" >> /root/PLUGIN_INFO
echo "Database User: $USER" >> /root/PLUGIN_INFO
echo "Database Password: $PASS" >> /root/PLUGIN_INFO

# Thank you Asigra plugin for your service on this hack
echo "Figure out our Network IP"
#Very Dirty Hack to get the ip for dhcp, the problem is that IOCAGE_PLUGIN_IP doesent work on DCHP clients
#cat /var/db/dhclient.leases* | grep fixed-address | uniq | cut -d " " -f4 | cut -d ";" -f1 > /root/dhcpip
#netstat -nr | grep lo0 | awk '{print $1}' | uniq | cut -d " " -f4 | cut -d ";" -f1 > /root/dhcpip
netstat -nr | grep lo0 | grep -v '::' | grep -v '127.0.0.1' | awk '{print $1}' | head -n 1 > /root/dhcpip
#netstat -nr | grep lo0 | awk '{print $1}' > /root/dhcpip 
#sed -i.bak '2,$d' /root/dhcpip 
IP=`cat /root/dhcpip`
#rm /root/dhcpip.bak

# Show user database details 
echo "-------------------------------------------------------"
echo "DATABASE INFORMATION"
echo "-------------------------------------------------------"
echo "Host: localhost or 127.0.0.1" 
echo "Database Type: PostgresSQL" 
echo "Database Name: $DB" 
echo "Database User: $USER" 
echo "Database Password: $PASS" 
echo "To begin the installation go to http://${IP}:3000/install"
echo "To review this information again click Post Install Notes"
