# HarmonyOS 智能动作推荐卡片Demo

## 项目概述

### 应用名称
Action Recommendation Card Demo

### 核心功能
1. **Card Display**: 在桌面卡片上展示动作推荐信息
2. **WebSocket Communication**: 与服务器建立WebSocket连接，接收实时推送
3. **HTTP Requests**: 通过HTTP API获取动作数据
4. **Vibration Feedback**: 收到新推荐时提供震动反馈
5. **Simple UI**: 初期以文字展示为主，逐步迭代UI

### 架构理解
基于服务器代码分析，正确的通信流程是：
1. **外部系统** → **HTTP API** (`/api/recommendations`) → 服务器
2. **服务器** → **WebSocket** (`/recommendation-stream`) → HarmonyOS卡片
3. **卡片** 显示接收到的动作推荐信息

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
│   │   │   ├── model/          # 数据模型
│   │   │   ├── service/        # 业务服务
│   │   │   └── utils/          # 工具类
│   │   └── resources/
│   │       └── base/profile/
│   │           └── form_config.json  # 卡片配置
│   ├── module.json5            # 模块配置
│   └── oh-package.json5        # 依赖配置
├── build-profile.json5         # 构建配置
└── README.md                   # 本文档
```

## 功能模块设计

### 1. 卡片展示模块 (WidgetCard)
**功能**:
- 在桌面卡片上展示动作推荐信息
- 显示最新接收到的动作数据
- 简单的文字展示（初期版本）
- 点击卡片可跳转到应用主页面

**技术实现**:
- 基于现有的`WidgetCard.ets`组件扩展
- 使用`@Entry`和`@Component`装饰器
- 卡片尺寸：2*2（可在form_config.json中配置）

### 2. 网络通信模块
#### 2.1 WebSocket服务 (WebSocketService)
**功能**:
- 与服务器建立WebSocket连接
- 接收服务器实时推送的动作数据
- 处理连接状态和错误恢复

**技术实现**:
- 使用`@kit.NetworkKit`的WebSocket API
- 连接地址：`ws://0.0.0.0:8080/recommendation-stream`
- 在卡片生命周期中管理连接

#### 2.2 HTTP服务 (HttpService) 
**功能**:
- 通过HTTP API获取动作数据（如果需要主动拉取）
- 发送请求到服务器（如果需要客户端发起请求）

**技术实现**:
- 使用`@kit.NetworkKit`的HTTP API
- API地址：`http://0.0.0.0:8080/api/recommendations`

### 3. 数据处理模块 (DataService)
**功能**:
- 解析WebSocket接收的JSON数据
- 验证数据格式的正确性
- 数据转换和格式化
- 管理当前显示的动作数据

**数据格式**:
```json
{
  "id": "rec_1736923200_001",
  "type": "recommend",
  "action": "transit_QR_code",
  "timestamp": 1736923200,
  "metadata": {
    "reward": 0.8,
    "description": "Subway station 100m ahead, suggest opening transit QR code."
  }
}
```

### 4. 震动反馈模块 (VibrationService)
**功能**:
- 收到新消息时触发设备震动
- 简单的震动反馈（不区分动作类型）
- 申请和处理震动权限

**技术实现**:
- 使用`@ohos.vibrator` API
- 简单震动模式：500ms单次震动
- 在卡片中集成震动功能

### 5. 状态管理
**功能**:
- 管理卡片显示状态
- 管理网络连接状态
- 管理当前显示的数据

**实现方式**:
- 使用ArkTS的`@State`装饰器管理组件状态
- 简单的状态管理，不复杂化
- 不持久化数据（卡片刷新即清空）

## UI设计（渐进式实现）

### 阶段一：基础文字展示（初始版本）
**卡片布局**:
```
┌─────────────────┐
│ Action Recommendation│
│                 │
│ Type: [Recommend]│
│ Action: transit_QR_code │
│ Reward: 0.8     │
│ Desc: Subway station...│
│ Time: just now  │
└─────────────────┘
```

**显示内容**:
1. **标题**: "Action Recommendation"
2. **动作类型**: "Recommend" 或 "Probe"
3. **动作名称**: 原始action字段（如transit_QR_code）
4. **奖励值**: reward数值显示
5. **描述**: 截断显示前20个字符
6. **时间**: 相对时间（just now、X minutes ago）

**设计原则**:
- 简单文字，无复杂样式
- 自动换行处理长文本
- 固定字体大小和颜色

