#!/bin/bash
timer_start=`date +%s`

# ORIGINAL IDEA
# http://forum.ubuntu-it.org/viewtopic.php?p=3284474#p3284474

# NEEDS MEGACL FROM
# https://pypi.python.org/pypi/megacl
# - you need to log in first! - $ mcl login --email=dave@example.com


####################
### CONFIGURATION
####################
MAIL='your@mail.com'

ORIGIN='/var/www'
DESTINATION='/media/Storage/Backups/'

BACKUP_ON_MEGA=false

DB_USER='root'
DB_PASS=''


####################
### TODAY'S DATE
####################
DATE=`date '+%Y-%02m-%02d_%02k.%M'`
DAY=`date '+%02d'`




#######################
### BACKUP DATABASES
### if a $DESTINATION/00_databases.txt exists, grab the list of specified databases you want to backup, otherwise get them all
### 00_databases.txt content is just a line separated list of database names, e.g. 
###
### database1
### mywebsite
### otherdb
#######################
cd $DESTINATION

# create a temporary directory for database backups if needed
if ! [ -d "database_dumps" ]; then
	mkdir database_dumps
fi

if [ -f 00_databases.txt ]; then
	# backup only specified databases
	DATABASES=( `cat "00_databases.txt" `)

	for (( i = 0 ; i < ${#DATABASES[@]} ; i++ )) do
		db=${DATABASES[$i]}
		mysqldump --force --opt --user="$DB_USER" --password="$DB_PASS" --databases $db > database_dumps/$db.sql
	done
else
	# backup all databases
	DATABASES=`mysql --user="$DB_USER" --password="$DB_PASS" -e "SHOW DATABASES;" | grep -Ev "(Database|test|phpmyadmin|mysql|performance_schema|information_schema)"`

	for db in $DATABASES; do
		mysqldump --force --opt --user="$DB_USER" --password="$DB_PASS" --databases $db > database_dumps/$db.sql
	done
fi


# create a compressed archive for databases
DBFILENAME=Backup-Databases-$DATE.tar.bz2
tar cpfj $DBFILENAME database_dumps 

# remove the database dump's temporary directory
rm -rf database_dumps




###################
### BACKUP FILES
### Full backup every 1st day of month
### Differential backup every other day
###################
cd $ORIGIN
if [ $DAY = "01" ] || ! [ -f $DESTINATION/backup-log.snar ]; then
	BACKUP_TYPE="Full backup"

	# removing the .snar log tells tar to create a new full backup
	rm -f $DESTINATION/backup-log.snar

	FILENAME=$DESTINATION/Backup-FULL-$DATE.tar.bz2
	tar cpfj $FILENAME --ignore-failed-read --listed-incremental $DESTINATION/backup-log.snar ./

	# if the backup file was created successfully
	# keep the last two full backups, the last 7 diff backups and remove everything else
	if [ -f "$FILENAME" ]; then
		ls -td $DESTINATION/Backup-DIFF* | tail -n +8 | xargs rm -f
		ls -td $DESTINATION/Backup-FULL* | tail -n +3 | xargs rm -f
	fi
else
	BACKUP_TYPE="Differential backup"

	# I'm saving a copy of backup-log.snar because we want a differential backup and not incremental
	# I'll restore it later to have further differential backups based on the last full backup
	cp $DESTINATION/backup-log.snar $DESTINATION/backup-log.snar.0

	FILENAME=$DESTINATION/Backup-DIFF-$DATE.tar.bz2
	tar cpfj $FILENAME --ignore-failed-read --listed-incremental $DESTINATION/backup-log.snar ./

	mv $DESTINATION/backup-log.snar.0 $DESTINATION/backup-log.snar
fi

timer_end=`date +%s`
runtime=$((timer_end-timer_start))

echo "$BACKUP_TYPE finished in $runtime seconds."




##########################
### SAVE BACKUP ON MEGA
### and delete local backup file
##########################
if [ $BACKUP_ON_MEGA = true ]; then
	# Check if a Backup directory exist first
	DIRECTORY=`/usr/local/bin/mcl find --reload -f Backup`
	EXIST=${#DIRECTORY}

	# If a directory named Backup doesn't exist, let mcl create it
	if [ $EXIST = 0 ]; then
		/usr/local/bin/mcl mkdir Backup '/Cloud Drive'
	fi

	# upload...
	/usr/local/bin/mcl put --reload $FILENAME '/Cloud Drive/Backup'
	/usr/local/bin/mcl put --reload $DESTINATION/$DBFILENAME '/Cloud Drive/Backup'

	# if upload went successfull remove local files
	UPLOADED=`/usr/local/bin/mcl find --reload -f $DBFILENAME `
	EXIST=${#UPLOADED}
	if [ $EXIST = 0 ]; then
		# files not uploaded. Leave files alone and send an alert email
		mailx -s "Problema con il salvataggio dei backup su Mega. Per favore, verifica" < /dev/null $MAIL
	else
		# all good. Remove local file
		rm $FILENAME
		rm $DESTINATION/$DBFILENAME
	fi
fi
