#!/bin/bash

# チーム全体のステータス確認スクリプト

PROJECT_DIR="/home/seito_nakagane/project/GaijinHub"
TASK_DIR="$PROJECT_DIR/multi-agent/claude-tasks"
COMM_DIR="$PROJECT_DIR/multi-agent/claude-comm"
PANE_ID_FILE="$PROJECT_DIR/multi-agent/.pane_ids"
SESSION_NAME="claude-agents"

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
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --help     Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

TITLE="Claude Multi-Agent Status Report"

echo -e "${BLUE}==================================${NC}"
echo -e "${GREEN}$TITLE${NC}"
echo -e "${YELLOW}Time: $(date)${NC}"
echo -e "${YELLOW}Mode: multi-agent${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

# ペイン状況確認（利用可能な場合）
if [ -f "$PANE_ID_FILE" ]; then
    echo -e "${GREEN}Live Pane Status:${NC}"
    echo "-----------------"
    
    while IFS='=' read -r role pane_id; do
        if [[ -n "$pane_id" && "$role" != "monitor" ]]; then
            # ロールに応じた色を選択
            case $role in
                coordinator)
                    COLOR="${CYAN}"
                    ;;
                worker*)
                    COLOR="${GREEN}"
                    ;;
                *)
                    COLOR="${YELLOW}"
                    ;;
            esac
            
            echo -e "${COLOR}$role (${pane_id}):${NC}"
            # 最後の3行を取得
            LAST_OUTPUT=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null | tail -3 | head -2)
            if [ -n "$LAST_OUTPUT" ]; then
                echo "$LAST_OUTPUT" | sed 's/^/  /'
            else
                echo "  (No recent activity)"
            fi
            echo ""
        fi
    done < "$PANE_ID_FILE"
fi

# 従来のタスクファイル確認
echo -e "${GREEN}Task Files Status:${NC}"
echo "------------------"
for i in {1..3}; do
    echo -e "${GREEN}Worker $i:${NC}"
    
    # 最新のタスクファイルを取得
    LATEST_TASK=$(ls -t "$TASK_DIR"/worker${i}_task_*.txt 2>/dev/null | head -1)
    
    if [ -n "$LATEST_TASK" ]; then
        # タスクのステータスを抽出
        STATUS=$(grep -A1 "^Status:" "$LATEST_TASK" | tail -1 | xargs)
        TASK_TIME=$(grep "^Assigned at:" "$LATEST_TASK" | cut -d: -f2- | xargs)
        
        echo "  Latest Task: $(basename "$LATEST_TASK")"
        echo "  Assigned: $TASK_TIME"
        echo "  Status: $STATUS"
        
        # タスクの概要を表示（最初の3行）
        echo "  Task: "
        grep -A3 "^Task Description:" "$LATEST_TASK" | tail -3 | sed 's/^/    /'
    else
        echo "  No tasks assigned"
    fi
    echo ""
done

# 通信ディレクトリの確認
echo -e "${GREEN}Communication Files:${NC}"
echo "-------------------"
if [ -d "$COMM_DIR" ]; then
    if ls "$COMM_DIR"/*.txt >/dev/null 2>&1; then
        ls -la "$COMM_DIR"/*.txt | tail -5
    else
        echo "  No communication files"
    fi
else
    echo "  Communication directory not found"
fi

# tmuxセッション状態確認
echo ""
echo -e "${GREEN}tmux Session Status:${NC}"
echo "--------------------"
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo -e "  ${GREEN}✓ Session '$SESSION_NAME' is active${NC}"
    WINDOW_COUNT=$(tmux list-windows -t "$SESSION_NAME" 2>/dev/null | wc -l)
    PANE_COUNT=$(tmux list-panes -t "$SESSION_NAME" -a 2>/dev/null | wc -l)
    echo "  Windows: $WINDOW_COUNT"
    echo "  Total Panes: $PANE_COUNT"
else
    echo -e "  ${RED}✗ Session '$SESSION_NAME' not found${NC}"
    echo -e "  ${YELLOW}Run the setup script to create the session${NC}"
fi

echo ""
echo -e "${BLUE}==================================${NC}"
echo -e "${YELLOW}Tip: Use 'tmux attach -t $SESSION_NAME' to join the session${NC}"