#!/usr/bin/env bash

# 音频输出切换到AirPods Pro脚本
# 动态查找AirPods Pro设备ID并设置为默认音频输出

echo "正在查找AirPods Pro设备..."

# 动态查找AirPods Pro的设备ID
AIRPODS_SINK_ID=$(wpctl status | grep -E "earph.*airpods.*daisy" | grep -E "\[vol:" | sed 's/.*[[:space:]]\([0-9]*\)\.\s.*/\1/')

if [ -z "$AIRPODS_SINK_ID" ]; then
    echo "❌ 未找到AirPods Pro设备，请确保："
    echo "   1. AirPods Pro已连接"
    echo "   2. 设备名称包含 'earph' 和 'airpods'"
    echo ""
    echo "当前可用的音频输出设备:"
    wpctl status | grep -A 20 "Sinks:"
    exit 1
fi

echo "找到AirPods Pro设备，ID: $AIRPODS_SINK_ID"
echo "正在设置为默认音频输出设备..."

# 设置默认音频输出设备
if wpctl set-default "$AIRPODS_SINK_ID"; then
    echo "✅ 成功设置AirPods Pro为默认音频输出设备"
    
    # 显示当前音频状态
    echo ""
    echo "当前音频输出设备:"
    wpctl get-volume "$AIRPODS_SINK_ID"
    
    echo ""
    echo "所有音频输出设备:"
    wpctl status | grep -A 20 "Sinks:"
else
    echo "❌ 设置失败，请检查AirPods Pro连接状态"
    exit 1
fi
