#/bin/bash
#处理压缩包内的路径问题
cd ${GITHUB_WORKSPACE}/AnyKernel3-${ANYKERNEL_HASH}/
zip -r9 ../releases/${1}.zip * -x .git README.md *placeholder
ls -lh ../releases/