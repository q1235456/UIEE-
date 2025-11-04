#!/bin/bash

#################################
# UIEE模块C++编译脚本
# 3.0版本 - ARM64原生编译
#################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 编译目录
BUILD_DIR="/workspace/uiee_module_v3/build"
SRC_DIR="/workspace/uiee_module_v3/bin"
INCLUDE_DIR="/workspace/uiee_module_v3/include"
OUTPUT_DIR="/workspace/uiee_module_v3/bin"

# 清理函数
cleanup() {
    echo -e "${YELLOW}清理编译目录...${NC}"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
}

# 编译函数
compile() {
    echo -e "${GREEN}开始编译UIEE引擎...${NC}"
    
    # 检查NDK环境
    if [ -z "$ANDROID_NDK_ROOT" ]; then
        echo -e "${RED}错误: ANDROID_NDK_ROOT环境变量未设置${NC}"
        echo "请设置Android NDK路径，例如:"
        echo "export ANDROID_NDK_ROOT=/path/to/android-ndk"
        exit 1
    fi
    
    # 设置编译器
    CXX="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang++"
    STRIP="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android-strip"
    
    if [ ! -f "$CXX" ]; then
        echo -e "${RED}错误: 编译器不存在: $CXX${NC}"
        echo "请确保Android NDK已正确安装"
        exit 1
    fi
    
    # 编译参数
    CXXFLAGS="-std=c++17 -O2 -Wall -Wextra"
    LDFLAGS="-pthread -static-libstdc++"
    INCLUDES="-I$INCLUDE_DIR"
    
    # 编译源文件
    echo -e "${YELLOW}编译 main.cpp...${NC}"
    $CXX $CXXFLAGS $INCLUDES -c "$SRC_DIR/main.cpp" -o "$BUILD_DIR/main.o"
    
    echo -e "${YELLOW}编译 uiee_engine.cpp...${NC}"
    $CXX $CXXFLAGS $INCLUDES -c "$SRC_DIR/uiee_engine.cpp" -o "$BUILD_DIR/uiee_engine.o"
    
    # 链接
    echo -e "${YELLOW}链接生成可执行文件...${NC}"
    $CXX $LDFLAGS "$BUILD_DIR/main.o" "$BUILD_DIR/uiee_engine.o" -o "$OUTPUT_DIR/uiee_engine"
    
    # 剥离调试信息
    echo -e "${YELLOW}剥离调试信息...${NC}"
    $STRIP "$OUTPUT_DIR/uiee_engine"
    
    # 设置执行权限
    chmod 755 "$OUTPUT_DIR/uiee_engine"
    
    echo -e "${GREEN}编译完成!${NC}"
    echo -e "输出文件: $OUTPUT_DIR/uiee_engine"
    
    # 显示文件信息
    ls -lh "$OUTPUT_DIR/uiee_engine"
}

# 验证函数
verify() {
    echo -e "${YELLOW}验证编译结果...${NC}"
    
    if [ ! -f "$OUTPUT_DIR/uiee_engine" ]; then
        echo -e "${RED}错误: 编译失败，可执行文件不存在${NC}"
        exit 1
    fi
    
    # 检查文件类型
    file_info=$(file "$OUTPUT_DIR/uiee_engine")
    echo -e "文件信息: $file_info"
    
    # 检查是否为ARM64二进制
    if echo "$file_info" | grep -q "ARM aarch64"; then
        echo -e "${GREEN}✓ 正确的ARM64架构${NC}"
    else
        echo -e "${YELLOW}警告: 可能不是ARM64架构${NC}"
    fi
    
    # 测试运行
    echo -e "${YELLOW}测试运行...${NC}"
    timeout 5s "$OUTPUT_DIR/uiee_engine" --test || true
}

# 主函数
main() {
    echo "=================================="
    echo "UIEE智能调度引擎编译脚本 v3.0"
    echo "=================================="
    
    cleanup
    compile
    verify
    
    echo -e "${GREEN}=================================="
    echo "编译成功完成!"
    echo "==================================${NC}"
}

# 运行主函数
main "$@"