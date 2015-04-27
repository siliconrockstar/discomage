#!/bin/bash

# Globals
OUTPUT='';

PHP_MODS_TO_TEST_FOR=( mysql mcrypt hash xml gd PDO mhash soap apc );

PROCESSES_TO_TEST_FOR=( httpd nginx apache apache2 varnishd 
	mysql mysqld redis redis-server memcache memcached java php5-fpm postfix);
FOUND_PROCESSES=();

# used to test if apache is installed
APACHE_PROCESS_NAMES=( apache apache2 httpd );


#
#
#
#
# O/S
OUTPUT+='--- O/S \n';

OUTPUT+='- Version\n';
VERSION=`cat /proc/version`;
OUTPUT+="$VERSION \n\n";

OUTPUT+='- Release\n';
RELEASE=`cat /etc/*-release`;
RELEASE=`printf %q "$RELEASE" | sed s/\'//g`;
OUTPUT+="$RELEASE \n\n";


# CPU architecture
OUTPUT+='--- CPU \n';
LSCPU=`lscpu`;
LSCPU=`printf %q "$LSCPU" | sed s/\'//g`;
OUTPUT+="$LSCPU \n\n";

# CPU cores
OUTPUT+='--- Total Logical Cores\n';
NPROC=`nproc`;
OUTPUT+="$NPROC \n\n";

# memory
OUTPUT+='--- Memory \n';
FREE=`free`;
FREE=`printf %q "$FREE" | sed s/\'//g`;
OUTPUT+="$FREE\n\n";

# mounts
OUTPUT+='--- Mounts \n';
MOUNTS=`mount -l`;
MOUNTS=`printf %q "$MOUNTS" | sed s/\'//g`;
OUTPUT+="$MOUNTS \n\n";


# Processes
OUTPUT+='--- Processes\n';

for P in ${PROCESSES_TO_TEST_FOR[@]}
do
    SEARCH=" $P\$"; # add a preceding space and following newline
    COUNT=`ps -A | grep $SEARCH | wc -l`;
    if [[ $COUNT -gt 0 ]]; then
        FOUND_PROCESSES+=$P;              
        OUTPUT+="$COUNT $P processes running\n";
    else        
        OUTPUT+="$P not running\n";        
    fi
done

OUTPUT+="\n\n";

# Network
OUTPUT+='--- Network\n';
NET=`ifconfig | grep -B1 inet`;
NET=`printf %q "$NET" | sed s/\'//g`;
OUTPUT+="$NET\n\n";

# set some flags for what is installed by testing for running processes
HAS_PHP=0;
HAS_MYSQL=0;
HAS_APACHE=0;
HAS_NGINX=0;

# apache
for X in ${APACHE_PROCESS_NAMES[@]}
do
    if [[ $FOUND_PROCESSES == *"$X"* ]]; then
        HAS_APACHE=1;
    fi 
done
# nginx
if [[ $FOUND_PROCESSES == *"nginx"* ]]; then
    HAS_NGINX=1;
fi
#php
# if apache or nginx installed, assume php is installed
if [ $HAS_NGINX == "1" ] || [ $HAS_APACHE == "1" ] ; then
    HAS_PHP=1;
else # test for php-fpm process, could be running standalone
    if [[ $FOUND_PROCESSES == *"php"* ]]; then
        HAS_PHP=1;
    fi
fi
# mysql
if [[ $FOUND_PROCESSES == *"mysql"* ]]; then
    HAS_MYSQL=1;
fi

# gather php info
if [[ $HAS_PHP == "1" ]]; then
    OUTPUT+='--- PHP\n';
    OUTPUT+='Version\n';
    PHPV=`php -v`;
    PHPV=`printf %q "$PHPV" | sed s/\'//g`;
    OUTPUT+="$PHPV\n\n";

    # PHP extensions
    OUTPUT+='- PHP Modules\n';
    MODS=`php -m`;
    PMODS=`printf %q "$MODS" | sed s/\'//g`;
    OUTPUT+="$PMODS\n\n";

    # PHP required modules
    OUTPUT+='- PHP Modules Required by Magento\n';

    for X in ${PHP_MODS_TO_TEST_FOR[@]}
    do # test if module is in mod list
        if [[ $MODS == *"$X"* ]]; then
            OUTPUT+="$X found\n";
        else
	    OUTPUT+="$X NOT FOUND\n";
        fi
    done
fi

OUTPUT+='\n\n';

# get Apache info
if [[ $HAS_APACHE == "1" ]]; then
    OUTPUT+='--- Apache Config\n';
    APACHECONFIG=`apache2ctl -S`;
    APACHECONFIG=`printf %q "$APACHECONFIG" | sed s/\'//g`;
    OUTPUT+="$APACHECONFIG\n\n";
fi

# get Nginx info 
if [[ $HAS_NGINX == "1" ]]; then
    OUTPUT+="--- Nginx \n\n";
    # nginx commands writes to stderr, not stdout
    NGINXCONFIG=`nginx -v 2>&1`;
    NGINXCONFIG+=$'\n';
    NGINXCONFIG+=`nginx -t 2>&1`;
    NGINXCONFIG+=$'\n';    
    NGINXCONFIG+=`grep -R server_name /etc/nginx`;
    NGINXCONFIG=`printf %q "$NGINXCONFIG" | sed s/\'//g`;
    OUTPUT+="$NGINXCONFIG\n\n";
fi 

# MySQL - can't really get info without creds but give it a shot
if [[ $HAS_MYSQL == "1" ]]; then
    OUTPUT+='--- MySQL is running\n';   
    OUTPUT+="Trying to get version with blank password...\n";
    MYSQLINFO+=`mysql -u root version`;
    MYSQLINFO=`printf %q "$MYSQLINFO" | sed s/\'//g`;
    OUTPUT+="$MYSQLINFO\n\n";
fi

# See if you can find Magento installs by looking for license
OUTPUT+='--- Searching for Mage.php files\n';
MAGES=`locate Mage.php`;
MAGES=`printf %q "$MAGES" | sed s/\'//g`;
OUTPUT+=$MAGES;


echo -e $OUTPUT > ./ServerConfigOutput.txt;


