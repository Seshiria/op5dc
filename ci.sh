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
Patch_ksu() {
    #The kernelsu module is no longer supported and will be removed in the future.
    ##
    test -d KernelSU || mkdir KernelSU
    cp -R ../KernelSU-$KERNELSU_HASH/* ./KernelSU/
    #source  https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh
    GKI_ROOT=$(pwd)
    DRIVER_DIR="$GKI_ROOT/drivers"
    cd "$DRIVER_DIR"
    if test -d "$GKI_ROOT/common/drivers"; then
        ln -sf "../../KernelSU/kernel" "kernelsu"
    elif test -d "$GKI_ROOT/drivers"; then
        ln -sf "../KernelSU/kernel" "kernelsu"
    fi
    cd "$GKI_ROOT"
    DRIVER_MAKEFILE=$DRIVER_DIR/Makefile
    grep -q "kernelsu" "$DRIVER_MAKEFILE" || printf "\nobj-y += kernelsu/\n" >>"$DRIVER_MAKEFILE"
    #额外的修补
    grep -q CONFIG_KSU arch/arm64/configs/lineage_oneplus5_defconfig || \
        echo "CONFIG_KSU=y" >>arch/arm64/configs/lineage_oneplus5_defconfig
    grep -q CONFIG_OVERLAY_FS arch/arm64/configs/lineage_oneplus5_defconfig || \
        echo "CONFIG_OVERLAY_FS=y" >>arch/arm64/configs/lineage_oneplus5_defconfig
    #修补kernelsu/makefile
    ## https://gist.github.com/0penBrain/7be59a48aba778c955d992aa69e524c5
    KSU_GIT_VERSION=$(curl -I -k "https://api.github.com/repos/tiann/KernelSU/commits?per_page=1&sha=$KERNELSU_HASH" | \
        sed -n '/^[Ll]ink:/ s/.*"next".*page=\([0-9]*\).*"last".*/\1/p')
    if grep -q import_KSU_GIT_VERSION KernelSU/kernel/Makefile ;then
        echo "The patch already exists, you may need to reset the relevant files of ksu"
    else
        echo "Patching..." 
        patch -p1 <../ksu_patch/import_patch.diff
    fi
    #KernelSU/kernel/ksu.h :10
    KERNEL_SU_VERSION=$(expr "$KSU_GIT_VERSION" + 10200) #major * 10000 + git version + 200
    #拷贝修补后的文件
    #cp -R ../ksu_patch/* ./
    patch -p1 <../ksu_patch/ksu_patch.diff
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
    Releases "op5lin21-dc") || (echo "dc build error" && exit 1)

##kernelsu
echo "The kernelsu module is no longer supported and will be removed in the future."
Patch_ksu
test -f localversion || touch localversion
cat >localversion <<EOF
-1
EOF
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
    LLVM=1 \
    import_KSU_GIT_VERSION="${KSU_GIT_VERSION}" &&
    Releases "op5lin21-dc-ksu$KERNEL_SU_VERSION") || (echo "ksu build error" && exit 1)
