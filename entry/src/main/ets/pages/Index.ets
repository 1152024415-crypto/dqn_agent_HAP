@Entry
@Component
struct Index {
  @State message: string = 'Welcome to Action Recommendation';

  build() {
    RelativeContainer() {
      Column() {
        // Title
        Text(this.message)
          .id('Title')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 40, bottom: 20 })
          .alignRules({
            top: { anchor: '__container__', align: VerticalAlign.Top },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })

        // Instructions
        Column({ space: 16 }) {
          this.instructionItem('1', 'Long press on empty space of your home screen')
          this.instructionItem('2', 'Tap "Widgets" or "Cards" option')
          this.instructionItem('3', 'Find and select "Action Recommendation"')
          this.instructionItem('4', 'Place the card on your home screen')
          this.instructionItem('5', 'Click the card to test interaction')
        }
        .alignRules({
          top: { anchor: 'Title', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })

        // Note
        Text('Note: This app provides a home screen card widget for displaying action recommendations.')
          .fontSize(14)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .margin({ top: 20, left: 20, right: 20 })
          .alignRules({
            bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  instructionItem(number: string, text: string) {
    Row({ space: 12 }) {
      Text(number)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1890FF')
        .width(30)

      Text(text)
        .fontSize(14)
        .fontColor('#333333')
        .flexGrow(1)
    }
    .width('100%')
    .padding(8)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }
}