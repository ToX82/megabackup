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

DATE=`date '+%Y-%02m-%02d_%02k.%M'`
DAY=`date '+%02d'`




#######################
### BACKUP DATABASES
### if a $ORIGIN/00_databases.txt exists, grab the list of specified databases you want to backup, otherwise get them all
### 00_databases.txt content is just a list of database names, separated by a space
### e.g. database1 mywebsite otherdb
#######################
cd $ORIGIN

# create a temporary directory for database backups if needed
if ! [ -d "000_database_dumps" ]
then
	mkdir 000_database_dumps
fi

# check if we want to backup specified databases, or get them all
if [ -f 00_databases.txt ]
then
	mapfile DATABASES < 00_databases.txt
else
	DATABASES=`mysql --user="$DB_USER" --password="$DB_PASS" -e "SHOW DATABASES;" | grep -Ev "(Database|test|phpmyadmin|mysql|performance_schema|information_schema)"`
fi

# let's do the backup
for db in $DATABASES; do
	mysqldump --force --opt --user="$DB_USER" --password="$DB_PASS" --databases $db > "000_database_dumps/$db.sql"
done





###################
### BACKUP FILES
### Full backup every 1st day of month
### Differential backup every other day
###################
if [ $DAY = "01" ] || ! [ -f $DESTINATION/backup-log.snar ]; then
	BACKUP_TYPE="Full backup"

	# removing the .snar log tells tar to create a new full backup
	rm -f $DESTINATION/backup-log.snar

	FILENAME=$DESTINATION/Backup-FULL-$DATE.tar.bz2
	tar cpfj $FILENAME --listed-incremental $DESTINATION/backup-log.snar ./

	# if the backup file was created successfully
	# keep the last two full backups, the last 7 diff backups and remove everything else
	if [ -f "$FILENAME" ]
	then
		ls -td $DESTINATION/Backup-DIFF* | tail -n +8 | xargs rm -f
		ls -td $DESTINATION/Backup-FULL* | tail -n +3 | xargs rm -f
	fi
else
	BACKUP_TYPE="Differential backup"

	# I'm saving a copy of backup-log.snar because we want a differential backup and not incremental
	# I'll restore it later to have further differential backups based on the last full backup
	cp $DESTINATION/backup-log.snar $DESTINATION/backup-log.snar.0

	FILENAME=$DESTINATION/Backup-DIFF-$DATE.tar.bz2
	tar cpfj $FILENAME --listed-incremental $DESTINATION/backup-log.snar ./

	mv $DESTINATION/backup-log.snar.0 $DESTINATION/backup-log.snar
fi

# remove the database dump's temporary directory
rm -rf 000_database_dumps

timer_end=`date +%s`
runtime=$((timer_end-timer_start))

echo "$BACKUP_TYPE finished in $runtime seconds."




##########################
### SAVE BACKUP ON MEGA
### and delete local backup file
##########################
if [ $BACKUP_ON_MEGA = true ]; then
	# Check if a Backup directory exist first
	DIRECTORY=`mcl find -f Backup`
	EXIST=${#DIRECTORY}

	# If a directory named Backup doesn't exist, let mcl create it
	if [ $EXIST = 0 ]; then
		mcl mkdir Backup '/Cloud Drive'
		mcl reload
	fi

	# upload...
	mcl put $FILENAME '/Cloud Drive/Backup'

	# ...and remove local file
	rm $FILENAME
fi
