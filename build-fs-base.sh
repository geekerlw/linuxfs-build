#!/bin/bash -e
# Base root filesystem build script
# set TARGET_ROOTFS_DIR by yourself, default dir in your build path named ubuntu

TARGET_ROOTFS_DIR="ubuntu"
ARCH="armhf"

if [ ! $BOARDNAME ]; then
	BOARDNAME="rk3288"
	echo -e "\033[1m\033[34m -------- Boardname is: $BOARDNAME -------- \033[0m"
fi
if [ ! $USERNAME ]; then
	USERNAME="cqutprint"
	echo -e "\033[1m\033[34m -------- USERNAME is: $USERNAME -------- \033[0m"
fi

# set ubuntu version
if [ ! $ROOTFS_VERSION ]; then
	ROOTFS_VERSION="16.04.1"
	echo -e "\033[1m\033[34m -------- Start build ubuntu $ROOTFS_VERSION -------- \033[0m"
fi

# create target dir and clean
if [ ! -e $TARGET_ROOTFS_DIR ]; then
	echo -e "\033[5m\033[34m -------- Make rootfs target dir -------- \033[0m"
	mkdir $TARGET_ROOTFS_DIR
fi
sudo rm -rvf $TARGET_ROOTFS_DIR/*

# get ubuntu base filesystem
if [ ! -e ubuntu-base-$ROOTFS_VERSION-base-armhf.tar.gz ]; then
	echo -e "\033[5m\033[34m -------- Download ubuntu base file system -------- \033[0m"
	wget http://cdimage.ubuntu.com/ubuntu-base/releases/$ROOTFS_VERSION/release/ubuntu-base-$ROOTFS_VERSION-base-armhf.tar.gz
fi

# extarct image
echo -e "\033[5m\033[34m -------- Extract image -------- \033[0m"
sudo tar -xvpf ubuntu-base-$ROOTFS_VERSION-base-armhf.tar.gz -C $TARGET_ROOTFS_DIR

# replace sources.list and dns server
echo -e "\033[5m\033[34m -------- Replace ubuntu source to tuna source mirror -------- \033[0m"
sudo cp -av ./preset/overlay/etc/apt/sources.list $TARGET_ROOTFS_DIR/etc/apt/sources.list
sudo cp -bv /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf

# prepare the environment to chroot
echo -e "\033[5m\033[34m -------- Preprare to chroot -------- \033[0m"
sudo cp -av ./prebuild/ $TARGET_ROOTFS_DIR/
sudo cp -av ./preset/ $TARGET_ROOTFS_DIR/
sudo cp -av /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/ 

# chroot to install some packages
echo -e "\033[5m\033[34m --------------------Change root----------------------- \033[0m"
cat << EOF | sudo chroot $TARGET_ROOTFS_DIR
apt update && apt upgrade -y

# timezone locale and keyboard
echo -e "\033[5m\033[34m -------- Set timezone keyboard and default language --------- \033[0m"
echo "UTC=yes" >> /etc/default/rcS
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
echo "LANG="zh_CN.UTF-8"" > /etc/default/locale
echo "LANGUAGE="zh_CN:en_GB:en"" >> /etc/default/locale
echo "XKBLAYOUT="us"" >> /etc/default/keyboard

# install some base tools
echo -e "\033[5m\033[34m -------- Install some base tools -------- \033[0m"
apt install -y xfce4 net-tools iputils-ping wicd vim

# gstreamer base tools
echo -e "\033[5m\033[34m -------- Install gstreamer base environment -------- \033[0m"
apt install -y gstreamer1.0-alsa gstreamer1.0-nice gstreamer1.0-plugins-bad \
gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-tools \
gstreamer1.0-x gstreamer1.0-plugins-bad-faad

# transitional chinese support
echo -e "\033[5m\033[34m -------- Add chinese support -------- \033[0m"
apt install -y fonts-wqy-microhei

# cups and hp printer driver
echo -e "\033[5m\033[34m -------- Add printer driver support -------- \033[0m"
apt install -y cups hplip

# Split screen tool
echo -e "\033[5m\033[34m -------- Add a split screen tool -------- \033[0m"
apt install -y devilspie

# xserver
echo -e "\033[5m\033[34m -------- Extract xserver to support 2D Accelerate -------- \033[0m"
dpkg -x ./prebuild/xserver/xserver-common*_all.deb /
dpkg -x ./prebuild/xserver/xserver-xorg-core*_armhf.deb /

# maligpu
echo -e "\033[5m\033[34m -------- Install libmali to support 3D Accelerate -------- \033[0m"
dpkg -i ./prebuild/libmali/libmali-rk-midgard*_armhf.deb 
dpkg -i ./prebuild/libmali/libmali-rk-dev*_armhf.deb 
rm -rvf /usr/lib/arm-linux-gnueabihf/mesa-egl/*

# libdrm
echo -e "\033[5m\033[34m -------- Install libdrm-rockchip -------- \033[0m"
dpkg -i ./prebuild/libdrm/libdrm-rockchip*_armhf.deb

# mpp
echo -e "\033[5m\033[34m -------- Install Media Process Platform (MPP) module -------- \033[0m"
dpkg -i ./prebuild/mpp/librockchip-mpp*_armhf.deb
dpkg -i ./prebuild/mpp/librockchip-vpu*_armhf.deb


# gstreamer-rockchip
echo -e "\033[5m\033[34m -------- Install gstreamer-rockchip to support hw decode -------- \033[0m"
dpkg -i ./prebuild/gstreamer-rockchip/gstreamer1.0-rockchip*_armhf.deb

# enable dhcp network
echo -e "\033[5m\033[34m -------- Enable ethernet autostart -------- \033[0m"
echo auto eth0 > /etc/network/interfaces.d/eth0
echo iface eth0 inet dhcp >> /etc/network/interfaces.d/eth0

# hostname
echo -e "\033[5m\033[34m -------- Set hostname -------- \033[0m"
echo $BOARDNAME > /etc/hostname 

# add user name and passwd default cqutprint
echo -e "\033[5m\033[34m -------- Add user and set passwd -------- \033[0m"
useradd -m -s /bin/bash $USERNAME
echo "$USERNAME:$USERNAME" | chpasswd
echo "root:root" | chpasswd

# overlay the presets
echo -e "\033[5m\033[34m -------- Extract presets -------- \033[0m"
cp -av ./preset/overlay/* /
cp -av ./preset/user/. /home/$USERNAME/

# remove package cache
echo -e "\033[5m\033[34m -------- Remove none needed packages -------- \033[0m"
rm -rvf /var/cache/apt/archives/*
rm -rvf /prebuild
rm -rvf /preset
EOF

# End chroot and the rootfs in ./ubuntu
echo -e "\033[1m\033[34m \n-------- Build successfully --------\n---- Auther: geekerlw@gmail.com ----\n \033[0m"
