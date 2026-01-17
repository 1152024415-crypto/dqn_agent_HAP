import { DataService } from '../../service/DataService';
import { FormCardData, FormData } from '../../common/CommonData';
import { VibrationService } from '../../service/VibrationService';

let storageLocal = new LocalStorage();

@Entry(storageLocal)
@Component
struct WidgetCard {
  @LocalStorageProp('formTime') formTime: string = '';
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('cardList') @Watch('onCardListChange') cardList: FormCardData[] = [];
  @State currentData: FormCardData | null = null;

  readonly fullWidthPercent: string = '100%';
  readonly fullHeightPercent: string = '100%';

  onCardListChange() {
    console.log('WidgetCard: cardList changed, length =', this.cardList?.length);

    if (this.cardList && this.cardList.length > 0) {
      this.currentData = this.cardList[0];
      console.log('WidgetCard: currentData set, id =', this.currentData?.id);
      console.log('WidgetCard: active_module =', this.currentData?.active_module);

      if (this.currentData?.dqn?.type) {
        VibrationService.vibrateByModule(this.currentData.active_module, this.currentData.dqn.type);
      }
    } else {
      console.log('WidgetCard: cardList is empty or undefined');
      this.currentData = null;
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
          .fill('#52C41A')

        if (this.currentData) {
          Text(this.getModuleLabel(this.currentData.active_module))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getModuleLabelTextColor(this.currentData.active_module))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(this.getModuleLabelBgColor(this.currentData.active_module))
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
        if (this.currentData) {
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
      Text('⏳')
        .fontSize(32)
        .fontColor('#999999')

      Text('Waiting for data...')
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .maxLines(3)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  private getStatusText(): string {
    return this.currentData ? 'Data received' : 'Waiting for data...';
  }

  private getModuleLabel(activeModule: string): string {
    switch (activeModule) {
      case 'rule_engine':
        return '[Rule]';
      case 'dqn':
        return '[DQN]';
      case 'vlm':
        return '[VLM]';
      default:
        return '[Unknown]';
    }
  }

  private getModuleLabelBgColor(activeModule: string): string {
    switch (activeModule) {
      case 'rule_engine':
        return '#E0E0E0';
      case 'dqn':
        return '#E6F7FF';
      case 'vlm':
        return '#F9F0FF';
      default:
        return '#E0E0E0';
    }
  }

  private getModuleLabelTextColor(activeModule: string): string {
    switch (activeModule) {
      case 'rule_engine':
        return '#666666';
      case 'dqn':
        return '#1890FF';
      case 'vlm':
        return '#722ED1';
      default:
        return '#666666';
    }
  }
}
