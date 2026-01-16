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
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 12, bottom: 12 })
        .width('100%')

      // Main content
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
      .margin({ left: 16, right: 16 })
      .layoutWeight(1)

      // Footer hint
      Text('Tap card to refresh')
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
    .padding({ top: 0, bottom: 0 })
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