#!/bin/bash

# YouAreTheCEO Boss Handler Script
# 上司（Boss）用の自動化スクリプト

set -e

# 設定読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config/system-config.sh"

# 関数定義
log_boss() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BOSS] $1" | tee -a "$CEO_LOGS/boss.log"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" | tee -a "$CEO_LOGS/error.log"
}

# ワークフロー分析
analyze_workflow() {
    local user_task="$1"
    log_boss "ワークフロー分析開始: $user_task"
    
    # タスクの複雑度を分析（簡易版）
    local complexity=1
    local keywords=("複数" "並列" "同時" "分割" "複雑" "大規模" "多数")
    
    for keyword in "${keywords[@]}"; do
        if echo "$user_task" | grep -qi "$keyword"; then
            ((complexity++))
        fi
    done
    
    # 推奨部下数を計算
    local recommended_workers=$((complexity > CEO_MAX_WORKERS ? CEO_MAX_WORKERS : complexity))
    
    echo "$recommended_workers" > "$CEO_COMM_DIR/recommended_workers"
    
    log_boss "分析完了 - 推奨部下数: $recommended_workers"
    
    # Boss に結果を報告
    cat > "$CEO_COMM_DIR/workflow_analysis" << EOF
ワークフロー分析結果:
- タスク: $user_task
- 複雑度: $complexity
- 推奨部下数: $recommended_workers

次のアクションを推奨します:
1. spawn_workers コマンドで部下を起動
2. assign_task コマンドでタスクを分割・割り振り
EOF
    
    return 0
}

