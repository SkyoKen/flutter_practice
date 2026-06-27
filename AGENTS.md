# AGENTS.md

## リポジトリ概要

このリポジトリは `Cyber Table Order` という Flutter 練習アプリです。Dart package 名は `cyber_table_order` です。現在のアプリ本体は、複数テーマを切り替えられる飲食店・テーブル注文 UI で、言語切り替え、疑似会員ログイン、QR 注文ダイアログ、メニュー絞り込み、カート管理、注文確定、会計、メモリ上の注文履歴を扱います。

実装規模は小さく、主なアプリコードはほぼ `lib/` 配下にあります。各 platform ディレクトリは Flutter が生成する標準的な設定・ランナー類です。

## 最初に確認するファイル

- `pubspec.yaml`: パッケージ情報、SDK 制約、依存関係、アセット登録を確認します。依存は `provider`, `intl`, `qr_flutter`, `google_nav_bar`, Cupertino icons です。`lib/images/` がアセットディレクトリとして登録されています。
- `analysis_options.yaml`: lint は `package:flutter_lints/flutter.yaml` を利用しています。
- `lib/main.dart`: アプリの入口です。トップレベルで `ChangeNotifierProvider<Restaurant>` を作り、`IntroPage` から開始します。
- `lib/models/restaurant.dart`: アプリ状態の中心です。言語、疑似認証・会員情報、メニュー、カート数量、注文履歴、合計金額計算、注文確定を持っています。
- `lib/models/food.dart`: メニュー項目のモデルです。`Food` はカート内で `Map` のキーとして使われるため、等価性と `hashCode` が `id` ベースになっています。
- `lib/utils/translations.dart`: `en`, `zh`, `ja` の翻訳テーブルです。新しい UI 文言を追加する場合は 3 言語すべてにキーを追加してください。
- `lib/pages/intro_page.dart`: 最初の画面と、アプリに入る前の言語切り替えです。
- `lib/pages/home_page.dart`: アプリの外枠です。AppBar、Drawer、会員ログイン・プロフィール、QR ダイアログ、設定ダイアログ、店員呼び出し、履歴ダイアログを扱います。本文は `MenuPage` です。
- `lib/pages/menu_page.dart`: メインの注文 UI です。カテゴリ・サブカテゴリ選択、メニューグリッド、カート側パネル、注文確認、会計依頼、履歴ダイアログを持っています。
- `lib/components/food_tile.dart`: 1 つのメニュー項目を表示するカードです。カートへの追加・削除操作もここにあります。
- `lib/theme/app_theme_mode.dart`, `lib/theme/app_theme.dart`, `lib/theme/theme_tokens.dart`, `lib/theme/theme_controller.dart`: テーマ切り替えの中心です。現在は `Neon Terminal`, `Neo Brutalism`, `Paper Receipt`, `Retro OS` を扱います。
- `test/widget_test.dart`: Intro から点餐画面へ進む smoke test と、狭い画面での表示確認を持っています。
- `test/restaurant_test.dart`: `Restaurant` のカート、合計金額、注文履歴、言語切り替えを確認します。

## ディレクトリ構成

- `lib/`: アプリケーションコードです。
  - `components/`: 再利用する Widget。
  - `models/`: データモデルや状態オブジェクト。
  - `pages/`: 画面単位、または大きめの UI。
  - `theme/`: テーマモード、テーマ token、テーマ状態管理。
  - `utils/`: 共通ヘルパー。現状は翻訳のみです。
  - `images/`: 登録済みのアセットディレクトリです。現時点では `logo.jpg` があります。メニュー項目の `imagePath` は複数の画像名を参照していますが、それらのファイルは存在せず、`FoodTile` でもまだ表示されていません。
- `test/`: Flutter テストです。
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`: Flutter の platform プロジェクトです。platform 固有の作業でない限り、生成ファイルは編集しないでください。
- `.dart_tool/`, `build/`: ローカル生成物・キャッシュです。手動編集やコミット対象にしないでください。

## 開発コマンド

リポジトリルートで実行します。

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d chrome
```

platform 固有の確認が必要な場合は、対象に合わせて別の `flutter run -d ...` を使ってください。

現時点で分かっている検証状態:

- `flutter analyze` は通ります。
- `flutter test` は通ります。
- `flutter pub get` 実行後の package 名は `cyber_table_order` です。

## 実装方針

- 明示的な要望がない限り、既存の Provider / `ChangeNotifier` パターンを維持してください。
- 共有される可変状態は `Restaurant` に置きます。UI 更新が必要な変更の後は `notifyListeners()` を呼びます。
- メニュー項目を追加する場合は、ユニークな `Food.id` を使い、`price` は小数として parse できる文字列にし、`tags` は `MenuPage` のカテゴリ・サブカテゴリ ID と一致させてください。
- UI 文言を追加する場合は `restaurant.translate(...)` を使い、`Translations` の英語・中国語・日本語すべてにキーを追加してください。
- UI を追加・変更する場合は、必ずすべてのテーマとの互換性を確認してください。色だけを直接指定せず、まず `AppTheme.of(context)` または `AppTheme` の theme-aware getter を使います。構造差が必要な UI は `AppTheme.activeMode` で分岐し、`Neon Terminal`, `Neo Brutalism`, `Paper Receipt`, `Retro OS` の見た目が破綻しないようにします。
- `Food.imagePath` を実際に表示する変更を行う場合は、先に実ファイルを `lib/images/` に追加するか、存在するアセットを参照するようにデータを変更してください。
- 指示がない限り、現在のテーマ構造を維持してください。特定テーマだけに固定された黒背景、白文字、amber などの直書きは避け、ダイアログ、SnackBar、Drawer、ボタン、カードなどもテーマ互換にします。
- `MenuPage` は幅 900px 以上では 2 カラム、狭い画面ではメニュー上・カート下の縦積み表示になります。レイアウトに関わる変更では、広い画面と狭い画面の両方を確認してください。
- `HistoryPage` は存在しますが、現在 `HomePage` から直接ルーティングされていません。現状の履歴表示はダイアログ内で実装されています。
- platform ディレクトリの編集は必要最小限にしてください。通常のアプリ挙動は、まず `lib/` とテストを変更します。

## 今後のテスト方針

- モデルや状態管理を変更する場合は、カート数量、合計金額、言語変更、注文履歴など、`Restaurant` の振る舞いに対するテストを追加・更新してください。
- UI を変更する場合は、`MyApp` を pump して `HomePage` に入り、広い画面・狭い画面の両方でカートや注文 UI を確認するテストを更新してください。
- コード変更を渡す前に、`dart format lib test`、`flutter analyze`、関連テストを実行してください。既存の無関係な lint やテスト失敗が残る場合は、内容を明確に報告してください。
