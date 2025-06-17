#!/bin/bash

# YouAreTheCEO tmux Setup Script
# tmux環境の自動セットアップ

set -e

# 設定読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config/system-config.sh"

# ログ関数
log_tmux() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TMUX] $1" | tee -a "$CEO_LOGS/tmux.log"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TMUX ERROR] $1" | tee -a "$CEO_LOGS/error.log"
}

# tmux設定の確認と調整
configure_tmux_settings() {
    log_tmux "tmux設定を調整中..."
    
    # 基本設定
    tmux set-option -g mouse on
    tmux set-option -g history-limit 10000
    tmux set-option -g base-index 1
    tmux set-option -g pane-base-index 1
    
    # 表示設定
    tmux set-option -g status-position top
    tmux set-option -g status-left-length 50
    tmux set-option -g status-right-length 50
    
    # YouAreTheCEO専用の色設定
    tmux set-option -g status-bg colour235
    tmux set-option -g status-fg colour136
    tmux set-option -g status-left '#[fg=colour166,bold][CEO System] #S '
    tmux set-option -g status-right '#[fg=colour166,bold]%Y-%m-%d %H:%M #[default]'
    
    # ウィンドウ設定
    tmux set-window-option -g window-status-current-style 'fg=colour208,bold'
    tmux set-window-option -g automatic-rename on
    
    # pane設定
    tmux set-option -g pane-border-style 'fg=colour238'
    tmux set-option -g pane-active-border-style 'fg=colour208'
    
    log_tmux "tmux設定調整完了"
}

# CEO専用キーバインドの設定
setup_key_bindings() {
    log_tmux "CEO専用キーバインドを設定中..."
    
    # プリフィックスキーの設定（デフォルトのCtrl-bを維持）
    tmux set-option -g prefix C-b
    
    # CEO System専用のキーバインド
    # Ctrl-b + c: 新しい部下ウィンドウを作成
    tmux bind-key c new-window -n "CEO-Worker-New" 
    
    # Ctrl-b + w: ワーカーリスト表示
    tmux bind-key w choose-window
    
    # Ctrl-b + s: システム状態表示
    tmux bind-key s display-message "CEO System Status - Session: #S, Windows: #{session_windows}, Panes: #{session_panes}"
    
    # Ctrl-b + r: 設定リロード
    tmux bind-key r source-file ~/.tmux.conf \; display-message "Config reloaded!"
    
    # Ctrl-b + q: 全pane番号表示（長時間）
    tmux bind-key q display-panes -t 5000
    
    # Ctrl-b + Space: レイアウト切り替え
    tmux bind-key Space next-layout
    
    log_tmux "キーバインド設定完了"
}

# レイアウトプリセットの作成
create_layout_presets() {
    log_tmux "レイアウトプリセットを作成中..."
    
    # 基本レイアウト（上司のみ）
    save_layout "boss_only" "CEO-Boss"
    
    # 2人体制レイアウト（上司+部下1人）
    setup_2_worker_layout
    save_layout "2_workers" "CEO-Boss,CEO-Worker-1"
    
    # 4人体制レイアウト（上司+部下3人）
    setup_4_worker_layout
    save_layout "4_workers" "CEO-Boss,CEO-Worker-1,CEO-Worker-2,CEO-Worker-3"
    
    # 8人体制レイアウト（上司+部下7人）
    setup_8_worker_layout
    save_layout "8_workers" "CEO-Boss,CEO-Worker-1,CEO-Worker-2,CEO-Worker-3,CEO-Worker-4,CEO-Worker-5,CEO-Worker-6,CEO-Worker-7"
    
    log_tmux "レイアウトプリセット作成完了"
}

# 2人体制レイアウトの設定
setup_2_worker_layout() {
    log_tmux "2人体制レイアウトを設定中..."
    
    # 垂直分割（左：上司、右：部下）
    tmux split-window -h -t "$CEO_SESSION:CEO-Boss"
    tmux select-pane -t 0
    
    # ウィンドウサイズ調整（上司:60%, 部下:40%）
    tmux resize-pane -t 0 -x 60%
    
    log_tmux "2人体制レイアウト設定完了"
}

