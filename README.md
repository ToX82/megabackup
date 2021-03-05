megabackup
==========

A simple BASH script useful to backup mySQL databases and files.

Based upon an idea found here: [Ubuntu-it forum](http://forum.ubuntu-it.org/viewtopic.php?p=3284474#p3284474).

Needs MEGAcmd if you want to save backups on mega.nz [MEGAcmd](https://mega.nz/cmd) and a [mega.co.nz](https://mega.nz/) account, of course .


## INSTALLATION STEPS:
* place this file everywhere you want
* edit the configuration settings as your needs

### OPTIONAL
* install and configure MEGAcmd ()
* set BACKUP_ON_MEGA = true

## OK BUT... HOW DO I RESTORE MY BACKUPS?

The backup files are just tar.bz2 files, so you can treat them as you would with any compressed files and folders. Let's say that you want to restore a backup made on July 23rd 2018. Here's what you would do to extract the backup. Just remember to adjust the file and folder names according to your situation :)

First thing first. Download the FULL backup, the one which is made on the first day of that month, and the last DIFF backup, using MEGAcmd.
You could do the same thing by going to https://mega.nz and manually download those files, though.

    mega-cmd
    get Backup/2018-07-01_00.30-Backup-FULL.tar.bz2 /home/myuser/backups/2018-07-01_00.30-Backup-FULL.tar.bz2
    get Backup/2018-07-23_00.30-Backup-DIFF.tar.bz2 /home/myuser/backups/2018-07-23_00.30-Backup-DIFF.tar.bz2
    exit

Now we want to extract the backup. The full backup first, then the diff backup. We could extract it all like this:

    tar xfj 2018-07-01_00.30-Backup-FULL.tar.bz2
    tar xfj 2018-07-23_00.30-Backup-DIFF.tar.bz2

Or, if the backup file is really bit or if you just need to extract a single folder, you could do this

    tar xfj 2018-07-01_00.30-Backup-FULL.tar.bz2 ./mybackuppedfolder
    tar xfj 2018-07-23_00.30-Backup-DIFF.tar.bz2 ./mybackuppedfolder

That's all! Now you just need to copy the extracted files wherever you need

## Contributing

Your feedback is precious! Don't hesitate to [open GitHub Issues](https://github.com/ToX82/megabackup/issues) for any problem or question you may have.

All contributions are welcome. If you extend it, write me a line so that I can update it for everyone.

## License

Megabackup is licensed under the MIT Licence, courtesy of [Emanuele "ToX" Toscano ](http://emanuele.itoscano.com/).
