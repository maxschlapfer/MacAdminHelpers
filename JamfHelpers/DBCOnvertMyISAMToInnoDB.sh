#!/bin/bash
# This script helps with the conversion from MyISAM to InnoDB.
###
# v1.0: 2018-09-24
###
# Written for internal use at ETH Zurich
# by Max Schlapfer
###

###
# If you only have one DB us the tool from Jamf:
# https://www.jamf.com/jamf-nation/articles/531/converting-the-mysql-database-storage-engine-from-myisam-to-innodb-using-the-jamf-pro-server-tools-command-line-interface
###
# If you host a lot of databases in your environment, this tool might reduce the amount of manual work.
# It is based in the work of MacMule:
# https://macmule.com/2018/09/23/manually-converting-jamf-pro-tables-from-myisam-to-innodb
###
# This script has been tested on
#    - Red Hat Enterprise Linux Server release 7.5 (Maipo)
#    - MySQL Community Server (GPL), v5.7.23
#    - Jamf Pro 10.7.1-t1536934276
###

###
# Set GLOBAL variables for MySQL to be optimised for InnoDB
###
# Settings recommendations from Jamf
#    - innodb_buffer_pool_size:         75% of remaining server memory (server memory minus other services memory)
#    - innodb_file_per_table:           1
#    - innodb_flush_log_at_trx_commit   0 - Default is one, 0 or 2 provides better performance with the risk of 
#                                           loosing 1 sec of transactions in case of power loss/crash of the server
#    - key_buffer_size:                 16M
###
# Please check with your DB admin and/or Jamf Support
# to optimize these settings for your environment.
###
timestamp=$(date +%Y-%m-%d_%H-%M)
MySQLConfigFile="/etc/my.cnf"
BackupDestination="/Data/MySQL-Backups/${timestamp}"
innodb_buffer_pool_size="6G"
key_buffer_size="16M"
innodb_file_per_table="1"
innodb_flush_log_at_trx_commit="0"

###
# Issue a warning about tomcat running or not
###
echo "******************************************************************************************"
echo "WARNING: MAKE SURE THAT ALL TOMCAT SERVICES CONNECTING TO THIS MYSQL SERVER ARE TURNED OFF"
echo "******************************************************************************************"
echo " "
while true; do
   read -p "Do you wish to start the conversion now? (yes/no)" yn
     case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
     esac
done

###
# Make backups of the important files
###
# backup the original MySQL conf file
cp "$MySQLConfigFile" /etc/my.cnf.backup_${timestamp}

# make a full backup of all MySQL databases
mkdir -p "${BackupDestination}"
echo "Doing databases backup now..."
/usr/bin/mysqldump --all-databases --single-transaction --quick --lock-tables=false | gzip -9 > ${BackupDestination}/${timestamp}-backup_all_DBs.gz
echo "Backup done, continuing."

# set the global parameters
# set innodb_buffer_pool_size
if grep -E "^innodb_buffer_pool_size\s+=\s+" ${MySQLConfigFile};then
   sed -c -i "s/\(innodb_buffer_pool_size *= *\).*/\1$innodb_buffer_pool_size/" $MySQLConfigFile
else
   echo "innodb_buffer_pool_size = ${innodb_buffer_pool_size}" >> $MySQLConfigFile
fi

# set key_buffer_size
if grep -E "^key_buffer_size\s+=\s+" ${MySQLConfigFile};then
   sed -c -i "s/\(key_buffer_size *= *\).*/\1$key_buffer_size/" $MySQLConfigFile
else
   echo "key_buffer_size = ${key_buffer_size}" >> $MySQLConfigFile
fi

#set innodb_file_per_table
if grep -E "^innodb_file_per_table\s+=\s+" ${MySQLConfigFile};then
   sed -c -i "s/\(innodb_file_per_table *= *\).*/\1$innodb_file_per_table/" $MySQLConfigFile
else
   echo "innodb_file_per_table = ${innodb_file_per_table}" >> $MySQLConfigFile
fi

# set innodb_flush_log_at_trx_commit
if grep -E "^innodb_flush_log_at_trx_commit\s+=\s+" ${MySQLConfigFile};then
   sed -c -i "s/\(innodb_flush_log_at_trx_commit *= *\).*/\1$innodb_flush_log_at_trx_commit/" $MySQLConfigFile
else
   echo "innodb_flush_log_at_trx_commit = ${innodb_flush_log_at_trx_commit}" >> $MySQLConfigFile
fi


# get a list of all tables from your database server
# and exclude the default tables (we do not touch these)
DATABASES=($(mysql -Bse "show databases" | grep -i -v "_schema" | grep -i -v "sys" | grep -i -v "mysql"))

# Save the actual internal field separator
SAVEIFS=$IFS

for i in "${DATABASES[@]}"
do
   echo "Converting $i"
   IFS=$'\n'    # set \n as the new internal field separator
   COMMANDS=($(mysql $i -e "show table status where Engine='MyISAM';" | awk 'NR>1 {print "ALTER TABLE "$1" ENGINE = InnoDB;"}'))
   IFS=$SAVEIFS   # set the internal field separator back to original

   for n in "${COMMANDS[@]}"
   do
     mysql $i -e "$n"
   done
   echo "   --> $i successfully converted to InnoDB"
   echo " "
done

###
# Restarting the MySQL service to activate all new settings
###
systemctl restart mysqld

echo "*********************************"
echo "All databases have been converted"
echo "*********************************"
echo "MySQL service restarted"
echo "*********************************"
echo " "
echo "*********************************"
echo "You can now restart tomcat"
echo "*********************************"
