#!/bin/bash
set -eu
source submodules.conf
(command -v unzip && command -v wget && command -v tar ) || \
    apt install unzip  wget  tar -y
#wget or curl
DOWNLOADER() {
    __download_url=$1
    __download_name=$2
    wget -c -N -q -O "${__download_name}" "${__download_url}"
}
# tar
if [ -x "$(command -v tar)" ]; then
    TAR="tar"
else
    echo "Error: tar is required"
    exit 1
fi
# unzip
if [ -x "$(command -v unzip)" ]; then
    UNZIP="unzip -q "
else
    echo "Error: unzip is required"
    exit 1
fi
# if llvm is not installed, install it
if [ ! -d "./$LLVM_TAG/bin" ]; then
    echo "llvm is not installed, installing it"
    #download llvm and tar it
    DOWNLOADER $LLVM_URL llvm.tar-$LLVM_TAG.tar.gz
    mkdir $LLVM_TAG
    $TAR -zxvf llvm.tar-$LLVM_TAG.tar.gz -C $LLVM_TAG
fi
# if aarch64 gcc is not installed, install it
if [ ! -d "./android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9-${AARCH64_GCC_HASH}/bin" ]; then
    echo "aarch gcc is not installed, installing it"
    #download aarch gcc and tar it
    DOWNLOADER $AARCH64_GCC_URL aarch64_gcc-$AARCH64_GCC_HASH.zip
    $UNZIP aarch64_gcc-$AARCH64_GCC_HASH.zip
fi
# if arm gcc is not installed, install it
if [ ! -d "./android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9-${ARM_GCC_HASH}/bin" ]; then
    echo "arm gcc is not installed, installing it"
    #download arm gcc and tar it
    DOWNLOADER $ARM_GCC_URL arm_gcc-$ARM_GCC_HASH.zip
    $UNZIP arm_gcc-$ARM_GCC_HASH.zip
fi
# if prebuilts is not installed, install it
if [ ! -d "./android_prebuilts_build-tools-${PREBUILTS_HASH}/linux-x86/bin/" ]; then
    echo "clang is not installed, installing it"
    #download clang and tar it
    DOWNLOADER $PREBUILTS_URL prebuilts-$PREBUILTS_HASH.zip
    $UNZIP prebuilts-$PREBUILTS_HASH.zip
fi
# if anykernel is not installed, install it
if [ ! -d "./AnyKernel3-${ANYKERNEL_HASH}" ]; then
    echo "anykernel3 is not installed, installing it"
    #download anykernel and tar it
    DOWNLOADER $ANYKERNEL_URL anykernel-$ANYKERNEL_HASH.zip
    $UNZIP anykernel-$ANYKERNEL_HASH.zip
fi
# download kernel 
if [ ! -d "./android_kernel_oneplus_msm8998-${KERNEL_HASH}" ]; then
    echo "kernel is not installed, installing it"
    #download kernel and tar it
    DOWNLOADER $KERNEL_URL kernel-$KERNEL_HASH.zip
    $UNZIP kernel-$KERNEL_HASH.zip
fi