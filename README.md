# oneplus 5 (cheeseburger) DC Dimming  kernel on lineageOS

适用于一加5(cheeseburger)、基于lineageOS的dc调光内核。

由于第三方内核在一加5、官方lineageOS 16上，出现WiFi不可用的问题，所以把DC调光移植回lineageOS官方内核。


### 特点（问题列表）

- [x] WIFI在lineageOS 16直接可用
- [x] DC调光
- [ ] 启用VPN后，待机时电量消耗（似乎来源于lineageOS的问题）
- [ ] lineageOS18.0的内核源码，在lineageOS16的系统上，出现间接性的锁屏后双击唤醒失效

### 兼容性

** 2020年11月22日：由于官方lineageOS主线已经切换到17.1，针对lineageOS16的测试将会在最近结束，建议更新到最新的lineageOS版本。 **

- 一加5 (cheeseburger) lineageOS 16 （测试兼容）

- 一加5 (cheeseburger) lineageOS 17 （理论兼容、未测试）

- 一加5 (cheeseburger) 其他系统 （未测试）

- 一加5T (dumpling) lineageOS 16（理论兼容、未测试）

- 一加5T (dumpling) lineageOS 17（理论兼容、未测试）

- 一加5T (dumpling) 其他系统（未测试）

  

## 引用

* 上游：https://github.com/LineageOS/android_kernel_oneplus_msm8998
* DC调光 ：https://github.com/lyq1996/android_kernel_oneplus_msm8998
* 鸣谢：[迅速入门Android内核编译 & 一加5 DC调光](https://makiras.org/archives/173?amp)
* 鸣谢：[DC调光进阶版的开发过程及思路](https://www.akr-developers.com/d/273)
* 交叉编译：https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9
* 交叉编译（llvm、clang）：https://developer.android.com/ndk/downloads
* 自动发布：https://github.com/ncipollo/release-action

## 构建

### 依赖处理

todo