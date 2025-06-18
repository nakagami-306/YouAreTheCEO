# YouAreTheCEO v1.0.4

並行開発のためのClaude Codeマルチエージェントシステム

## 概要

YouAreTheCEOは、Claude Codeを活用したマルチエージェント並行開発システムです。上司（Boss）として動作する1つのOpus Claude Codeと、部下（Worker）として動作する複数のSonnet Claude Codeが協調して、複雑なタスクを効率的に処理します。



## システム要件

- Linux/macOS/WSL
- tmux
- Claude Code
- Bash 4.0+

### 2. ディレクトリ構造

```
your-project/                  # あなたのプロジェクトルート
├── src/                       # あなたのプロジェクトファイル
├── package.json               # あなたのプロジェクト設定
├── YouAreTheCEO/              # このシステム
│   ├── start-ceo.sh           # メイン起動スクリプト
│   ├── CLAUDE.md              # Claude Code用指示ファイル
│   ├── tmux-help.md           # tmuxキーバインドヘルプ
│   ├── config/
│   │   ├── system-config.sh   # システム設定
│   │   ├── boss-instructions.md    # Bossエージェント用詳細指示
│   │   └── worker-instructions.md  # Workerエージェント用詳細指示
│   ├── scripts/
│   │   ├── boss-handler.sh    # 上司用自動化スクリプト
│   │   ├── worker-handler.sh  # 部下用自動化スクリプト
│   │   ├── communication.sh   # エージェント間通信システム
│   │   └── setup-tmux.sh      # tmux自動セットアップ
│   ├── logs/                  # ログファイル（自動生成）
│   │   ├── boss.log           # Bossエージェントの活動ログ
│   │   ├── communication.log  # エージェント間通信ログ
│   │   ├── worker_*.log       # 各Workerエージェントの活動ログ
│   │   ├── worker_reports.log # Workerからの報告集約ログ
│   │   ├── error.log          # システムエラーログ
│   │   ├── emergency.log      # 緊急メッセージログ
│   │   ├── message_log.txt    # 全メッセージ履歴
│   │   ├── session.log        # tmuxセッション情報
│   │   ├── session_monitor.log # セッション監視ログ
│   │   ├── tmux.log           # tmux設定・操作ログ
│   │   └── comm/              # 通信用ファイル（自動生成）
│   │       ├── boss_status    # Bossの状態ファイル
│   │       ├── worker_count   # 現在のWorker数
│   │       ├── worker_*_status # 各Workerの状態
│   │       ├── worker_*_task  # 各Workerのタスク内容
│   │       ├── worker_*_instructions.md # 各Worker用カスタマイズ指示
│   │       ├── worker_list    # Worker一覧
│   │       ├── task_queue     # タスクキュー
│   │       ├── task_assignments # タスク割り当て履歴
│   │       ├── current_task   # 現在のメインタスク
│   │       ├── boss_reports   # Boss向け報告キュー
│   │       ├── latest_report  # 最新の報告
│   │       ├── spawn_result   # Worker起動結果
│   │       ├── worker_status_report # Worker状態レポート
│   │       └── layout_*       # tmuxレイアウト設定
│   └── README.md
└── other-files...
```

**注意**: `logs/` ディレクトリとその内容はシステム起動時に自動生成されます。手動で作成する必要はありません。

## 使用方法

### 1. システム起動

```bash
# あなたのプロジェクトルートで実行
# 初回のみ: スクリプトに実行権限を付与
chmod +x ./YouAreTheCEO/start-ceo.sh ./YouAreTheCEO/scripts/*.sh

# システム起動
./YouAreTheCEO/start-ceo.sh
```

### 2. セッションにアタッチ

```bash
tmux attach-session -t your-company
```

### 3. 上司に指示を出す

tmuxセッション内で直接上司に指示を送信してください。上司はあなたのプロジェクトルート（YouAreTheCEOの親ディレクトリ）で作業します：

```
Webアプリケーションの認証システムを実装してください。
フロントエンド、バックエンド、データベース設計を並列で進めたいです。
```

### 4. 自動処理の流れ

1. 上司がワークフローを分析
2. 必要な部下数を自動決定（例：3人）
3. 部下を自動起動
4. タスクを分割・割り振り
5. 部下が並列実行・進捗報告
6. 上司が全体管理・問題対処

### 5. システム終了

```bash
tmux kill-session -t your-company
```

## 主要コマンド

### tmux操作

#### キーボード操作
- `Ctrl-b + o`: 次のペインへ移動
- `Ctrl-b + 方向キー`: ペイン間移動
- `Ctrl-b + z`: ペインの最大化/元に戻す
- `Ctrl-b + Space`: レイアウト切り替え
- `Ctrl-b + q`: ペイン番号表示
- `Ctrl-b + d`: セッションからデタッチ
- `Ctrl-b + [`: コピーモードに入る（スクロール用）
  - コピーモード中: 矢印キーでスクロール、`q`または`Esc`で終了

