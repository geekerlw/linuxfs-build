#!/bin/bash -e

# Base root filesystem build script
# set TARGET_ROOTFS_DIR by yourself, default dir in your build path named ubuntu
TARGET_ROOTFS_DIR="ubuntu"
ARCH="armhf"
if [ ! $BOARDNAME ]; then
	BOARDNAME="rk3288"
fi
if [ ! $USERNAME ]; then
	USERNAME="cqutprint"
fi

# set ubuntu version
if [ ! $ROOTFS_VERSION ]; then
	ROOTFS_VERSION="16.04.1"
fi

# create target dir and clean
if [ ! -e $TARGET_ROOTFS_DIR ]; then
	echo "make target dir"
	mkdir $TARGET_ROOTFS_DIR
fi
sudo rm -rvf $TARGET_ROOTFS_DIR/*

# get ubuntu base filesystem
if [ ! -e ubuntu-base-$ROOTFS_VERSION-base-armhf.tar.gz ]; then
	echo Download ubuntu base file system
	wget http://cdimage.ubuntu.com/ubuntu-base/releases/$ROOTFS_VERSION/release/ubuntu-base-$ROOTFS_VERSION-base-armhf.tar.gz
fi

# extarct image
echo "extract image"
sudo tar -xvpf ubuntu-base-$ROOTFS_VERSION-base-armhf.tar.gz -C $TARGET_ROOTFS_DIR

# replace sources.list and dns server
sudo cp -av ./preset/overlay/etc/apt/sources.list $TARGET_ROOTFS_DIR/etc/apt/sources.list
sudo cp -bv /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf

# prepare the environment to chroot
sudo cp -av ./prebuild/ $TARGET_ROOTFS_DIR/
sudo cp -av ./preset/ $TARGET_ROOTFS_DIR/
sudo cp -av /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/ 
# sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

# chroot to install some packages
cat << EOF | sudo chroot $TARGET_ROOTFS_DIR
apt update && apt upgrade -y

# timezone locale and keyboard
echo "UTC=yes" >> /etc/default/rcS
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
echo "LANG="zh_CN.UTF-8"" > /etc/default/locale
echo "LANGUAGE="zh_CN:en_GB:en"" >> /etc/default/locale
echo "XKBLAYOUT="us"" >> /etc/default/keyboard

# install some base tools
apt install -y xfce4 net-tools iputils-ping wicd vim

# gstreamer base tools
apt install -y gstreamer1.0-alsa gstreamer1.0-nice gstreamer1.0-plugins-bad \
gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-tools \
gstreamer1.0-x gstreamer1.0-plugins-bad-faad

# transitional chinese support
apt install -y fonts-wqy-microhei

# cups and hp printer driver
apt install -y cups hplip

# Split screen tool
apt install -y devilspie

# xserver
dpkg -x ./prebuild/xserver/xserver-common*_all.deb /
dpkg -x ./prebuild/xserver/xserver-xorg-core*_armhf.deb /

# maligpu
dpkg -i ./prebuild/libmali/libmali-rk-midgard*_armhf.deb 
dpkg -i ./prebuild/libmali/libmali-rk-dev*_armhf.deb 
rm -rvf /usr/lib/arm-linux-gnueabihf/mesa-egl/*

# libdrm
dpkg -i ./prebuild/libdrm/libdrm-rockchip*_armhf.deb

# mpp
dpkg -i ./prebuild/mpp/librockchip-mpp*_armhf.deb
dpkg -i ./prebuild/mpp/librockchip-vpu*_armhf.deb


# gstreamer-rockchip
dpkg -i ./prebuild/gstreamer-rockchip/gstreamer1.0-rockchip*_armhf.deb

# enable dhcp network
echo auto eth0 > /etc/network/interfaces.d/eth0
echo iface eth0 inet dhcp >> /etc/network/interfaces.d/eth0

# hostname
echo $BOARDNAME > /etc/hostname 

# add user name and passwd default cqutprint
useradd -m -s /bin/bash $USERNAME
echo "$USERNAME:$USERNAME" | chpasswd
echo "root:root" | chpasswd

# overlay the presets
cp -av ./preset/overlay/* /
cp -av ./preset/user/. /home/$USERNAME/

# remove package cache
rm -rvf /var/cache/apt/archives/*
rm -rvf /prebuild
rm -rvf /preset
EOF


# end chroot
# sudo umount $TARGET_ROOTFS_DIR/dev

echo "build successful,enjoy!!!"
