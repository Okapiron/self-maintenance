# 自己メンテナンス

自己メンテナンスの「そろそろ」を忘れないための、iPhone向けローカル記録アプリです。

## MVP

- SwiftUI + SwiftData
- iOS 17以上
- ローカル保存
- ローカル通知
- 広告なし
- 課金なし
- 分析SDKなし
- 外部通信なし

## Build

```sh
xcodebuild -project SelfMaintenance.xcodeproj -scheme SelfMaintenance -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## App Store Metadata

- App Store名: 自己メンテナンス
- ホーム画面表示名: 自己メンテ
- サブタイトル: 美容と健康の自己投資手帳

## Notes

App Store提出前に、以下を確認してください。

- アプリアイコン
- GitHub PagesのサポートURL: https://okapiron.github.io/self-maintenance/support.html
- GitHub PagesのプライバシーポリシーURL: https://okapiron.github.io/self-maintenance/privacy.html
- 問い合わせメールアドレス: okapiron@gmail.com
