---
name: read-comments
description: "Atomic skill. Read all comments and discussions from a Notion page, including inline block-level comments and resolved threads. Called by composite skills (prd-edit, prd-critique) that need to incorporate feedback before modifying a PRD. The calling skill must provide page_id; this skill returns all discussion threads with their anchored content."
---

# Read Comments

## Purpose
Retrieve all comments and discussion threads from a Notion page.
This captures feedback from the user, advisor, or collaborators
that is embedded directly in the document as inline comments.

Never called directly by the user — always invoked by composite skills
(`prd-edit`, `prd-critique`) that need to read feedback before acting.

---

## Calling Interface

Composite skills call this skill by providing:

| Parameter | Required | Default | Notes |
|-----------|----------|---------|-------|
| `page_id` | **yes** | — | Notion page ID of the target page |

**Return value to caller:**
```
[COMMENTS: {page_id}]
{structured list of all discussions}
```

---

## Execution Steps

### Step 0: Load Required Tools (CRITICAL)
Before any Notion operation, call `tool_search` with these queries:
1. `tool_search("notion fetch page")` — loads `notion-fetch`
2. `tool_search("notion get comments")` — loads `notion-get-comments`

Do NOT skip Step 0. These are deferred tools.

### Step 1: Fetch Page with Discussion Markers

```
tool: notion-fetch
id: {page_id}
include_discussions: true
```

This returns page content with inline `discussion://` markers
showing WHERE each comment is anchored. Record the mapping:
- Which section/block each discussion is attached to
- The `discussion://` URL for each thread

### Step 2: Fetch All Comment Threads

```
tool: notion-get-comments
page_id: {page_id}
include_all_blocks: true
include_resolved: true
```

This returns all discussions with full comment content.
For each discussion thread, extract:
- **Anchor**: which section/block it's attached to (from Step 1 mapping)
- **Comments**: all messages in the thread, in chronological order
- **Author**: who wrote each comment
- **Status**: open or resolved
- **Date**: when each comment was posted

### Step 3: Return Structured Output

```
[COMMENTS: {page_id}]
Total: {N} discussions ({M} open, {K} resolved)

[DISCUSSION 1 — {open/resolved}]
Anchored to: {section heading or content snippet}
  [{date}] {author}: {comment text}
  [{date}] {author}: {reply text}
  ...

[DISCUSSION 2 — {open/resolved}]
Anchored to: {section heading or content snippet}
  [{date}] {author}: {comment text}
  ...

---
```

---

## Output Contract

- Return ALL discussions — both open and resolved
- Preserve chronological order within each thread
- Always include the anchor location so callers know which section the feedback targets
- If no comments exist, explicitly state:
  `"No comments found on page {page_id}"`
- If page cannot be fetched, stop and report:
  `"Page {page_id} not found — cannot read comments"`

---

## Notes

- Read-only skill — never create, modify, or resolve comments
- Resolved discussions are included because they may contain historical decisions that inform current edits
- The `discussion://` URLs from Step 1 correlate with discussion IDs from Step 2 — use this to map comments to their anchored content