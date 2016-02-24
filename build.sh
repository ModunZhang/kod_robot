#!/bin/bash
# mac下运行脚本用命令行编译项目。编译后的文件位置bin/Release
# MULTI_THREAD宏定义,如果不需要启用多线程,将MULTI_THREAD设置为0
MULTI_THREAD=1
test -d bin && rm -rf bin
xcodebuild clean
xcodebuild -scheme kod_client -target kod_client -configuration Release GCC_PREPROCESSOR_DEFINITIONS="\${GCC_PREPROCESSOR_DEFINITIONS} MULTI_THREAD=${MULTI_THREAD}"
rm -rf build