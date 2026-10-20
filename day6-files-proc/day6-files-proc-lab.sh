#!/bin/bash
LOGFILE="files_proc_lab_output.txt"
echo "=== DAY 6 SRE LAB: FILESYSTEM & PROC DIAGNOSTICS ===" > $LOGFILE

python3 unlinked_recovery.py >> $LOGFILE 2>&1 &
APP_PID=$!
sleep 3

DELETED_FD=$(ls -l /proc/$APP_PID/fd | grep "deleted" | awk '{print $9}')
if [ -n "$DELETED_FD" ]; then
    cp /proc/$APP_PID/fd/$DELETED_FD recovered_file.log
fi
wait $APP_PID

IMG_FILE="/tmp/loopback_inode.img"
MOUNT_DIR="/mnt/inode_test"
dd if=/dev/zero of=$IMG_FILE bs=1M count=20 >> $LOGFILE 2>&1
mkfs.ext4 -N 2000 $IMG_FILE >> $LOGFILE 2>&1
mkdir -p $MOUNT_DIR
mount -o loop $IMG_FILE $MOUNT_DIR

python3 inode_exhaustion.py $MOUNT_DIR >> $LOGFILE 2>&1

df -i $MOUNT_DIR >> $LOGFILE
umount $MOUNT_DIR
rm -f $IMG_FILE
rmdir $MOUNT_DIR