※ プリフィックスキーは`Ctrl-b`（tmuxデフォルト）です

### 上司が使用する自動化コマンド

```bash
# タスク情報保存（参考用）
./YouAreTheCEO/scripts/boss-handler.sh save_workflow_info "$USER_TASK"

# 部下起動（必要数を自分で判断）
./YouAreTheCEO/scripts/boss-handler.sh spawn_workers [数]

# タスク割り振り
./YouAreTheCEO/scripts/boss-handler.sh assign_task worker_1 "$TASK_DESCRIPTION"

# 部下管理
./YouAreTheCEO/scripts/boss-handler.sh manage_workers status
```

### 部下が使用する報告コマンド

```bash
# 進捗報告
./YouAreTheCEO/scripts/communication.sh report_to_boss worker_1 "タスクAの50%完了"

# 問題報告
./YouAreTheCEO/scripts/communication.sh report_to_boss worker_1 "エラー: ファイルが見つかりません"

# 完了報告
./YouAreTheCEO/scripts/communication.sh report_to_boss worker_1 "タスク完了"
```

## 設定のカスタマイズ

`config/system-config.sh` で以下の設定を変更可能：

- `CEO_MAX_WORKERS`: 最大部下数（デフォルト: 8）
- `CEO_DEFAULT_WORKERS`: デフォルト部下数（デフォルト: 2）
- `CC_BOSS`: 上司用Claude Codeコマンド
- `CC_WORKER`: 部下用Claude Codeコマンド

## ログとモニタリング

- `YouAreTheCEO/logs/boss.log`: 上司の活動ログ
- `YouAreTheCEO/logs/communication.log`: 通信ログ  
- `YouAreTheCEO/logs/worker_*.log`: 各部下の活動ログ
- `YouAreTheCEO/logs/error.log`: エラーログ

**注意**: ログはYouAreTheCEOディレクトリ内に保存されますが、実際の作業ファイルはあなたのプロジェクトルートに作成されます。

## トラブルシューティング

### tmuxキーバインドが動作しない

```bash
# キーバインド修正スクリプトを実行
./YouAreTheCEO/scripts/fix-tmux-keys.sh

# 詳細なトラブルシューティング
cat ./YouAreTheCEO/tmux-troubleshooting.md
```

**代替方法**: マウス操作が最も確実です。ペインをクリックして選択できます。

### セッションが見つからない

```bash
# YouAreTheCEOディレクトリで実行
cd YouAreTheCEO
tmux list-sessions

# 権限確認・再付与
chmod +x start-ceo.sh scripts/*.sh
./start-ceo.sh
```

### 部下が応答しない

```bash
# YouAreTheCEOディレクトリで実行
cd YouAreTheCEO

# 権限確認
chmod +x scripts/*.sh

# 部下の状態確認
./scripts/boss-handler.sh manage_workers status

# 部下のコンテキストクリア
./scripts/boss-handler.sh manage_workers clear worker_1
```

### 通信エラー

```bash
# YouAreTheCEOディレクトリで実行
cd YouAreTheCEO

# 権限確認
chmod +x scripts/*.sh

# 通信状態確認
./scripts/communication.sh check_communication

# 通信履歴確認
./scripts/communication.sh show_message_history
```

## ライセンス

MIT License

## 更新履歴

### v1.0.5 (2025-06-17)
- 作業ディレクトリを親ディレクトリに変更: Boss/Workerがプロジェクトルートで直接作業
- tmux prefixキーをCtrl-aに変更: より使いやすい設定
- ペイン分割に変更: 全Workerが同一ウィンドウ内に表示
- tmux send-keysに-lフラグ追加: 入力欄にメッセージが残る問題を解決
- READMEにログファイル詳細を追記: 自動生成されるファイルを明記

### v1.0.4 (2025-06-17)
- Boss/Worker指示をMarkdown形式に変更（boss-instructions.md, worker-instructions.md）
- 視認性向上: 絵文字とセクション分けで指示を明確化
- システム起動時に/readコマンドで指示ファイルを自動読み込み
- 「一人でやろうとしない」を強調した注意事項を追加

### v1.0.3 (2025-06-17)
- analyze_workflow関数を削除: Claudeが自分でワークフロー分析・部下数決定
- より柔軟な判断システム: タスク複雑度以外の要因も考慮可能
- save_workflow_info関数追加: タスク情報保存（参考用）

### v1.0.2 (2025-06-17)
- ユーザープロジェクトルート対応: GitHubからクローン後にプロジェクト内で使用可能
- エージェントが自動でユーザープロジェクトルート（../）で作業
- 明確なディレクトリ構造とインストール手順を追加

### v1.0.1 (2025-06-17)
- 初回リリース
- 基本的なマルチエージェント機能
- tmux統合
- リアルタイム通信システム

---

**注意**: Claude Codeの使用には適切なAPIキーと使用制限の管理が必要です。大量のトークンを消費する可能性があるため、使用前に利用規約をご確認ください。