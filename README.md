# HarmonyOS 智能动作推荐卡片 (HTTP轮询实现版)

> **项目状态**: ✅ 已完成 - 功能完整，可稳定运行

hdc rport tcp:8080 tcp:8080

ip设置：entry/src/main/ets/common/CommonConstants.ets

static readonly SERVER_URL: string = 'http://127.0.0.1:8080'
## 项目概述

### 应用名称
Action Recommendation Card (HarmonyOS Widget)

### 核心功能
1. **卡片展示**: 在桌面显示4×4智能动作推荐卡片
2. **HTTP轮询通信**: 每2秒轮询服务器获取最新推荐数据
3. **智能震动反馈**: 仅在实际数据变化时触发震动（800ms）
4. **统一数据格式**: 支持动作类型、场景分类和图像显示
5. **后台运行**: 使用Worker线程+长时任务实现后台持续轮询
6. **实时更新**: 数据变化时自动更新卡片显示

### 架构
- **轻量级轮询**: 2秒间隔HTTP GET轮询，简单可靠
- **数据智能比较**: 震动仅在实际内容变化时触发
- **后台保活**: Worker线程+长时任务确保应用不被系统回收
- **统一数据模型**: 简化数据结构，易于扩展和维护
- **详细日志**: 完整的数据流追踪和错误诊断

##                  架构

### 项目结构
```
dqnApp/
├── entry/src/main/ets/
│   ├── common/                    # 公共模块
│   │   ├── CommonConstants.ets    # 常量定义
│   │   ├── CommonData.ets         # 数据模型定义
│   │   └── utils/PreferencesUtil.ets # 存储工具
│   ├── service/                   # 业务服务
│   │   ├── DataService.ets        # 数据解析服务
│   │   └── HTTPPollService.ets    # HTTP轮询服务（主线程）
│   ├── workers/                   # Worker线程
│   │   └── HTTPPollWorker.ets     # 后台HTTP轮询Worker
│   ├── widget/pages/              # 卡片组件
│   │   └── WidgetCard.ets         # 4x4卡片UI组件
│   ├── entryability/              # 应用入口
│   │   └── EntryAbility.ets       # 主Ability（启动Worker）
│   └── entryformability/          # 卡片Ability
│       └── EntryFormAbility.ets   # 卡片生命周期管理
└── README.md                      # 本文档

../datapallet/app_server/          # Python HTTP服务器
    ├── server.py                  # HTTP轮询服务器
    ├── test.py                    # 测试数据发送脚本
    ├── util.py                    # 图像处理工具
    └── test.png                   # 测试图像
```

## 完整数据流

```
┌─────────────────┐     HTTP POST           ┌─────────────┐
│   外部系统        │ ────────────────>       │  HTTP服务器  │
│  (Python)       │  /update-recommendation │ (127.0.0.1:8080) │
└─────────────────┘                         └──────┬──────┘
                                                   │ 内存存储
┌─────────────────┐     HTTP GET            ┌──────▼──────┐
│ HarmonyOS卡片    │ <────────────────       │  最新数据    │
│                 │  /latest-recommendation │  (JSON格式)  │
└─────────────────┘     (每2秒轮询)           └─────────────┘
        │
        │ 数据解析 & 存储
        ▼
┌─────────────────┐    震动触发判断     ┌─────────────┐
│  智能震动逻辑    │ ────────────────>  │  震动反馈    │
│ (比较数据变化)   │  (仅内容变化时)       │   (800ms)   │
└─────────────────┘                   └─────────────┘
        │
        │ 卡片更新
        ▼
┌─────────────────┐
│  卡片UI刷新       │
│ (显示动作/场景/图像)│
└─────────────────┘
```

## 核心模块详解

### 1. 网络通信模块

#### 1.1 后台轮询Worker (`HTTPPollWorker.ets`)
- **位置**: `entry/src/main/ets/workers/HTTPPollWorker.ets`
- **功能**: 独立Worker线程执行HTTP轮询，避免阻塞主线程
- **配置**: 2秒轮询间隔，连接超时5秒
- **通信**: 通过`postMessage`与主线程交换数据
- **错误处理**: 网络错误时发送错误消息到主线程

#### 1.2 主线程轮询服务 (`HTTPPollService.ets`)
- **位置**: `entry/src/main/ets/service/HTTPPollService.ets`
- **功能**: 处理Worker传来的数据，管理震动逻辑和卡片更新
- **数据存储**: 使用Preferences存储最新数据和历史比较数据
- **卡片更新**: 通过`formProvider.updateForm()`更新所有卡片实例

#### 1.3 HTTP服务器 (`server.py`)
- **位置**: `../datapallet/app_server/server.py`
- **接口**:
  - `GET /latest-recommendation` - 获取最新数据 (返回200+JSON或204无内容)
  - `POST /update-recommendation` - 更新数据 (接收JSON格式数据)
- **特性**: 支持CORS跨域，内存存储，完整数据验证

### 2. 数据处理模块 (`DataService.ets`)

#### 数据格式定义
```typescript
// 统一动作数据格式
interface RecommendationData {
  id: string;                    // 唯一标识符，如 "rec_1737744000_001"
  timestamp: number;             // Unix时间戳（秒）
  action_type: 'probe' | 'recommend' | 'none';  // 动作类型
  action_name: string;           // 具体动作名称
  image: string | null;          // base64编码的图像数据URL或null
  scene_category: string;        // 场景分类
}
```

#### 数据验证
- **必需字段**: `id`, `timestamp`, `action_type`, `action_name`, `scene_category`
- **action_type验证**: 必须是`'probe'`、`'recommend'`或`'none'`
- **action_name验证**: 检查是否在预定义动作列表中
- **image处理**: `null`或有效的base64数据URL

