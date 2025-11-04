#!/bin/bash

# 一键编译脚本
set -e

echo "开始一键编译..."

# 检查编译器
if command -v aarch64-linux-gnu-g++ >/dev/null 2>&1; then
    echo "使用ARM64交叉编译器"
    CXX=aarch64-linux-gnu-g++
elif [ -n "$ANDROID_NDK_ROOT" ] && [ -f "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang++" ]; then
    echo "使用Android NDK"
    CXX="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang++"
else
    echo "错误: 未找到ARM64编译器"
    echo "请安装ARM64交叉编译器或设置ANDROID_NDK_ROOT环境变量"
    exit 1
fi

# 编译
echo "编译 main.cpp..."
$CXX -std=c++17 -O2 -Wall -Wextra -static-libstdc++ -I./include -c ./bin/main.cpp -o build/main.o

echo "编译 uiee_engine.cpp..."
$CXX -std=c++17 -O2 -Wall -Wextra -static-libstdc++ -I./include -c ./bin/uiee_engine.cpp -o build/uiee_engine.o

echo "链接生成ARM64二进制..."
$CXX -pthread -static-libstdc++ build/main.o build/uiee_engine.o -o bin/uiee_engine_arm64

echo "设置执行权限..."
chmod 755 bin/uiee_engine_arm64

echo "验证架构..."
file bin/uiee_engine_arm64

echo "编译完成!"
