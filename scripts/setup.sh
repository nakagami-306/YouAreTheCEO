#!/bin/bash

# Claude Code Multi-Agent Setup Script
# CEOが決定する動的エージェント数による階層構造でClaude Codeインスタンスを管理

# 設定
SESSION_NAME="claude-agents"
PROJECT_DIR="/home/seito_nakagane/project/GaijinHub"
TASK_DIR="$PROJECT_DIR/multi-agent/claude-tasks"
COMM_DIR="$PROJECT_DIR/multi-agent/claude-comm"
PANE_ID_FILE="$PROJECT_DIR/multi-agent/.pane_ids"
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

# 必要なディレクトリの作成
echo -e "${BLUE}Setting up communication directories...${NC}"
mkdir -p "$TASK_DIR" "$COMM_DIR"

# tmuxセッションが既に存在する場合は削除
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo -e "${YELLOW}Existing session found. Killing it...${NC}"
    tmux kill-session -t $SESSION_NAME
fi

# 新しいtmuxセッションを作成
echo -e "${GREEN}Creating multi-agent structure with CEO and teams...${NC}"
tmux new-session -d -s $SESSION_NAME -n "headquarters" -c $PROJECT_DIR

# ペインIDを記録する関数
function save_pane_id() {
    local role="$1"
    local pane_id="$2"
    echo "${role}=${pane_id}" >> "$PANE_ID_FILE"
}

# ペインIDファイルを初期化
> "$PANE_ID_FILE"

# デフォルト構成: CEO + 2マネージャー + 3ワーカー = 6ペイン
echo -e "${GREEN}Creating default structure with 6 panes...${NC}"

# 6つのペインに分割
tmux split-window -t $SESSION_NAME:headquarters -h
tmux split-window -t $SESSION_NAME:headquarters -v
tmux split-window -t $SESSION_NAME:headquarters -v
tmux select-pane -t $SESSION_NAME:headquarters.0
tmux split-window -t $SESSION_NAME:headquarters -v
tmux select-pane -t $SESSION_NAME:headquarters.2
tmux split-window -t $SESSION_NAME:headquarters -v

# レイアウトを整理
tmux select-layout -t $SESSION_NAME:headquarters tiled

# ペインの構造とIDを確認
echo -e "${BLUE}Checking pane structure...${NC}"
PANE_INFO=$(tmux list-panes -t $SESSION_NAME:headquarters -F "#{pane_index}:#{pane_id}:#{pane_current_command}:#{pane_active}")

# 各ペインの役割を設定
CEO_PANE=""
MANAGER_PANES=()
WORKER_PANES=()

while IFS= read -r line; do
    PANE_INDEX=$(echo $line | cut -d: -f1)
    PANE_ID=$(echo $line | cut -d: -f2)
    
    case $PANE_INDEX in
        0)
            CEO_PANE=$PANE_ID
            save_pane_id "ceo" "$PANE_ID"
            echo -e "${CYAN}CEO Pane: $PANE_ID${NC}"
            ;;
        1|2)
            MANAGER_PANES+=($PANE_ID)
            save_pane_id "manager$PANE_INDEX" "$PANE_ID"
            echo -e "${MAGENTA}Manager $PANE_INDEX Pane: $PANE_ID${NC}"
            ;;
        *)
            if [ $PANE_INDEX -ge 3 ]; then
                WORKER_INDEX=$((PANE_INDEX - 2))
                WORKER_PANES+=($PANE_ID)
                save_pane_id "worker$WORKER_INDEX" "$PANE_ID"
                echo -e "${GREEN}Worker $WORKER_INDEX Pane: $PANE_ID${NC}"
            fi
            ;;
    esac
done <<< "$PANE_INFO"

# CEO設定
echo -e "${CYAN}Setting up CEO...${NC}"
tmux send-keys -t $CEO_PANE "# CEO Claude Code Instance" C-m
tmux send-keys -t $CEO_PANE "echo 'This is the CEO instance (Pane: $CEO_PANE)'" C-m
tmux send-keys -t $CEO_PANE "echo '役割: 全体戦略の決定、タスクの分解、進捗管理'" C-m
tmux send-keys -t $CEO_PANE "export CLAUDE_ROLE=ceo" C-m
tmux send-keys -t $CEO_PANE "export CEO_PANE=$CEO_PANE" C-m
tmux send-keys -t $CEO_PANE "export TASK_DIR=$TASK_DIR" C-m
tmux send-keys -t $CEO_PANE "export COMM_DIR=$COMM_DIR" C-m

# マネージャー設定
MANAGER_INDEX=1
for PANE_ID in "${MANAGER_PANES[@]}"; do
    echo -e "${MAGENTA}Setting up Manager $MANAGER_INDEX...${NC}"
    tmux send-keys -t $PANE_ID "# Manager $MANAGER_INDEX Claude Code Instance" C-m
    tmux send-keys -t $PANE_ID "echo 'This is MANAGER $MANAGER_INDEX instance (Pane: $PANE_ID)'" C-m
    tmux send-keys -t $PANE_ID "echo '役割: タスクの詳細化、ワーカーへの指示、品質管理'" C-m
    tmux send-keys -t $PANE_ID "export CLAUDE_ROLE=manager" C-m
    tmux send-keys -t $PANE_ID "export MANAGER_ID=$MANAGER_INDEX" C-m
    tmux send-keys -t $PANE_ID "export MANAGER_PANE=$PANE_ID" C-m
    tmux send-keys -t $PANE_ID "export CEO_PANE=$CEO_PANE" C-m
    tmux send-keys -t $PANE_ID "export TASK_DIR=$TASK_DIR" C-m
    tmux send-keys -t $PANE_ID "export COMM_DIR=$COMM_DIR" C-m
    MANAGER_INDEX=$((MANAGER_INDEX + 1))
