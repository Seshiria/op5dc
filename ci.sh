#!/bin/bash
#for github actions
set -eu
if command -v sudo; then
    sudo apt update
else
    apt update
    apt install -y sudo
fi
source submodules.conf
#submodules
bash -x get-submodules.sh
Initsystem() {
    sudo apt install -y \
        libssl-dev \
        python2 \
        libc6-dev \
        binutils \
        libgcc-11-dev \
        zip
    # fix aarch64-linux-android-4.9-gcc 从固定的位置获取python
    test -f /usr/bin/python || ln /usr/bin/python2 /usr/bin/python
    export PATH="${GITHUB_WORKSPACE}"/android_prebuilts_build-tools-"${PREBUILTS_HASH}"/path/linux-x86/:$PATH
    export PATH="${GITHUB_WORKSPACE}"/android_prebuilts_build-tools-"${PREBUILTS_HASH}"/linux-x86/bin/:$PATH
    export PATH="${GITHUB_WORKSPACE}"/$LLVM_TAG/bin:"$PATH"
    export PATH="${GITHUB_WORKSPACE}"/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9-"${AARCH64_GCC_HASH}"/bin:"$PATH"
    export PATH="${GITHUB_WORKSPACE}"/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9-"${ARM_GCC_HASH}"/bin:"$PATH"

}

Patch_dc() {
    #cp -R ../drivers/* ./drivers/
    patch -p1 <../dc_patch/dc_patch.diff
    grep -q CONFIG_FLICKER_FREE arch/arm64/configs/lineage_oneplus5_defconfig || echo "CONFIG_FLICKER_FREE=y" >>arch/arm64/configs/lineage_oneplus5_defconfig
}
Releases() {
    #path to ./kernel/
    cp -f out/arch/arm64/boot/Image.gz-dtb ../AnyKernel3-${ANYKERNEL_HASH}/Image.gz-dtb
    #一天可能提交编译多次
    #用生成的文件的MD5来区分每次生成的文件
    md5=$(md5sum ../AnyKernel3-${ANYKERNEL_HASH}/Image.gz-dtb)
    md5tab=${md5:0:5}
    kernelversion=$(head -n 3 "${GITHUB_WORKSPACE}"/android_kernel_oneplus_msm8998-"${KERNEL_HASH}"/Makefile | awk '{print $3}' | tr -d '\n')
    buildtime=$(date +%Y%m%d-%H%M%S)
    touch "${GITHUB_WORKSPACE}"/AnyKernel3-${ANYKERNEL_HASH}/buildinfo
    cat >"${GITHUB_WORKSPACE}"/AnyKernel3-${ANYKERNEL_HASH}/buildinfo <<EOF
    buildtime ${buildtime}
    Image.gz-dtb hash ${md5}
EOF
    bash "${GITHUB_WORKSPACE}"/zip.sh "${1}"-"${kernelversion}"_testbuild_"${buildtime}"_"${md5tab}" "${GITHUB_WORKSPACE}"/AnyKernel3-"${ANYKERNEL_HASH}"
}
#使用指定的anykernel配置文件
cp "${GITHUB_WORKSPACE}"/anykernel.sh "${GITHUB_WORKSPACE}"/AnyKernel3-${ANYKERNEL_HASH}/anykernel.sh

Initsystem
test -d releases || mkdir releases
ls -lh
cd ./android_kernel_oneplus_msm8998-"${KERNEL_HASH}"/

##dc patch
Patch_dc
#Write flag
test -f localversion || touch localversion
cat >localversion <<EOF
-0
EOF
#llvm dc build
make -j"$(nproc --all)" O=out lineage_oneplus5_defconfig \
    ARCH=arm64 \
    SUBARCH=arm64 \
    LLVM=1

(make -j"$(nproc --all)" O=out \
    ARCH=arm64 \
    SUBARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-android- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    LLVM=1 &&
    Releases "op5lin22.1-dc") || (echo "dc build error" && exit 1)
