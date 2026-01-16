# HarmonyOS 智能动作推荐卡片

## 项目概述

### 应用名称
Action Recommendation Card

### 核心功能
1. **Card Display**: 在桌面卡片上展示动作推荐信息
2. **WebSocket Communication**: 与服务器建立WebSocket连接，接收实时推送
3. **Three-Layer AI Module**: 支持Rule Engine、DQN、VLM三层AI架构的推荐展示
4. **Vibration Feedback**: 根据不同AI模块提供差异化震动反馈
5. **Dynamic UI**: 根据激活的AI模块动态调整卡片显示内容

### 架构说明
基于服务器代码分析，正确的通信流程是：
1. **外部系统** → **HTTP API** (`/api/recommendations`) → 服务器
2. **服务器** → **WebSocket** (`/recommendation-stream`) → HarmonyOS卡片
3. **卡片** 显示接收到的动作推荐信息

### 三层AI模块架构
系统采用分层决策架构，从下到上依次为：
- **Rule Engine (基础层)**: 基于规则的简单决策
- **DQN (中间层)**: 深度Q网络学习决策
- **VLM (最高层)**: 视觉语言模型高级分析

**激活规则**:
- 同一时间只有一个模块激活（`active_module`字段指定）
- VLM激活时，必定包含DQN的数据
- DQN激活时，必定包含Rule Engine的数据
- 不降级显示：只显示激活模块对应的内容

## 技术架构

### 开发环境
- **开发工具**: DevEco Studio
- **开发语言**: ArkTS (TypeScript扩展)
- **目标平台**: HarmonyOS 6.0.2(22)
- **SDK版本**: 6.0.2(22)
- **应用类型**: 卡片应用 (Form Ability)

### 项目结构
```
dqnApp/
├── AppScope/                    # 应用全局资源
│   ├── app.json5               # 应用配置
│   └── resources/              # 资源文件
├── entry/                      # 主模块
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── widget/pages/   # 卡片页面
│   │   │   │   └── WidgetCard.ets  # 主卡片组件
│   │   │   ├── service/        # 业务服务
│   │   │   │   ├── WebSocketService.ets   # WebSocket连接管理
│   │   │   │   ├── DataService.ets        # 数据解析处理
│   │   │   │   └── VibrationService.ets   # 震动反馈服务
│   │   │   └── entryability/   # 应用入口
│   │   │       └── EntryAbility.ets
│   │   └── resources/
│   │       └── base/profile/
│   │           └── form_config.json  # 卡片配置
│   ├── module.json5            # 模块配置
│   └── oh-package.json5        # 依赖配置
├── build-profile.json5         # 构建配置
└── README.md                   # 本文档
```

## 功能模块设计

### 1. 卡片展示模块 (WidgetCard) ✅
**功能**:
- 在桌面卡片上展示动作推荐信息
- 根据激活的AI模块动态显示不同内容
- 显示连接状态指示器
- 显示模块标签（Rule/DQN/VLM）
- 点击卡片可管理WebSocket连接

**技术实现**:
- 基于`@Entry`和`@Component`装饰器
- 卡片尺寸：4×4
- 支持三种模块的内容展示：
  - **Rule Engine**: Category, Decision, Description
  - **DQN**: Action Type, Action
  - **VLM**: Action Type, Scene, Action, Analysis

### 2. 网络通信模块 ✅
#### 2.1 WebSocket服务 (WebSocketService)
**功能**:
- 与服务器建立WebSocket连接
- 接收服务器实时推送的动作数据
- 处理连接状态和错误恢复
- 自动重连机制（最多5次，指数退避）

**技术实现**:
- 使用`@kit.NetworkKit`的WebSocket API
- 连接地址：`ws://0.0.0.0:8080/recommendation-stream`
- 连接状态枚举：`DISCONNECTED` | `CONNECTING` | `CONNECTED` | `ERROR`
- 在卡片生命周期中管理连接

### 3. 数据处理模块 (DataService) ✅
**功能**:
- 解析WebSocket接收的JSON数据
- 验证数据格式的正确性
- 数据转换和格式化
- 提供模块标签和颜色方法

