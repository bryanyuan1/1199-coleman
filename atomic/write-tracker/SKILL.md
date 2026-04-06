---
name: write-tracker
description: "Atomic skill. Create or update entries in the Weekly Research Progress Tracker database in Notion. Called by composite skills (progress-digest, prd-draft, experiment-design) to log new tasks or update status. NEVER write without human confirmation."
---
 
# Write Tracker
 
## Purpose
Create new task entries or update existing ones in the
📅 Weekly Research Progress Tracker database.
This is the only write path to the tracker — always requires human confirmation.
 
## Database Reference
 
- **Database ID**: `01d855dcafb44fccb2ddc11cb695aaca`
- **Data Source ID**: `5c199a22-4e27-4889-8c35-882cb5cca0e9`
- **URL**: https://www.notion.so/01d855dcafb44fccb2ddc11cb695aaca
 
## Schema
 
| Field | Type | Valid Values |
|-------|------|-------------|
| `Task` | title | Free text — task name |
| `Status` | select | `Todo` / `In Progress` / `Done` |
| `Priority` | select | `High` / `Medium` / `Low` |
| `Week` | select | `Week 1` … `Week 12` |
| `Week Start Date` | date | ISO-8601 date e.g. `2026-04-07` |
| `Due Date` | date | ISO-8601 date e.g. `2026-04-11` |
| `Source` | multi_select | Any combination of: `Slides` / `Advisor Meeting` / `Self-Initiated` / `Paper Reading` |
| `Deliverable` | text | Free text — expected output artifact |
| `Notes` | text | Free text — additional context |
 
---
 
## Execution Steps
 
### Step 1: Pre-Write Confirmation (HARD STOP)
 
Display a preview table of all entries to be written:
 
```
[TRACKER WRITE PREVIEW]
Action: {CREATE / UPDATE}
 
| Task | Status | Priority | Week | Due Date | Source | Deliverable | Notes |
|------|--------|----------|------|----------|--------|-------------|-------|
| ...  | ...    | ...      | ...  | ...      | ...    | ...         | ...   |
 
Type "confirm" to write, or give feedback to revise.
```
 
Do not proceed until the user explicitly confirms.
 
### Step 2: Execute Write
 
**If CREATE** — use `notion-create-pages` with data source as parent:
 
```
tool: notion-create-pages
parent: { data_source_id: "5c199a22-4e27-4889-8c35-882cb5cca0e9" }
properties:
  Task:                        {task name}
  Status:                      {Todo | In Progress | Done}
  Priority:                    {High | Medium | Low}
  Week:                        {Week N}
  date:Week Start Date:start:  {YYYY-MM-DD}
  date:Week Start Date:is_datetime: 0
  date:Due Date:start:         {YYYY-MM-DD}
  date:Due Date:is_datetime:   0
  Source:                      {JSON array, e.g. ["Slides", "Self-Initiated"]}
  Deliverable:                 {deliverable text}
  Notes:                       {notes text}
```
 
**If UPDATE** — first fetch the existing entry page ID via `notion-search`,
then use `notion-update-page` with only the fields that changed.
 
### Step 3: Confirm and Return
 
```
[TRACKER WRITE COMPLETE]
Action:   {created / updated}
Task:     {task name}
Status:   {status}
Week:     {week}
URL:      {notion page url}
```
 
---
 
## Output Contract
 
- Always return the Notion page URL on success
- On failure, return the error verbatim — do NOT retry silently
- For bulk creates (multiple tasks), execute one `notion-create-pages` call
  with all entries in a single `pages` array — do not loop individually
- If a required field (`Task`, `Status`, `Week`) is missing, stop and ask
  before proceeding
 
---
 
## Special Operations

### Shelve / Backlog a Task

When the user says "搁置", "暂时搁置", "shelve", "put on hold", or similar
for a tracker task:

1. **Do NOT delete the task.**
2. Set `Priority` → `Low`
3. Prepend `⏸ 搁置 (Backlog):` to the existing `Notes` field
   (preserve existing notes after the prefix).
4. Leave `Status` unchanged (user may want it to stay WIP/Todo).

Example update:
```
tool: notion-update-page
page_id: {task page id}
command: update_properties
properties:
  Priority: "Low"
  Notes: "⏸ 搁置 (Backlog): {existing notes}"
```

### Un-shelve / Resume a Task

When the user says "恢复", "取消搁置", "resume", "un-shelve", or similar:

1. Remove the `⏸ 搁置 (Backlog):` prefix from `Notes`.
2. Set `Priority` back to the user-specified level (ask if unclear).
3. Update `Status` if the user specifies (e.g., back to `In Progress`).

---

## Critical Rules

1. **Never write without human confirmation** — Step 1 is mandatory
2. **Never infer Week from date** — always ask or derive from tracker context explicitly
3. **Source is multi_select** — pass as JSON array even for a single value: `["Self-Initiated"]`
4. **Status default** — if not specified by calling skill, default to `Todo`
5. **Never delete on shelve** — "搁置"/"shelve" means deprioritize, not remove