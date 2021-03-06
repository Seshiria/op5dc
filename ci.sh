#!/bin/bash
#for github actions
set -eu
Initsystem(){
    apt update && \
    apt install -y \
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

sed -i "s/^KBUILD_CFLAGS   += -O3/KBUILD_CFLAGS   += -O2/" Makefile
#尝试修复以下问题
#由https://github.com/LineageOS/android_kernel_oneplus_msm8998/commit/1dc47f9e7d9de9f28628083ba8b14a0aa8d0c490 引入
#提交把gcc 优化级别设置为-O3，导致CC时报错
#../drivers/staging/qcacld-3.0/core/mac/src/pe/rrm/rrm_api.c:1211:8: error: 'report' may be used uninitialized in this function [-Werror=maybe-uninitialized]

##dc patch
Patch

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
Releases "`date +%Y%m%d`gcc-dc-fix"

#llvm build
#Patch
make -j$(nproc --all) O=out lineage_oneplus5_defconfig \
                        ARCH=arm64 \
                        SUBARCH=arm64
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      SUBARCH=arm64 \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      PATH=${GITHUB_WORKSPACE}/llvm/bin:$PATH \
                      CC=clang \
                      AR=llvm-ar \
                      NM=llvm-nm \
                      AS=llvm-as \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip
Releases "`date +%Y%m%d`llvm-dc"