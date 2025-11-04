# UIEE ARM64手动编译指南

## 方案1: 使用GitHub Actions (推荐)

1. 将项目推送到GitHub仓库
2. GitHub Actions会自动编译ARM64版本
3. 从Actions页面下载编译好的二进制文件

## 方案2: 本地交叉编译

### 安装ARM64交叉编译器
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install g++-aarch64-linux-gnu

# CentOS/RHEL
sudo yum install gcc-aarch64-linux-gnu

# macOS (使用Homebrew)
brew install aarch64-linux-gnu-gcc
```

### 编译命令
```bash
cd /workspace/uiee_module_v3
aarch64-linux-gnu-g++ -std=c++17 -O2 -Wall -Wextra -static-libstdc++ -I./include -c ./bin/main.cpp -o build/main.o
aarch64-linux-gnu-g++ -std=c++17 -O2 -Wall -Wextra -static-libstdc++ -I./include -c ./bin/uiee_engine.cpp -o build/uiee_engine.o
aarch64-linux-gnu-g++ -pthread -static-libstdc++ build/main.o build/uiee_engine.o -o bin/uiee_engine_arm64
chmod 755 bin/uiee_engine_arm64
```

## 方案3: 使用Android NDK

### 下载Android NDK
```bash
# 下载NDK
wget https://dl.google.com/android/repository/android-ndk-r25c-linux.zip
unzip android-ndk-r25c-linux.zip
export ANDROID_NDK_ROOT=$(pwd)/android-ndk-r25c
```

### 编译命令
```bash
cd /workspace/uiee_module_v3
$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang++ \
-std=c++17 -O2 -I./include ./bin/main.cpp ./bin/uiee_engine.cpp -o bin/uiee_engine_arm64
```

## 验证编译结果
```bash
file bin/uiee_engine_arm64
# 应该显示: ARM aarch64

# 测试运行
./bin/uiee_engine_arm64 --test
```

## 替换现有二进制
```bash
# 备份原文件
cp bin/uiee_engine bin/uiee_engine_x86_64

# 替换为ARM64版本
cp bin/uiee_engine_arm64 bin/uiee_engine
```

## 重新打包模块
```bash
cd /workspace/uiee_module_v3
zip -r uiee_module_v3.0_hamilton_arm64.zip . -x "build/*" "*.log" "*.tmp"
```
