interface ActionMessage {
  action: string;
  type: string;
  reward: number;
  desc: string;
}

@Entry
@Component
struct WidgetCard {
  // 卡片状态
  @State currentAction: string = 'transit_QR_code';
  @State actionType: string = 'recommend';
  @State reward: number = 0.8;
  @State description: string = 'Subway station 100m ahead, suggest opening transit QR code.';
  @State lastUpdate: string = 'just now';

  // 卡片配置
  readonly fullWidthPercent: string = '100%';
  readonly fullHeightPercent: string = '100%';

  build() {
    Column() {
      // Title
      Text('Action Recommendation')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 8 })

      // Divider
      Row()
        .height(1)
        .width('100%')
        .backgroundColor('#CCCCCC')
        .margin({ top: 4, bottom: 8 })

      // Action information
      Column({ space: 4 }) {
        // Type and action
        Row({ space: 8 }) {
          Text('Type:')
            .fontSize(12)
            .fontColor('#666666')
          Text(this.actionType === 'recommend' ? 'Recommend' : 'Probe')
            .fontSize(12)
            .fontColor(this.actionType === 'recommend' ? '#1890FF' : '#722ED1')
        }

        // Action name
        Row({ space: 8 }) {
          Text('Action:')
            .fontSize(12)
            .fontColor('#666666')
          Text(this.currentAction)
            .fontSize(12)
            .fontColor('#333333')
        }

        // Reward value
        Row({ space: 8 }) {
          Text('Reward:')
            .fontSize(12)
            .fontColor('#666666')
          Text(this.reward.toFixed(2))
            .fontSize(12)
            .fontColor('#52C41A')
        }

        // Description (truncated)
        Row({ space: 8 }) {
          Text('Desc:')
            .fontSize(12)
            .fontColor('#666666')
          Text(this.description.length > 20 ? this.description.substring(0, 20) + '...' : this.description)
            .fontSize(12)
            .fontColor('#333333')
            .maxLines(1)
        }

        // Update time
        Row({ space: 8 }) {
          Text('Time:')
            .fontSize(12)
            .fontColor('#666666')
          Text(this.lastUpdate)
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .margin({ left: 12, right: 12 })
    }
    .width(this.fullWidthPercent)
    .height(this.fullHeightPercent)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .padding({ top: 4, bottom: 8 })
    .onClick(() => {
      // Update data when card is clicked (simulate receiving new data)
      this.updateCardData();
    })
  }

  // Simulate updating card data
  private updateCardData(): void {
    // Define action data array with explicit typing
    const actions: Array<ActionMessage> = [
      { action: 'transit_QR_code', type: 'recommend', reward: 0.8, desc: 'Subway station 100m ahead, suggest opening transit QR code.' },
      { action: 'navigation', type: 'recommend', reward: 0.9, desc: 'Detected you are going out, need navigation to destination?' },
      { action: 'QUERY_LOC_GPS', type: 'probe', reward: 0.6, desc: 'Get high precision location information.' },
      { action: 'payment_QR_code', type: 'recommend', reward: 0.7, desc: 'Detected payment scenario, suggest opening payment QR code.' }
    ];
    
    const randomAction = actions[Math.floor(Math.random() * actions.length)];
    this.currentAction = randomAction.action;
    this.actionType = randomAction.type;
    this.reward = randomAction.reward;
    this.description = randomAction.desc;
    this.lastUpdate = 'just now';
  }
}