# 部下の起動
spawn_workers() {
    local worker_count="${1:-$(cat "$CEO_COMM_DIR/recommended_workers" 2>/dev/null || echo "$CEO_DEFAULT_WORKERS")}"
    
    log_boss "$worker_count 人の部下を起動中..."
    
    # 現在の部下数を取得
    local current_workers=$(cat "$CEO_COMM_DIR/worker_count" 2>/dev/null || echo "0")
    
    # 新しい部下を起動
    for ((i=current_workers+1; i<=current_workers+worker_count; i++)); do
        local worker_id="worker_$i"
        local pane_name="CEO-Worker-$i"
        
        log_boss "部下 $worker_id を起動中..."
        
        # 新しいpaneを作成
        tmux new-window -t "$CEO_SESSION" -n "$pane_name"
        
        # 部下用の初期化スクリプトを送信
        tmux send-keys -t "$CEO_SESSION:$pane_name" "cd '$SCRIPT_DIR'" Enter
        tmux send-keys -t "$CEO_SESSION:$pane_name" "$CC_WORKER" Enter
        
        # 部下に初期化メッセージを送信
        sleep 2
        cat > "$CEO_COMM_DIR/worker_${i}_init.txt" << EOF
あなたは部下ID: $worker_id です。

## あなたの役割
- 上司から割り振られたタスクを実行する
- 進捗を定期的に報告する
- 問題が発生した場合は即座に報告する
- タスク完了時に結果を報告する

## 作業ディレクトリ
- YouAreTheCEOシステム: $SCRIPT_DIR
- ユーザープロジェクトルート: $(dirname "$SCRIPT_DIR")
- 重要: すべてのファイル操作はユーザープロジェクトルート（../）で実行してください

## 重要な報告ルール
進捗・問題・完了報告は必ず以下のコマンドを使用:
\`\`\`bash
./scripts/communication.sh report_to_boss $worker_id "\$MESSAGE"
\`\`\`

## 報告例
- 進捗: ./scripts/communication.sh report_to_boss $worker_id "タスクAの50%完了"
- 問題: ./scripts/communication.sh report_to_boss $worker_id "エラー: ファイルが見つかりません"
- 完了: ./scripts/communication.sh report_to_boss $worker_id "タスク完了: 結果は..."

準備完了です。上司からのタスク割り振りをお待ちしています。
EOF
        
        tmux send-keys -t "$CEO_SESSION:$pane_name" "$(cat "$CEO_COMM_DIR/worker_${i}_init.txt")" Enter
        
        # 部下の状態を記録
        echo "ready" > "$CEO_COMM_DIR/worker_${i}_status"
        echo "$worker_id:ready:$(date)" >> "$CEO_COMM_DIR/worker_list"
        
        log_boss "部下 $worker_id 起動完了"
    done
    
    # 現在の部下数を更新
    echo "$((current_workers + worker_count))" > "$CEO_COMM_DIR/worker_count"
    
    log_boss "全部下起動完了 - 総数: $((current_workers + worker_count))"
    
    # Boss に完了報告
    echo "部下 $worker_count 人の起動が完了しました。assign_task コマンドでタスクを割り振ってください。" > "$CEO_COMM_DIR/spawn_result"
    
    return 0
}

# タスク割り振り
assign_task() {
    local worker_id="$1"
    local task_description="$2"
    
    if [[ -z "$worker_id" || -z "$task_description" ]]; then
        log_error "assign_task: worker_id と task_description が必要です"
        return 1
    fi
    
    log_boss "部下 $worker_id にタスクを割り振り: $task_description"
    
    # 部下の存在確認
    if [[ ! -f "$CEO_COMM_DIR/${worker_id}_status" ]]; then
        log_error "部下 $worker_id が見つかりません"
        return 1
    fi
    
    # 部下の状態確認
    local worker_status=$(cat "$CEO_COMM_DIR/${worker_id}_status")
    if [[ "$worker_status" != "ready" && "$worker_status" != "idle" ]]; then
        log_boss "警告: 部下 $worker_id は現在 $worker_status 状態です"
    fi
    
    # タスクを部下に送信
    local pane_name="CEO-Worker-${worker_id#worker_}"
    ./scripts/communication.sh send_to_worker "$worker_id" "$task_description"
    
    # 部下の状態を「作業中」に更新
    echo "working" > "$CEO_COMM_DIR/${worker_id}_status"
    echo "$worker_id:working:$(date):$task_description" >> "$CEO_COMM_DIR/task_assignments"
    
    log_boss "タスク割り振り完了: $worker_id"
    
    return 0
}

# 部下の管理
manage_workers() {
    local action="$1"
    
    case "$action" in
        "status")
            log_boss "部下の状態確認中..."
            echo "=== 部下状態レポート ===" > "$CEO_COMM_DIR/worker_status_report"
            
            local worker_count=$(cat "$CEO_COMM_DIR/worker_count" 2>/dev/null || echo "0")
            echo "総部下数: $worker_count" >> "$CEO_COMM_DIR/worker_status_report"
            echo "" >> "$CEO_COMM_DIR/worker_status_report"
            
            for ((i=1; i<=worker_count; i++)); do
                local worker_id="worker_$i"
                local status=$(cat "$CEO_COMM_DIR/${worker_id}_status" 2>/dev/null || echo "unknown")
                echo "$worker_id: $status" >> "$CEO_COMM_DIR/worker_status_report"
            done
            
            cat "$CEO_COMM_DIR/worker_status_report"
            ;;
            
        "clear")
            local worker_id="$2"
            if [[ -n "$worker_id" ]]; then
                log_boss "部下 $worker_id のコンテキストをクリア中..."
                local pane_name="CEO-Worker-${worker_id#worker_}"
                tmux send-keys -t "$CEO_SESSION:$pane_name" "/clear" Enter
                log_boss "部下 $worker_id のクリア完了"
            else
                log_boss "全部下のコンテキストをクリア中..."
                local worker_count=$(cat "$CEO_COMM_DIR/worker_count" 2>/dev/null || echo "0")
                for ((i=1; i<=worker_count; i++)); do
                    local pane_name="CEO-Worker-$i"
                    tmux send-keys -t "$CEO_SESSION:$pane_name" "/clear" Enter &
                done
                wait
                log_boss "全部下のクリア完了"
            fi
            ;;
            
        "shutdown")
            log_boss "全部下をシャットダウン中..."
            local worker_count=$(cat "$CEO_COMM_DIR/worker_count" 2>/dev/null || echo "0")
            for ((i=1; i<=worker_count; i++)); do
                local pane_name="CEO-Worker-$i"
                tmux kill-window -t "$CEO_SESSION:$pane_name" 2>/dev/null || true
            done
            echo "0" > "$CEO_COMM_DIR/worker_count"
            rm -f "$CEO_COMM_DIR"/worker_*_status
            rm -f "$CEO_COMM_DIR/worker_list"
            log_boss "全部下シャットダウン完了"
            ;;
            
        *)
            log_error "不正な管理アクション: $action"
            return 1
            ;;
    esac
    
    return 0
}

# 部下からの報告処理
handle_reports() {
    local worker_id="$1"
    local report_message="$2"
    
    log_boss "部下 $worker_id からの報告: $report_message"
    
    # 報告をログに記録
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$worker_id] $report_message" >> "$CEO_LOGS/worker_reports.log"
    
    # 報告を Boss に転送（tmux経由）
    echo "[$worker_id] $report_message" > "$CEO_COMM_DIR/latest_report"
    tmux send-keys -t "$CEO_SESSION:CEO-Boss" "echo '[$worker_id] $report_message'" Enter
    
    # 報告内容に応じた自動処理
    if echo "$report_message" | grep -qi "完了\|complete\|done"; then
        echo "idle" > "$CEO_COMM_DIR/${worker_id}_status"
        log_boss "部下 $worker_id のステータスを idle に更新"
    elif echo "$report_message" | grep -qi "エラー\|error\|問題\|失敗"; then
        echo "error" > "$CEO_COMM_DIR/${worker_id}_status"
        log_boss "部下 $worker_id でエラーが発生 - 要対応"
    fi
    
    return 0
}

# メイン処理
main() {
    local command="$1"
    shift
    
    case "$command" in
        "analyze_workflow")
            analyze_workflow "$@"
            ;;
        "spawn_workers")
            spawn_workers "$@"
            ;;
        "assign_task")
            assign_task "$@"
            ;;
        "manage_workers")
            manage_workers "$@"
            ;;
        "handle_reports")
            handle_reports "$@"
            ;;
        *)
            echo "使用方法: $0 {analyze_workflow|spawn_workers|assign_task|manage_workers|handle_reports} [args...]"
            exit 1
            ;;
    esac
}

# 実行
main "$@"