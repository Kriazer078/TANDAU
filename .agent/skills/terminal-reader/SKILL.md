---
name: terminal-reader
description: |
  Teaches the agent how to READ existing terminal output that the USER has already run.
  Use this skill whenever the user says "смотри в терминал", "посмотри терминал", 
  "я уже запустил", or the run_command tool is cancelled/rejected by the user.
---

# Terminal Reader Skill

## When to Use This Skill

Use this skill when:
- The user cancels your `run_command` proposals
- The user says "смотри в терминал" / "look at the terminal" / "я сам запущу"
- You need to see the output of a command the USER has already run themselves
- You want to check build errors, `flutter analyze` output, or logs WITHOUT running a command yourself

## Core Tool: `read_terminal`

Use the `read_terminal` tool to read the current content of any open terminal.

### Required Parameters
- `ProcessID` — the ID of the terminal process (see how to find it below)
- `Name` — a human-readable label for the terminal (e.g. "Flutter Terminal")

### How to Find the ProcessID

The terminal ProcessID is NOT shown to you automatically. You must ask the user:

> "Открой терминал и скажи мне его Process ID (или я могу попробовать прочитать терминал по умолчанию)"

OR — try common terminal IDs used in VS Code integrated terminals. VS Code typically assigns sequential IDs starting from `1`.

### Example Usage

```
// Step 1 — Ask user to confirm their terminal is open with output
// Step 2 — Call read_terminal:
read_terminal(
  ProcessID: "1",   // or whatever the user provides
  Name: "Flutter Dev Terminal"
)
```

## Workflow: Read Instead of Run

### ❌ BAD (proposes commands user cancels):
```
run_command("flutter analyze") → USER CANCELS → run_command again → USER CANCELS
```

### ✅ GOOD (reads what user already has):
```
1. Tell user: "Запусти `flutter analyze` в своём терминале, я подожду"
2. Call: read_terminal(ProcessID: "1", Name: "Analysis Output")
3. Parse the output and fix errors
```

## Parsing Terminal Output

When you get terminal output, look for:

### Flutter Analyze
```
Analyzing...
  error • Message here • file.dart:LINE:COL • error_code
  warning • Message here • file.dart:LINE:COL • warning_code
  info • Message here • file.dart:LINE:COL • info_code
```
→ Fix each `error` immediately, then `warning`, then `info`

### Flutter Build Errors
```
FAILED: reason
lib/path/to/file.dart:LINE:COL: Error: message
```
→ Navigate to the file and line, fix the issue

### Flutter Run (Hot Reload)
```
Reloading...                                       371ms
```
→ App is running fine

```
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══
The following assertion was thrown building MyWidget
```
→ Widget tree error — find the widget mentioned and fix

## Tips for This Project (TANDAU)

1. **flutter analyze** — run this to check all Dart errors before asking me to fix
2. **flutter run -d <device>** — check the terminal for runtime errors
3. **Common errors in this project:**
   - `Undefined name 'X'` → missing import or orphaned code
   - `Target of URI doesn't exist` → wrong import path
   - `Unused import` → remove the import line
   - `A value of type 'X' can't be assigned to 'Y'` → type mismatch, add cast or fix type

## Important Rules

1. **NEVER propose `run_command` if the user has cancelled it twice in a row** — switch to `read_terminal` instead
2. **Always tell the user WHAT to run** before calling `read_terminal` — they need to execute it first
3. **Be patient** — wait for user to run the command before reading
4. **Parse ALL errors** from terminal output in one pass — don't ask user to run multiple times
