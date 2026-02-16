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

## Commit Checklist
*   [ ] Checked applicable skills?
*   [ ] Ran `flutter analyze`?
*   [ ] Formatted code?
