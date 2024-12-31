#!/bin/sh
set -e
if [ -f submodules.conf ]; then
    . submodules.conf
fi
changed=0
#从github上获取最新hash
get_hash() {
    repo=$1
    branch=$2
    wget -O - -q https://api.github.com/repos/"$repo"/commits/"$branch" | grep -m 1 sha |  awk '{print $2}' | tr -d '",'
}
get_release_hash() {
    repo=$1
    branch=$2
    tag=$(wget -O - -q https://api.github.com/repos/"$repo"/releases/latest | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    wget -O - -q https://api.github.com/repos/"$repo"/git/refs/tags/"$tag"| grep -m 1 sha |  awk '{print $2}' | tr -d '",'
}
#hash比较
compare_hash() {
    _name=$1
    _hash=$2
    eval _name_hash=\$"$_name"
    if [ -z "$_hash" ]; then
        echo "${_name} no get hash"
            elif [ "$_hash" != "${_name_hash}" ]; then
            eval "$_name"="$_hash"
            echo "update $_name"
            changed=1
    fi
}
update_conf() {
        echo "update submodules.conf"
        #写入配置文件
        cat > submodules.conf << EOF

LLVM_TAG=$LLVM_TAG
LLVM_URL=$LLVM_URL
#aarch64 gcc 
AARCH64_GCC_HASH=$AARCH64_GCC_HASH
AARCH64_GCC_URL=https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9/archive/"\${AARCH64_GCC_HASH}".zip
#arm gcc 
ARM_GCC_HASH=$ARM_GCC_HASH
ARM_GCC_URL=https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9/archive/"\${ARM_GCC_HASH}".zip
#prebuilts toolchain
PREBUILTS_HASH=$PREBUILTS_HASH
PREBUILTS_URL=https://github.com/LineageOS/android_prebuilts_build-tools/archive/"\${PREBUILTS_HASH}".zip
#Anykernel
ANYKERNEL_HASH=$ANYKERNEL_HASH
ANYKERNEL_URL=https://github.com/osm0sis/AnyKernel3/archive/"\${ANYKERNEL_HASH}".zip
#lineageos kernel
KERNEL_HASH=$KERNEL_HASH
KERNEL_URL=https://github.com/LineageOS/android_kernel_oneplus_msm8998/archive/"\${KERNEL_HASH}".zip
EOF
}

#lineage_branch=lineage-21
# LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9
up_hash=$(get_hash "LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9" "lineage-19.1")
compare_hash "AARCH64_GCC_HASH" "$up_hash"
up_hash=$(get_hash "LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9" "lineage-19.1")
compare_hash "ARM_GCC_HASH" "$up_hash"
up_hash=$(get_hash "LineageOS/android_prebuilts_build-tools" "lineage-21.0")
compare_hash "PREBUILTS_HASH" "$up_hash"
up_hash=$(get_hash "LineageOS/android_kernel_oneplus_msm8998" "lineage-22.1")
compare_hash "KERNEL_HASH" "$up_hash"
up_hash=$(get_hash "osm0sis/AnyKernel3" "master")
compare_hash "ANYKERNEL_HASH" "$up_hash"

if [ "$changed" = "1" ]; then
    update_conf
    else
    echo "no update submodules conf"
fi
