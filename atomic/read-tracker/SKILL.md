---
name: read-tracker
description: "Atomic skill. Read the Progress Tracker database from Notion. Trigger whenever current task status, weekly progress, priorities, or blocked items are needed. Returns all tracker entries grouped by week and status."
---
 
# Read Tracker
 
## Purpose
Retrieve the current state of the Progress Tracker DB to understand
what is Done, WIP, Todo, and Blocked.
Always read tracker before generating any progress report, PRD, or status email.
Never infer task status from memory or conversation history.
 
## Notion Tracker Location
 
Database ID: `01d855dcafb44fccb2ddc11cb695aaca`
Direct URL: https://www.notion.so/01d855dcafb44fccb2ddc11cb695aaca?v=33550aefb54b8183a9c0000cbb223781
 
## Execution Steps

### Step 0: Load Required Tools (CRITICAL)
Before any Notion operation, call `tool_search` with EXACTLY these queries in order:
1. `tool_search("notion fetch page")` — loads `notion-fetch`
2. `tool_search("notion search pages")` — loads `notion-search`

Do NOT skip Step 0. `notion-fetch` is a deferred tool and will not be available otherwise.

1. Fetch the tracker database using Notion MCP:
   ```
   tool: notion-fetch
   target: database ID 01d855dcafb44fccb2ddc11cb695aaca
   ```
 
2. If the database cannot be fetched by ID directly, fall back to search:
   ```
   tool: notion-search
   query: "Progress Tracker"
   filter: database
   ```
 
3. Retrieve ALL entries. For each entry extract:
   - Task name
   - Status (Done / WIP / Todo / Blocked)
   - Week number or date range
   - Priority (if present)
   - Linked PRD URL (if present)
   - Notes / comments (if present)
   - Assignee (if present)
 
4. Return grouped output:
 
```
[TRACKER: Week {N} | {date range}]
 
DONE:
- {task name} | Priority: {p} | PRD: {link or "none"}
 
WIP:
- {task name} | Priority: {p} | PRD: {link or "none"}
 
TODO:
- {task name} | Priority: {p}
 
BLOCKED:
- {task name} | Reason: {reason or "unspecified"}
 
---
[TRACKER: Week {N-1} | {date range}]
...
```
 
## Output Contract
- Return at minimum: current week + previous week
- Return ALL entries within those weeks — do not filter by priority
- Blocked items must include reason if available; if not, flag as "reason unspecified"
- Tasks with no linked PRD must be flagged as "no PRD linked"
- If database is empty or inaccessible, explicitly state:
  `"Tracker DB not found or empty — do not infer task status"`
 
## Notes
- Read-only skill; never modify any tracker entry
- If a task appears in both current and previous week with different statuses,
  return both entries — do not deduplicate