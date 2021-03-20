# oneplus 5 (cheeseburger) DC Dimming  kernel on lineageOS

[toc]

适用于一加5(cheeseburger)、基于lineageOS的dc调光内核。

由于第三方内核在一加5、官方lineageOS 16上，出现WiFi不可用的问题，所以把DC调光移植回lineageOS官方内核。


### 特点（问题列表）

- [x] ~~WIFI在lineageOS 16直接可用~~（过时）
- [x] DC调光
- [x] ~~启用VPN后，待机时电量消耗（似乎来~~源于lineageOS的问题，已经由上游解决）
- [ ] lineageOS18.0的内核源码，在lineageOS16的系统上，出现间接性的锁屏后双击唤醒失效（疑似llvm工具链编译的问题）

### 兼容性

**2020年12月31日：由于官方lineageOS主线已经切换到17.1，针对lineageOS16的测试已经结束，建议更新到最新的lineageOS版本。** 

- ~~一加5 (cheeseburger) lineageOS 16 （测试兼容）~~
- 一加5 (cheeseburger) lineageOS 17 （测试兼容）
- 一加5 (cheeseburger) 其他系统 （未测试）
- ~~一加5T (dumpling) lineageOS 16（理论兼容、未测试）~~
- 一加5T (dumpling) lineageOS 17（理论兼容、未测试）
- 一加5T (dumpling) 其他系统（未测试）

#### 系统与内核

| 内核版本/系统版本 | lineageOS16（Android9） | lineageOS17（Android10） |
| ----------------- | ----------------------- | ------------------------ |
| 153               | O                       | O                        |
| 153+              | X                       | O                        |

注：O代表已经经过真机测试，X代表未经过真机测试。

lineageOS16（Android9）最后经过测试的内核版本为4.4.153。

## 引用和参考过的资料

* 内核代码：https://github.com/LineageOS/android_kernel_oneplus_msm8998
* DC调光 ：https://github.com/lyq1996/android_kernel_oneplus_msm8998
* 鸣谢：[迅速入门Android内核编译 & 一加5 DC调光](https://makiras.org/archives/173?amp)
* 鸣谢：[DC调光进阶版的开发过程及思路](https://www.akr-developers.com/d/273)
* 交叉编译（gcc）：https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9
* 交叉编译（gcc）：https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9
* 交叉编译（llvm、clang）：https://developer.android.com/ndk/downloads
* 自动发布：https://github.com/ncipollo/release-action

## 构建

### 依赖处理

测试环境是docker的Ubuntu20.02 x86_64镜像

拉取本仓库以及子模块（由于内核和编译工具链的提交历史巨大，推荐使用``--depth=1``获取最新一次的提交。）

依赖图谱：

|           子模块名            |         GCC依赖          |         llvm依赖         |
| :---------------------------: | :----------------------: | :----------------------: |
|            aarch64            |           需要           |          不需要          |
|              arm              |           需要           |          不需要          |
|            kernel             |           需要           |           需要           |
|             llvm              |          不需要          |           需要           |
| android_prebuilts_build-tools |           需要           |           需要           |
|          AnyKernel3           | 可选（如果执行打包的话） | 可选（如果执行打包的话） |

````shell
#由于文档更新延后，可以参阅repo根目录下的ci.sh了解执行的操作
#以下内容仅供参考
##################################################
#先进入到当前repo的根目录
homepath=`pwd`
#处理依赖
apt update && \
apt install -y \
        gcc \
        libssl-dev

cd kernel/

#添加编译需要的依赖
export PATH=${homepath}/android_prebuilts_build-tools/path/linux-x86/:$PATH
export PATH=${homepath}/android_prebuilts_build-tools/linux-x86/bin/:$PATH

#复制补丁文件和写入补丁的配置信息
#未修改的情况下仅需执行一次
cp -R ../drivers/* ./drivers/
echo "CONFIG_FLICKER_FREE=y" >> arch/arm64/configs/lineage_oneplus5_defconfig

#配置编译
make -j$(nproc --all) O=out lineage_oneplus5_defconfig \
                        ARCH=arm64 \
                        SUBARCH=arm64

#使用GCC工具链编译
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      SUBARCH=arm64 \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi- \
                      PATH=${homepath}/aarch64/bin:${homepath}/arm/bin:$PATH
#或者使用llvm工具链编译
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      SUBARCH=arm64 \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      PATH=${homepath}/llvm/bin:$PATH \
                      CC=clang \
                      AR=llvm-ar \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip
#编译成功后可以在 out/out/arch/arm64/boot/ 获取 Image.gz-dtb

#可选操作
#执行打包
cp out/out/arch/arm64/boot/Image.gz-dtb ../AnyKernel3/Image.gz-dtb
cd ../AnyKernel3/
zip -r9 ../releases/zip.zip * -x .git README.md *placeholder

````



