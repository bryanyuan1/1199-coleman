---
name: experiment-design
description: "Composite skill. Design a complete experiment specification tied to a PRD's Evaluation section. Every step must be explicitly specified in natural language before any code is generated. Works in two modes: web-side (planning-level spec from PRD and wiki) and dev-side (enriched with actual code paths, build commands, and test scripts from local codebase). Trigger whenever the user says 'design an experiment', 'how should we test this', 'write a test plan', 'specify the evaluation'. The spec card is the primary artifact — code is secondary."
---

# Experiment Design

## Purpose
Produce a complete, step-by-step experiment specification that a human
can read, verify, and reproduce without ambiguity.

**Core principle: if a step is not written down, it does not exist.**

**Two modes of operation:**
- **PLANNING** (web-side): drafts spec from PRD + wiki + experiment logs. Some steps have `{TODO}` placeholders.
- **ENRICHED** (dev-side): fills in placeholders with real paths and commands from `/tmp/{repo}/`.

Both modes produce the same spec card format. The difference is completeness.

**Where your time goes:**
You only need to carefully review two things: the **Execution Procedure** (every step correct?) and the **Parameter Space** (testing the right variables?). Everything else (environment, measurement, resource estimate) is auto-filled from context and included for completeness — you can skim or skip.

---

## Atomic Dependencies

| Step | Skill | Required? | Purpose |
|------|-------|-----------|---------|
| 1 | `read-all-prds` | yes | Target PRD's Method + Evaluation sections |
| 2 | `read-wiki` | yes | Background for parameter selection |
| 3 | `read-experiment-logs` | yes | Past experiments to avoid duplication |
| 4 | (local code) | conditional | Real paths, commands, scripts from `/tmp/{repo}/` |
| 5 | `write-wiki-page` | yes | Write spec card to Dev team internal logs |
| 6 | `write-comments` | conditional | Flag gaps in PRD or post placeholder warnings |

---

## Execution Steps

### Step 1: Gather Context

Execute reads:
1. `read-all-prds` — locate target PRD, read Method and Evaluation sections
2. `read-wiki` — relevant paper knowledge for parameter choices
3. `read-experiment-logs` — what has already been tested

Check local code:
```bash
ls /tmp/ | head -20
```
Set mode = `ENRICHED` if code available, `PLANNING` if not.

If PRD Method section is too vague:
```
PRD "{title}" Method section insufficient for experiment design.
Post a [DRAFT GAP] comment on Evaluation section?
```

### Step 2: Confirm Preamble (HARD STOP #1)

Present a one-screen preamble for quick confirmation:

```
[EXPERIMENT SPEC — CONFIRM TARGET]
Mode: {PLANNING / ENRICHED}

Name:       {experiment name}
PRD:        {PRD title} — Evaluation section
Purpose:    {one sentence — what question does this answer?}
Hypothesis: {If we do X, we expect Y, because Z.}
Prior work: {similar experiment from logs, or "None"}

Is this the right experiment to design? (y/n)
```

This takes 10 seconds to verify. If wrong, stop and redirect.

### Step 3: Auto-Fill Environment, Measurement, Resources

These sections are generated automatically — **no HARD STOP**.
The user can review them in the final spec card but does not
need to approve them separately.

**Environment Setup** (auto-filled):
```
## Environment Setup

Platform:     {hardware, software, simulation mode}
Repository:   {URL, branch, commit}
Build:        {build command — real if ENRICHED, {TODO} if PLANNING}
Input data:   {dataset name, size, format, storage location}
```

ENRICHED mode verifies against local code:
```bash
git -C /tmp/{repo} log --oneline -1
ls /tmp/{repo}/Makefile /tmp/{repo}/CMakeLists.txt 2>/dev/null
```

**Measurement** (auto-filled):
```
## Measurement

| Metric | Unit | How to Extract | From Which Output |
|--------|------|----------------|-------------------|
| {m1}   | {u}  | {command}      | {file}            |

Sanity checks:
| Metric | Expected Range | Red Flag If |
|--------|---------------|-------------|
| {m1}   | {min}–{max}   | {condition} |

Baseline: {source and values}
Success criteria: {what validates / invalidates the hypothesis}
```

**Resource Estimate** (auto-filled):
```
## Resource Estimate

Per config: {time}  |  Total configs: {N}  |  Total: {time}
Storage: {size}  |  Parallelizable: {yes/no}
```

