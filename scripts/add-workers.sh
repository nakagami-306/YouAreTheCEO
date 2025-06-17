#!/bin/bash

# Add Workers Script
# コーディネーターが必要に応じてワーカーを動的に追加するスクリプト

# 設定
SESSION_NAME="claude-agents"
PROJECT_DIR="/home/seito_nakagane/project/GaijinHub"
PANE_ID_FILE="$PROJECT_DIR/multi-agent/.pane_ids"
TASK_DIR="$PROJECT_DIR/multi-agent/claude-tasks"
COMM_DIR="$PROJECT_DIR/multi-agent/claude-comm"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 使用方法表示
show_usage() {
    echo "Usage: $0 [number_of_workers]"
    echo ""
    echo "Examples:"
    echo "  $0 3        # 3つのワーカーを追加"
    echo "  $0          # インタラクティブモード"
    echo ""
    echo "Options:"
    echo "  --help      Show this help"
}

# コマンドライン引数の処理
if [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# tmuxセッションの存在確認
if ! tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo -e "${RED}Error: セッション '$SESSION_NAME' が見つかりません${NC}"
    echo -e "${YELLOW}先にスマートセットアップを実行してください: ./scripts/smart-setup.sh${NC}"
    exit 1
fi

# コーディネーターペインの存在確認
if [ ! -f "$PANE_ID_FILE" ]; then
    echo -e "${RED}Error: ペイン情報ファイルが見つかりません${NC}"
    exit 1
fi

COORDINATOR_PANE=$(grep "coordinator=" "$PANE_ID_FILE" | cut -d= -f2)
if [ -z "$COORDINATOR_PANE" ]; then
    echo -e "${RED}Error: コーディネーターペインが見つかりません${NC}"
    exit 1
fi

# 現在のワーカー数を取得
CURRENT_WORKER_COUNT=$(grep "worker[0-9]*=" "$PANE_ID_FILE" | wc -l)

echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}    ワーカー追加ツール                       ${NC}"
echo -e "${CYAN}===============================================${NC}"
echo ""
echo -e "${BLUE}現在の状況:${NC}"
echo -e "  コーディネーター: 1"
echo -e "  既存ワーカー: ${CURRENT_WORKER_COUNT}"
echo ""

# ワーカー数の決定
if [ -z "$1" ]; then
    # インタラクティブモード
    echo -e "${YELLOW}追加するワーカー数を決定してください。${NC}"
    echo ""
    echo -e "${BLUE}タスクの複雑さによる推奨:${NC}"
    echo "  1-2: 小規模タスク (単機能追加・修正)"
    echo "  3-4: 中規模タスク (複数機能開発)"
    echo "  5-6: 大規模タスク (アーキテクチャ変更)"
    echo "  7-10: 超大規模タスク (システム再設計)"
    echo ""
    
    while true; do
        read -p "追加するワーカー数を入力してください (1-10): " WORKERS_TO_ADD
        if [[ "$WORKERS_TO_ADD" =~ ^[1-9]$|^10$ ]]; then
            break
        else
            echo -e "${RED}無効な入力です。1-10の数字を入力してください。${NC}"
        fi
    done
else
    # コマンドライン引数モード
    WORKERS_TO_ADD="$1"
    if [[ ! "$WORKERS_TO_ADD" =~ ^[1-9]$|^10$ ]]; then
        echo -e "${RED}Error: 無効なワーカー数です。1-10の数字を指定してください。${NC}"
        exit 1
    fi
fi

NEW_TOTAL_WORKERS=$((CURRENT_WORKER_COUNT + WORKERS_TO_ADD))
TOTAL_AGENTS=$((1 + NEW_TOTAL_WORKERS))

echo ""
echo -e "${CYAN}追加予定:${NC}"
echo -e "  追加ワーカー: ${WORKERS_TO_ADD}"
echo -e "  総ワーカー数: ${NEW_TOTAL_WORKERS}"
echo -e "  総エージェント数: ${TOTAL_AGENTS}"
echo ""

# 確認
read -p "この構成でワーカーを追加しますか? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}ワーカー追加を中止しました。${NC}"
    exit 0
fi

# coordinatorウィンドウに移動
tmux select-window -t $SESSION_NAME:coordinator

echo -e "${GREEN}ワーカーを追加中...${NC}"

