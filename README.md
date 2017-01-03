# Build your own linux rootfs base on ubuntu
---------
## Build deps
sudo apt install qemu-user-static binfmt-support  
## Build
the script support change ***username*** and ***boardname***  
the build env is named ***USERNAME*** and ***BOARDNAME***  
USERNAME=cqutprint BOARDNAME=rk3288 ./build-fs-base.sh  
