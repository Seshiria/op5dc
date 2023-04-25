#!/bin/bash
#处理压缩包内的路径问题
cd "${2}" || exit
(command -v zip) || \
    sudo apt instal -y zip
zip -r9 ../releases/"${1}".zip * -x .git README.md *placeholder
ls -lh ../releases/
