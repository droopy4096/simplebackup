#!/bin/sh

DEVICE=$1
MNT_PNT=$2
LABEL=$3
SYSTEMID=$4

# sample:
# setup_drive.sh /dev/sdb1 /media/KINGSTON BACKUP DELL_E4300

echo "mtools_skip_check=1" >> $HOME/.mtoolsrc

echo "Current label:"
mlabel -i $DEVICE  -s ::

echo "Changing label:"
mlabel -i $DEVICE ::$LABEL

touch $MNT_PNT/backup_target
mkdir ${MNT_PNT}/${SYSTEMID}

cat > ${MNT_PNT}/${SYSTEMID}/backup_filter <<EOF
+ /tmp/
+ /tmp/**
- *
EOF
