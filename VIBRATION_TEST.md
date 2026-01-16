# Vibration Feature Test Guide

## 功能说明

已实现震动反馈功能，卡片现在可以在特定事件时触发设备震动：

### 震动触发场景
1. **收到新数据**: 根据动作类型触发震动
   - 推荐动作: 短震动 (500ms)
   - 探测动作: 长震动 (1000ms)
2. **连接成功**: 短震动 (200ms)
3. **连接错误**: 双震动 (300ms)

### 震动模式说明
- **RECOMMEND**: 500ms 短震动 - 推荐动作时触发
- **PROBE**: 1000ms 长震动 - 探测动作时触发
- **CONNECTED**: 200ms 极短震动 - 连接成功时触发
- **ERROR**: 300ms 中等震动 - 连接错误时触发

## 测试方法

### 前提条件
1. 确保设备支持震动功能
2. 确保应用有震动权限
3. 震动功能已启用（系统设置中）

### 测试步骤

#### 1. 测试推荐动作震动
```bash
# 发送推荐动作数据
python D:\proj\datapallet\app_server\test.py

# 或手动发送curl请求
curl -X POST http://localhost:8080/api/recommendations \
  -H "Content-Type: application/json" \
  -d '{
    "id": "rec_001",
    "type": "recommend",
    "action": "transit_QR_code",
    "timestamp": 1736923200,
    "metadata": {
      "reward": 0.8,
      "description": "Subway station ahead"
    }
  }'
```

**预期结果**: 设备震动500ms

#### 2. 测试探测动作震动
```bash
# 发送探测动作数据
curl -X POST http://localhost:8080/api/recommendations \
  -H "Content-Type: application/json" \
  -d '{
    "id": "rec_002",
    "type": "probe",
    "action": "QUERY_LOC_GPS",
    "timestamp": 1736923200,
    "metadata": {
      "reward": 0.6,
      "description": "Get GPS location"
    }
  }'
```

**预期结果**: 设备震动1000ms

#### 3. 测试连接成功震动
1. 启动服务器
2. 安装应用并添加卡片
3. 卡片自动连接服务器
4. 连接成功时

**预期结果**: 设备震动200ms

#### 4. 测试连接错误震动
1. 停止服务器
2. 让卡片尝试连接
3. 连接失败时

**预期结果**: 设备震动300ms

## 权限管理

### 自动权限申请
- 卡片创建时自动检查震动权限
- 如果权限未授予，弹出权限申请对话框
- 用户授权后震动功能启用

### 手动权限检查
如果震动不工作，可以手动检查：
1. 设置 → 应用管理 → Action Recommendation
2. 权限 → 检查"震动"权限状态

### 系统震动设置
确保系统震动功能已启用：
1. 设置 → 声音和振动
2. 确认"振动"开关已打开
3. 可以调整振动强度

## 故障排查

### 问题1: 收到数据但没有震动
**可能原因**:
- 震动权限未授予
- 系统震动已关闭
- 设备不支持震动

**解决方法**:
1. 检查应用权限设置
2. 检查系统震动设置
3. 重启应用

### 问题2: 震动太强或太弱
**解决方法**:
1. 在系统设置中调整震动强度
2. 在VibrationService.ets中修改震动时长参数

### 问题3: 权限被拒绝
**解决方法**:
1. 设置 → 应用 → Action Recommendation → 权限
2. 手动授予"震动"权限
3. 重启应用

## 代码结构

### VibrationService类
```typescript
// 主要方法
- checkPermission(): 检查权限状态
- requestPermission(): 申请震动权限
- ensurePermission(): 确保有权限
- vibrateRecommend(): 触发推荐动作震动
- vibrateProbe(): 触发探测动作震动
- vibrateConnected(): 触发连接成功震动
- vibrateError(): 触发错误震动
- stopVibration(): 停止震动
```

### WidgetCard集成
```typescript
// 震动触发点
- initVibration(): 初始化时检查权限
- handleMessage(): 收到数据时根据类型触发震动
- handleStatusChange(): 连接状态变化时触发震动
- cleanup(): 清理时停止震动
```

## 下一步优化

可以继续优化的方向：
1. 震动强度可配置
2. 震动模式可自定义
3. 震动历史记录
4. 震动统计功能