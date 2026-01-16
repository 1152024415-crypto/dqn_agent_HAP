import { WebSocketService, ConnectionStatus } from '../../service/WebSocketService';
import { DataService, ActionData } from '../../service/DataService';
import { VibrationService, VibrationMode } from '../../service/VibrationService';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct WidgetCard {
  // 卡片状态
  @State currentAction: string = 'Waiting for data...';
  @State actionType: string = 'unknown';
  @State reward: number = 0;
  @State description: string = 'Connecting to server...';
  @State lastUpdate: string = 'never';
  @State connectionStatus: ConnectionStatus = ConnectionStatus.DISCONNECTED;
  @State hasReceivedData: boolean = false;

  // WebSocket服务
  private wsService: WebSocketService | null = null;

  // 卡片配置
  readonly fullWidthPercent: string = '100%';
  readonly fullHeightPercent: string = '100%';

  // 组件创建时初始化
  aboutToAppear(): void {
    console.log('WidgetCard: aboutToAppear');
    this.initVibration();
    this.initWebSocket();
  }

  // 组件销毁时清理
  aboutToDisappear(): void {
    console.log('WidgetCard: aboutToDisappear');
    this.cleanup();
  }

  /**
   * 初始化震动服务
   */
  private initVibration(): void {
    // Form组件中暂时不主动请求权限，在首次震动时处理
    console.log('WidgetCard: Vibration service ready');
  }

  /**
   * 确保有震动权限（可选）
   */
  private async ensureVibrationPermission(): Promise<void> {
    try {
      await VibrationService.ensurePermission();
    } catch (error) {
      console.error(`WidgetCard: Vibration permission error - ${JSON.stringify(error)}`);
    }
  }

  /**
   * 初始化WebSocket连接
   */
  private initWebSocket(): void {
    this.wsService = new WebSocketService('ws://0.0.0.0:8080/recommendation-stream');

    // 设置消息回调
    this.wsService.onMessage((data: string) => {
      this.handleMessage(data);
    });

    // 设置状态回调
    this.wsService.onStatusChange((status: ConnectionStatus) => {
      this.connectionStatus = status;
      this.updateStatusUI(status);
      this.handleStatusChange(status);
    });

    // 连接服务器
    this.wsService.connect();
  }

  /**
   * 处理接收到的消息
   */
  private handleMessage(jsonString: string): void {
    console.log(`WidgetCard: Received message: ${jsonString}`);

    // 解析数据
    const actionData = DataService.parseActionData(jsonString);

    if (actionData) {
      // 更新卡片显示
      this.currentAction = actionData.action;
      this.actionType = actionData.type;
      this.reward = actionData.metadata.reward;
      this.description = actionData.metadata.description;
      this.lastUpdate = DataService.formatTime(actionData.timestamp);
      this.hasReceivedData = true;

      console.log(`WidgetCard: Updated card with action: ${actionData.action}`);

      // 根据动作类型触发震动
      this.triggerActionVibration(actionData.type);
    } else {
      console.warn('WidgetCard: Failed to parse message');
    }
  }

  /**
   * 根据动作类型触发震动
   */
  private triggerActionVibration(actionType: string): void {
    this.ensureVibrationPermission().then(() => {
      if (actionType === 'recommend') {
        VibrationService.vibrate(VibrationMode.RECOMMEND);
        console.log('WidgetCard: Triggered recommend vibration');
      } else if (actionType === 'probe') {
        VibrationService.vibrate(VibrationMode.PROBE);
        console.log('WidgetCard: Triggered probe vibration');
      }
    });
  }

  /**
   * 根据连接状态更新UI
   */
  private updateStatusUI(status: ConnectionStatus): void {
    switch (status) {
      case ConnectionStatus.CONNECTING:
        this.description = 'Connecting to server...';
        break;
      case ConnectionStatus.CONNECTED:
        if (!this.hasReceivedData) {
          this.description = 'Connected, waiting for data...';
        }
        break;
      case ConnectionStatus.DISCONNECTED:
        this.description = 'Disconnected from server';
        break;
      case ConnectionStatus.ERROR:
        this.description = 'Connection error';
        break;
    }
  }

  /**
   * 处理连接状态变化
   */
  private handleStatusChange(status: ConnectionStatus): void {
    this.ensureVibrationPermission().then(() => {
      switch (status) {
        case ConnectionStatus.CONNECTED:
          // 连接成功，触发短震动
          VibrationService.vibrate(VibrationMode.CONNECTED);
          break;
        case ConnectionStatus.ERROR:
          // 连接错误，触发错误震动
          VibrationService.vibrate(VibrationMode.ERROR);
          break;
        case ConnectionStatus.DISCONNECTED:
          // 连接断开，不触发震动
          break;
        case ConnectionStatus.CONNECTING:
          // 连接中，不触发震动
          break;
      }
    });
  }

  /**
   * 清理资源
   */
  private cleanup(): void {
    // 停止震动
    VibrationService.stopVibration();
    console.log('WidgetCard: Stopped vibration');

    // 断开WebSocket连接
    if (this.wsService) {
      this.wsService.disconnect();
      this.wsService = null;
    }
  }

  /**
   * 处理卡片点击 - 重新连接或断开
   */
  private handleCardClick(): void {
    console.log(`WidgetCard: Card clicked, current status: ${this.connectionStatus}`);

    if (!this.wsService) {
      this.initWebSocket();
      return;
    }

    if (this.connectionStatus === ConnectionStatus.DISCONNECTED || 
        this.connectionStatus === ConnectionStatus.ERROR) {
      this.wsService.connect();
    } else if (this.connectionStatus === ConnectionStatus.CONNECTED) {
      this.wsService.disconnect();
    }
  }

  build() {
    Column() {
      // Title with status indicator
      Row() {
        Text('Action Recommendation')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        // Connection status indicator
        Circle()
          .width(8)
          .height(8)
          .fill(this.getStatusColor())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 12, bottom: 12, left: 20 })

      // Divider
      Row()
        .height(1)
        .width('100%')
        .backgroundColor('#E0E0E0')
        .margin({ left: 20, right: 20 })

      // Main content
      Column({ space: 12 }) {
        if (this.hasReceivedData) {
          // 有数据时显示动作信息
          this.actionContent();
        } else {
          // 无数据时显示连接状态
          this.statusContent();
        }
      }
      .margin({ left: 16, right: 16, top: 16 })
      .layoutWeight(1)

      // Footer with status text
      Text(this.getStatusText())
        .fontSize(10)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 8 })
        .width('100%')
    }
    .width(this.fullWidthPercent)
    .height(this.fullHeightPercent)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      this.handleCardClick();
    })
  }

  /**
   * 动作内容区域
   */
  @Builder
  actionContent(): void {
    Column({ space: 12 }) {
      // Action type badge
      Row() {
        Text(this.actionType === 'recommend' ? 'RECOMMEND' : 'PROBE')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .backgroundColor(this.actionType === 'recommend' ? '#1890FF' : '#722ED1')
          .borderRadius(12)
      }
      .width('100%')

      // Action name section
      Column({ space: 4 }) {
        Text('Action')
          .fontSize(12)
          .fontColor('#999999')
        Text(this.currentAction)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
      }
      .width('100%')

      // Reward section with progress bar
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text('Reward')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.reward.toFixed(2))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#52C41A')
        }

        // Reward progress bar
        Row() {
          Row()
            .height(6)
            .borderRadius(3)
            .backgroundColor(this.actionType === 'recommend' ? '#1890FF' : '#722ED1')
            .width(`${this.reward * 100}%`)
        }
        .width('100%')
        .height(6)
        .backgroundColor('#F0F0F0')
        .borderRadius(3)
      }
      .width('100%')

      // Description section
      Column({ space: 4 }) {
        Text('Description')
          .fontSize(12)
          .fontColor('#999999')
        Text(this.description)
          .fontSize(14)
          .fontColor('#333333')
          .lineHeight(20)
          .maxLines(3)
      }
      .width('100%')

      // Update time
      Row() {
        Text(`Updated: ${this.lastUpdate}`)
          .fontSize(11)
          .fontColor('#999999')
      }
      .width('100%')
    }
  }

  /**
   * 状态内容区域
   */
  @Builder
  statusContent(): void {
    Column({ space: 12 }) {
      // Status icon
      Text(this.getStatusIcon())
        .fontSize(32)
        .fontColor(this.getStatusColor())

      // Status message
      Text(this.description)
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .maxLines(3)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 获取状态颜色
   */
  private getStatusColor(): string {
    switch (this.connectionStatus) {
      case ConnectionStatus.CONNECTING:
        return '#FAAD14'; // 橙色
      case ConnectionStatus.CONNECTED:
        return '#52C41A'; // 绿色
      case ConnectionStatus.DISCONNECTED:
        return '#999999'; // 灰色
      case ConnectionStatus.ERROR:
        return '#F5222D'; // 红色
      default:
        return '#999999';
    }
  }

  /**
   * 获取状态文本
   */
  private getStatusText(): string {
    switch (this.connectionStatus) {
      case ConnectionStatus.CONNECTING:
        return 'Connecting to server...';
      case ConnectionStatus.CONNECTED:
        return this.hasReceivedData ? 'Tap card to disconnect' : 'Connected, tap card to disconnect';
      case ConnectionStatus.DISCONNECTED:
        return 'Tap card to connect';
      case ConnectionStatus.ERROR:
        return 'Tap card to reconnect';
      default:
        return 'Tap card to connect';
    }
  }

  /**
   * 获取状态图标
   */
  private getStatusIcon(): string {
    switch (this.connectionStatus) {
      case ConnectionStatus.CONNECTING:
        return '⏳';
      case ConnectionStatus.CONNECTED:
        return '✓';
      case ConnectionStatus.DISCONNECTED:
        return '⊘';
      case ConnectionStatus.ERROR:
        return '✕';
      default:
        return '⊘';
    }
  }
}