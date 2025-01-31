#!/usr/bin/env zsh

o_dir_base=/mnt/work/overlay.d
nm=${1:-test}
o_dir=$o_dir_base/$nm

echo Overlaying $o_dir...


up_dir=$o_dir/root.upper
wrk_dir=$o_dir/root.work
mpt_dir=$o_dir/root.mount

mkdir -p $up_dir $wrk_dir $mpt_dir

cat > $o_dir/load.sh <<EOF
mount --make-rprivate /

mount -t overlay -o lowerdir=/,upperdir=$up_dir,workdir=$wrk_dir overlay $mpt_dir

mount -o bind /mnt/work $mpt_dir/mnt/work

mount -o bind /mnt/work $mpt_dir/mnt/work

mount -o bind /mnt/work/projects $mpt_dir/home/janmejay/projects

# # exec chroot $mpt_dir /bin/sh

chroot $mpt_dir /nix/var/nix/profiles/system/activate
exec chroot $mpt_dir /run/current-system/sw/bin/bash
EOF

unshare --mount --fork --pid --mount-proc -- bash $o_dir/load.sh
