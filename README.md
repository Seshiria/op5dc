# oneplus 5 (cheeseburger) DC Dimming  kernel on lineageOS

[![Build lineageOS Kernel](https://github.com/Seshiria/op5dc/actions/workflows/main.yml/badge.svg)](https://github.com/Seshiria/op5dc/actions/workflows/main.yml)

适用于一加5(cheeseburger)、基于lineageOS的dc调光内核。

由于第三方内核在一加5、官方lineageOS 16上，出现WiFi不可用的问题，所以把DC调光移植回lineageOS官方内核。

特性：
- 跟随lineageOS维护的内核持续更新。
- 使用aosp的ndk clang构建。
- 仅包含官方功能。

**本项目仅维护dc调光和构建编译。**

## 安装与使用内核

刷入前建议备份当前boot.img。打开本项目的release页面，根据tag查找对应的内核版本，在recovery模式下刷入，然后进入系统安装下方的控制器软件。

控制器：https://github.com/aa889788/DC-Tuner/blob/master/app/release/DC%20tuner.apk

**注意，一加5需要设置DC最小亮度为200以上。**

### 如何选择release

**一般情况下请使用最新的lineageOS系统和最新发布的内核稳定版本**

release命名方式：系统版本 + 内核版本 + 对用系统发布日期/发布次数（autobuild无此标签） +  构建日期（仅autobuild） + 内核文件hash（仅autobuild）

```
形如 （新）op5lin19.1-dc-44302v20220919.zip
        |—— 系统版本:lineageOS 19.1
        |—— 内核版本：4.4.302
        |—— 对应系统发布版本日期：20220919

形如 （旧）op5lin19.1-dc-44302v9.zip
        |—— 系统版本:lineageOS 19.1
        |—— 内核版本：4.4.302
        |—— 发布次数：9
```

在release'页面标注：“20220919 and up”，说明适用于lineage-19.1-20220919-nightly-cheeseburger-signed.zip。

由于官方维护者在维护系统内核的时候，修改内核但并不是会同时合并kernel的主线代码，所以会导致同一个内核版本号发布多次的问题。

而且没更新的内核版本号并不代表与之前系统兼容（可能会更新HAL层），所以请仔细核对release页面的发布信息。


## 恢复官方内核

请刷入备份的内核或者使用官方刷机包重新刷机，或者刷入对应版本官方刷机包内boot.img。


### 兼容性

~~2020年12月31日：由于官方lineageOS主线已经切换到17.1，针对lineageOS16的测试已经结束，建议更新到最新的lineageOS版本。~~ 

~~2021年4月1日：官方lineageOS18.1已经发布，所有测试迁移到Android11，建议更新到最新的lineageOS版本。~~ 

~~2022年5月23日：官方lineageOS19.1已经发布，所有测试迁移到Android12，请更新到最新的lineageOS版本。~~

**2023年1月2日，官方lineagesOS20.0已经发布，所有测试迁移到Android13，请更新到最新的lineageOS版本。**

#### 系统与内核兼容性

|   系统版本    |   内核    |
| ------------ | --------- |
|lineageOS16(Android9)| 4.4.153 |
|lineageOS17(Android10)| 4.4.153 - 4.4.258 |
|lineageOS18.1(Android11)| 4.4.258v2 - 4.4.302v2 |
|lineageOS19.1(android12)| 4.4.302v3 - 4.4.302v20221205 |
|lineageOS20(android13)| 4.4.302v20230102 and up |


注：O代表已经经过真机的兼容测试，X代表未经过测试。

lineageOS16（Android9）最后经过测试的内核版本为4.4.153。

lineageOS17（Android10）最后经过测试的版本为4.4.258。（注意4.4.258v2为不同的版本，请参阅发布的tag）

lineageOS18.1(Android11)最后经过测试的内核版本为4.4.302v2。（注意4.4.302v3为适配Android12的内核）

## 构建

测试环境是docker的Ubuntu20.02 x86_64镜像

拉取本仓库以及子模块，只编译的情况下推荐使用``--depth=1``获取最新一次的提交。

````shell
#由于文档更新延后，可以参阅repo根目录下的ci.sh了解具体执行的操作
#以下内容仅供参考
#
#自动构建（推荐）
#
##################################################
#先进入到当前repo的根目录
#如果非github actions，请指定GITHUB_WORKSPACE变量
export GITHUB_WORKSPACE=${pwd}
bash -x ci.sh
#由于使用git submoudle导致开发时大量的资源开销（需要pull完整模块的提交）
#所以修改成脚本处理依赖
#脚本会自动处理构建过程中的依赖和内核源码
##################################################

#
#手动构建
#
##################################################
#以下是编译过程中使用的指令，你需要手动解决依赖问题
#环境变量需要指定下面几个项目,请参阅ci.sh是怎么处理的
#prebuilts_build-tools
#aarch64 gcc
#arm gcc
#clang
make -j"$(nproc --all)" O=out lineage_oneplus5_defconfig \
    ARCH=arm64 \
    SUBARCH=arm64 \
    HOSTCC=clang \
    HOSTCXX=clang++

make -j"$(nproc --all)" O=out \
    ARCH=arm64 \
    SUBARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-android- \
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
    STRIP=llvm-strip
##################################################
````

## 引用和参考过的资料

* 内核代码：https://github.com/LineageOS/android_kernel_oneplus_msm8998
* DC调光 ：https://github.com/lyq1996/android_kernel_oneplus_msm8998
* 鸣谢：[迅速入门Android内核编译 & 一加5 DC调光](https://makiras.org/archives/173?amp)
* 鸣谢：[DC调光进阶版的开发过程及思路](https://www.akr-developers.com/d/273)
* 交叉编译（gcc）：https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9
* 交叉编译（gcc）：https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9
* 工具链：https://github.com/LineageOS/android_prebuilts_build-tools
* 交叉编译（llvm、clang）：https://developer.android.com/ndk/downloads
* Anykernel3：https://github.com/osm0sis/AnyKernel3
* 代码检出：https://github.com/actions/checkout
* 自动发布：https://github.com/ncipollo/release-action