import { DataService } from '../../service/DataService';
import { FormCardData } from '../../common/CommonData';

// 创建一个LocalStorage实例，用于在组件间共享状态
let storageLocal = new LocalStorage();

const DOMAIN = 0x0000;
const TAG: string = 'WidgetCard';

@Entry(storageLocal)
@Component
struct WidgetCard {
  // 使用 @LocalStorageProp 订阅 formTime 和 cardList 的变化
  @LocalStorageProp('formTime') @Watch('onFormTimeChange') formTime: string = '';
  @LocalStorageProp('cardList') @Watch('onCardListChange') cardList: FormCardData[] = [];

  // @State 用于组件内部的状态管理，当它改变时会触发UI刷新
  @State currentData: FormCardData | null = null;
  @State animOpacity: number = 1; // 用于实现简单的淡入淡出动画

  // 定义常量以提高代码可读性
  readonly fullWidthPercent: string = '100%';
  readonly fullHeightPercent: string = '100%';

  // 当 formTime 变化时的回调
  onFormTimeChange() {
    console.log('WidgetCard: formTime changed');
  }

   // 当 cardList 变化时的回调，这是更新UI的主要触发点
    onCardListChange() {
      // 简单的淡入淡出效果
      console.log('WidgetCard: onCardListChange');
      this.animOpacity = 0.3;
       if (this.cardList && this.cardList.length > 0) {
        // 总是显示列表中的第一条数据
        this.currentData = this.cardList[0];
        
        // 详细日志
        if (this.currentData?.action_data?.dqn_state) {
          const ds = this.currentData.action_data.dqn_state;
          console.log('WidgetCard dqn_state full: activity=' + ds.activity +
            ', location=' + ds.location +
            ', light=' + ds.light +
            ', scene=' + ds.scene);
        } else {
          console.log('WidgetCard: dqn_state is missing!');
        }
      } else {
        this.currentData = null;
        console.log('WidgetCard: cardList empty');
      }
      // 动画恢复不透明度
      this.animOpacity = 1;
    }