**数据格式**（新架构）:
```json
{
  "id": "rec_1736923200_001",
  "timestamp": 1736923200,
  "active_module": "dqn",
  
  "rule_engine": {
    "category": "transit",
    "decision": "open_qr_code",
    "description": "建议打开乘车码"
  },
  
  "dqn": {
    "action": "transit_QR_code",
    "type": "recommend"
  },
  
  "vlm": {
    "scene_category": "transit",
    "description": "前方100米有地铁站，建议打开乘车码。"
  }
}
```

**字段说明**:
- `active_module`: 激活的模块，可选值：`"rule_engine"` | `"dqn"` | `"vlm"`
- `rule_engine`: 规则引擎数据
  - `category`: 场景类别（如transit, food, shopping）
  - `decision`: 规则决策（字符串，在推荐范围内）
  - `description`: 可选的简短说明
- `dqn`: DQN数据
  - `action`: 具体动作
  - `type`: `"recommend"` | `"probe"`
- `vlm`: VLM数据
  - `scene_category`: 场景类别
  - `description`: 长文本描述（一般20字左右）

### 4. 震动反馈模块 (VibrationService) ✅
**功能**:
- 根据激活的AI模块提供差异化震动反馈
- 根据动作类型调整震动强度
- 简单直接的震动触发机制

**震动级别枚举**:
| 模块 | 动作类型 | 震动模式 | 震动时长 |
|------|---------|---------|---------|
| Rule Engine | - | 单次震动 | 200ms |
| DQN | Recommend | 单次震动 | 300ms |
| DQN | Probe | 单次震动 | 800ms |
| VLM | - | 双震动 | 1500ms |

**技术实现**:
- 使用`@ohos.vibrator` API
- VLM双震动使用系统预设：`haptic.clock.timer` × 2
- 震动权限已在`module.json5`中声明

## UI设计

### 整体布局（4×4卡片）

```
┌────────────────────────────────┐
│ Action Recommendation    ● [DQN]│  ← 标题 + 连接状态 + 模块标签
├────────────────────────────────┤
│                                │
│ [RECOMMEND] ← Action类型标签   │
│                                │
│ Action                         │
│ transit_QR_code                │
│                                │
│ Updated: 2m ago                │
│                                │
└────────────────────────────────┘
Tap card to disconnect           ← 底部状态文本
```

### 不同激活模块的显示

#### Rule Engine激活时
```
┌────────────────────────────────┐
│ Action Recommendation    ● [Rule]│
├────────────────────────────────┤
│                                │
│ Category                       │
│ transit                        │
│                                │
│ Decision                       │
│ open_qr_code                   │
│                                │
│ Description (可选)             │
│ 建议打开乘车码                  │
│                                │
└────────────────────────────────┘
```

#### DQN激活时
```
┌────────────────────────────────┐
│ Action Recommendation    ● [DQN]│
├────────────────────────────────┤
│                                │
│ [RECOMMEND]                    │
│                                │
│ Action                         │
│ transit_QR_code                │
│                                │
│ Updated: just now              │
│                                │
└────────────────────────────────┘
```

#### VLM激活时
```
┌────────────────────────────────┐
│ Action Recommendation    ● [VLM]│
├────────────────────────────────┤
│                                │
│ [RECOMMEND]                    │
│                                │
│ Scene                          │
│ transit                        │
│                                │
│ Action                         │
│ transit_QR_code                │
│                                │
│ Analysis                       │
│ 前方100米有地铁站，建议打开     │
│ 乘车码。                       │
│                                │
│ Updated: 1m ago                │
│                                │
└────────────────────────────────┘
```

### 颜色方案

**模块标签颜色**:
| 模块 | 标签 | 背景色 | 文字色 |
|------|------|--------|--------|
| Rule Engine | [Rule] | 灰色 #E0E0E0 | 深灰 #666666 |
| DQN | [DQN] | 浅蓝 #E6F7FF | 蓝色 #1890FF |
| VLM | [VLM] | 浅紫 #F9F0FF | 紫色 #722ED1 |

**Action类型标签颜色**:
| 类型 | 背景色 |
|------|--------|
| RECOMMEND | 蓝色 #1890FF |
| PROBE | 紫色 #722ED1 |

