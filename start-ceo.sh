#!/bin/bash

# YouAreTheCEO - マルチエージェント並行開発システム
# Copyright (c) 2025 YouAreTheCEO Project

set -e

# 設定ファイルの読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config/system-config.sh"

# 関数定義
print_banner() {
    echo -e "${CEO_COLOR_SYSTEM}"
    echo "=========================================="
    echo "      YouAreTheCEO System v1.0"
    echo "   Parallel Development with Claude Code"
    echo "=========================================="
    echo -e "${CEO_COLOR_RESET}"
}

print_status() {
    echo -e "${CEO_COLOR_SYSTEM}[CEO System]${CEO_COLOR_RESET} $1"
}

print_error() {
    echo -e "${CEO_COLOR_ERROR}[ERROR]${CEO_COLOR_RESET} $1"
}

check_dependencies() {
    print_status "依存関係をチェック中..."
    
    if ! command -v tmux &> /dev/null; then
        print_error "tmux がインストールされていません"
        exit 1
    fi
    
    if ! command -v claude &> /dev/null; then
        print_error "Claude Code がインストールされていません"
        exit 1
    fi
    
    print_status "依存関係チェック完了"
}

cleanup_existing_session() {
    if tmux has-session -t "$CEO_SESSION" 2>/dev/null; then
        print_status "既存のセッション $CEO_SESSION をクリーンアップ中..."
        tmux kill-session -t "$CEO_SESSION"
        sleep 1
    fi
}

create_tmux_session() {
    print_status "tmux セッション '$CEO_SESSION' を作成中..."
    
    # セッション作成
    tmux new-session -d -s "$CEO_SESSION" -x 120 -y 40
    
    # ウィンドウ名を設定
    tmux rename-window -t "$CEO_SESSION:0" "CEO-Boss"
    
    # メインpaneでシステム初期化
    # 親ディレクトリに移動
    tmux send-keys -t "$CEO_SESSION:0" -l "cd '$(dirname "$SCRIPT_DIR")'"
    tmux send-keys -t "$CEO_SESSION:0" C-m
    tmux send-keys -t "$CEO_SESSION:0" -l "echo 'CEO System initializing in project root...'"
    tmux send-keys -t "$CEO_SESSION:0" C-m
    
    print_status "tmux セッション作成完了"
}

start_boss() {
    print_status "上司（Boss）を起動中..."
    
    # 上司を起動
    tmux send-keys -t "$CEO_SESSION:0" -l "echo 'Starting Boss (Opus)...'"
    tmux send-keys -t "$CEO_SESSION:0" C-m
    # -lフラグを使用してリテラル文字列として送信
    tmux send-keys -t "$CEO_SESSION:0" -l "$CC_BOSS"
    tmux send-keys -t "$CEO_SESSION:0" C-m
    
    # Claudeが起動するまで少し待機
    sleep 3
    
    # シンプルな初期化メッセージを送信
    print_status "Bossに初期化指示を送信中..."
    
    # MDファイルを参照するだけのシンプルなメッセージ
    local init_message=" $SCRIPT_DIR/config/boss-instructions.md を参照し、自身の役割を理解した後、ユーザーの指示を待ってください。"
    
    # -lフラグを使用してメッセージを送信
    tmux send-keys -t "$CEO_SESSION:0" -l "$init_message"
    tmux send-keys -t "$CEO_SESSION:0" C-m
    
    print_status "上司（Boss）起動完了"
}

initialize_system() {
    print_status "システムを初期化中..."
    
    # ログディレクトリの準備
    mkdir -p "$CEO_LOGS"
    mkdir -p "$CEO_COMM_DIR"
    
    # ステータスファイルの初期化
    echo "ready" > "$CEO_COMM_DIR/boss_status"
    echo "0" > "$CEO_COMM_DIR/worker_count"
    echo "" > "$CEO_COMM_DIR/task_queue"
    
    # 実行可能権限の設定
    chmod +x "$SCRIPT_DIR/scripts"/*.sh 2>/dev/null || true
    
    print_status "システム初期化完了"
}

show_usage() {
    echo -e "${CEO_COLOR_SYSTEM}"
    echo "=========================================="
    echo "      使用方法"
    echo "=========================================="
    echo "1. tmux セッションにアタッチ:"
    echo "   tmux attach-session -t $CEO_SESSION"
    echo ""
    echo "2. 上司に指示を出す:"
    echo "   直接メッセージを入力してください"
    echo ""
    echo "3. ペイン操作（マウス推奨）:"
    echo "   - マウスクリック: ペイン選択"
    echo "   - マウスホイール: スクロール"
    echo "   - ドラッグ: テキスト選択"
    echo "   - Ctrl-a + z: ペイン最大化（動作しない場合あり）"
    echo ""
    echo "4. システム終了:"
    echo "   tmux kill-session -t $CEO_SESSION"
    echo ""
    echo "5. トラブルシューティング:"
    echo "   cat ./YouAreTheCEO/tmux-troubleshooting.md"
    echo "=========================================="
    echo -e "${CEO_COLOR_RESET}"
}

# 自動アタッチ確認
auto_attach() {
    echo ""
    echo -e "${CEO_COLOR_SYSTEM}セッションに自動的にアタッチしますか？ (y/n):${CEO_COLOR_RESET} \c"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_status "セッションにアタッチ中..."
        sleep 1
        tmux attach-session -t "$CEO_SESSION"
    else
        echo ""
        echo -e "${CEO_COLOR_BOSS}[Boss Ready]${CEO_COLOR_RESET} セッションにアタッチして指示を出してください："
        echo "tmux attach-session -t $CEO_SESSION"
    fi
}

# メイン実行
main() {
    print_banner
    
    check_dependencies
    cleanup_existing_session
    create_tmux_session
    initialize_system
    start_boss
    
    print_status "$CEO_MSG_READY"
    show_usage
    
    # 自動アタッチの確認
    auto_attach
}

# 実行
main "$@"