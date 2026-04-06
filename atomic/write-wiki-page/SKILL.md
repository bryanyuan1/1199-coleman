---
name: write-wiki-page
description: "Atomic skill. Write or update a single page in Notion. Supports three target folders: 'Knowledge Base' (wiki/paper notes), 'Product team PRDs' (design docs), 'Dev team internal logs' (experiment logs). Only called by composite skills after explicit human confirmation. NEVER write to Notion without approval."
---

# Write Wiki Page

## Purpose
The single write path into Notion for all three content folders:
- **Knowledge Base** — paper distillations, architectural notes, design principles
- **Product team PRDs** — PRD documents and design specs
- **Dev team internal logs** — experiment logs, results, spec cards

Always requires human confirmation before writing. Never called directly by the user — always invoked by a composite skill that has already prepared the content.

---

## Target Folder Reference

| Content Type | Notion Folder Name | When to Use |
|---|---|---|
| Paper notes, wiki entries, architecture knowledge | `Knowledge Base` | Called by `paper-distill`, `knowledge-correction`, `wiki-lint` |
| Design documents, PRDs | `Product team PRDs` | Called by `prd-draft`, `prd-edit` |
| Experiment records, logs | `Dev team internal logs` | Called by `experiment-design` (log phase) |

---

## Execution Steps

### Step 1: Locate Target Folder
Use Notion MCP `notion-search` to find the target folder by name:

```
tool: notion-search
query: "{folder name}"   # e.g. "Knowledge Base"
filter: page
```

From results, identify the page whose title exactly matches the folder name.
Extract its `page_id` — this is the parent for all writes in this folder.

### Step 2: Check for Existing Page
Search within the folder for a page matching the target title:

```
tool: notion-search
query: "{target page title}"
filter: page
```

- If found AND parent matches folder → **update** existing page
- If not found → **create** new page under folder

### Step 3: Pre-Write Confirmation (HARD STOP)

Display the following to the user before any write:

```
[WRITE PREVIEW]
Action:        {CREATE / UPDATE}
Target folder: {folder name}
Page title:    {title}
Sections:      {list of sections to be written}

--- CONTENT PREVIEW ---
{full content to be written}
-----------------------

Type "confirm" to proceed, or give feedback to revise.
```

**Do not proceed until the user explicitly confirms.**

### Step 4: Execute Write

**If CREATE** — use `notion-create-pages`:
```
tool: notion-create-pages
parent_id: {folder page_id from Step 1}
title: {page title}
content: {approved content in markdown}
```

**If UPDATE** — use `notion-update-page`:
```
tool: notion-update-page
page_id: {existing page_id from Step 2}
content: {approved content in markdown}
```

For PRD updates: always preserve the existing Version Log section.
Append new version entry via `append-version-log` skill AFTER the write succeeds.

### Step 5: Confirm and Return

After successful write, return:

```
[WRITE COMPLETE]
Action:   {created / updated}
Folder:   {folder name}
Title:    {page title}
URL:      {notion page url}
Version:  {version if PRD, else n/a}
```

---

## Output Contract

- Always return the Notion page URL on success
- On failure, return the error message verbatim — do NOT retry silently
- For UPDATE operations: confirm that the Version Log was NOT overwritten
- If folder not found in Step 1, stop and report: `"Folder '{name}' not found in Notion — aborting write"`

---

## Critical Rules

1. **Never write without human confirmation** — Step 3 is mandatory, no exceptions
2. **Never overwrite Version Log** — append only, via `append-version-log`
3. **Never infer the target folder** — the calling composite skill must specify which folder explicitly
4. **If content contradicts existing wiki** — flag the contradiction in the Step 3 preview before writing
5. **One page per invocation** — for bulk writes, call this skill multiple times