#!/bin/bash
# mac下运行脚本用命令行编译项目。编译后的文件位置bin/Release
test -d bin && rm -rf bin
xcodebuild clean
xcodebuild -scheme kod_client -target kod_client -configuration Release
rm -rf build