**连接状态颜色**:
| 状态 | 颜色 |
|------|------|
| CONNECTING | 橙色 #FAAD14 |
| CONNECTED | 绿色 #52C41A |
| DISCONNECTED | 灰色 #999999 |
| ERROR | 红色 #F5222D |

## 数据模型

### 推荐数据接口
```typescript
interface RecommendationData {
  id: string;
  timestamp: number;
  active_module: 'rule_engine' | 'dqn' | 'vlm';
  
  rule_engine?: {
    category: string;
    decision: string;
    description?: string;
  };
  
  dqn?: {
    action: string;
    type: 'recommend' | 'probe';
  };
  
  vlm?: {
    scene_category: string;
    description: string;
  };
}
```

### 连接状态枚举
```typescript
enum ConnectionStatus {
  DISCONNECTED = 0,
  CONNECTING = 1,
  CONNECTED = 2,
  ERROR = 3
}
```

## 用户交互流程

### 1. 卡片添加流程
1. 用户在桌面长按添加卡片
2. 选择"Action Recommendation Card"
3. 卡片添加到桌面，显示初始状态（连接中）
4. 卡片自动尝试连接WebSocket服务器

### 2. 数据接收流程
1. 外部系统通过HTTP API发送动作数据到服务器
2. 服务器通过WebSocket推送数据到已连接的卡片
3. 卡片接收并解析WebSocket消息
4. 根据激活模块触发对应的震动反馈
5. 根据激活模块更新卡片显示内容
6. 显示最新的动作推荐信息

### 3. 卡片交互流程
1. 用户查看桌面卡片上的动作推荐
2. 点击卡片可管理WebSocket连接：
   - 未连接状态：点击连接
   - 已连接状态：点击断开
   - 错误状态：点击重连

## 权限配置

### 已声明权限
在`module.json5`中已声明：
```json
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "Need network access to connect to server",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  },
  {
    "name": "ohos.permission.VIBRATE",
    "reason": "Need vibration feedback when receiving new action recommendations",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  }
]
```

## 服务器集成

### 服务器信息
- **地址**: 0.0.0.0:8080
- **WebSocket端点**: `/recommendation-stream`
- **HTTP API**: `/api/recommendations` (POST)
- **服务器路径**: `D:\proj\datapallet\app_server`

### 服务器架构
```
外部系统 → HTTP POST → 服务器 → WebSocket → HarmonyOS卡片
           /api/recommendations           /recommendation-stream
```

### 测试流程

#### 1. 启动服务器
```bash
cd D:\proj\datapallet\app_server
python server.py
```

#### 2. 发送测试数据
```bash
cd D:\proj\datapallet\app_server
python test.py
```

#### 3. 测试数据格式
**Rule Engine测试数据**:
```json
{
  "id": "rec_1234567890_001",
  "timestamp": 1234567890,
  "active_module": "rule_engine",
  "rule_engine": {
    "category": "transit",
    "decision": "open_qr_code",
    "description": "建议打开乘车码"
  }
}
```

**DQN测试数据**:
```json
{
  "id": "rec_1234567890_001",
  "timestamp": 1234567890,
  "active_module": "dqn",
  "rule_engine": {
    "category": "transit",
    "decision": "open_qr_code"
  },
  "dqn": {
    "action": "transit_QR_code",
    "type": "recommend"
  }
}
```

**VLM测试数据**:
```json
{
  "id": "rec_1234567890_001",
  "timestamp": 1234567890,
  "active_module": "vlm",
  "rule_engine": {
    "category": "transit",
    "decision": "open_qr_code"
  },
  "dqn": {
    "action": "transit_QR_code",
    "type": "recommend"
  },
  "vlm": {
    "scene_category": "transit",
    "description": "前方100米有地铁站，建议打开乘车码。"
  }
}
```

## 动作类型定义

### 探测动作 (Probe Actions)
- `QUERY_LOC_NET`: 通过网络获取位置信息
- `QUERY_LOC_GPS`: 通过GPS获取高精度位置信息
- `QUERY_VISUAL`: 查询视觉/图像信息
- `QUERY_SOUND_INTENSITY`: 查询环境声音强度
- `QUERY_LIGHT_INTENSITY`: 查询环境光照强度

