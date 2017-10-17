#!/bin/bash

# data purger - to run before giving a laptop back to office

set -e

if [ -z $1 ]; then
    echo "Usage: ./kill_disk.sh <block device path>"
fi

dev=$1

echo -n "Kill device: ${dev}? (y/n): "
read $answer
if [ "x${answer}" != "xy" ]; then
    echo "Aborting..."
    exit 1
fi

disk_sz_bytes=$(lsblk -b | grep $1 | awk '{print $4}')

blk_sz_mb=16

iter_sz_mb=$(expr 4 * 1024)
iter_sz_bytes=$(expr $iter_sz_mb * 1024 * 1024)
blk_count=$(expr $iter_sz_mb '/' $blk_sz_mb)

echo "Writing $blk_count 16MB random blocks starting at offset 0"
sudo dd if=/dev/urandom of=$dev bs=16M count=$blk_count status=progress

iter_count=$(expr disk_sz_bytes '/' $iter_sz_bytes)

for i in $(seq 1 $iter_count); do
    start_blk=$(expr $i '*' $iter_sz_bytes '/' $blk_count)
    echo "Copying ${blk_count} 16MB blocks from block-offset 0 to ${start_blk}"
    sudo dd if=$dev of=$dev bs=16M count=$blk_count \
         seek=$start_blk status=progress
done

bytes_rewritten=$(expr $iter_count '*' $iter_sz_bytes)
remaining_orig_bytes=$(expr $disk_sz_bytes '-' $bytes_rewritten)

echo "Copying ${remaining_orig_bytes} bytes from offset 0 to ${bytes_rewritten}"
sudo dd if=$dev of=$dev bs=1 count=$remaining_orig_bytes \
     seek=$bytes_rewritten status=progress
