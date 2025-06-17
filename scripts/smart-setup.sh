#!/bin/bash

# Claude Code Smart Setup Script
# コーディネーター中心のセットアップ（コーディネーターがワーカー数を決定）

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SESSION_NAME="claude-agents"
PROJECT_DIR="$PROJECT_ROOT"
TASK_DIR="$PROJECT_ROOT/YouAreTheCEO/claude-tasks"
COMM_DIR="$PROJECT_ROOT/YouAreTheCEO/claude-comm"
PANE_ID_FILE="$PROJECT_ROOT/YouAreTheCEO/.pane_ids"
USE_DANGEROUS_FLAG=false

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# コマンドライン引数の処理
while [[ $# -gt 0 ]]; do
    case $1 in
        --dangerously-skip-permissions)
            USE_DANGEROUS_FLAG=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --dangerously-skip-permissions  Use dangerous flag for Claude Code"
            echo "  --help                          Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# シンプルなセットアップ
echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}    Claude Code Multi-Agent Setup             ${NC}"
echo -e "${CYAN}===============================================${NC}"
echo ""
echo -e "${YELLOW}コーディネーターのみを起動し、ワーカー数はコーディネーターが決定します。${NC}"
echo ""

# 必要なディレクトリの作成
echo -e "${BLUE}Setting up communication directories...${NC}"
mkdir -p "$TASK_DIR" "$COMM_DIR"

# tmuxセッションが既に存在する場合は削除
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo -e "${YELLOW}Existing session found. Killing it...${NC}"
    tmux kill-session -t $SESSION_NAME
fi

# 新しいtmuxセッションを作成（コーディネーターのみ）
echo -e "${GREEN}Creating coordinator session...${NC}"
tmux new-session -d -s $SESSION_NAME -n "coordinator" -c $PROJECT_ROOT/YouAreTheCEO

# ペインIDを記録する関数
function save_pane_id() {
    local role="$1"
    local pane_id="$2"
    echo "${role}=${pane_id}" >> "$PANE_ID_FILE"
}

# ペインIDファイルを初期化
> "$PANE_ID_FILE"

# コーディネーターペインのIDを取得
COORDINATOR_PANE=$(tmux list-panes -t $SESSION_NAME:coordinator -F '#{pane_id}' | head -1)
save_pane_id "coordinator" "$COORDINATOR_PANE"
save_pane_id "worker_count" "0"

# Coordinator設定
echo -e "${CYAN}Setting up Coordinator...${NC}"
tmux send-keys -t $COORDINATOR_PANE "# Coordinator Claude Code Instance" C-m
tmux send-keys -t $COORDINATOR_PANE "echo 'This is the COORDINATOR instance (Pane: $COORDINATOR_PANE)'" C-m
tmux send-keys -t $COORDINATOR_PANE "echo '役割: タスク分析、ワーカー数決定、チーム管理'" C-m
tmux send-keys -t $COORDINATOR_PANE "echo 'ワーカー追加: ./scripts/add-workers.sh [数]'" C-m
tmux send-keys -t $COORDINATOR_PANE "export CLAUDE_ROLE=coordinator" C-m
tmux send-keys -t $COORDINATOR_PANE "export COORDINATOR_PANE=$COORDINATOR_PANE" C-m
tmux send-keys -t $COORDINATOR_PANE "export TASK_DIR=$TASK_DIR" C-m
tmux send-keys -t $COORDINATOR_PANE "export COMM_DIR=$COMM_DIR" C-m
tmux send-keys -t $COORDINATOR_PANE "export WORKER_COUNT=0" C-m
tmux send-keys -t $COORDINATOR_PANE "export SESSION_NAME=$SESSION_NAME" C-m

# 簡易モニタリングウィンドウを作成
echo -e "${GREEN}Setting up monitoring window...${NC}"
tmux new-window -t $SESSION_NAME -n "monitor" -c $PROJECT_ROOT/YouAreTheCEO
MONITOR_PANE=$(tmux list-panes -t $SESSION_NAME:monitor -F '#{pane_id}' | head -1)
save_pane_id "monitor" "$MONITOR_PANE"

