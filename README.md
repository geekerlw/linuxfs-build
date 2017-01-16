# Build your own linux rootfs base on ubuntu
---------
## Introduction
The script can support you a base ubuntu rootfs, provide the following functions：  
1. username and boardname commission  
2. tiny xfce4 desktop environment  
3. use the tuna mirror sources.list  
4. chinese display and fonts support    
5. basic net tools  
6. xserver with 2d acceleration  
7. hardware decoder plugin named gstreamer-rockchip  
8. auto ethernet connect  
9. chinese timezone default set  
## Build deps
sudo apt install qemu-user-static binfmt-support  
## Build
the script support change ***username*** and ***boardname***  
the build env is named ***USERNAME*** and ***BOARDNAME***  
USERNAME=cqutprint BOARDNAME=rk3288 ./build-fs-base.sh  
