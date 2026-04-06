---
name: read-experiment-logs
description: "Atomic skill. Read all experiment logs from the Dev team internal logs folder in Notion. Trigger whenever past experiment results, parameter settings, or performance numbers are referenced. Never cite numerical results without reading logs first."
---

# Read Experiment Logs

## Purpose
Retrieve all experiment records to understand what has been tested,
what parameters were used, and what results were obtained.
Never reference performance numbers, parameter settings, or experiment
outcomes from memory — always read logs first.

## Notion Locations

Two sources must both be read:

| Source | Page ID | Notes |
|--------|---------|-------|
| Dev team internal logs | `33550aefb54b80dcaca9c7c7e0cdd9ec` | Container folder — fetch child pages |
| Experiment Logs | `2ef50aefb54b80119a3ef58d910424f7` | Primary log page — fetch full content |

## Execution Steps

### Step 1: Fetch Container Folder (Dev team internal logs)
```
tool: notion-fetch
id: 33550aefb54b80dcaca9c7c7e0cdd9ec
```
Returns list of child log pages. Fetch each child page individually:
```
tool: notion-fetch
id: {child page url}
```

### Step 2: Fetch Primary Experiment Log Page
```
tool: notion-fetch
id: 2ef50aefb54b80119a3ef58d910424f7
```
This is a long chronological page. Extract all dated sections.

### Step 3: Parse and Structure Results

For each dated section or child log page, extract:

- **Date / date range** (e.g. `02/25/2026 - 03/03/2026`)
- **Experiment name** (if titled)
- **Platform** (hardware target, simulation mode, or execution environment)
- **Parameters** — enumerate all, with exact values
- **Key findings** — DONE / TODO / FINDING items
- **Results** — exact numbers, pass/fail status
- **Open issues** — TODO items still unresolved

Return structured output:
```
[LOG: {date range or title}]
Source: {page title + URL}
Platform: {platform}
Parameters: {full list}
Key Findings:
  DONE: {list}
  FINDING: {list}
  TODO (open): {list}
Results: {exact numbers if present}
---
```

### Step 4: Flag Data Quality Issues

For any section missing platform or parameter info:
```
[WARNING: incomplete spec in section "{date}" — results unverifiable]
```

## Output Contract
- Read BOTH sources — do not skip either
- Return exact numbers verbatim — never summarize or round
- Return ALL dated sections, oldest to newest
- Flag incomplete spec sections prominently
- If both sources are empty, state explicitly:
  `"Experiment logs empty — do not infer results from memory"`

## Notes
- Read-only skill — never modify any page
- The Experiment Logs page is a living document; child pages under
  Dev team internal logs are discrete structured entries
- If a child page 404s, skip and flag: `"[FETCH FAILED: {url}]"`