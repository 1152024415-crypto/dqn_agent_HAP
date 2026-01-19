import { DataService } from '../../service/DataService';
import { FormCardData, FormData } from '../../common/CommonData';
import formProvider from '@kit.FormKit';

let storageLocal = new LocalStorage();

@Entry(storageLocal)
@Component
struct WidgetCard {
  @LocalStorageProp('formTime') @Watch('onFormTimeChange') formTime: string = '';
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('cardList') @Watch('onCardListChange') cardList: FormCardData[] = [];
  @State currentData: FormCardData | null = null;

  readonly fullWidthPercent: string = '100%';
  readonly fullHeightPercent: string = '100%';

  onFormTimeChange() {
    console.log('WidgetCard: formTime changed to', this.formTime);
    // formTime变化表示数据已更新，可以触发额外处理
  }

   onCardListChange() {
    console.log('WidgetCard: cardList changed, length =', this.cardList?.length);

    if (this.cardList && this.cardList.length > 0) {
      this.currentData = this.cardList[0];
      console.log('WidgetCard: currentData set, id =', this.currentData?.id);
      console.log('WidgetCard: action_data =', this.currentData?.action_data);
    } else {
      console.log('WidgetCard: cardList is empty or undefined');
      this.currentData = null;
    }
  }

  // 保留onUpdateForm用于调试，但数据现在通过LocalStorage自动注入
  onUpdateForm(formData: FormData) {
    console.log('WidgetCard: onUpdateForm called (legacy), formTime =', formData.formTime);
    console.log('WidgetCard: cardList from LocalStorage length =', this.cardList?.length);
    // 数据已通过LocalStorage注入，这里不需要额外处理
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


        if (this.currentData?.action_data) {
          Text(DataService.getActionTypeLabel(this.currentData.action_data.action_type))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(DataService.getActionTypeLabelTextColor(this.currentData.action_data.action_type))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(DataService.getActionTypeLabelBgColor(this.currentData.action_data.action_type))
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
  actionContent() {
    Column({ space: 12 }) {
      if (this.currentData?.action_data) {


        // Action type badge
        Row() {
          Text(DataService.getActionTypeLabel(this.currentData.action_data.action_type))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(DataService.getActionTypeLabelTextColor(this.currentData.action_data.action_type))
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor(DataService.getActionTypeLabelBgColor(this.currentData.action_data.action_type))
            .borderRadius(12)
        }
        .width('100%')

        // Action name
        if (this.currentData.action_data.action_name && this.currentData.action_data.action_name !== 'NONE') {
          Column({ space: 4 }) {
            Text('Action')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.currentData.action_data.action_name)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
          }
          .width('100%')
        }

        // Scene category
        if (this.currentData.action_data.scene_category) {
          Column({ space: 4 }) {
            Text('Scene')
              .fontSize(12)
              .fontColor('#999999')
            Text(this.currentData.action_data.scene_category)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
          }
          .width('100%')
        }

        // Image display (if available)
        if (this.currentData.action_data.image) {
          Column({ space: 4 }) {
            Text('Image')
              .fontSize(12)
              .fontColor('#999999')
            Image(this.currentData.action_data.image)
              .width(120)
              .height(120)
              .objectFit(ImageFit.Contain)
              .borderRadius(8)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }

        // Timestamp
        if (this.currentData.timestamp) {
          Row() {
            Text(`Updated: ${DataService.formatTime(this.currentData.timestamp)}`)
              .fontSize(11)
              .fontColor('#999999')
          }
          .width('100%')
        }
      }
    }
  }







   @Builder
  statusContent() {
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
