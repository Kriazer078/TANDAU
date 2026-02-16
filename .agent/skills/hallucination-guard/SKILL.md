---
description: Anti-Hallucination and Project Integrity Guard
---

## Overview
This skill is designed to prevent AI hallucinations, maintain project integrity, and protect against accidental deletion or modification of working features. It acts as a safety layer, enforcing strict checks before code modifications and ensuring that the AI's actions align with the existing project structure and reality.

## Core Rules

1.  **Reality Check (No Hallucinations):**
    *   **Verify Existence:** Before modifying ANY file, class, method, or variable, you MUST verify its existence using `view_file` or `grep_search`. Do not assume something exists just because it "should".
    *   **No Ghost Imports:** Never import a package or file that you haven't confirmed exists in `pubspec.yaml` or the file system.
    *   **Contextual Awareness:** If you are unsure about the current state of the project, use `list_dir` or `view_file` to re-orient yourself. Do not guess.

2.  **Integrity Protection (Do No Harm):**
    *   **Incremental Changes:** When adding new features, use `update` or `extend` patterns rather than `rewrite` or `replace` whenever possible.
    *   **Preserve Working Code:** If a feature is working (e.g., "Profile Editor"), DO NOT duplicate it or create a competing version. Improve the existing one.
    *   **Safe Refactoring:** If you must refactor, ensure you understand the dependencies. Use `flutter analyze` after every significant change to catch regressions immediately.

3.  **Self-Correction Protocol:**
    *   **Lint Check:** If a tool execution results in lint errors (e.g., `Undefined name`), STOP. Do not proceed to the next step. Fix the error immediately using the context you have.
    *   **Rollback:** If a change causes widespread errors that you cannot easily fix, consider reverting the file to its previous state rather than piling on more broken fixes.

4.  **User-Defined Constaints:**
    *   **Strict Adherence:** Follow user rules explicitly. If the user says "Don't delete X", then X must remain untouchable.
    *   **Clarification:** If a user request contradicts the project's reality (e.g., "Edit the settings screen" when no settings screen exists), inform the user about the reality and ask for guidance, rather than hallucinating a settings screen.

## Workflow for Critical Tasks

When performing complex tasks (e.g., integrating a new service, major refactoring), follow this checklist:

1.  **Scout:** `list_dir` and `view_file` relevant areas.
2.  **Verify:** Check `pubspec.yaml` for dependencies.
3.  **Plan:** strict mental or written plan of what to touch.
4.  **Execute:** `replace_file_content` with surgical precision.
5.  **Validate:** `flutter analyze` immediately.

## Emergency Command
If the user says "Stop hallucinating" or similar, IMMEDIATELY:
1.  Stop all current code generation.
2.  Run `flutter analyze` to see the real state of the project.
3.  Report the actual file status to the user.