# 新しいワーカーペインを作成
for ((i=1; i<=WORKERS_TO_ADD; i++)); do
    WORKER_ID=$((CURRENT_WORKER_COUNT + i))
    
    echo -e "${GREEN}Worker $WORKER_ID を作成中...${NC}"
    
    # ペインを分割
    if [ $((i % 2)) -eq 1 ]; then
        tmux split-window -t $SESSION_NAME:coordinator -h -c $PROJECT_DIR
    else
        tmux split-window -t $SESSION_NAME:coordinator -v -c $PROJECT_DIR
    fi
    
    # 新しく作成されたペインのIDを取得
    NEW_PANE_ID=$(tmux list-panes -t $SESSION_NAME:coordinator -F '#{pane_id}' | tail -1)
    
    # ペイン情報を保存
    echo "worker${WORKER_ID}=${NEW_PANE_ID}" >> "$PANE_ID_FILE"
    
    # ワーカー設定
    tmux send-keys -t $NEW_PANE_ID "# Worker $WORKER_ID Claude Code Instance" C-m
    tmux send-keys -t $NEW_PANE_ID "echo 'This is WORKER $WORKER_ID instance (Pane: $NEW_PANE_ID)'" C-m
    tmux send-keys -t $NEW_PANE_ID "echo '役割: 独立したタスク実行、直接報告'" C-m
    tmux send-keys -t $NEW_PANE_ID "echo 'Coordinator: $COORDINATOR_PANE'" C-m
    tmux send-keys -t $NEW_PANE_ID "export CLAUDE_ROLE=worker" C-m
    tmux send-keys -t $NEW_PANE_ID "export WORKER_ID=$WORKER_ID" C-m
    tmux send-keys -t $NEW_PANE_ID "export WORKER_PANE=$NEW_PANE_ID" C-m
    tmux send-keys -t $NEW_PANE_ID "export COORDINATOR_PANE=$COORDINATOR_PANE" C-m
    tmux send-keys -t $NEW_PANE_ID "export TASK_DIR=$TASK_DIR" C-m
    tmux send-keys -t $NEW_PANE_ID "export COMM_DIR=$COMM_DIR" C-m
    tmux send-keys -t $NEW_PANE_ID "export SESSION_NAME=$SESSION_NAME" C-m
    
    # 報告方法を設定
    REPORT_COMMAND="echo '報告方法: tmux send-keys -t $COORDINATOR_PANE \"[Worker $WORKER_ID] 報告内容\" && sleep 0.1 && tmux send-keys -t $COORDINATOR_PANE Enter'"
    tmux send-keys -t $NEW_PANE_ID "$REPORT_COMMAND" C-m
    
    echo -e "${GREEN}Worker $WORKER_ID が追加されました (Pane: $NEW_PANE_ID)${NC}"
done

# レイアウトを整理
echo -e "${BLUE}レイアウトを整理中...${NC}"
tmux select-layout -t $SESSION_NAME:coordinator tiled

# ワーカー数を更新
sed -i "s/worker_count=.*/worker_count=$NEW_TOTAL_WORKERS/" "$PANE_ID_FILE"

# コーディネーターに通知
tmux send-keys -t $COORDINATOR_PANE "echo '=== チーム構成が更新されました ==='" C-m
tmux send-keys -t $COORDINATOR_PANE "echo '新規ワーカー: $WORKERS_TO_ADD 人'" C-m
tmux send-keys -t $COORDINATOR_PANE "echo '総ワーカー数: $NEW_TOTAL_WORKERS 人'" C-m
tmux send-keys -t $COORDINATOR_PANE "echo '利用可能なコマンド:'" C-m
tmux send-keys -t $COORDINATOR_PANE "echo '  ./multi-agent/scripts/assign-task.sh [WORKER_ID] [TASK]'" C-m
tmux send-keys -t $COORDINATOR_PANE "echo '  ./multi-agent/scripts/check-status.sh'" C-m
tmux send-keys -t $COORDINATOR_PANE "echo '  ./multi-agent/scripts/start-all-claude.sh'" C-m
tmux send-keys -t $COORDINATOR_PANE "export WORKER_COUNT=$NEW_TOTAL_WORKERS" C-m

# コーディネーターペインをアクティブにする
tmux select-pane -t $COORDINATOR_PANE

echo ""
echo -e "${BLUE}===============================================${NC}"
echo -e "${GREEN}ワーカー追加完了！${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""
echo -e "${CYAN}更新された構成:${NC}"
echo -e "  コーディネーター: 1"
echo -e "  ワーカー: ${NEW_TOTAL_WORKERS}"
echo -e "  総エージェント: $((1 + NEW_TOTAL_WORKERS))"
echo ""
echo -e "${YELLOW}次のステップ:${NC}"
echo -e "1. ${GREEN}Claude Code起動${NC}: ./multi-agent/scripts/start-all-claude.sh"
echo -e "2. ${GREEN}タスク配布${NC}: ./multi-agent/scripts/assign-task.sh [WORKER_ID] [TASK]"
echo -e "3. ${GREEN}進捗確認${NC}: ./multi-agent/scripts/check-status.sh"
echo ""
echo -e "${BLUE}現在のセッション: tmux attach -t $SESSION_NAME${NC}"