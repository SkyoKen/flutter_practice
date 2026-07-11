# AGENTS.md

## リポジトリ概要

このリポジトリは `TABLE NOVA` という Flutter 製のシングルプレイ・オフラインレストラン経営放置ゲームです。Dart package 名は `cyber_table_order` のまま維持しています。

プレイヤーはレストラン経営者として、自動営業の収益を受け取り、座席・サービス・キッチン・料理を強化します。手動の `Kitchen Rush`、料理熟練度、店舗レベル、解放、営業目標、デイリータスク、客タイプ、イベント、最大 8 時間の放置収益を扱います。旧テーブル注文 UI、会員、QR、カート、注文履歴は製品スコープ外です。

## 最初に確認するファイル

- `pubspec.yaml`: SDK 制約、`provider`、`shared_preferences` を確認します。
- `lib/main.dart`: ゲーム、言語、テーマ、新手ガイドの Controller を Provider で注入し、`IntroPage` から開始します。
- `lib/models/game_controller.dart`: 自動営業、手動接客、強化、解放、目標、タスク、イベントを調停します。
- `lib/models/game_storage.dart`, `game_models.dart`, `game_balance.dart`: 保存層、ゲーム値オブジェクト、純粋な経営計算です。
- `lib/models/food_catalog.dart`: 料理 ID、翻訳キー、解放レベル、基礎報酬の唯一の定義元です。
- `lib/models/restaurant.dart`: 料理一覧と言語状態を持ちます。
- `lib/models/food.dart`: 料理モデルです。`id` はゲーム保存データと解放条件で使うため、安定かつユニークにしてください。
- `lib/pages/intro_page.dart`: 開始画面と開始前の言語切り替えです。
- `lib/pages/home_page.dart`: 経営画面の AppBar と設定ダイアログを持つ外枠です。
- `lib/pages/menu_page.dart`: 自動営業舞台、収益受取、運営強化、料理図鑑、目標、Kitchen Rush への主導線です。
- `lib/components/customer_arrival_stage.dart`: 自動客の来店から退店までを表示します。
- `lib/components/kitchen_rush_panel.dart`: 手動接客、料理選択、コンボ、班次結果を扱います。
- `lib/components/game_status_bar.dart`: コイン、収益率、店舗レベルなどを表示します。
- `lib/utils/translations.dart`: `en`、`zh`、`ja` の翻訳テーブルです。
- `lib/theme/`: `Neon Terminal`、`Neo Brutalism`、`Paper Receipt`、`Retro OS` のトークンと状態管理です。
- `test/game_controller_test.dart`: ゲーム状態遷移と保存復元の中心テストです。
- `test/widget_test.dart`: Intro から経営画面へ進む広幅・狭幅 smoke test です。

## ディレクトリ構成

- `lib/components/`: 再利用 Widget。
- `lib/models/`: 料理データ、ゲーム状態、保存処理。
- `lib/pages/`: 開始画面、経営画面外枠、メインダッシュボード。
- `lib/theme/`: テーマモード、ThemeData、theme token。
- `lib/utils/`: 翻訳。
- `lib/images/`: 旧練習用ファイルが残っていますが、現在は asset 登録も実行時参照もありません。
- `test/`: model test と widget test。
- platform ディレクトリ: Flutter のランナーと表示名設定。platform 固有作業以外は必要最小限の編集にしてください。
- `.dart_tool/`, `build/`: 生成物。手動編集・コミット対象外です。

## 開発コマンド

リポジトリルートで実行します。

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d chrome
```

## 実装方針

- Provider / `ChangeNotifier` パターンを維持してください。
- 永続化されるゲーム状態は `GameController`、料理一覧と言語状態は `Restaurant`、テーマ状態は `ThemeController`、新手ガイドは `OnboardingController` に置きます。
- `GameController.load()` 完了前にゲーム操作を進めないでください。
- メニュー項目を追加・変更する場合は `FoodCatalog` のみを定義元とし、安定した `Food.id` と 3 言語の name/description キーを追加してください。
- UI 文言を追加する場合は `restaurant.translate(...)` を使い、英語・中国語・日本語の全テーブルに同じキーを追加してください。
- UI 変更は四テーマすべてで確認し、色、角丸、境界、影、テーマモードは `AppTheme.of(context)` / `AppTheme.modeOf(context)` から取得してください。グローバルなテーマ状態を追加しないでください。
- 主画面は横長かつ幅 820px 以上で左右分割、それ以外は上下配置です。広幅・狭幅・短い画面を考慮してください。
- 自動営業の Timer、保存、ユーザー操作が重ならないよう、非同期処理の再入を防いでください。
- 料理画像を導入する場合は、実アセットを追加して `pubspec.yaml` に明示登録し、四テーマの代替表示も用意してください。
- 旧テーブル注文、会員、QR、呼び出し、カート、注文履歴を再導入しないでください。必要な履歴機能は経営ログまたは班次ログとして設計してください。

## テスト方針

- ゲームモデル変更では、時刻を固定し、状態遷移、収益、保存復元、上限、重複実行をテストしてください。
- UI 変更では、四テーマと 390px / 1000px 程度の幅を確認し、主画面は広幅・狭幅 smoke test を更新してください。
- アニメーション UI は `disableAnimations` も考慮してください。
- コード変更前の受け渡しでは、`dart format lib test`、`flutter analyze`、`flutter test`、`git diff --check` を実行してください。