### 阶段二：基础样式优化（后续迭代）
**可添加的简单样式**:
- 不同类型使用不同文字颜色
- 添加简单分隔线
- 调整文字对齐方式
- 添加简单背景色区分

### 阶段三：高级UI（如有需求）
- 添加图标标识
- 进度条显示奖励值
- 卡片边框样式
- 动画效果

## 交互设计

### 1. 卡片点击交互
- 点击卡片可跳转到应用主页面
- 在主页面上显示更多详细信息
- 保留基本的卡片刷新机制

### 2. 数据更新
- WebSocket实时推送更新卡片内容
- 收到新数据时触发震动
- 卡片内容自动刷新

### 3. 状态反馈
- **连接状态**: 通过文字简单显示（"已连接"/"未连接"）
- **新消息**: 更新卡片内容并震动
- **错误状态**: 显示简单错误信息

## 数据模型

### 动作类型定义（来自服务器）
**探测动作 (Probe Actions)**:
- `QUERY_LOC_NET`: 通过网络获取位置信息
- `QUERY_LOC_GPS`: 通过GPS获取高精度位置信息
- `QUERY_VISUAL`: 查询视觉/图像信息
- `QUERY_SOUND_INTENSITY`: 查询环境声音强度
- `QUERY_LIGHT_INTENSITY`: 查询环境光照强度

**推荐动作 (Recommend Actions)**:
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

### 卡片数据模型
```typescript
// 当前卡片显示的数据
interface CardDisplayData {
  id: string;                    // 数据ID
  type: 'recommend' | 'probe';   // 动作类型
  action: string;                // 动作名称
  timestamp: number;             // 服务器时间戳
  metadata: {
    reward: number;              // 奖励值 (0-1)
    description: string;         // 动作描述
  };
  displayTime: string;           // 格式化显示时间
}

// 连接状态
type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

// 卡片状态
interface CardState {
  currentData: CardDisplayData | null;  // 当前显示的数据
  connectionStatus: ConnectionStatus;    // 连接状态
  lastUpdateTime: number;                // 最后更新时间
}
```

## 用户交互流程

### 1. 卡片添加流程
1. 用户在桌面长按添加卡片
2. 选择"智能动作推荐卡片"
3. 卡片添加到桌面，显示初始状态
4. 卡片自动尝试连接WebSocket服务器

### 2. 数据接收流程
1. 外部系统通过HTTP API发送动作数据到服务器
2. 服务器通过WebSocket推送数据到已连接的卡片
3. 卡片接收并解析WebSocket消息
4. 触发设备震动反馈
5. 更新卡片显示内容
6. 显示最新的动作推荐信息

### 3. 卡片交互流程
1. 用户查看桌面卡片上的动作推荐
2. 点击卡片跳转到应用主页面（可选）
3. 在主页面查看更详细的信息（可选）
4. 卡片定期刷新或实时更新

## 权限配置

### 必需权限
在`module.json5`中声明：
```json
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "需要网络访问权限以连接服务器",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  },
  {
    "name": "ohos.permission.VIBRATE",
    "reason": "需要震动反馈功能",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  }
]
```

### 权限说明
1. **网络权限**: 用于WebSocket连接和HTTP请求
2. **震动权限**: 用于收到新消息时的震动反馈
3. **卡片权限**: 已在form_config.json中配置卡片相关权限

## 服务器集成

### 服务器信息
- **地址**: 0.0.0.0:8080
- **WebSocket端点**: `/recommendation-stream`
- **HTTP API**: `/api/recommendations` (POST)

### 服务器架构
```
外部系统 → HTTP POST → 服务器 → WebSocket → HarmonyOS卡片
           /api/recommendations           /recommendation-stream
```

### 服务器功能
1. **HTTP API**: 接收外部系统的动作数据
2. **WebSocket服务**: 实时推送数据给已连接的卡片
3. **单客户端模式**: 只保持最新的卡片连接

### 测试流程
1. 启动服务器：`python server.py` (在D:\proj\datapallet\app_server目录)
2. 安装HarmonyOS应用到设备/模拟器
3. 在桌面添加"智能动作推荐卡片"
4. 发送测试数据：`python test.py`
5. 验证卡片收到数据并更新显示

## 开发计划（模块化实现）

### 阶段一：基础卡片改造 (0.5天)
1. 修改现有`WidgetCard.ets`，添加数据展示区域
2. 定义基础数据模型和接口
3. 配置网络和震动权限
4. 实现简单的文字展示布局

