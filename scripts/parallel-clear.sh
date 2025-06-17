#!/bin/bash

# Parallel Clear Script
# 全てのClaude Codeペインで同時に/clearコマンドを実行

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$PROJECT_ROOT"
PANE_ID_FILE="$PROJECT_ROOT/YouAreTheCEO/.pane_ids"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# ペインIDファイルの確認
echo -e "${BLUE}Using YouAreTheCEO mode${NC}"

# ペインIDファイルの存在確認
if [ ! -f "$PANE_ID_FILE" ]; then
    echo -e "${RED}Error: Pane ID file not found: $PANE_ID_FILE${NC}"
    echo -e "${YELLOW}Please run the setup script first.${NC}"
    exit 1
fi

# ペインIDを読み込む
echo -e "${GREEN}Reading pane IDs...${NC}"
declare -A PANES

while IFS='=' read -r role pane_id; do
    # monitorペインは除外
    if [[ "$role" != "monitor" && -n "$pane_id" ]]; then
        PANES[$role]=$pane_id
        echo -e "  ${GREEN}$role: $pane_id${NC}"
    fi
done < "$PANE_ID_FILE"

# 全ペインで並列に/clearを実行
echo -e "${YELLOW}Executing /clear on all panes...${NC}"

for role in "${!PANES[@]}"; do
    pane_id="${PANES[$role]}"
    echo -e "${GREEN}Clearing $role (${pane_id})...${NC}"
    tmux send-keys -t "$pane_id" "/clear" && sleep 0.1 && tmux send-keys -t "$pane_id" Enter &
done

# 全てのバックグラウンドジョブが完了するまで待つ
wait

echo -e "${GREEN}All panes cleared successfully!${NC}"

# トークン使用量の確認を促す
echo ""
echo -e "${YELLOW}Tip: Use 'ccusage' in each pane to check token usage.${NC}"