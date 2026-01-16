# MVP卡片测试说明

## 当前实现状态

已创建最简单的MVP版本卡片，包含以下功能：

### 1. 基础卡片展示
- Card title: "Action Recommendation"
- Display area: 4*4 size
- Enhanced layout with better spacing and visual elements

### 2. 显示内容
- **Action Type**: Recommend action (blue) or Probe action (purple)
- **Action Name**: e.g. `transit_QR_code`
- **Reward Value**: 0.8 (displayed in green)
- **Description**: Truncated to first 20 characters
- **Update Time**: "just now"

### 3. 交互功能
- **Click Card**: Simulate receiving new data, randomly switch to display different actions
- **Data Update**: Click to randomly display one of 4 preset actions

### 4. 预设动作数据
1. `transit_QR_code` - Recommend action, reward 0.8
2. `navigation` - Recommend action, reward 0.9  
3. `QUERY_LOC_GPS` - Probe action, reward 0.6
4. `payment_QR_code` - Recommend action, reward 0.7

## 测试方法

### 在DevEco Studio中测试:
1. Open project `D:\proj\dqnApp`
2. Connect HarmonyOS device or start emulator
3. Run project to device/emulator
4. Long press on desktop to add card
5. Select "Action Recommendation" card
6. Click card to test interaction function

### 预期结果:
1. Card can be successfully added to desktop
2. Card displays preset action information
3. Clicking card can update display content
4. Different action types display in different colors
5. Basic layout and style display normally

## 代码结构

### 主要文件:
- `entry/src/main/ets/widget/pages/WidgetCard.ets` - Main card component
- `entry/src/main/resources/base/profile/form_config.json` - Card configuration
- `entry/src/main/resources/base/element/string.json` - String resources

### 卡片特性:
- Use `@Entry` and `@Component` decorators
- Use `@State` to manage component state
- Responsive design, adapts to card size
- Simple click interaction

## 下一步计划

Based on this MVP version, can gradually add:
1. WebSocket connection function
2. Real server data reception
3. Vibration feedback function
4. Richer UI styles
5. Error handling and state management

## 注意事项

1. Current version uses hard-coded data, does not connect to real server
2. UI style is simple, can be optimized gradually
3. Card size fixed at 2*2, can support more sizes later
4. Vibration function not yet implemented, to be added later