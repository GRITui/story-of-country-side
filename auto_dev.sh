#!/usr/bin/env bash
# Model-Agnostic Local Autonomous Script
# Define active models via environment variables
ARCHITECT_MODEL=${AI_ARCHITECT_MODEL:-"claude-3-7-sonnet-20250219"}
BUILDER_MODEL=${AI_BUILDER_MODEL:-"opencode/qwen-2.5-coder"}

while [ -s backlog.json ]; do
    echo "=== Starting Task with Architect ($ARCHITECT_MODEL) & Builder ($BUILDER_MODEL) ==="

    # 1. Architect drafts feature spec
    claude-code --model "$ARCHITECT_MODEL" --non-interactive \
      "Read top item in backlog.json. Write Godot 4 implementation spec and unit test stub in /tests."

    # 2. OpenCode builds the feature code
    opencode run --model "$BUILDER_MODEL" --yolo \
      "Implement GDScript files per latest spec in /tests. Keep changes inside /scripts."

    # 3. Godot Headless Test Execution
    godot --headless -s addons/gut/gut_cmdln.gd > test_results.log 2>&1
    TEST_EXIT_CODE=$?

    # 4. Self-Healing Loop if tests fail
    RETRIES=0
    while [ $TEST_EXIT_CODE -ne 0 ] && [ $RETRIES -lt 3 ]; do
        echo "Tests failed. Triggering auto-fix (Attempt $((RETRIES+1)))..."
        opencode run --model "$BUILDER_MODEL" --yolo \
          "Fix GDScript errors shown in test_results.log: $(cat test_results.log)"
        godot --headless -s addons/gut/gut_cmdln.gd > test_results.log 2>&1
        TEST_EXIT_CODE=$?
        ((RETRIES++))
    done

    # 5. Commit or Log
    if [ $TEST_EXIT_CODE -eq 0 ]; then
        git add .
        git commit -m "auto(build): completed backlog task"
        jq 'del(.[0])' backlog.json > backlog.tmp && mv backlog.tmp backlog.json
    else
        echo "Task failed after 3 retries. Manual review required."
        break
    fi
done