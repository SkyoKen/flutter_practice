# TABLE NOVA

TABLE NOVA は Flutter で作られた、シングルプレイ専用のオフライン・レストラン経営放置ゲームです。自動営業で収益を蓄え、店舗や料理を強化しながら、手動の Kitchen Rush で接客と調理のコンボに挑戦します。

バックエンド、アカウント、クラウド同期は使用せず、ゲームの進行状態は端末内に保存します。

## ゲームの主な流れ

- 自動営業: 客は来店後、待機列、座席、キッチン、食事、会計の順に進みます。プレイ中は自動で営業が続き、蓄積した収益をコインとして受け取れます。
- 放置収益: 前回の保存時刻から経過した時間を基に、最大 8 時間分の収益を計算します。
- Kitchen Rush: 客を席へ案内し、注文伝票に合う料理を選びます。制限時間内に正しく提供すると、コンボ、追加報酬、料理の熟練度が上がります。
- 店舗強化: 座席、サービス、キッチン、各料理をコインで強化できます。強化と接客で店舗 XP が増え、店舗レベルに応じて料理が解放されます。
- 経営診断: 現在のボトルネック、推定処理量、強化前後の COINS/MIN と推奨強化を確認できます。
- 目標とタスク: 営業目標、デイリータスク、シフト結果、統計を通じて進行状況と報酬を確認できます。通常客、せっかち客、VIP 客や、営業に影響するイベントも発生します。

## 表示と操作

- 英語、中国語、日本語の 3 言語に対応しています。
- Neon Terminal、Neo Brutalism、Paper Receipt、Retro OS の 4 テーマを切り替えられます。
- 広い画面と狭い画面の両方に対応するレスポンシブ UI です。
- 初回は 3 ステップのガイドを表示し、完了位置を端末内に保存します。OS の「アニメーションを減らす」設定にも対応します。

## データ保存

`GameController` は `shared_preferences` を通じて、コイン、店舗・料理の強化、解放状態、接客実績、タスク、営業中の客状態、未受取収益などを 1 つのバージョン付きスナップショットとして端末内に保存します。書き込みは直列化され、旧形式の分散キーは自動移行されます。設定画面からゲームの保存データをリセットできます。

表示言語、テーマ、新手ガイドの進行も端末内に保存され、再起動後に復元されます。

## 主なファイル

- `lib/main.dart`: ゲーム、表示設定、新手ガイドの各 Controller を Provider で注入するアプリの入口です。
- `lib/models/game_controller.dart`: 自動営業、放置収益、Kitchen Rush、強化、タスクを調停するゲーム状態の中心です。
- `lib/models/game_storage.dart`, `game_models.dart`, `game_balance.dart`: 保存、値オブジェクト、純粋な経営計算を分担します。
- `lib/models/food_catalog.dart`: 料理 ID、翻訳キー、解放レベル、基礎報酬の唯一の定義元です。
- `lib/models/restaurant.dart`: 料理一覧と言語状態を公開します。
- `lib/pages/intro_page.dart`: ゲーム開始画面と開始前の言語切り替えを扱います。
- `lib/pages/home_page.dart`: 経営画面の外枠と設定を扱います。
- `lib/pages/menu_page.dart`: 自動営業、料理図鑑、運営強化、Kitchen Rush を配置するメイン画面です。
- `lib/components/customer_arrival_stage.dart`: 来店から会計までの自動営業を表示します。
- `lib/components/kitchen_rush_panel.dart`: Kitchen Rush の手動接客フローを表示します。
- `lib/theme/`: 4 テーマのトークン、ThemeData、切り替え状態を管理します。
- `lib/utils/translations.dart`: 3 言語の翻訳テーブルです。
- `test/`: ゲームロジック、保存後の復帰、主要コンポーネント、4 テーマ、広い画面と狭い画面の動作を検証します。

## 開発コマンド

リポジトリルートで実行します。

```sh
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d chrome
```

## 現在の制約

- オンライン同期、マルチプレイ、バックエンド連携はありません。
- 現在の料理表示はテーマ対応アイコンを使用し、画像アセットはアプリにバンドルしません。
- 練習用の application/bundle ID として `dev.practice.cybertableorder` を使用しています。
- Android の release signing は練習用の設定です。配布前に正式な signing 設定が必要です。
