#!/bin/bash

# YouAreTheCEO Communication System
# エージェント間リアルタイム通信システム

set -e

# 設定読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config/system-config.sh"

# 通信ログ
log_comm() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [COMM] $1" | tee -a "$CEO_LOGS/communication.log"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [COMM ERROR] $1" | tee -a "$CEO_LOGS/error.log"
}

# 上司から部下への指示送信
send_to_worker() {
    local worker_id="$1"
    local message="$2"
    
    if [[ -z "$worker_id" || -z "$message" ]]; then
        log_error "send_to_worker: worker_id と message が必要です"
        return 1
    fi
    
    log_comm "上司から部下 $worker_id へ送信: $message"
    
    # 部下の存在確認
    if [[ ! -f "$CEO_COMM_DIR/${worker_id}_status" ]]; then
        log_error "部下 $worker_id が見つかりません"
        return 1
    fi
    
    # 部下のpane名を取得
    local worker_num="${worker_id#worker_}"
    local pane_name="CEO-Worker-$worker_num"
    
    # paneの存在確認
    if ! tmux list-windows -t "$CEO_SESSION" | grep -q "$pane_name"; then
        log_error "部下 $worker_id のpane $pane_name が見つかりません"
        return 1
    fi
    
    # メッセージをタスクファイルに書き込み
    echo "$message" > "$CEO_COMM_DIR/${worker_id}_task"
    
    # 部下のpaneに直接メッセージを送信
    local formatted_message="[上司より] $message"
    
    # tmux経由でメッセージを送信
    tmux send-keys -t "$CEO_SESSION:$pane_name" "$formatted_message" Enter
    
    # 送信ログを記録
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] TO_$worker_id: $message" >> "$CEO_LOGS/message_log.txt"
    
    log_comm "部下 $worker_id への送信完了"
    
    return 0
}

# 部下から上司への報告
report_to_boss() {
    local worker_id="$1"
    local message="$2"
    
    if [[ -z "$worker_id" || -z "$message" ]]; then
        log_error "report_to_boss: worker_id と message が必要です"
        return 1
    fi
    
    log_comm "部下 $worker_id から上司へ報告: $message"
    
    # 報告メッセージをフォーマット
    local formatted_message="[$worker_id] $message"
    
    # 上司のpaneに報告を送信
    tmux send-keys -t "$CEO_SESSION:CEO-Boss" "$formatted_message" Enter
    
    # 報告ログを記録
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] FROM_$worker_id: $message" >> "$CEO_LOGS/message_log.txt"
    
    # 上司用の報告キューにも追加
    echo "$formatted_message" >> "$CEO_COMM_DIR/boss_reports"
    
    # 部下のハンドラーにも通知
    ./scripts/boss-handler.sh handle_reports "$worker_id" "$message" &
    
    log_comm "上司への報告完了"
    
    return 0
}

# ブロードキャスト（全部下への一斉送信）
broadcast_to_workers() {
    local message="$1"
    
    if [[ -z "$message" ]]; then
        log_error "broadcast_to_workers: message が必要です"
        return 1
    fi
    
    log_comm "全部下へブロードキャスト: $message"
    
    local worker_count=$(cat "$CEO_COMM_DIR/worker_count" 2>/dev/null || echo "0")
    
    if [[ "$worker_count" -eq 0 ]]; then
        log_comm "送信先の部下がいません"
        return 0
    fi
    
    # 並列で全部下に送信
    for ((i=1; i<=worker_count; i++)); do
        local worker_id="worker_$i"
        send_to_worker "$worker_id" "$message" &
    done
    
    wait
    
    log_comm "ブロードキャスト完了 - $worker_count 人の部下に送信"
    
    return 0
}

# 部下間通信（部下同士でのメッセージ交換）
worker_to_worker() {
    local from_worker="$1"
    local to_worker="$2"
    local message="$3"
    
    if [[ -z "$from_worker" || -z "$to_worker" || -z "$message" ]]; then
        log_error "worker_to_worker: from_worker, to_worker, message が必要です"
        return 1
    fi
    
    log_comm "部下間通信: $from_worker -> $to_worker: $message"
    
    # 送信元・送信先の存在確認
    if [[ ! -f "$CEO_COMM_DIR/${from_worker}_status" ]]; then
        log_error "送信元部下 $from_worker が見つかりません"
        return 1
    fi
    
    if [[ ! -f "$CEO_COMM_DIR/${to_worker}_status" ]]; then
        log_error "送信先部下 $to_worker が見つかりません"
        return 1
    fi
    
    # 送信先部下にメッセージを送信
    local formatted_message="[$from_worker より] $message"
    send_to_worker "$to_worker" "$formatted_message"
    
    # 上司にも部下間通信を報告
    report_to_boss "$from_worker" "部下間通信: $to_worker へ「$message」を送信"
    
    log_comm "部下間通信完了"
    
    return 0
}

