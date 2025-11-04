#!/bin/bash

#################################
# UIEE引擎5分钟稳定运行测试
# 简化版测试脚本
#################################

echo "=================================="
echo "UIEE智能调度引擎5分钟稳定运行测试"
echo "=================================="

# 设置测试环境
export MODPATH="/tmp/magisk_test/data/adb/modules/uiee_smart_engine"
export MODDATA="$MODPATH/data"
export MODLOGS="$MODPATH/logs"
export MODBIN="$MODPATH/bin"

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
echo ""

# 启动引擎
echo "=== 启动引擎 ==="
cd "$MODPATH"
"$MODBIN/uiee_engine" &
ENGINE_PID=$!

echo "引擎PID: $ENGINE_PID"
sleep 5

# 检查引擎是否启动
if kill -0 "$ENGINE_PID" 2>/dev/null; then
    echo "✓ 引擎启动成功"
else
    echo "✗ 引擎启动失败"
    exit 1
fi

# 开始5分钟测试
echo ""
echo "=== 开始5分钟稳定运行测试 ==="
echo "开始时间: $(date)"
echo "引擎PID: $ENGINE_PID"

START_TIME=$(date +%s)
END_TIME=$((START_TIME + 300))  # 5分钟
CHECK_INTERVAL=30  # 每30秒检查一次

while [ $(date +%s) -lt $END_TIME ]; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    REMAINING=$((END_TIME - CURRENT_TIME))
    
    # 检查引擎状态
    if ! kill -0 "$ENGINE_PID" 2>/dev/null; then
        echo "✗ 引擎异常退出 (运行时间: ${ELAPSED}s)"
        break
    fi
    
    # 每30秒输出状态
    if [ $((ELAPSED % CHECK_INTERVAL)) -eq 0 ]; then
        echo "✓ 运行时间: ${ELAPSED}s / 300s, 剩余: ${REMAINING}s"
        
        # 检查日志大小
        if [ -f "$MODLOGS/engine.log" ]; then
            LOG_SIZE=$(wc -l < "$MODLOGS/engine.log")
            echo "  日志行数: $LOG_SIZE"
        fi
        
        # 检查内存使用
        if [ -f "/proc/$ENGINE_PID/status" ]; then
            VM_SIZE=$(grep VmSize /proc/$ENGINE_PID/status 2>/dev/null | awk '{print $2}')
            if [ -n "$VM_SIZE" ]; then
                echo "  内存使用: ${VM_SIZE}KB"
            fi
        fi
        
        # 检查性能日志
        if [ -f "$MODLOGS/performance.log" ]; then
            PERF_COUNT=$(wc -l < "$MODLOGS/performance.log")
            echo "  性能记录: $PERF_COUNT 条"
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
    sleep 2
    echo "引擎已停止"
fi

# 生成测试报告
echo ""
echo "=== 测试报告 ==="

# 计算实际运行时间
ACTUAL_TIME=$((CURRENT_TIME - START_TIME))
echo "实际运行时间: ${ACTUAL_TIME}s"

# 引擎状态
if kill -0 "$ENGINE_PID" 2>/dev/null; then
    echo "引擎运行状态: 正常退出"
else
    echo "引擎运行状态: 异常退出"
fi

# 日志统计
if [ -f "$MODLOGS/engine.log" ]; then
    SERVICE_LINES=$(wc -l < "$MODLOGS/engine.log")
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

# 检查核心功能
echo ""
echo "=== 核心功能检查 ==="

# 检查任务检测
if [ -f "$MODLOGS/engine.log" ] && grep -q "检测到新任务" "$MODLOGS/engine.log"; then
    echo "✓ 任务检测功能: 正常"
else
    echo "✗ 任务检测功能: 异常"
fi

# 检查调度执行
if [ -f "$MODLOGS/engine.log" ] && grep -q "调度执行完成" "$MODLOGS/engine.log"; then
    echo "✓ 调度功能: 正常"
else
    echo "✗ 调度功能: 异常"
fi

# 检查性能监控
if [ -f "$MODLOGS/performance.log" ] && [ $(wc -l < "$MODLOGS/performance.log") -gt 5 ]; then
    echo "✓ 性能监控: 正常"
else
    echo "✗ 性能监控: 异常"
fi

# 检查Web UI状态
if [ -f "$MODLOGS/web_ui.log" ] || [ -f "$MODLOGS/service.log" ] && grep -q "Web UI" "$MODLOGS/service.log"; then
    echo "✓ Web UI服务: 正常"
else
    echo "✗ Web UI服务: 异常"
fi

echo ""
echo "=================================="
echo "5分钟稳定运行测试完成"
echo "=================================="