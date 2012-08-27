#!/bin/sh

# Usage: backup.sh [<backup_device> [system_id]]

##TODO
## * redesign to have use 2 partitions:
##   * LUKS partition for FILTERS and other info
##   * "normal" partition for the backup itself


# File (flag) on backup device to make sure we're not backing up
# where we're not supposed to (that file has to be present at the 
# / of the device)

BACKUP_STAMP_FILE="backup_target"

# Where do we mount device for backup
MNT_PNT=${1:-"/media/BACKUP"}
# ID for the system running backup
SYSTEM_ID=${2:-"E4300"}

DATESTAMP=$(date "+%Y-%m-%d-%H:%M")

# files we'll exclude from the backup (full path)
EXCLUDES="backup_excludes"
FILTER="backup_filter"

BACKUP_BASE=${MNT_PNT}/${SYSTEM_ID}

# Backup log file
# LOG_FILE="/var/log/system_backup.log"
LOG_FILE="$HOME/system_backup.log"

PATH=${PATH}:/sbin:/bin:/usr/bin:/usr/sbin

run_backup(){ 
  rsync -a --stats --link-dest=${BACKUP_BASE}/last -F ". ${BACKUP_BASE}/${FILTER}" \
        --log-file=${LOG_FILE} \
        / ${BACKUP_BASE}/${DATESTAMP}
  ( cd ${BACKUP_BASE} && unlink last && ln -sf ${DATESTAMP} last )
}


if [ -e "${MNT_PNT}/${BACKUP_STAMP_FILE}" ]
 then
  if [ -d "${BACKUP_BASE}" ]
   then
     run_backup
   else 
     echo "No backup base directory exists. bailing"
  fi
 else
  echo "No backup stamp found"
fi
