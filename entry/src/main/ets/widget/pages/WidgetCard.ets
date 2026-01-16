import { WebSocketService, ConnectionStatus } from '../../service/WebSocketService';
import { DataService, RecommendationData } from '../../service/DataService';
import { VibrationService } from '../../service/VibrationService';

@Entry
@Component
struct WidgetCard {
  @State currentData: RecommendationData | null = null;
  @State connectionStatus: ConnectionStatus = ConnectionStatus.DISCONNECTED;
  @State hasReceivedData: boolean = false;

  private wsService: WebSocketService | null = null;

  readonly fullWidthPercent: string = '100%';
  readonly fullHeightPercent: string = '100%';

  aboutToAppear(): void {
    console.log('WidgetCard: aboutToAppear');
    this.initWebSocket();
  }

  aboutToDisappear(): void {
    console.log('WidgetCard: aboutToDisappear');
    this.cleanup();
  }

  private initWebSocket(): void {
    this.wsService = new WebSocketService('ws://0.0.0.0:8080/recommendation-stream');

    this.wsService.onMessage((data: string) => {
      this.handleMessage(data);
    });

    this.wsService.onStatusChange((status: ConnectionStatus) => {
      this.connectionStatus = status;
      this.updateStatusUI(status);
    });

    this.wsService.connect();
  }

  private handleMessage(jsonString: string): void {
    console.log(`WidgetCard: Received message: ${jsonString}`);

    const recommendationData = DataService.parseRecommendationData(jsonString);

    if (recommendationData) {
      this.currentData = recommendationData;
      this.hasReceivedData = true;

      console.log(`WidgetCard: Updated card with module: ${recommendationData.active_module}`);

      VibrationService.vibrateByModule(
        recommendationData.active_module,
        recommendationData.dqn?.type
      );
    } else {
      console.warn('WidgetCard: Failed to parse message');
    }
  }

  private updateStatusUI(status: ConnectionStatus): void {
    switch (status) {
      case ConnectionStatus.CONNECTING:
        break;
      case ConnectionStatus.CONNECTED:
        break;
      case ConnectionStatus.DISCONNECTED:
        break;
      case ConnectionStatus.ERROR:
        break;
    }
  }

  private cleanup(): void {
    VibrationService.stopVibration();
    console.log('WidgetCard: Stopped vibration');

    if (this.wsService) {
      this.wsService.disconnect();
      this.wsService = null;
    }
  }

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
      Row() {
        Text('Action Recommendation')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Circle()
          .width(8)
          .height(8)
          .fill(this.getStatusColor())

        if (this.currentData) {
          Text(DataService.getModuleLabel(this.currentData.active_module))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(DataService.getModuleLabelTextColor(this.currentData.active_module))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(DataService.getModuleLabelBgColor(this.currentData.active_module))
            .borderRadius(6)
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 12, bottom: 12, left: 20, right: 16 })

      Row()
        .height(1)
        .width('100%')
        .backgroundColor('#E0E0E0')
        .margin({ left: 20, right: 20 })

      Column({ space: 12 }) {
        if (this.hasReceivedData && this.currentData) {
          this.actionContent();
        } else {
          this.statusContent();
        }
      }
      .margin({ left: 16, right: 16, top: 16 })
      .layoutWeight(1)

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

  @Builder
  actionContent(): void {
    Column({ space: 12 }) {
      if (this.currentData) {
        if (this.currentData.active_module === 'rule_engine') {
          this.ruleEngineContent();
        } else if (this.currentData.active_module === 'dqn') {
          this.dqnContent();
        } else if (this.currentData.active_module === 'vlm') {
          this.vlmContent();
        }
      }
    }
  }

  @Builder
  ruleEngineContent(): void {
    Column({ space: 12 }) {
      if (this.currentData?.rule_engine?.category) {
        Column({ space: 4 }) {
          Text('Category')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.currentData.rule_engine.category)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
        }
        .width('100%')
      }

      if (this.currentData?.rule_engine?.decision) {
        Column({ space: 4 }) {
          Text('Decision')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.currentData.rule_engine.decision)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
        }
        .width('100%')
      }

      if (this.currentData?.rule_engine?.description) {
        Column({ space: 4 }) {
          Text('Description')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.currentData.rule_engine.description)
            .fontSize(14)
            .fontColor('#333333')
            .lineHeight(20)
            .maxLines(3)
        }
        .width('100%')
      }
    }
  }

  @Builder
  dqnContent(): void {
    Column({ space: 12 }) {
      if (this.currentData?.dqn?.type) {
        Row() {
          Text(this.currentData.dqn.type === 'recommend' ? 'RECOMMEND' : 'PROBE')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor(this.currentData.dqn.type === 'recommend' ? '#1890FF' : '#722ED1')
            .borderRadius(12)
        }
        .width('100%')
      }

      if (this.currentData?.dqn?.action) {
        Column({ space: 4 }) {
          Text('Action')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.currentData.dqn.action)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
        }
        .width('100%')
      }

      if (this.currentData?.timestamp) {
        Row() {
          Text(`Updated: ${DataService.formatTime(this.currentData.timestamp)}`)
            .fontSize(11)
            .fontColor('#999999')
        }
        .width('100%')
      }
    }
  }

  @Builder
  vlmContent(): void {
    Column({ space: 12 }) {
      if (this.currentData?.dqn?.type) {
        Row() {
          Text(this.currentData.dqn.type === 'recommend' ? 'RECOMMEND' : 'PROBE')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor(this.currentData.dqn.type === 'recommend' ? '#1890FF' : '#722ED1')
            .borderRadius(12)
        }
        .width('100%')
      }

      if (this.currentData?.vlm?.scene_category) {
        Column({ space: 4 }) {
          Text('Scene')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.currentData.vlm.scene_category)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
        }
        .width('100%')
      }

      if (this.currentData?.dqn?.action) {
        Column({ space: 4 }) {
          Text('Action')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.currentData.dqn.action)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
        }
        .width('100%')
      }

      if (this.currentData?.vlm?.description) {
        Column({ space: 4 }) {
          Text('Analysis')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.currentData.vlm.description)
            .fontSize(14)
            .fontColor('#333333')
            .lineHeight(20)
            .maxLines(3)
        }
        .width('100%')
      }

      if (this.currentData?.timestamp) {
        Row() {
          Text(`Updated: ${DataService.formatTime(this.currentData.timestamp)}`)
            .fontSize(11)
            .fontColor('#999999')
        }
        .width('100%')
      }
    }
  }

  @Builder
  statusContent(): void {
    Column({ space: 12 }) {
      Text(this.getStatusIcon())
        .fontSize(32)
        .fontColor(this.getStatusColor())

      Text(this.getStatusDescription())
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .maxLines(3)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  private getStatusDescription(): string {
    switch (this.connectionStatus) {
      case ConnectionStatus.CONNECTING:
        return 'Connecting to server...';
      case ConnectionStatus.CONNECTED:
        return this.hasReceivedData ? 'Connected' : 'Connected, waiting for data...';
      case ConnectionStatus.DISCONNECTED:
        return 'Disconnected from server';
      case ConnectionStatus.ERROR:
        return 'Connection error';
      default:
        return 'Disconnected';
    }
  }

  private getStatusColor(): string {
    switch (this.connectionStatus) {
      case ConnectionStatus.CONNECTING:
        return '#FAAD14';
      case ConnectionStatus.CONNECTED:
        return '#52C41A';
      case ConnectionStatus.DISCONNECTED:
        return '#999999';
      case ConnectionStatus.ERROR:
        return '#F5222D';
      default:
        return '#999999';
    }
  }

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