# 緊急メッセージ（優先度高）
emergency_message() {
    local target="$1"
    local message="$2"
    
    if [[ -z "$target" || -z "$message" ]]; then
        log_error "emergency_message: target と message が必要です"
        return 1
    fi
    
    log_comm "緊急メッセージ送信: $target -> $message"
    
    local urgent_message="🚨 緊急: $message"
    
    case "$target" in
        "boss")
            tmux send-keys -t "$CEO_SESSION:CEO-Boss" "$urgent_message" Enter
            # 画面をフラッシュさせる
            tmux display-message -t "$CEO_SESSION:CEO-Boss" "$urgent_message"
            ;;
        "all_workers")
            broadcast_to_workers "$urgent_message"
            ;;
        worker_*)
            send_to_worker "$target" "$urgent_message"
            # 該当paneをハイライト
            local worker_num="${target#worker_}"
            local pane_name="CEO-Worker-$worker_num"
            tmux display-message -t "$CEO_SESSION:$pane_name" "$urgent_message"
            ;;
        *)
            log_error "不正な緊急メッセージ対象: $target"
            return 1
            ;;
    esac
    
    # 緊急ログに記録
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] EMERGENCY to $target: $message" >> "$CEO_LOGS/emergency.log"
    
    log_comm "緊急メッセージ送信完了"
    
    return 0
}

# システム通知
system_notification() {
    local notification_type="$1"
    local message="$2"
    
    log_comm "システム通知: $notification_type - $message"
    
    local system_message="[システム] $message"
    
    case "$notification_type" in
        "worker_joined")
            # 新しい部下が参加
            tmux send-keys -t "$CEO_SESSION:CEO-Boss" "$system_message" Enter
            ;;
        "worker_left")
            # 部下が離脱
            tmux send-keys -t "$CEO_SESSION:CEO-Boss" "$system_message" Enter
            ;;
        "task_completed")
            # タスク完了通知
            tmux send-keys -t "$CEO_SESSION:CEO-Boss" "$system_message" Enter
            ;;
        "error_occurred")
            # エラー発生通知
            emergency_message "boss" "$message"
            ;;
        *)
            # 汎用通知
            tmux send-keys -t "$CEO_SESSION:CEO-Boss" "$system_message" Enter
            ;;
    esac
    
    return 0
}

# 通信状態の確認
check_communication() {
    log_comm "通信状態をチェック中..."
    
    # tmuxセッションの確認
    if ! tmux has-session -t "$CEO_SESSION" 2>/dev/null; then
        log_error "tmuxセッション $CEO_SESSION が見つかりません"
        return 1
    fi
    
    # 上司paneの確認
    if ! tmux list-windows -t "$CEO_SESSION" | grep -q "CEO-Boss"; then
        log_error "上司pane CEO-Boss が見つかりません"
        return 1
    fi
    
    # 部下paneの確認
    local worker_count=$(cat "$CEO_COMM_DIR/worker_count" 2>/dev/null || echo "0")
    for ((i=1; i<=worker_count; i++)); do
        local pane_name="CEO-Worker-$i"
        if ! tmux list-windows -t "$CEO_SESSION" | grep -q "$pane_name"; then
            log_error "部下pane $pane_name が見つかりません"
        fi
    done
    
    # 通信ディレクトリの確認
    if [[ ! -d "$CEO_COMM_DIR" ]]; then
        log_error "通信ディレクトリ $CEO_COMM_DIR が見つかりません"
        return 1
    fi
    
    log_comm "通信状態チェック完了"
    
    return 0
}

# 通信履歴の表示
show_message_history() {
    local filter="$1"
    
    if [[ -f "$CEO_LOGS/message_log.txt" ]]; then
        if [[ -n "$filter" ]]; then
            grep "$filter" "$CEO_LOGS/message_log.txt" | tail -20
        else
            tail -20 "$CEO_LOGS/message_log.txt"
        fi
    else
        echo "メッセージ履歴が見つかりません"
    fi
}

# 通信システムの初期化
init_communication() {
    log_comm "通信システムを初期化中..."
    
    # 通信ディレクトリの作成
    mkdir -p "$CEO_COMM_DIR"
    
    # 通信ファイルの初期化
    touch "$CEO_COMM_DIR/boss_reports"
    touch "$CEO_LOGS/message_log.txt"
    touch "$CEO_LOGS/communication.log"
    touch "$CEO_LOGS/emergency.log"
    
    # 権限設定
    chmod 644 "$CEO_COMM_DIR"/*
    chmod 644 "$CEO_LOGS"/*.log
    
    log_comm "通信システム初期化完了"
    
    return 0
}

# メイン処理
main() {
    local command="$1"
    shift
    
    case "$command" in
        "send_to_worker")
            send_to_worker "$@"
            ;;
        "report_to_boss")
            report_to_boss "$@"
            ;;
        "broadcast_to_workers")
            broadcast_to_workers "$@"
            ;;
        "worker_to_worker")
            worker_to_worker "$@"
            ;;
        "emergency_message")
            emergency_message "$@"
            ;;
        "system_notification")
            system_notification "$@"
            ;;
        "check_communication")
            check_communication
            ;;
        "show_message_history")
            show_message_history "$@"
            ;;
        "init_communication")
            init_communication
            ;;
        *)
            echo "使用方法: $0 {send_to_worker|report_to_boss|broadcast_to_workers|worker_to_worker|emergency_message|system_notification|check_communication|show_message_history|init_communication} [args...]"
            exit 1
            ;;
    esac
}

# 実行
main "$@"