### 阶段二：WebSocket连接模块 (1天)
1. 创建WebSocketService，实现连接管理
2. 集成WebSocket到卡片生命周期
3. 实现基础的消息接收和解析
4. 添加连接状态管理

### 阶段三：数据处理和展示 (0.5天)
1. 实现数据解析和格式化
2. 添加时间格式化工具
3. 实现卡片内容更新机制
4. 添加简单的错误处理

### 阶段四：震动反馈集成 (0.5天)
1. 创建VibrationService
2. 集成震动到数据接收流程
3. 处理震动权限申请
4. 测试震动功能

### 阶段五：测试和优化 (0.5天)
1. 与本地服务器集成测试
2. 测试完整的数据流：HTTP→服务器→WebSocket→卡片
3. 验证震动反馈功能
4. 优化卡片显示效果

## 技术实现要点

### 1. 卡片开发要点
- 使用`@Entry`和`@Component`装饰器定义卡片
- 遵循HarmonyOS卡片开发规范
- 卡片尺寸和布局适配
- 卡片生命周期管理

### 2. WebSocket实现
- 使用`@kit.NetworkKit`的WebSocket API
- 在卡片中管理WebSocket连接
- 处理连接断开和重连
- 异步消息处理

### 3. 震动功能
- 使用`@ohos.vibrator` API
- 简单的震动模式（不复杂化）
- 权限申请和处理

### 4. 数据流处理
- JSON数据解析和验证
- 时间格式化显示
- 简单的状态管理
- 错误处理和恢复

## 已知约束和简化设计

### 技术约束
1. **单客户端连接**: 服务器只支持单个WebSocket客户端连接
2. **卡片尺寸限制**: 2*2卡片空间有限
3. **系统资源**: 卡片资源使用受限
4. **本地服务器**: 测试需要本地运行Python服务器

### 简化设计原则
1. **UI简化**: 初期只使用文字展示，无复杂样式
2. **功能聚焦**: 只实现核心的WebSocket接收和显示功能
3. **状态简化**: 简单的状态管理，不复杂化
4. **错误处理**: 基础错误处理，不追求完美
5. **性能忽略**: Demo阶段不优化性能

## 验收标准（Demo级别）

### 核心功能验收
- [ ] 卡片能成功添加到桌面
- [ ] 卡片能连接WebSocket服务器（0.0.0.0:8080）
- [ ] 卡片能接收服务器推送的动作数据
- [ ] 收到数据时能触发震动反馈
- [ ] 卡片能正确显示动作信息（文字形式）
- [ ] 点击卡片能正常响应（跳转或刷新）

### 数据流验收
- [ ] 外部系统通过HTTP POST发送数据到服务器
- [ ] 服务器通过WebSocket推送数据到卡片
- [ ] 卡片解析并显示JSON格式的动作数据
- [ ] 完整的数据流：HTTP → 服务器 → WebSocket → 卡片

### 基础UI验收
- [ ] 卡片能显示基本的文字信息
- [ ] 不同类型动作能区分显示（文字区分）
- [ ] 时间信息能正确格式化显示
- [ ] 卡片布局合理，文字可读

## 后续迭代建议（如有需要）

### UI增强
1. **样式优化**: 添加颜色、字体样式
2. **图标集成**: 为不同动作类型添加图标
3. **布局改进**: 优化卡片信息布局
4. **动画效果**: 添加简单的更新动画

### 功能扩展
1. **多数据显示**: 在卡片上轮播显示多条记录
2. **历史记录**: 在主页面查看历史动作记录
3. **设置界面**: 配置服务器地址等参数
4. **更多交互**: 在卡片上直接执行简单操作

### 稳定性提升
1. **错误恢复**: 增强网络断开重连机制
2. **数据验证**: 更严格的数据格式验证
3. **性能优化**: 优化卡片刷新性能
4. **兼容性**: 适配更多设备类型

---

## 需要确认的关键点

1. **服务器地址**: 确认使用 `0.0.0.0:8080` 还是其他地址？
2. **卡片尺寸**: 当前配置为2*2，是否需要支持其他尺寸？
3. **数据展示**: 是否需要为action字段提供中文翻译显示？
4. **震动模式**: 是否需要区分推荐/探测动作的不同震动？
5. **测试数据**: 是否需要内置测试按钮发送模拟数据？

**请确认以上设计方案是否符合您的期望**，特别是：
- 卡片为核心业务的设计思路
- 渐进式UI开发策略
- 简化的功能实现
- 正确的数据流理解（HTTP→服务器→WebSocket→卡片）