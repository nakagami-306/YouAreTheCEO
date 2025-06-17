# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

YouAreTheCEO is a multi-agent parallel development system using Claude Code. It operates with:
- **Boss Agent**: Claude Opus that analyzes workflows, determines worker requirements, and manages tasks
- **Worker Agents**: Claude Sonnet instances that execute assigned tasks in parallel
- **Communication System**: Real-time tmux-based inter-agent communication
- **Working Directory**: User's project root (parent directory of YouAreTheCEO)

## Essential Commands

### System Startup & Management
```bash
# Grant permissions (first time only)
chmod +x start-ceo.sh scripts/*.sh

# Start the system
./start-ceo.sh

# Attach to tmux session
tmux attach-session -t your-company

# Shutdown system
tmux kill-session -t your-company
```

### Boss Agent Operations (Auto-executed by Claude Opus)
```bash
# Spawn workers (Claude decides quantity)
./scripts/boss-handler.sh spawn_workers [number]

# Assign tasks to specific workers
./scripts/boss-handler.sh assign_task worker_1 "$TASK_DESCRIPTION"

# Manage workers
./scripts/boss-handler.sh manage_workers status
./scripts/boss-handler.sh manage_workers clear [worker_id]

# Save workflow info for reference
./scripts/boss-handler.sh save_workflow_info "$USER_TASK"
```

### Worker Agent Communication
```bash
# Report progress to boss
./scripts/communication.sh report_to_boss worker_1 "Message"

# Check communication status
./scripts/communication.sh check_communication

# View message history
./scripts/communication.sh show_message_history
```

## Architecture

### Core Components
- **start-ceo.sh**: Main system launcher, creates tmux session and initializes boss agent
- **config/system-config.sh**: Central configuration (session names, Claude models, paths)
- **scripts/boss-handler.sh**: Boss agent automation (worker spawning, task assignment)
- **scripts/communication.sh**: Inter-agent messaging system via tmux
- **scripts/worker-handler.sh**: Worker agent task execution framework
- **scripts/setup-tmux.sh**: tmux environment configuration and layouts

### Communication Flow
1. User instructions → Boss Agent (Claude Opus)
2. Boss Agent analyzes task → Determines worker count
3. Boss Agent spawns workers → Assigns tasks via communication.sh
4. Workers execute tasks → Report progress via communication.sh
5. Boss Agent monitors → Handles issues and coordination

### File System Structure
- **logs/**: All system logs (boss.log, communication.log, worker_*.log, error.log)
- **logs/comm/**: Inter-agent communication files and status tracking
- **User Project Root (../)**: Where all actual work files are created

## Configuration

Key settings in `config/system-config.sh`:
- `CEO_SESSION`: tmux session name ("your-company")
- `CC_BOSS`: Boss Claude command (opus with permissions)
- `CC_WORKER`: Worker Claude command (sonnet with permissions) 
- `CEO_MAX_WORKERS`: Maximum worker limit (8)
- `CEO_DEFAULT_WORKERS`: Default worker count (2)

## Important Behavior Notes

### For Boss Agents (Claude Opus)
- **NO pre-defined workflow analysis**: You decide worker count and task division based on your judgment
- **Work in user's project root**: Always use `../` as working directory for file operations
- **Autonomous decision making**: Consider task complexity, dependencies, urgency, and specialization needs
- **Use provided scripts**: Leverage automation scripts for worker management and communication

### For Worker Agents (Claude Sonnet)
- **Report frequently**: Use communication.sh to report progress, issues, and completion
- **Work in user's project root**: All file operations should target `../` directory
- **Follow task assignments**: Execute specific tasks assigned by boss agent
- **Error handling**: Immediately report errors with context to boss agent

## Troubleshooting

### Permission Issues
```bash
chmod +x start-ceo.sh scripts/*.sh
```

### Session Problems
```bash
tmux list-sessions
tmux kill-session -t your-company  # if needed
./start-ceo.sh  # restart
```

### Communication Failures
```bash
./scripts/communication.sh check_communication
./scripts/boss-handler.sh manage_workers status
```

This system is designed for deployment in any user's project directory, with all agents automatically operating in the user's project root while system files remain isolated in the YouAreTheCEO subdirectory.