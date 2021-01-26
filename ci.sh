#!/bin/bash
#for github actions
set -eu
Initsystem(){
    sudo apt update 
    sudo apt install -y \
            gcc \
            g++ \
            python \
            make \
            texinfo \
            texlive \
            bc \
            bison \
            build-essential \
            ccache \
            curl \
            flex \
            g++-multilib \
            gcc-multilib \
            git \
            gnupg \
            gperf \
            imagemagick \
            lib32ncurses5-dev \
            lib32readline-dev \
            lib32z1-dev \
            liblz4-tool \
            libncurses5-dev \
            libsdl1.2-dev \
            libssl-dev \
            libwxgtk3.0-gtk3-dev \
            libxml2 \
            libxml2-utils \
            lzop \
            pngcrush \
            rsync \
            schedtool \
            squashfs-tools \
            xsltproc \
            zip \
            zlib1g-dev \
            unzip \
            language-pack-zh-hans
}

Patch(){
    cp -R ../drivers/* ./drivers/
    echo "CONFIG_FLICKER_FREE=y" >> arch/arm64/configs/lineage_oneplus5_defconfig
}
Releases(){
    #path to ./kernel/
    cp -f out/arch/arm64/boot/Image.gz-dtb ../AnyKernel3/Image.gz-dtb
    bash ${GITHUB_WORKSPACE}/zip.sh ${1}
}

Initsystem
mkdir releases
cd ./kernel/
#gcc build
make -j$(nproc --all) O=out lineage_oneplus5_defconfig \
                        ARCH=arm64 \
                        SUBARCH=arm64
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      SUBARCH=arm64 \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi- \
                      PATH=${GITHUB_WORKSPACE}/aarch64/bin:${GITHUB_WORKSPACE}/arm/bin:$PATH
Releases gcc-debug
#dc patch
Patch
make -j$(nproc --all) O=out lineage_oneplus5_defconfig \
                        ARCH=arm64 \
                        SUBARCH=arm64
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      SUBARCH=arm64 \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi- \
                      PATH=${GITHUB_WORKSPACE}/aarch64/bin:${GITHUB_WORKSPACE}/arm/bin:$PATH
Releases "`date +%Y%m%d`gcc-dc"