# 4人体制レイアウトの設定
setup_4_worker_layout() {
    log_tmux "4人体制レイアウトを設定中..."
    
    # 基本的な4分割レイアウト
    # 左上：上司、右上：部下1、左下：部下2、右下：部下3
    
    # 最初に垂直分割
    tmux split-window -h -t "$CEO_SESSION:CEO-Boss"
    
    # 左側を水平分割（上司と部下2）
    tmux split-window -v -t 0
    
    # 右側を水平分割（部下1と部下3）
    tmux split-window -v -t 2
    
    # レイアウト調整
    tmux select-layout tiled
    
    log_tmux "4人体制レイアウト設定完了"
}

# 8人体制レイアウトの設定
setup_8_worker_layout() {
    log_tmux "8人体制レイアウトを設定中..."
    
    # 3x3グリッドレイアウト（中央上が上司、周りが部下）
    
    # 基本分割を実行
    for i in {1..7}; do
        tmux split-window -t "$CEO_SESSION:CEO-Boss"
        tmux select-layout tiled
    done
    
    # 上司を中央に配置
    tmux swap-pane -s 0 -t 4
    
    log_tmux "8人体制レイアウト設定完了"
}

# レイアウトの保存
save_layout() {
    local layout_name="$1"
    local windows="$2"
    
    local layout_info=$(tmux list-windows -t "$CEO_SESSION" -F "#{window_layout}")
    echo "$layout_info" > "$CEO_COMM_DIR/layout_${layout_name}"
    
    log_tmux "レイアウト '$layout_name' を保存"
}

# レイアウトの読み込み
load_layout() {
    local layout_name="$1"
    local layout_file="$CEO_COMM_DIR/layout_${layout_name}"
    
    if [[ -f "$layout_file" ]]; then
        local layout_info=$(cat "$layout_file")
        tmux select-layout -t "$CEO_SESSION" "$layout_info"
        log_tmux "レイアウト '$layout_name' を読み込み"
    else
        log_error "レイアウトファイル $layout_file が見つかりません"
        return 1
    fi
}

# 動的レイアウト調整
adjust_layout_for_workers() {
    local worker_count="$1"
    
    log_tmux "部下数 $worker_count に応じてレイアウトを調整中..."
    
    case "$worker_count" in
        0)
            # 上司のみ - レイアウト調整不要
            log_tmux "上司のみのレイアウト"
            ;;
        1)
            setup_2_worker_layout
            ;;
        2|3)
            setup_4_worker_layout
            ;;
        4|5|6|7)
            setup_8_worker_layout
            ;;
        *)
            # 8人を超える場合はタイルレイアウト
            tmux select-layout tiled
            log_tmux "多人数用タイルレイアウトを適用"
            ;;
    esac
    
    log_tmux "レイアウト調整完了"
}

# ウィンドウタイトルの設定
setup_window_titles() {
    log_tmux "ウィンドウタイトルを設定中..."
    
    # 自動リネーム機能を有効化
    tmux set-window-option -g automatic-rename on
    tmux set-window-option -g automatic-rename-format '#{pane_current_command}'
    
    # CEO-Boss ウィンドウのタイトル設定
    tmux rename-window -t "$CEO_SESSION:0" "CEO-Boss"
    
    log_tmux "ウィンドウタイトル設定完了"
}

# pane同期機能の設定
setup_pane_sync() {
    log_tmux "pane同期機能を設定中..."
    
    # Ctrl-b + y: 全pane同期のトグル
    tmux bind-key y set-window-option synchronize-panes \; \
        display-message "Pane synchronization #{?synchronize-panes,ON,OFF}"
    
    # Ctrl-b + Y: 選択paneのみの同期
    tmux bind-key Y set-window-option synchronize-panes off \; \
        set-window-option synchronize-panes on \; \
        display-message "Selected pane synchronization ON"
    
    log_tmux "pane同期機能設定完了"
}

