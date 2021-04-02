#!/bin/bash
#for github actions
set -eu
Initsystem(){
    sudo apt update && \
    sudo apt install -y \
        gcc \
        libssl-dev
    #ghttps://github.com/LineageOS/android_prebuilts_build-tools
    export PATH=${GITHUB_WORKSPACE}/android_prebuilts_build-tools/path/linux-x86/:$PATH
    export PATH=${GITHUB_WORKSPACE}/android_prebuilts_build-tools/linux-x86/bin/:$PATH
}

Patch(){
    cp -R ../drivers/* ./drivers/
    echo "CONFIG_FLICKER_FREE=y" >> arch/arm64/configs/lineage_oneplus5_defconfig
}
Releases(){
    #path to ./kernel/
    cp -f out/arch/arm64/boot/Image.gz-dtb ../AnyKernel3/Image.gz-dtb
    #一天可能提交编译多次
    #用生成的文件的MD5来区分每次生成的文件
    var=`md5sum ../AnyKernel3/Image.gz-dtb`
    var=${var:0:5}
    bash ${GITHUB_WORKSPACE}/zip.sh ${1}_${var}
}


Initsystem
mkdir releases
cd ./kernel/

#llvm build
make -j$(nproc --all) O=out lineage_oneplus5_defconfig \
                        ARCH=arm64 \
                        SUBARCH=arm64
(make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      SUBARCH=arm64 \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      PATH=${GITHUB_WORKSPACE}/llvm/bin:$PATH \
                      CC="clang"\
                      CXX=clang++ \
                      AR=llvm-ar \
                      NM=llvm-nm \
                      AS=llvm-as \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip \
)&& Releases "op5lin17-llvm`date +%Y%m%d`" || echo "build error"

##dc patch
Patch
#llvm dc build
make -j$(nproc --all) O=out lineage_oneplus5_defconfig \
                        ARCH=arm64 \
                        SUBARCH=arm64
(make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      SUBARCH=arm64 \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      PATH=${GITHUB_WORKSPACE}/llvm/bin:$PATH \
                      CC="clang"\
                      CXX=clang++ \
                      AR=llvm-ar \
                      NM=llvm-nm \
                      AS=llvm-as \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip \
)&& Releases "op5lin17-dc-llvm`date +%Y%m%d`" || echo "dc build error"