done

# ワーカー設定
WORKER_INDEX=1
for PANE_ID in "${WORKER_PANES[@]}"; do
    echo -e "${GREEN}Setting up Worker $WORKER_INDEX...${NC}"
    tmux send-keys -t $PANE_ID "# Worker $WORKER_INDEX Claude Code Instance" C-m
    tmux send-keys -t $PANE_ID "echo 'This is WORKER $WORKER_INDEX instance (Pane: $PANE_ID)'" C-m
    tmux send-keys -t $PANE_ID "echo '役割: 実装作業、テスト実行、結果報告'" C-m
    tmux send-keys -t $PANE_ID "export CLAUDE_ROLE=worker" C-m
    tmux send-keys -t $PANE_ID "export WORKER_ID=$WORKER_INDEX" C-m
    tmux send-keys -t $PANE_ID "export WORKER_PANE=$PANE_ID" C-m
    tmux send-keys -t $PANE_ID "export CEO_PANE=$CEO_PANE" C-m
    tmux send-keys -t $PANE_ID "export TASK_DIR=$TASK_DIR" C-m
    tmux send-keys -t $PANE_ID "export COMM_DIR=$COMM_DIR" C-m
    WORKER_INDEX=$((WORKER_INDEX + 1))
done

# 報連相の方法を全ペインに伝える
echo -e "${YELLOW}Setting up reporting system...${NC}"
REPORT_COMMAND="echo '報告方法: tmux send-keys -t $CEO_PANE \"[自分の役割] 報告内容\" && sleep 0.1 && tmux send-keys -t $CEO_PANE Enter'"

for PANE_ID in "${MANAGER_PANES[@]}" "${WORKER_PANES[@]}"; do
    tmux send-keys -t $PANE_ID "$REPORT_COMMAND" C-m
done

# モニタリングウィンドウを作成
echo -e "${GREEN}Setting up monitoring window...${NC}"
tmux new-window -t $SESSION_NAME -n "monitor" -c $PROJECT_DIR
MONITOR_PANE=$(tmux list-panes -t $SESSION_NAME:monitor -F '#{pane_id}' | head -1)
save_pane_id "monitor" "$MONITOR_PANE"

# モニタリングウィンドウに会社構造を表示
tmux send-keys -t $MONITOR_PANE "watch -n 2 'echo \"=== Company Structure ===\"; cat $PANE_ID_FILE; echo; echo \"=== Task Directory ===\"; ls -la $TASK_DIR/; echo; echo \"=== Recent Communications ===\"; tail -n 10 $COMM_DIR/communications.log 2>/dev/null || echo \"No communications yet\"'" C-m

# CEOウィンドウに戻る
tmux select-window -t $SESSION_NAME:headquarters
tmux select-pane -t $CEO_PANE

# 完了メッセージ
echo -e "${BLUE}===================================${NC}"
echo -e "${GREEN}Multi-agent structure setup complete!${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""
echo -e "${CYAN}組織構造:${NC}"
echo -e "  ${CYAN}CEO${NC} - 全体戦略・タスク分解 (Pane: $CEO_PANE)"
echo -e "  ${MAGENTA}Manager 1-2${NC} - タスク詳細化・品質管理"
echo -e "  ${GREEN}Worker 1-3${NC} - 実装・テスト実行"
echo ""
echo -e "${YELLOW}Claude Code起動方法:${NC}"
if [ "$USE_DANGEROUS_FLAG" = true ]; then
    echo -e "  ${RED}危険モードが有効です！${NC}"
    CLAUDE_CMD="claude --dangerously-skip-permissions"
else
    CLAUDE_CMD="claude"
fi
echo -e "  全ペインで起動: ${GREEN}./multi-agent/scripts/start-all-claude.sh${NC}"
echo ""
echo -e "${YELLOW}報連相システム:${NC}"
echo -e "  CEOへの報告: ${GREEN}tmux send-keys -t $CEO_PANE '[役割] 内容' && sleep 0.1 && tmux send-keys -t $CEO_PANE Enter${NC}"
echo ""
echo -e "${YELLOW}便利なコマンド:${NC}"
echo -e "  ${GREEN}tmux attach -t $SESSION_NAME${NC} - セッションにアタッチ"
echo -e "  ${GREEN}Ctrl+b Space${NC} - レイアウト自動整理"
echo -e "  ${GREEN}./multi-agent/scripts/parallel-clear.sh${NC} - 全ペインで/clearを実行"
echo -e "  ${GREEN}./multi-agent/scripts/collect-results.sh${NC} - 結果を収集"
echo ""

# セッションにアタッチするか確認
read -p "Do you want to attach to the session now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    tmux attach -t $SESSION_NAME
fi