#!/bin/bash

# Collect Results Script
# 全ペインから最新の状況を収集して表示

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$PROJECT_ROOT"
PANE_ID_FILE="$PROJECT_ROOT/YouAreTheCEO/.pane_ids"
SESSION_NAME="claude-agents"
OUTPUT_FILE="$PROJECT_ROOT/YouAreTheCEO/results_$(date +%Y%m%d_%H%M%S).md"

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
        --lines)
            LINES="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --lines N       Number of lines to capture (default: 20)"
            echo "  --output FILE   Output file path"
            echo "  --help          Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# デフォルト値
LINES=${LINES:-20}

# ペインIDファイルの確認
echo -e "${BLUE}Using YouAreTheCEO mode${NC}"

# ペインIDファイルの存在確認
if [ ! -f "$PANE_ID_FILE" ]; then
    echo -e "${RED}Error: Pane ID file not found: $PANE_ID_FILE${NC}"
    echo -e "${YELLOW}Please run the setup script first.${NC}"
    exit 1
fi

# 結果収集開始
echo -e "${GREEN}Collecting results from all panes...${NC}"
echo -e "${YELLOW}Output file: $OUTPUT_FILE${NC}"

# ヘッダーを書き込む
{
    echo "# Claude Code Results Collection"
    echo "Date: $(date)"
    echo "Mode: YouAreTheCEO"
    echo "Session: $SESSION_NAME"
    echo ""
} > "$OUTPUT_FILE"

# ペインIDを読み込んで結果を収集
while IFS='=' read -r role pane_id; do
    if [[ -n "$pane_id" ]]; then
        echo -e "${GREEN}Collecting from $role (${pane_id})...${NC}"
        
        # ロールに応じた色を選択
        case $role in
            coordinator)
                COLOR_CODE="${CYAN}"
                ;;
            worker*)
                COLOR_CODE="${GREEN}"
                ;;
            monitor)
                COLOR_CODE="${BLUE}"
                ;;
            *)
                COLOR_CODE="${YELLOW}"
                ;;
        esac
        
        # 結果をファイルに追記
        {
            echo "## $role (Pane: $pane_id)"
            echo ""
            echo '```'
            tmux capture-pane -t "$pane_id" -p | tail -n "$LINES" 2>/dev/null || echo "Failed to capture pane"
            echo '```'
            echo ""
            echo "---"
            echo ""
        } >> "$OUTPUT_FILE"
        
        # コンソールにも要約を表示
        echo -e "${COLOR_CODE}=== $role ===${NC}"
        tmux capture-pane -t "$pane_id" -p | tail -n 5 2>/dev/null || echo "Failed to capture pane"
        echo ""
    fi
done < "$PANE_ID_FILE"

echo -e "${GREEN}Results collected successfully!${NC}"
echo -e "${YELLOW}View full results: ${NC}${OUTPUT_FILE}"

# 結果ファイルをエディタで開くか確認
read -p "Do you want to open the results file? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 利用可能なエディタを確認
    if command -v code &> /dev/null; then
        code "$OUTPUT_FILE"
    elif command -v vim &> /dev/null; then
        vim "$OUTPUT_FILE"
    elif command -v nano &> /dev/null; then
        nano "$OUTPUT_FILE"
    else
        echo -e "${YELLOW}No suitable editor found. Please open manually: $OUTPUT_FILE${NC}"
    fi
fi