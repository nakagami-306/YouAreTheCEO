#!/bin/bash

# タスク割り当てスクリプト
# Usage: ./assign-task.sh <worker_id> <task_description>

WORKER_ID=$1
TASK_DESC=$2
TASK_DIR="/home/seito_nakagane/project/GaijinHub/multi-agent/claude-tasks"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TASK_FILE="$TASK_DIR/worker${WORKER_ID}_task_${TIMESTAMP}.txt"

if [ -z "$WORKER_ID" ] || [ -z "$TASK_DESC" ]; then
    echo "Usage: $0 <worker_id> <task_description>"
    exit 1
fi

# タスクファイルを作成
cat > "$TASK_FILE" << EOF
TASK FOR WORKER $WORKER_ID
========================
Assigned at: $(date)
Status: PENDING

Task Description:
$TASK_DESC

Instructions:
1. Read this task carefully
2. Update status to IN_PROGRESS when starting
3. Create implementation in appropriate directory
4. Update status to COMPLETED when done
5. Add any notes or issues below

Status Updates:
--------------

Notes:
------

EOF

echo "Task assigned to Worker $WORKER_ID: $TASK_FILE"

# tmuxペインに通知を送る（フラット構造）
if tmux has-session -t claude-agents 2>/dev/null; then
    # WorkerペインIDを取得して直接通知
    PANE_ID_FILE="/home/seito_nakagane/project/GaijinHub/multi-agent/.pane_ids"
    if [ -f "$PANE_ID_FILE" ]; then
        WORKER_PANE=$(grep "^worker${WORKER_ID}=" "$PANE_ID_FILE" | cut -d= -f2)
        if [ -n "$WORKER_PANE" ]; then
            tmux send-keys -t "$WORKER_PANE" "" C-m
            tmux send-keys -t "$WORKER_PANE" "# NEW TASK ASSIGNED: Check $TASK_FILE" C-m
        fi
    fi
fi