#!/bin/sh

DIALOG=kdialog

TERMINAL=konsole

RSYNC="rsync"

DEST=/media/something

$TERMINAL -e "${RSYNC} $@ ${DEST}"
