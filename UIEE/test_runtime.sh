#!/bin/bash

#################################
# UIEE引擎运行时测试脚本
# 模拟Magisk环境运行测试
#################################

echo "=================================="
echo "UIEE智能调度引擎运行时测试"
echo "=================================="

# 设置测试环境
export TEST_MODE=1
export MODPATH="/tmp/magisk_test/data/adb/modules/uiee_smart_engine"
export MODDATA="$MODPATH/data"
export MODLOGS="$MODPATH/logs"
export MODCONF="$MODPATH/conf"
export MODBIN="$MODPATH/bin"

# 设置环境变量供引擎使用
export MODPATH="$MODPATH"

# 创建测试目录
mkdir -p "$MODDATA/config"
mkdir -p "$MODDATA/cache"
mkdir -p "$MODDATA/logs"
mkdir -p "$MODDATA/performance"

# 设置权限
chmod 755 "$MODPATH"
chmod 755 "$MODDATA"
chmod 755 "$MODDATA/config"
chmod 755 "$MODDATA/cache"
chmod 755 "$MODDATA/logs"
chmod 755 "$MODDATA/performance"

# 创建日志文件
touch "$MODLOGS/service.log"
touch "$MODLOGS/error.log"
touch "$MODLOGS/performance.log"

echo "测试环境初始化完成"
echo "模块路径: $MODPATH"
echo "数据路径: $MODDATA"
echo "日志路径: $MODLOGS"
echo ""

# 测试引擎启动
echo "=== 测试引擎启动 ==="
cd "$MODPATH"
"$MODBIN/uiee_engine" --daemon &
ENGINE_PID=$!

echo "引擎PID: $ENGINE_PID"
sleep 3

# 检查引擎是否启动
if kill -0 "$ENGINE_PID" 2>/dev/null; then
    echo "✓ 引擎启动成功"
    echo "$ENGINE_PID" > "$MODDATA/engine.pid"
else
    echo "✗ 引擎启动失败"
    exit 1
fi

# 状态检查
echo ""
echo "=== 状态检查 ==="
"$MODBIN/uiee_engine" --status

# 性能测试
echo ""
echo "=== 性能测试 ==="
for i in {1..10}; do
    echo "第 $i 次性能检查..."
    
    # 获取性能指标
    if [ -f "$MODLOGS/performance.log" ]; then
        tail -1 "$MODLOGS/performance.log" 2>/dev/null || echo "暂无性能数据"
    fi
    
    # 模拟任务添加
    "$MODBIN/uiee_engine" --test > /dev/null 2>&1
    
    sleep 2
done

# 长期运行测试
echo ""
echo "=== 开始长期运行测试 (5分钟) ==="
echo "开始时间: $(date)"

START_TIME=$(date +%s)
END_TIME=$((START_TIME + 300))  # 5分钟

while [ $(date +%s) -lt $END_TIME ]; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    REMAINING=$((END_TIME - CURRENT_TIME))
    
    # 检查引擎状态
    if ! kill -0 "$ENGINE_PID" 2>/dev/null; then
        echo "✗ 引擎异常退出"
        break
    fi
    
    # 每30秒输出状态
    if [ $((ELAPSED % 30)) -eq 0 ]; then
        echo "运行时间: ${ELAPSED}s / 300s, 剩余: ${REMAINING}s"
        
        # 检查日志大小
        if [ -f "$MODLOGS/service.log" ]; then
            LOG_SIZE=$(wc -l < "$MODLOGS/service.log")
            echo "  日志行数: $LOG_SIZE"
        fi
        
        # 检查内存使用
        if [ -f "/proc/$ENGINE_PID/status" ]; then
            VM_SIZE=$(grep VmSize /proc/$ENGINE_PID/status 2>/dev/null | awk '{print $2}')
            if [ -n "$VM_SIZE" ]; then
                echo "  内存使用: ${VM_SIZE}KB"
            fi
        fi
    fi
    
    sleep 1
done

# 结束测试
echo ""
echo "=== 测试结束 ==="
echo "结束时间: $(date)"

# 停止引擎
if kill -0 "$ENGINE_PID" 2>/dev/null; then
    kill "$ENGINE_PID"
    echo "引擎已停止"
fi

# 生成测试报告
echo ""
echo "=== 测试报告 ==="

# 引擎运行时间
if [ -f "$MODDATA/engine.pid" ]; then
    echo "引擎运行状态: 正常"
else
    echo "引擎运行状态: 异常"
fi

# 日志统计
if [ -f "$MODLOGS/service.log" ]; then
    SERVICE_LINES=$(wc -l < "$MODLOGS/service.log")
    echo "服务日志行数: $SERVICE_LINES"
fi

if [ -f "$MODLOGS/error.log" ]; then
    ERROR_LINES=$(wc -l < "$MODLOGS/error.log")
    echo "错误日志行数: $ERROR_LINES"
fi

if [ -f "$MODLOGS/performance.log" ]; then
    PERF_LINES=$(wc -l < "$MODLOGS/performance.log")
    echo "性能日志行数: $PERF_LINES"
fi

# 检查文件完整性
echo ""
echo "=== 文件完整性检查 ==="

files=(
    "$MODPATH/module.prop"
    "$MODPATH/service.sh"
    "$MODBIN/uiee_engine"
    "$MODCONF/uiee.conf"
    "$MODPATH/webroot/index.html"
    "$MODPATH/webroot/styles.css"
    "$MODPATH/webroot/app.js"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file (缺失)"
    fi
done

echo ""
echo "=================================="
echo "运行时测试完成"
echo "=================================="