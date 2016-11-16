# linuxfs-build

# build your own linux rootfs based on ubuntu

# build qemu environment on your work pc first
# just do like the following web page
http://blog.chinaunix.net/uid-9688646-id-3938235.html

# now you can run the build-fs-bash.sh
$: ./build-fs-base.sh

# the script can't set passwd
# please chroot by yourself and change passwd
$: sudo chroot ubuntu/
$: passwd type_your_username
$: passwd root
$: exit

# now you hava a complete rootfs
# enjoy!!!
