---
name: write-comments
description: "Atomic skill. Create inline comments on a Notion page, anchored to specific content blocks. Called by composite skills (prd-critique, prd-edit) that need to leave feedback directly on a page. Supports page-level comments, block-anchored comments, and replies to existing discussion threads. The calling skill must provide page_id and a list of comments with their anchor targets."
---

# Write Comments

## Purpose
Create inline comments on a Notion page, precisely anchored to the
content they reference. This enables critique, review feedback, and
discussion to be embedded directly in the document where it matters.

Never called directly by the user — always invoked by composite skills
(`prd-critique`, `prd-edit`) that have already prepared the comment content.

---

## Calling Interface

Composite skills call this skill by providing:

| Parameter | Required | Default | Notes |
|-----------|----------|---------|-------|
| `page_id` | **yes** | — | Notion page ID of the target page |
| `comments` | **yes** | — | List of comments to create (see format below) |

Each comment in the list must specify:

```
{
  "anchor": "{selection_with_ellipsis or 'page-level'}",
  "text": "{comment content}",
  "reply_to": "{discussion_id, if replying to existing thread, else null}"
}
```

**Return value to caller:**
```
[COMMENTS WRITTEN]
Page:     {page_id}
Created:  {N} comments
```

---

## Execution Steps

### Step 0: Load Required Tools (CRITICAL)
Before any Notion operation, call `tool_search` with these queries:
1. `tool_search("notion fetch page")` — loads `notion-fetch`
2. `tool_search("notion create comment")` — loads `notion-create-comment`

Do NOT skip Step 0. These are deferred tools.

### Step 1: Fetch Page Content for Anchor Validation

```
tool: notion-fetch
id: {page_id}
include_discussions: true
```

Use the returned content to:
- Validate that each comment's anchor text actually exists in the page
- Identify existing `discussion://` URLs for reply targeting
- If an anchor cannot be found, fall back to page-level comment and note the issue

### Step 2: Create Each Comment

For each comment in the list:

**Case A — Block-anchored comment (most common):**
```
tool: notion-create-comment
page_id: {page_id}
selection_with_ellipsis: "{first ~10 chars}...{last ~10 chars}"
rich_text: [{"text": {"content": "{comment text}"}}]
```

The `selection_with_ellipsis` must uniquely identify the target block.
Use ~10 characters from the start and end of the target content.

**Case B — Page-level comment:**
```
tool: notion-create-comment
page_id: {page_id}
rich_text: [{"text": {"content": "{comment text}"}}]
```

No `selection_with_ellipsis` — comment is attached to the page as a whole.

**Case C — Reply to existing discussion:**
```
tool: notion-create-comment
page_id: {page_id}
discussion_id: "{discussion://pageId/blockId/discussionId}"
rich_text: [{"text": {"content": "{reply text}"}}]
```

### Step 3: Handle Failures

If a comment fails to create (e.g. anchor text not found):
- Log the failure: `[COMMENT FAILED] anchor: "{anchor}" — reason: {error}`
- Do NOT retry automatically — report to caller
- Continue with remaining comments

### Step 4: Return Summary

```
[COMMENTS WRITTEN]
Page:     {page_id}
Created:  {N} of {M} comments succeeded
Failed:   {K} comments (see details below)

Anchored comments:
  - "{anchor snippet}" → {comment preview}
  - "{anchor snippet}" → {comment preview}

Page-level comments:
  - {comment preview}

Failed:
  - "{anchor}" — {reason}
```

---

## Output Contract

- Create all comments in the order provided by the caller
- Always validate anchors against actual page content before creating
- If an anchor cannot be found, fall back to page-level and flag the issue
- Never modify page content — only create comments
- Never resolve or delete existing comments
- Return the count of successfully created comments

---

## Notes

- `selection_with_ellipsis` must be unique within the page — if ambiguous, use more characters
- Comments are created as the Notion integration bot user
- Rich text supports basic formatting (bold, italic, code) via annotations — but plain text is usually sufficient for critique
- For bulk comments (>10), consider grouping related points into fewer, longer comments to avoid notification spam
- This skill pairs with `read-comments` — write creates, read retrieves