#### 预定义动作列表
```typescript
const validActions = [
  // 探测动作
  'QUERY_LOC_NET', 'QUERY_LOC_GPS', 'QUERY_VISUAL', 
  'QUERY_SOUND_INTENSITY', 'QUERY_LIGHT_INTENSITY',
  
  // 推荐动作  
  'NONE', 'step_count_and_map', 'transit_QR_code',
  'train_information', 'flight_information', 'payment_QR_code',
  'preferred_APP', 'glasses_snapshot', 'identify_person',
  'silent_DND', 'navigation', 'audio_record',
  'relax', 'arrived', 'parking'
];
```

### 3. 震动反馈模块

#### 智能震动逻辑
```typescript
private shouldTriggerVibration(newData: RecommendationData): boolean {
  // 1. 首次数据 -> 震动
  // 2. 数据解析失败 -> 震动（保守策略）
  // 3. 关键字段变化 -> 震动
  // 4. 相同数据 -> 不震动
}
```

#### 比较的关键字段
- `action_type`: 动作类型（probe/recommend/none）
- `action_name`: 具体动作名称
- `scene_category`: 场景分类
- `image`: 图像数据（null或base64）

**排除字段**: `id`和`timestamp`不参与比较，确保时间更新不会触发震动

#### 震动配置
- **持续时间**: 800ms
- **震动类型**: `time`模式
- **使用场景**: `notification`通知类型
- **权限**: `ohos.permission.VIBRATE`

### 4. 卡片UI模块 (`WidgetCard.ets`)

#### UI布局 (4×4卡片)
```
┌────────────────────────────────┐
│ Action Recommendation    ● [Probe] │ ← 标题 + 连接状态 + 动作类型标签
├────────────────────────────────┤
│                                │
│ [Probe]                       │ ← 动作类型徽章
│                                │
│ Action                        │
│ QUERY_LOC_NET                 │ ← 动作名称
│                                │
│ Scene                         │
│ transportation                │ ← 场景分类
│                                │
│ Image                         │ ← 图像显示（如果有）
│ [120×120 图片]                │
│                                │
│ Updated: 2m ago               │ ← 相对时间
└────────────────────────────────┘
Data received                    ← 底部状态文本
```

#### 动态显示规则
1. **动作类型徽章**: 根据`action_type`显示不同颜色
   - `probe`: 蓝色背景 `#E6F7FF`，蓝色文字 `#1890FF`
   - `recommend`: 绿色背景 `#E8F5E9`，绿色文字 `#52C41A`
   - `none`: 灰色背景 `#E0E0E0`，灰色文字 `#666666`

2. **图像显示**: 当`image`字段不为null时显示120×120图片
3. **时间格式**: 使用相对时间（just now, 2m ago, 3h ago, 1d ago）

#### 数据绑定
- **机制**: `@LocalStorageProp` + `@Watch`装饰器
- **实时更新**: 数据变化时自动触发`onCardListChange()`
- **状态管理**: `currentData`状态变量存储当前显示数据

## 后台运行机制

### Worker线程架构
```
EntryAbility.onCreate()
        │
        ├── 创建HTTPPollService实例
        │
        ├── 请求震动权限
        │
        ├── 启动长时后台任务
        │
        └── 创建Worker线程 (HTTPPollWorker.ets)
                │
                ├── 注册消息回调 (onmessage)
                │
                ├── 注册错误处理 (onAllErrors)
                │
                └── 启动轮询 (postMessage {command: 'start'})
```

### 长时任务配置
- **任务类型**: `DATA_TRANSFER`（数据传输）
- **WantAgent**: 通知栏点击跳转回应用
- **生命周期**: 应用进入后台时仍保持运行

### 数据存储策略
- **Preferences存储**: `recommendationStore`
- **存储键值**:
  - `latestRecommendation`: 最新推荐数据（JSON字符串）
  - `last_recommendation_data`: 上一次数据（用于震动比较）
  - `formId` / `allFormIds`: 卡片实例ID管理

## 服务器集成

### 服务器启动
```bash
cd ../datapallet/app_server
python server.py
```

### 测试数据发送
```bash
cd ../datapallet/app_server
python test.py
```

### 服务器响应格式
#### 成功响应 (GET /latest-recommendation)
```json
{
  "id": "rec_1737744000_001",
  "timestamp": 1737744000,
  "action_type": "probe",
  "action_name": "QUERY_LOC_NET",
  "scene_category": "transportation",
  "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgc..."
}
```

#### 无数据响应
- **状态码**: 204 No Content
- **场景**: 服务器暂无推荐数据时返回

### 数据更新 (POST /update-recommendation)
```json
{
  "id": "rec_1737744000_001",
  "timestamp": 1737744000,
  "action_type": "recommend",
  "action_name": "transit_QR_code",
  "scene_category": "transportation",
  "image": null
}
```

## 部署与测试

### 1. 启动HTTP服务器
```bash
# 终端1: 启动服务器
cd ../datapallet/app_server
python server.py
# 输出: 监听地址: http://0.0.0.0:8080
```

### 2. 发送测试数据
```bash
# 终端2: 发送测试数据
cd ../datapallet/app_server
python test.py
# 输出: ✓ 数据发送成功
```


### 调试日志
关键日志标签：
- `EntryAbility`: 应用生命周期和Worker管理
- `HTTPPollService`: 轮询服务和震动逻辑
- `HTTPPollWorker`: Worker线程网络请求
- `DataServiceHAP`: 数据解析验证
- `WidgetCard`: 卡片UI更新
