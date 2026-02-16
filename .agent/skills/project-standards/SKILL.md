---
name: project-standards
description: Enforces project-wide coding standards, file organization, and mandatory skill usage for every task.
---

# Project Standards & Global Rules

## Mandatory Skill Usage
**RULE:** For EVERY task involving code modification or generation, you MUST consult the relevant specialized skill:
1.  **Flutter & Firebase**: Use the `flutter-firebase` skill for UI, Auth, Firestore, Riverpod/Bloc.
2.  **Safe Coding**: Use the `safe-coder` skill for security checks (null safety, data leaks).
3.  **Skill Creation**: Use `skill-creator` when defining new capabilities.

## File Organization Structure
*   **Documentation**: All `.md` files (exc. README.md) go into `docs/`.
*   **Source Code**:
    *   `lib/` - Dart code only.
    *   `assets/` - Images, fonts.
*   **Backend**: `functions/` (JS/TS) or `backend_dart/`.

## Cleanup Rules
*   Delete temporary logs (`*.log`) immediately.
*   Keep `.gitignore` updated.

## Terminal & Execution Protocol
**RULE:** Be autonomous and proactive in the terminal.
1.  **Error Monitoring:** IMMEDIATELY analyze terminal output. If an error occurs (e.g., "Directory not found"), **FIX IT** (e.g., `mkdir`) instantly without asking.
2.  **Anti-Hang:** Do not wait indefinitely. Check command status frequently. If a command takes too long, investigate or suggest the user run it.
3.  **Auto-Creation:** If a file or folder is missing for an operation, create it automatically.
4.  **Self-Correction:** If you see an error in the previous step's output, your NEXT step MUST be to fix that error.

## Commit Checklist
*   [ ] Checked applicable skills?
*   [ ] Ran `flutter analyze`?
*   [ ] Formatted code?

