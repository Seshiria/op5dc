#!/bin/bash
#for github actions
set -eu
Initsystem() {
    sudo apt update &&
        sudo apt install -y \
            libssl-dev \
            python
    export PATH="${GITHUB_WORKSPACE}"/android_prebuilts_build-tools-"${PREBUILTS_HASH}"/path/linux-x86/:$PATH
    export PATH="${GITHUB_WORKSPACE}"/android_prebuilts_build-tools-"${PREBUILTS_HASH}"/linux-x86/bin/:$PATH
    export PATH="${GITHUB_WORKSPACE}"/$LLVM_TAG/bin:"$PATH"

}

Patch() {
    cp -R ../drivers/* ./drivers/
    echo "CONFIG_FLICKER_FREE=y" >>arch/arm64/configs/lineage_oneplus5_defconfig
}
Releases() {
    #path to ./kernel/
    cp -f out/arch/arm64/boot/Image.gz-dtb ../AnyKernel3-${ANYKERNEL_HASH}/Image.gz-dtb
    #一天可能提交编译多次
    #用生成的文件的MD5来区分每次生成的文件
    var=$(md5sum ../AnyKernel3-${ANYKERNEL_HASH}/Image.gz-dtb)
    md5tab=${var:0:5}
    kernelversion=$(head -n 3 "${GITHUB_WORKSPACE}"/kernel/Makefile | awk '{print $3}' | tr -d '\n')
    buildtime=$(date +%Y%m%d)
    bash "${GITHUB_WORKSPACE}"/zip.sh "${1}"-"${kernelversion}"_testbuild_"${buildtime}"_"${md5tab}"
}
#使用指定的anykernel配置文件
cp "${GITHUB_WORKSPACE}"/anykernel.sh "${GITHUB_WORKSPACE}"/AnyKernel3-${ANYKERNEL_HASH}/anykernel.sh

Initsystem
mkdir releases
cd ./kernel/

#Write flag
touch localversion
cat >localversion <<EOF
~DCdimming-for-Seshiria
EOF

##dc patch
Patch
#llvm dc build
make -j"$(nproc --all)" O=out lineage_oneplus5_defconfig \
    ARCH=arm64 \
    SUBARCH=arm64 \
    HOSTCC=clang \
    HOSTCXX=clang++

(make -j"$(nproc --all)" O=out \
    ARCH=arm64 \
    SUBARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    HOSTCC=clang \
    HOSTCXX=clang++ \
    CC=clang \
    CXX=clang++ \
    AR=llvm-ar \
    NM=llvm-nm \
    AS=llvm-as \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip &&
    Releases "op5lin19.1-dc") || (echo "dc build error" && exit 1)
