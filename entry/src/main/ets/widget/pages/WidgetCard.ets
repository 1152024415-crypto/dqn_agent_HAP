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
        // 左侧：图标和标题
        Row() {
          Text('🤖')
            .fontSize(18)
            .margin({ right: 8 })
          
          Text('Smart Actions')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
        }
        .layoutWeight(1)

        // 右侧：状态指示器和动作类型
        Row() {
          // 状态指示器
          Stack() {
            Circle()
              .width(10)
              .height(10)
              .fill(this.currentData ? '#52C41A' : '#FFA940')
              .opacity(this.currentData ? 0.8 : 0.6)
            
            if (!this.currentData) {
              Circle()
                .width(10)
                .height(10)
                .fill('#FFA940')
                .opacity(0.3)
                .scale({ x: 1.5, y: 1.5 })
            }
          }
          .margin({ right: 8 })

          // 动作类型标签
          if (this.currentData?.action_data) {
            Text(DataService.getActionTypeLabel(this.currentData.action_data.action_type))
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(DataService.getActionTypeLabelTextColor(this.currentData.action_data.action_type))
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(DataService.getActionTypeLabelBgColor(this.currentData.action_data.action_type))
              .borderRadius(20)
          }
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 16, bottom: 12, left: 18, right: 18 })

      Row()
        .height(0.5)
        .width('100%')
        .backgroundColor('#E0E0E0')
        .margin({ left: 18, right: 18 })
        .opacity(0.4)

      Column({ space: 12 }) {
        if (this.currentData) {
          this.actionContent();
        } else {
          this.statusContent();
        }
      }
      .margin({ left: 18, right: 18, top: 16, bottom: 12 })
      .layoutWeight(1)

       Row() {
         Text(this.currentData ? '✓' : '⏳')
           .fontSize(10)
           .margin({ right: 4 })
         
         Text(this.getStatusText())
           .fontSize(10)
           .fontColor(this.currentData ? '#666666' : '#999999')
           .fontWeight(this.currentData ? FontWeight.Medium : FontWeight.Normal)
       }
       .justifyContent(FlexAlign.Center)
       .margin({ bottom: 12 })
       .width('100%')
       .opacity(0.8)
    }
    .width(this.fullWidthPercent)
    .height(this.fullHeightPercent)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: '#00000010',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  actionContent() {
    Column({ space: 12 }) {
      if (this.currentData?.action_data) {




         // Action name (Primary Information)
        if (this.currentData.action_data.action_name && this.currentData.action_data.action_name !== 'NONE') {
          Column({ space: 6 }) {
            Row() {
              Text('⚡')
                .fontSize(12)
                .margin({ right: 8 })
              
              Text('ACTION')
                .fontSize(11)
                .fontColor('#666666')
                .fontWeight(FontWeight.Bold)
                .opacity(0.9)
            }
            
            Text(this.currentData.action_data.action_name)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12, left: 14, right: 14 })
          .backgroundColor(this.getActionNameBgColor())
          .borderRadius(10)
          .shadow({
            radius: 4,
            color: '#00000008',
            offsetX: 0,
            offsetY: 2
          })
        }

         // Scene category (Secondary Information)
        if (this.currentData.action_data.scene_category) {
          Column({ space: 4 }) {
            Row() {
              Text('📍')
                .fontSize(10)
                .margin({ right: 6 })
                .opacity(0.7)
              
              Text('SCENE')
                .fontSize(10)
                .fontColor('#888888')
                .fontWeight(FontWeight.Medium)
                .opacity(0.8)
            }
            
            Text(this.currentData.action_data.scene_category)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#666666')
              .margin({ top: 2 })
          }
          .width('100%')
          .padding({ top: 8, bottom: 8, left: 12, right: 12 })
          .backgroundColor('#FAFAFA')
          .borderRadius(8)
        }

         // Image display (if available)
        if (this.currentData.action_data.image) {
          Column({ space: 6 }) {
            Row() {
              Text('🖼️')
                .fontSize(11)
                .margin({ right: 6 })
              
              Text('Preview')
                .fontSize(11)
                .fontColor('#666666')
                .fontWeight(FontWeight.Medium)
                .opacity(0.8)
            }
            
            Image(this.currentData.action_data.image)
              .width(100)
              .height(100)
              .objectFit(ImageFit.Cover)
              .borderRadius(10)
              .shadow({
                radius: 6,
                color: '#00000006',
                offsetX: 0,
                offsetY: 1
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 8, bottom: 8 })
          .borderRadius(10)
        }

        // Timestamp
        if (this.currentData.timestamp) {
          Row() {
            Text('🕒')
              .fontSize(10)
              .margin({ right: 6 })
            
            Text(`Updated ${DataService.formatTime(this.currentData.timestamp)}`)
              .fontSize(11)
              .fontColor('#888888')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .margin({ top: 8 })
          .opacity(0.7)
        }
      }
    }
  }







   @Builder
   statusContent() {
    Column({ space: 16 }) {
      // Animated loading indicator
      Stack() {
        Circle()
          .width(40)
          .height(40)
          .fill('#E8F5E9')
          .opacity(0.7)
        
        Circle()
          .width(40)
          .height(40)
          .stroke('#52C41A')
          .strokeWidth(2)
          .fill('#FFFFFF00')
        
        Text('🤖')
          .fontSize(20)
      }
      
      Column({ space: 8 }) {
        // Skeleton text 1
        Row() {
          Row()
            .width(120)
            .height(12)
            .backgroundColor('#E0E0E0')
            .borderRadius(4)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        
        // Skeleton text 2
        Row() {
          Row()
            .width(80)
            .height(12)
            .backgroundColor('#E0E0E0')
            .borderRadius(4)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        
        // Status text
        Text('Waiting for smart actions...')
          .fontSize(13)
          .fontColor('#666666')
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 20, bottom: 20 })
  }

   private getStatusText(): string {
    return this.currentData ? 'Ready' : 'Connecting...';
  }

  private getActionNameBgColor(): string {
    if (!this.currentData?.action_data) {
      return '#F8F9FA';
    }
    const bgColor = DataService.getActionTypeLabelBgColor(this.currentData.action_data.action_type);
    // 将颜色调亮一些，作为主信息背景
    switch (this.currentData.action_data.action_type) {
      case 'probe':
        return '#F0F9FF';  // 更浅的蓝色
      case 'recommend':
        return '#F6FFED';  // 更浅的绿色
      case 'none':
        return '#F5F5F5';  // 更浅的灰色
      default:
        return '#F8F9FA';
    }
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
