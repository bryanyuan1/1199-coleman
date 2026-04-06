---
name: read-wiki
description: "Atomic skill. Read all pages from the Knowledge Base wiki in Notion. Trigger whenever background knowledge about papers, algorithms, or architectural decisions is needed. Returns structured summaries of all wiki pages."
---
 
# Read Wiki
 
## Purpose
Retrieve the full contents of the project knowledge wiki from Notion.
This is the ground truth for all paper knowledge, design decisions, and architectural context.
Never rely on training memory for paper details — always read wiki first.
 
## Notion Wiki Folder
Knowledge Base parent page ID: `33550aef-b54b-81bd-84f7-c919976444f5`
All wiki pages live under this parent. Always scope searches here.
 
## Execution Steps
 
### Step 0: Load required tools (CRITICAL)
Before any Notion operation, call `tool_search` with EXACTLY these queries in order:
1. `tool_search("notion fetch")` — loads `notion-fetch` for full page content
2. `tool_search("notion search pages")` — loads `notion-search`
 
Do NOT skip Step 0. `notion-fetch` is a deferred tool and will not be available otherwise.
 
### Step 1: Search within Knowledge Base
Use `notion-search` scoped to the Knowledge Base page:
- `page_url`: `33550aef-b54b-81bd-84f7-c919976444f5`
- `query`: `"knowledge base"` for all pages, or specific topic name
- `page_size`: 10, `max_highlight_length`: 0
 
### Step 2: Fetch full content for each result
For each page ID returned, call `notion-fetch` with the page ID.
Do NOT rely on search highlights — always fetch full content.
 
### Step 3: Return as structured list
```
[WIKI PAGE: {title}]
Last updated: {date}
{content}
---
```

## Output Contract
- Return ALL matching pages, not just the first result
- If no wiki pages found, explicitly state: "Wiki is empty or not found — knowledge-retrieval will fall back to training memory"
- Do NOT summarize or truncate content at this stage; downstream skills will filter

## Notes
- This is a read-only skill; never write or modify pages
- If Notion MCP is unavailable, state this clearly and proceed with training memory, flagging uncertainty
- `notion-fetch` keyword for tool_search is EXACTLY `"notion fetch"` — other variants may not load it