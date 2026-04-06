---
name: append-version-log
description: "Atomic skill. Append a new version entry to a PRD page's Version Log section in Notion. Called by composite skills (prd-edit, prd-draft, knowledge-correction) after they successfully write or update a PRD. NEVER overwrites existing Version Log entries — append only. The calling skill must provide page_id, version string, and change summary."
---

# Append Version Log

## Purpose
The only write path to a PRD's Version Log section.
Ensures version history is never lost — every PRD modification gets a
timestamped, attributed entry appended to the existing log.

Never called directly by the user — always invoked by a composite skill
(`prd-edit`, `prd-draft`, `knowledge-correction`) after a successful PRD write.

---

## Calling Interface

Composite skills call this skill by providing:

| Parameter | Required | Default | Notes |
|-----------|----------|---------|-------|
| `page_id` | **yes** | — | Notion page ID of the PRD to update |
| `version` | **yes** | — | Semantic version string, e.g. `v0.2`, `v1.0` |
| `changed_by` | no | calling skill name | Who triggered the change (e.g. `prd-edit`, `Bryan`) |
| `summary` | **yes** | — | One-line description of what changed |

**Return value to caller:**
```
[VERSION LOGGED]
Page:    {page_id}
Version: {version}
```

---

## Execution Steps

### Step 0: Load Required Tools (CRITICAL)
Before any Notion operation, call `tool_search` with these queries:
1. `tool_search("notion fetch page")` — loads `notion-fetch`
2. `tool_search("notion update page content")` — loads `notion-update-page`

Do NOT skip Step 0. These are deferred tools.

### Step 1: Fetch Current Page Content

```
tool: notion-fetch
id: {page_id}
```

Scan the returned content for the `## Version Log` section.

**If Version Log section exists** → extract the ENTIRE section content
(from `## Version Log` to the next `##` heading or end of page).
Proceed to Step 2.

**If Version Log section does NOT exist** → proceed to Step 3 (create it).

### Step 2: Append Entry to Existing Version Log

Use `notion-update-page` with `update_content` command.
Find the last row of the Version Log table and append after it:

```
tool: notion-update-page
page_id: {page_id}
command: update_content
content_updates:
  - old_str: "{last row of the version log table}"
    new_str: "{last row of the version log table}\n| {version} | {YYYY-MM-DD} | {changed_by} | {summary} |"
```

**CRITICAL**: The `old_str` must exactly match the existing content.
Always fetch the page first (Step 1) to get the exact string.

### Step 3: Create Version Log Section (if missing)

If no `## Version Log` section exists, append it at the END of the page.
Find the last section heading or last block of content:

```
tool: notion-update-page
page_id: {page_id}
command: update_content
content_updates:
  - old_str: "{last block of existing content}"
    new_str: "{last block of existing content}\n\n## Version Log\n\n| Version | Date | Changed By | Summary |\n|---------|------|------------|--------|\n| {version} | {YYYY-MM-DD} | {changed_by} | {summary} |"
```

### Step 4: Verify and Return

After the update succeeds, return:

```
[VERSION LOGGED]
Page:    {page_id}
Version: {version}
Entry:   | {version} | {YYYY-MM-DD} | {changed_by} | {summary} |
```

---

## Output Contract

- Always return confirmation with the exact entry that was appended
- On failure, return the Notion API error verbatim — do NOT retry silently
- NEVER overwrite or replace existing Version Log entries
- NEVER delete any rows from the Version Log table
- If the page cannot be fetched (404 or permission error), stop and report:
  `"Page {page_id} not found — cannot append version log"`

---

## Version String Convention

Callers should follow this convention:

| Scenario | Version Pattern | Example |
|----------|----------------|---------|
| Initial draft | `v0.1` | First creation by `prd-draft` |
| Minor edit (wording, clarification) | `v0.x+1` | `v0.2`, `v0.3` |
| Major revision (structural change) | `v{N+1}.0` | `v1.0`, `v2.0` |
| Post-experiment correction | `v{current}.{x+1}` | `v1.1` after experiment findings |

This skill does NOT enforce versioning — it is the caller's responsibility
to determine the correct version string.

---

## Notes

- Append-only skill — never modifies or deletes existing Version Log content
- Date is always today's date in `YYYY-MM-DD` format
- If `changed_by` is not provided, use the name of the calling composite skill
- This skill writes to PRD pages ONLY — do not use for wiki or experiment log pages