### Step 4: Present Execution Procedure + Parameter Space (HARD STOP #2)

**This is the section you actually need to read carefully.**

```
[REVIEW REQUIRED: Execution Procedure + Parameters]

## Parameter Space

Variables (swept):
  | Parameter | Values | Unit | Rationale |
  |-----------|--------|------|-----------|
  | {param1}  | {v1, v2, v3} | {unit} | {why} |
  | {param2}  | {v1, v2} | {unit} | {why} |
```

ENRICHED mode adds per parameter:
```
  Code location: /tmp/{repo}/{file}:{line}
  Default in code: {current value}
```

```
Controls (fixed):
  | Parameter | Value | Reason |
  |-----------|-------|--------|
  | {param1}  | {val} | {why}  |

Total configurations: {N}

## Execution Procedure

Step 1. {Action}
  Command:   {exact command — copy-pasteable}
  Dir:       {working directory}
  Expected:  {what success looks like}
  On error:  {what to check}

Step 2. {Action}
  Command:   {exact command}
  Dir:       {path}
  Expected:  {description}
  On error:  {description}

...

For each configuration ({param1} × {param2}):
  Step A. Set parameters
    Command: {how to set this config}
  Step B. Run
    Command: {exact run command}
    Timeout: {max time}
  Step C. Record
    Output:  {what to capture}
    Save to: {path/filename pattern}

---
PLANNING mode placeholders: {count} steps marked {TODO}
ENRICHED mode: all commands verified against /tmp/{repo}/

Type "confirm" to save spec card, or give feedback to revise.
```

**This is the only section that needs your careful review.**
Every command must be correct. Every parameter must make sense.

### Step 5: Check for Duplication

Compare against experiment logs:
```
[WARNING: Similar experiment found]
Log: {date, link}
Overlap: {matching params}
Difference: {what's new}
Proceed anyway?
```

### Step 6: Assemble and Write Spec Card (write-wiki-page)

Combine all sections into the final spec card:
- Preamble (from Step 2)
- Environment Setup (from Step 3, auto-filled)
- Parameter Space (from Step 4, user-reviewed)
- Execution Procedure (from Step 4, user-reviewed)
- Measurement (from Step 3, auto-filled)
- Resource Estimate (from Step 3, auto-filled)

Write to Notion:
```
Target folder: "Dev team internal logs"
Page title: "Spec: {experiment name} — {date}"
Content: {full spec card}
```

### Step 7: Link to PRD (write-comments)

Post comment on PRD Evaluation section:
```
page_id: {PRD page_id}
comments:
  - anchor: "## Evaluation...{last chars}"
    text: "[EXPERIMENT SPEC] {spec card Notion URL}
           Mode: {PLANNING / ENRICHED}
           Configs: {N}, est. {time}
           Placeholders: {count or 'none'}"
```

PLANNING mode additionally:
```
  - text: "[NEEDS CODE] Spec has {N} placeholder steps.
           Run experiment-design from dev-side to fill in."
```

### Step 8: Return

```
[EXPERIMENT DESIGNED]
Name:         {experiment name}
Mode:         {PLANNING / ENRICHED}
Spec card:    {Notion URL}
PRD:          {PRD title} — comment posted
Configs:      {N} total
Est. time:    {total}
Placeholders: {count — 0 if ENRICHED}
Status:       {Ready for execution / Needs dev-side enrichment}
```

---

## Output Contract

- NEVER generate test code before spec card is approved
- Execution Procedure: EVERY step must have exact command OR explicit `{TODO}`
- Parameter Space: EVERY variable must have rationale
- EVERY `{TODO}` must have a `[NEEDS CODE]` tag
- Sanity check ranges are mandatory (auto-filled but must be present)
- Duplication check is mandatory
- HARD STOP #1 (preamble) is quick — just confirm the target is right
- HARD STOP #2 (procedure + params) is the real review — take your time here
- Environment, Measurement, Resource Estimate are auto-filled — no separate approval needed
- PLANNING mode is valid output — upgrading to ENRICHED happens in a separate run from dev-side

---

## Notes

- A spec card can be upgraded PLANNING → ENRICHED by running this skill again from dev-side
- The `[NEEDS CODE]` comments on PRD signal that dev-side enrichment is needed
- Human runs the experiment following the spec card — this skill does not execute
- Sanity check ranges feed into `knowledge-correction` when results are outside bounds
- The two HARD STOPs are designed to minimize your review burden while ensuring you verify the things that matter most