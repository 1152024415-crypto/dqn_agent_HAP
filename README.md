# HarmonyOS 智能动作推荐卡片Demo

## 项目概述

### 应用名称
智能动作推荐卡片Demo

### 核心功能
1. **卡片展示**: 在桌面卡片上展示动作推荐信息
2. **WebSocket通信**: 与服务器建立WebSocket连接，接收实时推送
3. **HTTP请求**: 通过HTTP API获取动作数据
4. **震动反馈**: 收到新推荐时提供震动反馈
5. **简单UI**: 初期以文字展示为主，逐步迭代UI

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
    "description": "前方100米有地铁站，建议打开乘车码。"
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

## UI/UX设计

### 1. 布局设计
**顶部状态栏**:
- 连接状态图标（绿色/红色/黄色）
- 连接状态文字指示
- 消息计数显示

**主内容区**:
- 垂直列表展示所有接收到的动作推荐
- 空状态提示（无数据时显示）
- 支持下拉刷新

**底部操作栏**:
- 连接按钮（连接/断开切换）
- 清空列表按钮
- 测试按钮（发送测试消息）

### 2. 列表项设计（动作卡片）
**卡片包含元素**:
1. **动作类型标识**:
   - 图标区分推荐/探测动作
   - 文字标签（"推荐动作" / "探测动作"）

2. **动作名称**:
   - 清晰的动作标识（如"transit_QR_code"）
   - 中文翻译显示（如"地铁乘车码"）

3. **奖励展示**:
   - 视觉化展示reward值（0-1）
   - 进度条或星级评分显示

4. **描述文本**:
   - 动作的详细描述
   - 多行文本支持

5. **时间信息**:
   - 接收时间的格式化显示
   - 相对时间（如"刚刚"、"2分钟前"）

6. **视觉区分**:
   - 推荐动作：绿色边框
   - 探测动作：蓝色边框
   - 错误状态：红色边框

### 3. 状态反馈
**连接状态**:
- 实时显示连接状态变化
- 状态颜色：绿色（已连接）、红色（断开）、黄色（连接中）

**新消息提示**:
- 收到新消息时顶部短暂提示
- 提示内容："收到新动作推荐"

**震动反馈**:
- 收到消息时设备震动
- 震动强度根据动作类型调整

## 数据模型

### 动作类型定义
**探测动作 (Probe Actions)**:
- `QUERY_LOC_NET`: 通过网络获取位置信息
- `QUERY_LOC_GPS`: 通过GPS获取高精度位置信息
- `QUERY_VISUAL`: 查询视觉/图像信息
- `QUERY_SOUND_INTENSITY`: 查询环境声音强度
- `QUERY_LIGHT_INTENSITY`: 查询环境光照强度

**推荐动作 (Recommend Actions)**:
- `NONE`: 无动作/不推荐
- `step_count_and_map`: 显示步数统计与地图信息
- `transit_QR_code`: 弹出公交/地铁乘车码
- `train_information`: 显示火车/高铁行程信息
- `flight_information`: 显示航班动态信息
- `payment_QR_code`: 弹出支付二维码
- `preferred_APP`: 推荐常用或相关的应用程序
- `glasses_snapshot`: 触发（眼镜/穿戴设备）快照录入
- `identify_person`: 人脸识别/身份辨别
- `silent_DND`: 开启静音/勿扰模式
- `navigation`: 开启/显示导航建议
- `audio_record`: 开启音频录制
- `relax`: 推荐放松内容
- `arrived`: 目的地到达提醒
- `parking`: 车位/停车管理

### 本地数据存储
```typescript
interface ActionRecommendation {
  id: string;                    // 唯一标识
  type: 'recommend' | 'probe';   // 动作类型
  action: string;                // 动作名称
  timestamp: number;             // 服务器时间戳
  metadata: {
    reward: number;              // 奖励值 (0-1)
    description: string;         // 动作描述
  };
  localTimestamp: number;        // 本地接收时间
}
```

## 用户交互流程