# モニタリングウィンドウに構造を表示
tmux send-keys -t $MONITOR_PANE "watch -n 2 'echo \"=== Multi-Agent Status ===\"; echo \"Session: $SESSION_NAME\"; echo; cat $PANE_ID_FILE 2>/dev/null || echo \"No pane info yet\"; echo; echo \"=== Task Directory ===\"; ls -la $TASK_DIR/ 2>/dev/null || echo \"No tasks yet\"; echo; echo \"=== Recent Communications ===\"; tail -n 10 $COMM_DIR/communications.log 2>/dev/null || echo \"No communications yet\"'" C-m

# Coordinatorウィンドウに戻る
tmux select-window -t $SESSION_NAME:coordinator
tmux select-pane -t $COORDINATOR_PANE

# コーディネーターにClaude 4 Opusを自動起動
echo -e "${GREEN}Starting Claude 4 Opus Coordinator...${NC}"
CLAUDE_CMD="claude --model opus"
if [ "$USE_DANGEROUS_FLAG" = true ]; then
    CLAUDE_CMD="$CLAUDE_CMD --dangerously-skip-permissions"
fi

# コーディネーターにClaude起動
tmux send-keys -t $COORDINATOR_PANE "$CLAUDE_CMD" && sleep 0.1 && tmux send-keys -t $COORDINATOR_PANE Enter

# Claude起動を待つ
echo -e "${YELLOW}Waiting for Claude Coordinator to initialize...${NC}"
sleep 3

# コーディネーター指示書を読み込ませる
echo -e "${GREEN}Loading coordinator instructions...${NC}"
tmux send-keys -t $COORDINATOR_PANE "Read the file claude-coordinator.md to understand your role and capabilities." && sleep 0.1 && tmux send-keys -t $COORDINATOR_PANE Enter

sleep 2

# 初期化完了メッセージ
tmux send-keys -t $COORDINATOR_PANE "I am now ready as your Coordinator. Please describe your project requirements and I will:" && sleep 0.1 && tmux send-keys -t $COORDINATOR_PANE Enter
tmux send-keys -t $COORDINATOR_PANE "1. Analyze the complexity and requirements" && sleep 0.1 && tmux send-keys -t $COORDINATOR_PANE Enter
tmux send-keys -t $COORDINATOR_PANE "2. Determine optimal team size and structure" && sleep 0.1 && tmux send-keys -t $COORDINATOR_PANE Enter
tmux send-keys -t $COORDINATOR_PANE "3. Break down tasks for parallel execution" && sleep 0.1 && tmux send-keys -t $COORDINATOR_PANE Enter
tmux send-keys -t $COORDINATOR_PANE "4. Automatically spawn and coordinate workers" && sleep 0.1 && tmux send-keys -t $COORDINATOR_PANE Enter
tmux send-keys -t $COORDINATOR_PANE "5. Monitor progress and ensure quality" && sleep 0.1 && tmux send-keys -t $COORDINATOR_PANE Enter

# 完了メッセージ
echo -e "${BLUE}===============================================${NC}"
echo -e "${GREEN}Coordinator Ready and Operational!${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""
echo -e "${CYAN}Status:${NC}"
echo -e "  ${GREEN}✓${NC} Claude 4 Opus Coordinator running (Pane: $COORDINATOR_PANE)"
echo -e "  ${GREEN}✓${NC} Coordinator instructions loaded"
echo -e "  ${GREEN}✓${NC} Ready to receive project requirements"
echo ""
echo -e "${YELLOW}What happens next:${NC}"
echo -e "1. ${CYAN}Describe your project${NC} to the Coordinator"
echo -e "2. ${CYAN}Coordinator will analyze${NC} and determine team size"
echo -e "3. ${CYAN}Workers will be spawned${NC} automatically with Claude 4 Sonnet"
echo -e "4. ${CYAN}Parallel execution${NC} will begin under Coordinator supervision"
echo ""

# 自動的にセッションにアタッチ
echo -e "${GREEN}Attaching to Coordinator session...${NC}"
sleep 1
tmux attach -t $SESSION_NAME