# CEO System専用のステータス表示
setup_status_display() {
    log_tmux "CEO System専用ステータス表示を設定中..."
    
    # カスタムステータスライン
    tmux set-option -g status-left '#[fg=colour166,bold][CEO System] #S #[fg=colour244]| '
    tmux set-option -g status-right '#[fg=colour244]Workers: #{session_panes} #[fg=colour166,bold]| %Y-%m-%d %H:%M '
    
    # ウィンドウステータスのカスタマイズ
    tmux set-window-option -g window-status-format '#[fg=colour244]#I:#W '
    tmux set-window-option -g window-status-current-format '#[fg=colour208,bold]#I:#W*#[default] '
    
    # メッセージ表示の設定
    tmux set-option -g message-style 'fg=colour208,bg=colour235,bold'
    tmux set-option -g display-time 3000
    
    log_tmux "ステータス表示設定完了"
}

# セッション監視の設定
setup_session_monitoring() {
    log_tmux "セッション監視を設定中..."
    
    # セッション情報をファイルに出力
    tmux run-shell "echo 'CEO Session Started: $(date)' > $CEO_LOGS/session.log"
    
    # 定期的なセッション状態の記録（バックグラウンド）
    (
        while tmux has-session -t "$CEO_SESSION" 2>/dev/null; do
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session: $CEO_SESSION, Windows: $(tmux list-windows -t "$CEO_SESSION" | wc -l), Panes: $(tmux list-panes -t "$CEO_SESSION" -a | wc -l)" >> "$CEO_LOGS/session_monitor.log"
            sleep 60
        done
    ) &
    
    log_tmux "セッション監視設定完了"
}

# tmux環境のクリーンアップ
cleanup_tmux_environment() {
    log_tmux "tmux環境のクリーンアップを実行中..."
    
    # 不要なウィンドウの削除
    tmux list-windows -t "$CEO_SESSION" -F "#{window_name}" | while read window_name; do
        if [[ "$window_name" != "CEO-Boss" && ! "$window_name" =~ CEO-Worker-[0-9]+ ]]; then
            tmux kill-window -t "$CEO_SESSION:$window_name" 2>/dev/null || true
            log_tmux "不要なウィンドウ $window_name を削除"
        fi
    done
    
    log_tmux "クリーンアップ完了"
}

# tmux設定のバックアップ
backup_tmux_config() {
    log_tmux "tmux設定をバックアップ中..."
    
    local backup_file="$CEO_LOGS/tmux_config_backup_$(date +%Y%m%d_%H%M%S).conf"
    
    # 現在の設定をダンプ
    tmux show-options -g > "$backup_file"
    tmux show-window-options -g >> "$backup_file"
    
    log_tmux "設定を $backup_file にバックアップ"
}

# メイン処理
main() {
    local command="$1"
    shift
    
    case "$command" in
        "configure")
            configure_tmux_settings
            setup_key_bindings
            setup_window_titles
            setup_pane_sync
            setup_status_display
            setup_session_monitoring
            ;;
        "layout")
            local layout_action="$1"
            case "$layout_action" in
                "create")
                    create_layout_presets
                    ;;
                "load")
                    load_layout "$2"
                    ;;
                "adjust")
                    adjust_layout_for_workers "$2"
                    ;;
                *)
                    echo "レイアウトコマンド: create, load [name], adjust [count]"
                    ;;
            esac
            ;;
        "cleanup")
            cleanup_tmux_environment
            ;;
        "backup")
            backup_tmux_config
            ;;
        "full_setup")
            log_tmux "フル セットアップを開始..."
            configure_tmux_settings
            setup_key_bindings
            setup_window_titles
            setup_pane_sync
            setup_status_display
            setup_session_monitoring
            create_layout_presets
            log_tmux "フル セットアップ完了"
            ;;
        *)
            echo "使用方法: $0 {configure|layout|cleanup|backup|full_setup} [args...]"
            exit 1
            ;;
    esac
}

# 実行
main "$@"