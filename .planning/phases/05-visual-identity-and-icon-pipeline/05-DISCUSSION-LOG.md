# Phase 5: Visual Identity And Icon Pipeline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 05-visual-identity-and-icon-pipeline
**Areas discussed:** Icon Concept, Visual Style, Prompt Workflow

---

## Icon Concept

### Primary Message

| Option | Description | Selected |
|--------|-------------|----------|
| Pulse Calendar | Blends scheduled jobs with health/status, so it reads as automation plus condition at a glance. | Yes |
| Mac Utility | Emphasizes a native local inspector: calm, practical, and tool-like. | |
| Automation Map | Highlights connected workflows and job relationships more than health state. | |

**User's choice:** Pulse Calendar
**Notes:** This became the core metaphor for the icon.

### Recognizable Anchor Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Calendar Tile + Pulse Line | Clear scheduling metaphor with a health signal. | Yes |
| Status Dashboard Tile | Feels more like an inspector app, with small rows/dots suggesting jobs. | |
| Clock Ring + Check/Pulse | Emphasizes timing and healthy completion, less job-inventory specific. | |

**User's choice:** Calendar Tile + Pulse Line
**Notes:** The calendar tile is the main shape people should read first.

### Automation Detail Level

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle Schedule Cues | Calendar grid/clock ticks plus one pulse line; clean at small sizes. | Yes |
| Mini Job Rows | Tiny rows or status dots hint at the app's sidebar/inventory. | |
| Connected Nodes | A small automation graph, more workflow-like than calendar-like. | |

**User's choice:** Subtle Schedule Cues
**Notes:** Avoid miniature UI or graph detail.

### Health Signal

| Option | Description | Selected |
|--------|-------------|----------|
| Green Pulse Accent | Direct health/readiness cue, easy to recognize. | Yes |
| Checkmark Badge | Clearer OK signal, but a little generic. | |
| Amber/Green Status Dot | Matches monitoring/status language, quieter than a pulse. | |

**User's choice:** Green Pulse Accent
**Notes:** The pulse line carries the health/status message.

---

## Visual Style

### Overall Style

| Option | Description | Selected |
|--------|-------------|----------|
| Native macOS Utility | Rounded dimensional tile, polished but restrained; best fit for a local SwiftUI tool. | Yes |
| Dark Navigation Surface | Borrows the app's dark sidebar mood, higher contrast and more app-specific. | |
| Technical Monitor | Sharper, more systems/terminal-adjacent, less friendly. | |

**User's choice:** Native macOS Utility
**Notes:** The icon should feel at home as a local macOS app icon.

### Color Direction

| Option | Description | Selected |
|--------|-------------|----------|
| Cool Graphite + Green | Neutral macOS utility base with a clear health accent. | Yes |
| Deep Navy + Mint | Richer and more branded, slightly less neutral. | |
| White/Silver + Green | Brighter, very macOS, but less connected to the app's dark sidebar. | |

**User's choice:** Cool Graphite + Green
**Notes:** Green is the health accent, graphite is the utility base.

### Dimensional Finish

| Option | Description | Selected |
|--------|-------------|----------|
| Soft 3D Depth | Native macOS-style rounded shape, gentle shadows/highlights, still clean. | Yes |
| Flat Vector | Simpler and docs-friendly, but less like a polished macOS app icon. | |
| High Gloss | Dramatic App Store-style shine, more decorative. | |

**User's choice:** Soft 3D Depth
**Notes:** Polished but restrained.

### Relationship To App UI

| Option | Description | Selected |
|--------|-------------|----------|
| Loose Echo | Suggest the dark navigation/status feel without copying UI rows. | Yes |
| Direct Echo | Include tiny sidebar/list/status elements from the app. | |
| Standalone Symbol | No UI resemblance, just calendar plus pulse. | |

**User's choice:** Loose Echo
**Notes:** The icon can hint at the product surface without becoming a tiny screenshot.

### Typography

| Option | Description | Selected |
|--------|-------------|----------|
| No Text | Avoids unreadable tiny lettering and feels more timeless. | Yes |
| Subtle AH | Adds identity but risks looking logo-ish and cramped. | |
| Calendar Number | Small date number, more calendar-like but arbitrary. | |

**User's choice:** No Text
**Notes:** No initials, date numbers, or other lettering.

---

## Prompt Workflow

### Prompt Artifact

| Option | Description | Selected |
|--------|-------------|----------|
| One Final Prompt + Notes | A polished copy-paste ChatGPT prompt, plus short rationale and negative constraints. | Yes |
| Three Prompt Variants | Conservative, richer, and experimental options for manual selection. | |
| Prompt Kit | Base prompt plus editable knobs for palette, detail level, and composition. | |

**User's choice:** One Final Prompt + Notes
**Notes:** The output should be direct and copy-paste-ready.

### Variant Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Ask ChatGPT For 4 Variants In One Prompt | Same concept, small composition/material variations; choose best manually. | Yes |
| Generate One Image Only | Fastest, but less chance of landing the right icon. | |
| Separate Prompts Per Variant | More control, more documentation overhead. | |

**User's choice:** Ask ChatGPT For 4 Variants In One Prompt
**Notes:** The chosen prompt should request four variants.

### Source Art Record

| Option | Description | Selected |
|--------|-------------|----------|
| Committed Original Source PNG | Keep the chosen generated art as the stable source for deterministic icon builds. | Yes |
| Prompt Only | Regenerate from text each time, lighter repo but not visually deterministic. | |
| Source PNG + Prompt Transcript | Strongest provenance, but a bit more artifact weight. | |

**User's choice:** Committed Original Source PNG
**Notes:** The chosen PNG is the deterministic source of truth.

### Generation Docs Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Optional Reproducible Path | Document API/CLI generation as optional for people with paid access, not required. | |
| Manual ChatGPT Only | Keep docs focused on copy-paste generation. | Yes |
| Full API Recipe | Include stronger reproducibility details, but risks making secrets/env look required. | |

**User's choice:** Manual ChatGPT Only
**Notes:** Do not make paid/API generation part of the expected workflow.

### Selection Record

| Option | Description | Selected |
|--------|-------------|----------|
| Short Selection Notes | Record why the chosen PNG won: legible at small sizes, clean metaphor, no text/private data. | Yes |
| No Selection Rationale | Commit the chosen file and keep docs lean. | |
| Full Comparison Grid | Document all variants and tradeoffs, heavier than this phase likely needs. | |

**User's choice:** Short Selection Notes
**Notes:** Keep the selection record lean and useful.

---

## the agent's Discretion

- Exact asset directory names.
- Exact icon-generation script implementation.
- Exact generated icon sizes and `.icns` tooling.
- Exact documentation file placement and Makefile shortcuts.
- Exact build-script integration details, provided the generated `.app` displays the icon.

## Deferred Ideas

- Public screenshot/docs visual refresh remains Phase 9.