### 推荐动作 (Recommend Actions)
- `NONE`: No action / No recommendation
- `step_count_and_map`: Display step count and map information
- `transit_QR_code`: Show public transportation/transit QR code
- `train_information`: Display train/high-speed rail itinerary information
- `flight_information`: Display flight status information
- `payment_QR_code`: Show payment QR code
- `preferred_APP`: Recommend commonly used or related applications
- `glasses_snapshot`: Trigger glasses/wearable device snapshot input
- `identify_person`: Face recognition / identity verification
- `silent_DND`: Enable silent/Do Not Disturb mode
- `navigation`: Enable/display navigation suggestions
- `audio_record`: Enable audio recording
- `relax`: Recommend relaxation content
- `arrived`: Destination arrival reminder
- `parking`: Parking space management

## 验收标准

### 核心功能 ✅
- [x] 卡片能成功添加到桌面
- [x] 卡片能连接WebSocket服务器（0.0.0.0:8080）
- [x] 卡片能接收服务器推送的动作数据
- [x] 根据激活模块触发差异化震动反馈
- [x] 卡片能正确显示不同AI模块的信息
- [x] 点击卡片能管理WebSocket连接

### 数据流验收 ✅
- [x] 外部系统通过HTTP POST发送数据到服务器
- [x] 服务器通过WebSocket推送数据到卡片
- [x] 卡片解析并显示新格式的三层JSON数据
- [x] 完整的数据流：HTTP → 服务器 → WebSocket → 卡片

### UI验收 ✅
- [x] 卡片能显示基本的文字信息
- [x] 不同AI模块能区分显示（标签颜色、内容不同）
- [x] 连接状态通过颜色指示器显示
- [x] 时间信息能正确格式化显示（just now, Xm ago）
- [x] 卡片布局合理，文字可读

### 震动反馈验收 ✅
- [x] Rule Engine激活时震动200ms
- [x] DQN Recommend激活时震动300ms
- [x] DQN Probe激活时震动800ms
- [x] VLM激活时双震动1500ms

## Git提交历史

1. **Initial commit**: 项目初始化
2. **Update app text to English**: 将应用界面文本改为英文
3. **Update card size to 4x4**: 将卡片尺寸改为4×4
4. **Add WebSocket connection**: 添加WebSocket连接功能
5. **Simplify vibration service**: 简化震动服务实现
6. **Fix vibration API error**: 修复震动API调用错误
7. **Update data format to support three-layer AI modules**: 更新数据格式支持三层AI模块

## 后续迭代建议

### 功能扩展
1. **历史记录**: 在主页面查看历史动作记录
2. **设置界面**: 配置服务器地址等参数
3. **数据持久化**: 保存历史推荐记录
4. **多卡片支持**: 支持同时显示多个卡片

### UI增强
1. **图标集成**: 为不同模块添加图标
2. **动画效果**: 添加数据更新动画
3. **主题切换**: 支持暗色/亮色主题
4. **自定义布局**: 允许用户自定义卡片布局

### 稳定性提升
1. **错误恢复**: 增强网络断开重连机制
2. **数据验证**: 更严格的数据格式验证
3. **性能优化**: 优化卡片刷新性能
4. **兼容性**: 适配更多设备类型

### GitHub集成
1. 添加远程仓库：`git remote add origin https://github.com/1152024415-crypto/dqn_agent_HAP.git`
2. 推送代码：`git push -u origin master`

---

## 开发完成状态

✅ **核心功能已完成**
- 卡片展示
- WebSocket实时通信
- 三层AI模块架构
- 差异化震动反馈
- 动态UI展示

✅ **测试验证已完成**
- WebSocket连接测试
- 数据接收测试
- 震动反馈测试
- UI展示测试

📝 **文档已完成**
- 代码注释完善
- 测试数据示例完整
- README更新

🚀 **可进行下一步**
- 部署到实际设备测试
- 推送到GitHub
- 开始功能扩展开发
