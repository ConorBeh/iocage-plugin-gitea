# Set IP variable
IP="ifconfig epair0b | awk '$1 == "inet" { print $2 }'"

# Enable services
sysrc lighttpd_enable=YES
sysrc php_fpm_enable=YES


