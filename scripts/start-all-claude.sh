#!/bin/bash

# Start All Claude Script
# 全ペインでClaude Codeを起動

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
USE_DANGEROUS_FLAG=false
PANE_ID_FILE="$PROJECT_DIR/YouAreTheCEO/.pane_ids"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# ペインIDファイルの確認
echo -e "${BLUE}Using YouAreTheCEO mode${NC}"

# ペインIDファイルの存在確認
if [ ! -f "$PANE_ID_FILE" ]; then
    echo -e "${RED}Error: Pane ID file not found: $PANE_ID_FILE${NC}"
    echo -e "${YELLOW}Please run the setup script first.${NC}"
    exit 1
fi

# Claude起動コマンドを決定
CLAUDE_BASE_CMD="claude"
if [ "$USE_DANGEROUS_FLAG" = true ]; then
    CLAUDE_BASE_CMD="$CLAUDE_BASE_CMD --dangerously-skip-permissions"
    echo -e "${RED}Warning: Using dangerous permissions flag!${NC}"
fi

# エイリアスの確認
echo -e "${YELLOW}Checking for 'cc' alias...${NC}"
if alias cc &>/dev/null; then
    echo -e "${GREEN}Found 'cc' alias. Using it for Claude.${NC}"
    CLAUDE_BASE_CMD="cc"
    if [ "$USE_DANGEROUS_FLAG" = true ]; then
        CLAUDE_BASE_CMD="$CLAUDE_BASE_CMD --dangerously-skip-permissions"
    fi
fi

# モデル別コマンド設定
COORDINATOR_CMD="$CLAUDE_BASE_CMD --model=claude-4-opus-20241218"
WORKER_CMD="$CLAUDE_BASE_CMD --model=claude-4-sonnet-20241126"

echo -e "${CYAN}Model Configuration:${NC}"
echo -e "  ${YELLOW}Coordinator: Claude 4 Opus (戦略・統合)${NC}"
echo -e "  ${BLUE}Workers: Claude 4 Sonnet (実装・実行)${NC}"

# ペインIDを読み込んで並列起動
echo -e "${GREEN}Starting Claude Code in all panes...${NC}"

# 起動するペインのリストを作成
declare -A PANES_TO_START

while IFS='=' read -r role pane_id; do
    # monitorペインは除外
    if [[ "$role" != "monitor" && -n "$pane_id" ]]; then
        PANES_TO_START[$role]=$pane_id
    fi
done < "$PANE_ID_FILE"

# 並列起動コマンドを構築
PARALLEL_CMD=""
for role in "${!PANES_TO_START[@]}"; do
    pane_id="${PANES_TO_START[$role]}"
    
    # ロールに応じてコマンドを選択
    if [[ "$role" == "coordinator" ]]; then
        SELECTED_CMD="$COORDINATOR_CMD"
        echo -e "  ${YELLOW}Starting Claude 4 Opus in $role (${pane_id})${NC}"
    else
        SELECTED_CMD="$WORKER_CMD"
        echo -e "  ${BLUE}Starting Claude 4 Sonnet in $role (${pane_id})${NC}"
    fi
    
    if [ -n "$PARALLEL_CMD" ]; then
        PARALLEL_CMD="$PARALLEL_CMD & "
    fi
    
    PARALLEL_CMD="${PARALLEL_CMD}tmux send-keys -t $pane_id \"$SELECTED_CMD\" && sleep 0.1 && tmux send-keys -t $pane_id Enter"
done

# 実行
echo -e "${YELLOW}Executing parallel start...${NC}"
eval "$PARALLEL_CMD & wait"

echo -e "${GREEN}All Claude instances started successfully!${NC}"

# Coordinatorペインに初期メッセージを送る
sleep 2  # Claude起動を待つ

# CoordinatorペインIDを取得
COORDINATOR_PANE=$(grep "^coordinator=" "$PANE_ID_FILE" | cut -d= -f2)

if [ -n "$COORDINATOR_PANE" ]; then
    echo -e "${BLUE}Sending initial instructions to Coordinator...${NC}"
    tmux send-keys -t "$COORDINATOR_PANE" "You are the Coordinator. Your workers are ready. Use tmux list-panes -F '#{pane_index}: #{pane_id}' to see all panes. Workers will report to you using: tmux send-keys -t $COORDINATOR_PANE '[Worker ID] message' && sleep 0.1 && tmux send-keys -t $COORDINATOR_PANE Enter" && sleep 0.1 && tmux send-keys -t "$COORDINATOR_PANE" Enter
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. ${GREEN}tmux attach${NC} to join the session"
echo -e "  2. ${GREEN}Assign tasks${NC} to workers"
echo -e "  3. ${GREEN}Monitor progress${NC} in the monitor window"