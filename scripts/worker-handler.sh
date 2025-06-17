#!/bin/bash

# YouAreTheCEO Worker Handler Script
# 部下（Worker）用の自動化スクリプト

set -e

# 設定読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config/system-config.sh"

# 関数定義
log_worker() {
    local worker_id="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WORKER:$worker_id] $message" | tee -a "$CEO_LOGS/worker_${worker_id}.log"
}

log_error() {
    local worker_id="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR:$worker_id] $message" | tee -a "$CEO_LOGS/error.log"
}

# タスク受信と実行監視
monitor_task() {
    local worker_id="$1"
    
    log_worker "$worker_id" "タスク監視開始"
    
    # タスクキューを監視
    local task_file="$CEO_COMM_DIR/${worker_id}_task"
    
    while true; do
        if [[ -f "$task_file" && -s "$task_file" ]]; then
            local task_content=$(cat "$task_file")
            log_worker "$worker_id" "新しいタスクを受信: $task_content"
            
            # タスクを実行
            execute_task "$worker_id" "$task_content"
            
            # タスクファイルをクリア
            > "$task_file"
        fi
        
        sleep 2
    done
}

# タスク実行
execute_task() {
    local worker_id="$1"
    local task_description="$2"
    
    log_worker "$worker_id" "タスク実行開始: $task_description"
    
    # 実行開始を報告
    report_to_boss "$worker_id" "タスク開始: $task_description"
    
    # ステータスを「実行中」に更新
    echo "executing" > "$CEO_COMM_DIR/${worker_id}_status"
    
    # タスクの実行（この部分は実際のタスクに応じて拡張される）
    local result
    local exit_code=0
    
    # 基本的なタスク処理のシミュレーション
    case "$task_description" in
        *"ファイル作成"*|*"create file"*)
            result=$(handle_file_creation "$worker_id" "$task_description") || exit_code=$?
            ;;
        *"コード生成"*|*"generate code"*)
            result=$(handle_code_generation "$worker_id" "$task_description") || exit_code=$?
            ;;
        *"テスト"*|*"test"*)
            result=$(handle_testing "$worker_id" "$task_description") || exit_code=$?
            ;;
        *"分析"*|*"analyze"*)
            result=$(handle_analysis "$worker_id" "$task_description") || exit_code=$?
            ;;
        *)
            result=$(handle_generic_task "$worker_id" "$task_description") || exit_code=$?
            ;;
    esac
    
    # 実行結果を処理
    if [[ $exit_code -eq 0 ]]; then
        log_worker "$worker_id" "タスク完了: $result"
        report_to_boss "$worker_id" "タスク完了: $result"
        echo "completed" > "$CEO_COMM_DIR/${worker_id}_status"
    else
        log_error "$worker_id" "タスク失敗: $result"
        report_to_boss "$worker_id" "エラー発生: $result"
        echo "error" > "$CEO_COMM_DIR/${worker_id}_status"
    fi
}

# ファイル作成処理
handle_file_creation() {
    local worker_id="$1"
    local task_description="$2"
    
    log_worker "$worker_id" "ファイル作成タスクを処理中"
    
    # 進捗報告
    report_progress "$worker_id" "ファイル作成準備中..."
    
    # 実際の処理をシミュレート
    sleep 2
    report_progress "$worker_id" "ファイル作成中 (50%)"
    
    sleep 2
    report_progress "$worker_id" "ファイル作成完了 (100%)"
    
    echo "ファイル作成タスクが正常に完了しました"
}

# コード生成処理
handle_code_generation() {
    local worker_id="$1"
    local task_description="$2"
    
    log_worker "$worker_id" "コード生成タスクを処理中"
    
    report_progress "$worker_id" "コード生成開始..."
    sleep 3
    report_progress "$worker_id" "コード生成中 (70%)"
    sleep 2
    report_progress "$worker_id" "コード生成完了 (100%)"
    
    echo "コード生成タスクが正常に完了しました"
}

# テスト処理
handle_testing() {
    local worker_id="$1"
    local task_description="$2"
    
    log_worker "$worker_id" "テストタスクを処理中"
    
    report_progress "$worker_id" "テスト準備中..."
    sleep 2
    report_progress "$worker_id" "テスト実行中 (30%)"
    sleep 3
    report_progress "$worker_id" "テスト完了 (100%)"
    
    echo "テストタスクが正常に完了しました"
}

