#!/bin/bash
#for github actions
set -eu
source submodules.conf
#submodules
sudo apt update && sudo apt install -y unzip tar wget 
bash -x get-submodules.sh
Initsystem() {
    sudo apt update &&
        sudo apt install -y \
            libssl-dev \
            python
    export PATH="${GITHUB_WORKSPACE}"/android_prebuilts_build-tools-"${PREBUILTS_HASH}"/path/linux-x86/:$PATH
    export PATH="${GITHUB_WORKSPACE}"/android_prebuilts_build-tools-"${PREBUILTS_HASH}"/linux-x86/bin/:$PATH
    export PATH="${GITHUB_WORKSPACE}"/$LLVM_TAG/bin:"$PATH"
    export PATH="${GITHUB_WORKSPACE}"/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9-"${AARCH64_GCC_HASH}"/bin:"$PATH"
    export PATH="${GITHUB_WORKSPACE}"/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9-"${ARM_GCC_HASH}"/bin:"$PATH"

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
    md5=$(md5sum ../AnyKernel3-${ANYKERNEL_HASH}/Image.gz-dtb)
    md5tab=${md5:0:5}
    kernelversion=$(head -n 3 "${GITHUB_WORKSPACE}"/android_kernel_oneplus_msm8998-"${KERNEL_HASH}"/Makefile | awk '{print $3}' | tr -d '\n')
    buildtime=$(date +%Y%m%d-%H%M%S)
    bash "${GITHUB_WORKSPACE}"/zip.sh "${1}"-"${kernelversion}"_testbuild_"${buildtime}"_"${md5tab}" "${GITHUB_WORKSPACE}"/AnyKernel3-"${ANYKERNEL_HASH}"
    touch "${GITHUB_WORKSPACE}"/AnyKernel3-${ANYKERNEL_HASH}/buildinfo
    cat > "${GITHUB_WORKSPACE}"/AnyKernel3-${ANYKERNEL_HASH}/buildinfo <<EOF
    buildtime ${buildtime}
    Image.gz-dtb hash ${md5}
EOF
}
#使用指定的anykernel配置文件
cp "${GITHUB_WORKSPACE}"/anykernel.sh "${GITHUB_WORKSPACE}"/AnyKernel3-${ANYKERNEL_HASH}/anykernel.sh

Initsystem
mkdir releases
ls -lh
cd ./android_kernel_oneplus_msm8998-"${KERNEL_HASH}"/

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
    LLVM=1

(make -j"$(nproc --all)" O=out \
    ARCH=arm64 \
    SUBARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-android- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    LLVM=1 &&
    Releases "op5lin20-dc") || (echo "dc build error" && exit 1)