### 1. 启动流程
1. 应用启动，检查网络和震动权限
2. 显示初始界面（空列表，未连接状态）
3. 用户点击连接按钮或自动尝试连接

### 2. 消息接收流程
1. WebSocket收到服务器消息
2. 解析验证消息格式
3. 触发设备震动反馈
4. 将消息添加到推荐列表
5. UI自动更新显示新消息
6. 显示顶部新消息提示

### 3. 连接管理流程
1. 用户点击连接/断开按钮
2. 执行WebSocket连接/断开操作
3. 更新连接状态显示
4. 连接异常时显示错误信息
5. 自动重连机制（可选）

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

### 权限申请流程
1. 应用启动时检查权限状态
2. 未授予权限时弹出申请对话框
3. 用户授权后启用相应功能
4. 用户拒绝时提供功能受限提示

## 服务器集成

### 服务器信息
- **地址**: 0.0.0.0:8080
- **WebSocket端点**: `/recommendation-stream`
- **HTTP API**: `/api/recommendations` (POST)

### 服务器功能
1. **WebSocket服务**: 提供实时数据推送
2. **HTTP API**: 接收外部系统数据并转发给WebSocket客户端
3. **单客户端模式**: 新连接替代旧连接

### 测试方法
1. 启动服务器：`python server.py`
2. 启动HarmonyOS应用并连接
3. 发送测试数据：`python test.py`
4. 验证应用收到数据并显示

## 开发计划

### 阶段一：基础搭建 (1-2天)
1. 配置项目依赖和权限
2. 定义数据模型和接口
3. 创建基础项目结构

### 阶段二：核心功能开发 (2-3天)
1. 实现WebSocket连接管理
2. 实现震动反馈功能
3. 实现状态管理机制

### 阶段三：UI界面开发 (2-3天)
1. 设计主页面布局
2. 实现动作卡片组件
3. 实现状态反馈UI

### 阶段四：集成测试 (1-2天)
1. 功能测试（连接、消息接收、震动）
2. UI测试（布局、交互、状态更新）
3. 性能测试（内存、网络、列表性能）

## 技术要点

### 1. WebSocket连接管理
- 使用`@kit.NetworkKit`的WebSocket API
- 实现连接状态监听
- 处理连接异常和重连

### 2. 震动反馈实现
- 使用`@ohos.vibrator` API
- 区分不同动作类型的震动模式
- 处理震动权限申请

### 3. 状态管理
- 使用ArkUI的装饰器（@State, @Prop, @Link）
- 使用AppStorage管理全局状态
- 实现状态同步机制

### 4. UI组件设计
- 使用声明式UI（ArkUI）
- 组件化开发，提高复用性
- 响应式布局适配不同设备

## 已知约束

1. **单客户端连接**: 服务器只支持单个WebSocket客户端连接
2. **无数据持久化**: 应用关闭后数据不保存
3. **系统图标**: 使用HarmonyOS内置图标资源
4. **本地服务器**: 测试需要本地运行Python服务器

## 验收标准

### 功能验收
- [ ] 成功连接WebSocket服务器
- [ ] 正确接收和解析服务器数据
- [ ] 收到数据时触发震动反馈
- [ ] 正确显示动作推荐卡片
- [ ] 连接状态实时更新
- [ ] 支持手动连接/断开操作

### UI验收
- [ ] 布局美观，符合设计规范
- [ ] 卡片信息完整显示
- [ ] 状态反馈清晰可见
- [ ] 交互流畅无卡顿

### 性能验收
- [ ] 内存使用合理
- [ ] 网络连接稳定
- [ ] 列表滚动流畅
- [ ] 响应时间快速

## 后续扩展建议

1. **数据持久化**: 添加本地存储，保存历史记录
2. **多服务器支持**: 支持配置多个服务器地址
3. **动作执行**: 集成实际的动作执行功能
4. **数据分析**: 添加数据统计和分析功能
5. **主题切换**: 支持深色/浅色主题
6. **多语言支持**: 添加国际化支持

---

**最后确认**: 请确认以上功能设计是否符合您的期望，如有修改需求请提出。