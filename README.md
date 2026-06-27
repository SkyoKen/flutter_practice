# Cyber Table Order

サイバーパンク風の飲食店テーブル注文アプリです。Flutter で作られており、現在はローカル状態だけでメニュー表示、カート操作、注文履歴、会員ログイン風 UI、QR 注文ダイアログ、多言語表示を扱います。

## 主な機能

- Intro 画面から点餐画面へ遷移
- 英語・中国語・日本語の表示切り替え
- メニューカテゴリとサブカテゴリによる絞り込み
- カートへの追加・削除、合計金額表示
- 注文確定と注文履歴の保持
- 会員ログイン風のプロフィール表示
- テーブル ID 付き QR 注文ダイアログ

## よく見るファイル

- `lib/main.dart`: アプリの入口。`Restaurant` を Provider で注入します。
- `lib/models/restaurant.dart`: メニュー、カート、注文履歴、ログイン状態、言語状態を持つ中心モデルです。
- `lib/pages/intro_page.dart`: 初期画面と言語切り替え。
- `lib/pages/home_page.dart`: AppBar、Drawer、QR、会員、設定、履歴ダイアログを持つアプリ外枠です。
- `lib/pages/menu_page.dart`: メニューグリッド、カテゴリ、カート、注文確定、会計依頼を扱うメイン画面です。
- `lib/components/food_tile.dart`: メニュー項目カード。
- `lib/utils/translations.dart`: 翻訳テーブル。
- `test/`: widget test と `Restaurant` の状態テスト。

## 開発コマンド

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d chrome
```

## 注意点

- 現在のデータはすべてメモリ上にあり、永続化やバックエンド連携はありません。
- `lib/images/` は asset 登録済みですが、メニュー項目の `imagePath` に対応する実画像はまだ揃っていません。
- 練習用の application/bundle ID として `dev.practice.cybertableorder` を使っています。
- Android の release signing は練習用のままです。配布前に正式な signing 設定へ変更してください。