  build() {
    Column() {
      // 1. 顶部 Header
      Row() {
        Row({ space: 6 }) {
          Text('🤖')
            .fontSize(18)
          Text('Smart Actions')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
        }
        .alignItems(VerticalAlign.Center)

        // 右上角的状态标签
        if (this.currentData?.action_data) {
          Row({ space: 4 }) {
            Text(this.getActionTypeIcon(this.currentData.action_data.action_type))
              .fontSize(12)
            Text(this.getActionTypeShortLabel(this.currentData.action_data.action_type))
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(DataService.getActionTypeLabelTextColor(this.currentData.action_data.action_type))
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(DataService.getActionTypeLabelBgColor(this.currentData.action_data.action_type))
          .borderRadius(16)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 12, bottom: 4, left: 16, right: 16 })

      // 分割线
      Line()
        .width('92%')
        .height(0.5)
        .backgroundColor('#000000')
        .opacity(0.08)
        .margin({ bottom: 8 })

      // 2. 中间主要内容区
      Column() {
        if (this.currentData) {
          this.actionContent();
        } else {
          this.statusContent();
        }
      }
      .layoutWeight(1) // 占满剩余高度
      .opacity(this.animOpacity)
      .animation({ duration: 500, curve: Curve.EaseOut })
      .padding({ left: 14, right: 14 })

      // 3. 底部 Footer (状态 + 时间)
      Row() {
        // 左侧：运行状态
        Row({ space: 4 }) {
          Circle({ width: 6, height: 6 })
            .fill(this.currentData ? '#52C41A' : '#FAAD14')
          Text(this.currentData ? 'Ready' : 'Connecting')
            .fontSize(10)
            .fontColor('#999999')
        }
        .alignItems(VerticalAlign.Center)

        // 右侧：更新时间
        if (this.currentData?.timestamp) {
          Row({ space: 3 }) {
            Text('🕒')
              .fontSize(10)
              .opacity(0.6)
            Text(DataService.formatTime(this.currentData.timestamp))
              .fontSize(10)
              .fontColor('#999999')
          }
          .alignItems(VerticalAlign.Center)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 18, right: 18, bottom: 12, top: 6 })
    }
    .width(this.fullWidthPercent)
    .height(this.fullHeightPercent)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
  }

  /**
   • Builder for displaying the main action content

   */
  @Builder
  actionContent() {
    Column({ space: 8 }) {
      if (this.currentData?.action_data) {
        // --- 模块 A: 推荐动作信息 ---
        Column() {
          Text('SUGGESTED ACTION')
            .fontSize(9)
            .fontColor('#888888')
            .fontWeight(FontWeight.Bold)
            .letterSpacing(0.5)
            .margin({ bottom: 2 })

          Text(this.currentData.action_data.action_name || 'Unknown')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.currentData.action_data.scene_category) {
            Line()
              .width('100%')
              .height(1)
              .backgroundColor('#000000')
              .opacity(0.05)
              .margin({ top: 8, bottom: 6 })

            Row({ space: 6 }) {
              Text('📍 IN SCENE')
                .fontSize(9)
                .fontColor('#888888')
                .fontWeight(FontWeight.Bold)
              Text(this.currentData.action_data.scene_category)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
            }
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 10, bottom: 10, left: 14, right: 14 })
        .backgroundColor(this.getActionNameBgColor())
        .borderRadius(14)
        .border({
          width: { left: 4, right: 0, top: 0, bottom: 0 },
          color: this.getActionTypeBorderColor(this.currentData.action_data.action_type)
        })
        .shadow({ radius: 8, color: '#00000005', offsetY: 2 })

        if (this.currentData.action_data.dqn_state) {
          Column() {
            Text('CURRENT STATE (DQN INPUT)')
              .fontSize(9)
              .fontColor('#A0A0A0')
              .fontWeight(FontWeight.Bold)
              .letterSpacing(0.5)
              .margin({ bottom: 6 })

            GridRow({ columns: 2, gutter: { x: 8, y: 4 } }) {
              GridCol() {
                Row({ space: 4 }) {
                  Text('姿态:')
                    .fontSize(11)
                  Text(this.currentData.action_data.dqn_state.activity)
                    .fontSize(11)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(VerticalAlign.Center)
              }
              GridCol() {
                Row({ space: 4 }) {
                  Text('位置:')
                    .fontSize(11)
                  Text(this.currentData.action_data.dqn_state.location)
                    .fontSize(11)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(VerticalAlign.Center)
              }
              GridCol() {
                Row({ space: 4 }) {
                  Text('亮度:')
                    .fontSize(11)
                  Text(this.currentData.action_data.dqn_state.light)
                    .fontSize(11)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(VerticalAlign.Center)
              }
              GridCol() {
                Row({ space: 4 }) {
                  Text('场景:')
                    .fontSize(11)
                  Text(this.currentData.action_data.dqn_state.scene)
                    .fontSize(11)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(VerticalAlign.Center)
              }
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ top: 8, bottom: 8, left: 12, right: 12 })
          .backgroundColor('#F7F7F7')
          .borderRadius(12)
        }

        // --- 模块 C: 图片展示 ---
        if (this.currentData.action_data.image) {
          Stack({ alignContent: Alignment.BottomStart }) {
            Image(this.currentData.action_data.image)
              .width('100%')
              .height(130)
              .objectFit(ImageFit.Cover)
              .borderRadius(14)
              .interpolation(ImageInterpolation.High)
              .syncLoad(true)
          }
          .width('100%')
          .shadow({ radius: 8, color: '#0000000D', offsetY: 3 })
        }
      }
    }
    .justifyContent(FlexAlign.Start)
  }

  /**
   • Builder for displaying status when no data is available

   */
  @Builder
  statusContent() {
    Column({ space: 15 }) {
      Stack() {
        Circle({ width: 40, height: 40 }).fill('#F5F5F5')
        Text('⏳').fontSize(20)
      }
      Text('Waiting for input...')
        .fontSize(13)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }



  // --- 样式辅助函数 ---

  private getActionNameBgColor(): string {
    if (!this.currentData?.action_data) return '#F9F9F9';
    switch (this.currentData.action_data.action_type) {
      case 'probe': return '#F0F9FF';
      case 'recommend': return '#F0FFF4';
      default: return '#F9F9F9';
    }
  }

  private getActionTypeIcon(actionType: string): string {
    switch (actionType) {
      case 'probe': return '🔍';
      case 'recommend': return '💡';
      default: return '⚡';
    }
  }

  private getActionTypeBorderColor(actionType: string): string {
    switch (actionType) {
      case 'probe': return '#1890FF';
      case 'recommend': return '#52C41A';
      default: return '#D9D9D9';
    }
  }

  private getActionTypeShortLabel(actionType: string): string {
    switch (actionType) {
      case 'probe': return 'Probe';
      case 'recommend': return 'Recommend';
      case 'none': return 'Idle';
      default: return 'Unknown';
    }
  }
}