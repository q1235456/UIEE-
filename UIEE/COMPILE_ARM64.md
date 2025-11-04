# ARM64编译指南

## 问题说明
当前模块的二进制文件是x86-64架构，无法在Android设备上运行。

## 解决方案

### 方案1: 使用GitHub Actions自动编译
1. 将项目上传到GitHub
2. 创建.github/workflows/compile.yml文件
3. GitHub会自动编译ARM64版本

### 方案2: 本地交叉编译
```bash
# 安装ARM64交叉编译器
sudo apt install g++-aarch64-linux-gnu

# 编译
aarch64-linux-gnu-g++ -std=c++17 -O2 -Wall -Wextra -static-libstdc++ -I./include -c ./bin/main.cpp -o main.o
aarch64-linux-gnu-g++ -std=c++17 -O2 -Wall -Wextra -static-libstdc++ -I./include -c ./bin/uiee_engine.cpp -o uiee_engine.o
aarch64-linux-gnu-g++ -pthread -static-libstdc++ main.o uiee_engine.o -o bin/uiee_engine_arm64
```

### 方案3: 使用Android NDK
```bash
export ANDROID_NDK_ROOT=/path/to/android-ndk
$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang++ -std=c++17 -O2 -I./include ./bin/main.cpp ./bin/uiee_engine.cpp -o bin/uiee_engine_arm64
```

## 验证方法
```bash
file bin/uiee_engine_arm64
# 应该显示: ARM aarch64
```
