---
name: read-all-prds
description: "Atomic skill. Read all PRD documents from the Product team PRDs folder in Notion. Trigger whenever writing, editing, critiquing, or referencing any existing design — ensures interface contracts and open questions are known before any new design work."
---
 
# Read All PRDs
 
## Purpose
Retrieve all PRD documents from the Product team PRDs folder.
Never draft, edit, or critique a PRD without first reading existing ones.
This establishes interface contracts, versioning context, and open questions
that all downstream composite skills depend on.
 
## Notion Location
 
- **Folder page ID**: `33650aefb54b800aa130c911ff19ec95`
- **URL**: https://www.notion.so/33650aefb54b800aa130c911ff19ec95
 
## Execution Steps
 
### Step 1: Fetch Folder Index
```
tool: notion-fetch
id: 33650aefb54b800aa130c911ff19ec95
```
This returns a list of all child pages (each is one PRD).
 
### Step 2: Fetch Each PRD Page
For each child page URL returned in Step 1:
```
tool: notion-fetch
id: {child page url}
```
Extract from each PRD:
- Page title (canonical name + version)
- All sections present: Goal, Background, Related Works,
  Method, Evaluation, Open Questions, Version Log, Critique
- Inline comments (if any)
- Last modified date
 
### Step 3: Return Structured Output
```
[PRD: {title}]
URL: {notion page url}
Last updated: {date}
Sections: {comma-separated list of sections present}
Version Log: {latest version entry}
Open Questions: {verbatim, if section exists}
Critique: {verbatim, if section exists}
---
{full page content}
===
```
 
## Output Contract
- Fetch and return ALL child pages — do not filter by title or date
- Preserve Open Questions and Critique sections verbatim —
  these are inputs to `prd-critique` and `prd-edit`
- Flag any PRD missing a Version Log as: `"[WARNING: no Version Log]"`
- If folder is empty, state: `"Product team PRDs folder is empty"`
- Read-only — never modify any page
 
## Notes
- PRD titles follow the convention: `PRD: {name} - {version}`
- If a child page 404s on fetch, skip and flag: `"[FETCH FAILED: {url}]"`