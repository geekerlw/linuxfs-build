#!/bin/bash -e

# Base root filesystem build script
# set TARGET_ROOTFS_DIR by yourself, default dir in your build path named ubuntu
export TARGET_ROOTFS_DIR="ubuntu"
export ARCH="armhf"
export HOSTNAME="rk3288"
export USERNAME="cqutprint"

# set ubuntu version
export ROOTFS_VERSION="16.04.1"

# create target dir and clean
if [ ! -e $TARGET_ROOTFS_DIR ]; then
	echo "make target dir"
	mkdir ubuntu
fi
sudo rm -rvf ubuntu/*

# get ubuntu base filesystem
if [ ! -e ubuntu-base-$ROOTFS_VERSION-base-armhf.tar.gz ]; then
	echo Download ubuntu base file system
	wget http://cdimage.ubuntu.com/ubuntu-base/releases/$ROOTFS_VERSION/release/ubuntu-base-$ROOTFS_VERSION-base-armhf.tar.gz
fi

# extarct image
echo "extract image"
sudo tar -xvpf ubuntu-base-$ROOTFS_VERSION-base-armhf.tar.gz -C $TARGET_ROOTFS_DIR

# replace sources.list and dns server
sudo cp -av ./preset/network/sources.list $TARGET_ROOTFS_DIR/etc/apt/sources.list
sudo cp -bv /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf

# prepare the environment to chroot
sudo cp -av ./prebuild/ $TARGET_ROOTFS_DIR/
sudo cp -av ./preset/ $TARGET_ROOTFS_DIR/
sudo cp -av /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/ 
sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

# chroot to install some packages
cat << EOF | sudo chroot $TARGET_ROOTFS_DIR
apt update && apt upgrade -y

#........timezone locale and keyboard..........
echo "UTC=yes" >> /etc/default/rcS
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
echo "LANG="zh_CN.UTF-8"" > /etc/default/locale
echo "LANGUAGE="zh_CN:en_GB:en"" >> /etc/default/locale
echo "XKBLAYOUT="us"" >> /etc/default/keyboard

#........install some base tools..........
apt install -y xfce4 net-tools iputils-ping vim

#.........transitional chinese support....
apt install -y fonts-wqy-microhei

#................xserver...................
dpkg -X ./prebuild/xserver/xserver-common_*_all.deb /
dpkg -X ./prebuild/xserver/xserver-xorg-core_*_armhf.deb /

#................maligpu..................
dpkg -X ./prebuild/libmali/libmali-rk-midgard0_*_armhf.deb /
dpkg -X ./prebuild/libmali/libmali-rk-dev_*_armhf.deb /
rm -rvf /usr/lib/arm-linux-gnueabihf/mesa-egl/*
echo "KERNEL=="mali0", MODE="0666", GROUP="video"" > /etc/udev/rules.d/50-mali.rules

#........enable dhcp network.............
echo auto eth0 > /etc/network/interfaces.d/eth0
echo iface eth0 inet dhcp >> /etc/network/interfaces.d/eth0

#.......enable autologin from tty1.........
cp -av ./preset/getty/getty@tty1.service \
/etc/systemd/system/getty.target.wants/getty@tty1.service

# rename hostname
echo rk3288 > /etc/hostname 

# add user named cqutprint
useradd -m -s /bin/bash cqutprint

#.......enable autologin xfce from tty1.........
cp -av ./preset/xfce4/bash_profile /home/cqutprint/.bash_profile
cp -av ./preset/xfce4/xinitrc /home/cqutprint/.xinitrc
cp -av ./preset/xfce4/xserverrc /home/cqutprint/.xserverrc

#........remove package cache..............
rm -rvf /var/cache/apt/archives/*
rm -rvf /prebuild
rm -rvf /preset
EOF


# replace some preset here
sudo cp -av ./preset/rules/X11/20-modesetting.conf \
$TARGET_ROOTFS_DIR/usr/share/X11/xorg.conf.d/
sudo cp -av ./preset/rules/udev/50-mali.rules $TARGET_ROOTFS_DIR/etc/udev/rules.d/

# end chroot
sudo umount $TARGET_ROOTFS_DIR/dev

echo "build successful,enjoy!!!"