# 分析処理
handle_analysis() {
    local worker_id="$1"
    local task_description="$2"
    
    log_worker "$worker_id" "分析タスクを処理中"
    
    report_progress "$worker_id" "データ収集中..."
    sleep 2
    report_progress "$worker_id" "分析実行中 (60%)"
    sleep 3
    report_progress "$worker_id" "分析完了 (100%)"
    
    echo "分析タスクが正常に完了しました"
}

# 汎用タスク処理
handle_generic_task() {
    local worker_id="$1"
    local task_description="$2"
    
    log_worker "$worker_id" "汎用タスクを処理中: $task_description"
    
    report_progress "$worker_id" "タスク処理開始..."
    sleep 2
    report_progress "$worker_id" "タスク処理中 (50%)"
    sleep 2
    report_progress "$worker_id" "タスク処理完了 (100%)"
    
    echo "タスクが正常に完了しました: $task_description"
}

# 進捗報告
report_progress() {
    local worker_id="$1"
    local progress_message="$2"
    
    log_worker "$worker_id" "進捗: $progress_message"
    
    # 上司に進捗を報告
    ./scripts/communication.sh report_to_boss "$worker_id" "進捗: $progress_message"
}

# 上司への報告
report_to_boss() {
    local worker_id="$1"
    local message="$2"
    
    # 通信スクリプト経由で報告
    ./scripts/communication.sh report_to_boss "$worker_id" "$message"
    
    log_worker "$worker_id" "上司に報告: $message"
}

# エラー報告
report_error() {
    local worker_id="$1"
    local error_message="$2"
    
    log_error "$worker_id" "$error_message"
    
    # 上司にエラーを報告
    ./scripts/communication.sh report_to_boss "$worker_id" "エラー: $error_message"
    
    # ステータスをエラーに更新
    echo "error" > "$CEO_COMM_DIR/${worker_id}_status"
}

# ヘルスチェック
health_check() {
    local worker_id="$1"
    
    # 定期的にヘルスチェックを実行
    while true; do
        local current_status=$(cat "$CEO_COMM_DIR/${worker_id}_status" 2>/dev/null || echo "unknown")
        
        # ステータスファイルの更新
        echo "$current_status:$(date)" > "$CEO_COMM_DIR/${worker_id}_heartbeat"
        
        # 30秒間隔でチェック
        sleep 30
    done
}

# 初期化
initialize_worker() {
    local worker_id="$1"
    
    log_worker "$worker_id" "部下初期化開始"
    
    # ステータスファイルを作成
    echo "ready" > "$CEO_COMM_DIR/${worker_id}_status"
    
    # タスクファイルを作成
    touch "$CEO_COMM_DIR/${worker_id}_task"
    
    # ログファイルを作成
    touch "$CEO_LOGS/worker_${worker_id}.log"
    
    log_worker "$worker_id" "部下初期化完了"
    
    # 上司に準備完了を報告
    report_to_boss "$worker_id" "初期化完了 - タスクの割り振りをお待ちしています"
}

# シャットダウン処理
shutdown_worker() {
    local worker_id="$1"
    
    log_worker "$worker_id" "シャットダウン開始"
    
    # 上司に終了を報告
    report_to_boss "$worker_id" "シャットダウン開始"
    
    # ステータスをシャットダウンに更新
    echo "shutdown" > "$CEO_COMM_DIR/${worker_id}_status"
    
    # 一時ファイルをクリーンアップ
    rm -f "$CEO_COMM_DIR/${worker_id}_task"
    rm -f "$CEO_COMM_DIR/${worker_id}_heartbeat"
    
    log_worker "$worker_id" "シャットダウン完了"
}

# メイン処理
main() {
    local command="$1"
    local worker_id="$2"
    shift 2
    
    case "$command" in
        "initialize")
            initialize_worker "$worker_id"
            ;;
        "monitor")
            monitor_task "$worker_id"
            ;;
        "execute")
            execute_task "$worker_id" "$@"
            ;;
        "report_progress")
            report_progress "$worker_id" "$@"
            ;;
        "report_error")
            report_error "$worker_id" "$@"
            ;;
        "health_check")
            health_check "$worker_id"
            ;;
        "shutdown")
            shutdown_worker "$worker_id"
            ;;
        *)
            echo "使用方法: $0 {initialize|monitor|execute|report_progress|report_error|health_check|shutdown} worker_id [args...]"
            exit 1
            ;;
    esac
}

# 実行
main "$@"