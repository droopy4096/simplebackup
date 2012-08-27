#!/bin/sh

# this script relies on UDEV rules:

### UDEV #####
## KERNEL=="sd??", SUBSYSTEMS=="scsi", ATTRS{vendor}=="Hitachi ", ATTRS{model}=="HDS723030ALA640 ", PROGRAM+="/root/system_backup/udev_helper.sh"
### /UDEV #####

# and /root/system_backup/udev_helper.sh script
# that generates $BACKUP_DEVICE_LIST file 

# it will walk through all the devices listed under $BACKUP_DEVICE_LIST
# and spot whichever ones have $BACKUP_STAMP_FILE located in their root
# then it will use ALL of those devices for an incremental backup

# BACKUP_DEVICE_TOP="/dev/hitachi-backup"
# BACKUP_DEVICE="${BACKUP_DEVICE_TOP}/2"

# Name we give to a Luks device before mount...
BACKUP_DEVICE_NAME="backup-session"

# File containing list of possible backup devices
BACKUP_DEVICE_LIST="/var/run/backup_device"

# File (flag) on backup device to make sure we're not backing up
# where we're not supposed to (that file has to be present at the 
# / of the device)
BACKUP_STAMP_FILE="backup_target"

# Luks Key
KEY_FILE="/root/system_backup/backup_key"

# Where do we mount device for backup
MNT_PNT="/mnt/backup"
# ID for the system running backup
SYSTEM_ID="E4300"

DATESTAMP=$(date "+%Y-%m-%d-%H:%M")

# files we'll exclude from the backup (full path)
EXCLUDES="/backup_excludes"

# Backup log file
LOG_FILE="/var/log/system_backup.log"

PATH=${PATH}:/sbin:/bin:/usr/bin:/usr/sbin

crypt_mount(){
  cryptsetup luksOpen --key-file=${KEY_FILE} $1  ${BACKUP_DEVICE_NAME} 
  mount /dev/mapper/${BACKUP_DEVICE_NAME} ${MNT_PNT} 
}

crypt_umount(){
  umount ${MNT_PNT}
  cryptsetup luksClose ${BACKUP_DEVICE_NAME}
}

run_backup(){ 
  rsync -a --stats --link-dest=${MNT_PNT}/${SYSTEM_ID}/last --exclude-from=${EXCLUDES} \
	--log-file=${LOG_FILE} \
	/ ${MNT_PNT}/${SYSTEM_ID}/${DATESTAMP}
  ( cd ${MNT_PNT}/${SYSTEM_ID} && unlink last && ln -sf ${DATESTAMP} last )
}

BACKUP_DEVICES=""
for BACKUP_DEVICE in $(sort -u $BACKUP_DEVICE_LIST)
 do
	if cryptsetup isLuks "${BACKUP_DEVICE}"  
	then
          crypt_mount $BACKUP_DEVICE
	  [ -e ${MNT_PNT}/${BACKUP_STAMP_FILE} ] && BACKUP_DEVICES="$BACKUP_DEVICE $BACKUP_DEVICES"
          crypt_umount
	fi
 done

for d in $BACKUP_DEVICES
 do
        crypt_mount $d
        run_backup
        crypt_umount
 done

