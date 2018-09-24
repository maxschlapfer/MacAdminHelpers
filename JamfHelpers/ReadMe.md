# Jamf Pro InnoDB Converter Script

This script helps with the conversion from MyISAM to InnoDB in a setup where a lot of Jamf Pro instances are hosted on one MySQL server.

It is based in the work of MacMule:
[https://macmule.com/2018/09/23/manually-converting-jamf-pro-tables-from-myisam-to-innodb](https://macmule.com/2018/09/23/manually-converting-jamf-pro-tables-from-myisam-to-innodb)

### Note
If you only have one DB use the tool from Jamf:
[Jamf Pro Manual for converting your DBs](https://www.jamf.com/jamf-nation/articles/531/converting-the-mysql-database-storage-engine-from-myisam-to-innodb-using-the-jamf-pro-server-tools-command-line-interface)

### This script has been tested on

- Red Hat Enterprise Linux Server, Release 7.5 (Maipo)
- MySQL Community Server (GPL), v5.7.23
- Jamf Pro v10.7.1-t1536934276

### Use

- To run this script you should have a .my.cnf file containing your MySQL credentials

- Check with your DB admin and/or Jamf support to optimise the correct settings for your environment.
  - __innodb_buffer_pool_size__  
    75% to 80% of remaining server memory (total server memory minus other services memory)
  - __innodb_file_per_table = 1__  
    Jamf reccomended "1" for our environment
  - __innodb_flush_log_at_trx_commit = 0__  
    Default is 1  
    0 or 2 provides better performance but with a potential risk of loosing up  
    to 1 sec of transactions in case of power loss/crash
  - __key_buffer_size__  
    Optimise for your environment, this is good start:  
    [https://mariadb.com/kb/en/library/optimizing-key_buffer_size/](https://mariadb.com/kb/en/library/optimizing-key_buffer_size/)
    
- Define variables for your setup  
  - __timestamp__: The date format used to save your backup files
  - __MySQLConfigFile__:  The path of your my.cnf (for RedHat this should be /etc/my.cnf)
  - __BackupDestination__: Where to save your Backups before the conversion starts.
  
- Turn off all Tomcat services (on RedHat use `systemctl stop tomcat`)

- Run the script on the MySQL server (you must be root).

- Restart all Tomcat services and test your setup.
