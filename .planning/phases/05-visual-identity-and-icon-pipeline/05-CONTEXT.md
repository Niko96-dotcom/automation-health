# Phase 5: Visual Identity And Icon Pipeline - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 5 gives Automation Health a polished generated macOS app icon and a repeatable local asset path for public-ready development builds. It covers the copy-paste ChatGPT image prompt, source-art selection, committed source art, deterministic icon-asset generation, local `.app` bundle integration, and concise regeneration documentation. It does not redesign the app UI, add public screenshots or README visual refreshes beyond the icon workflow, require paid API/CLI generation, sign or notarize the app, or touch real scheduler data.

</domain>

<decisions>
## Implementation Decisions

### Icon Concept
- **D-01:** The icon's primary metaphor is **Pulse Calendar**: scheduled automations plus health/status at a glance.
- **D-02:** The recognizable anchor shape should be a **calendar tile with a pulse line**, not a dashboard, graph, or clock-only symbol.
- **D-03:** Automation detail should stay subtle: use schedule cues such as a calendar grid or timing marks plus one pulse line, not miniature job rows or connected-node diagrams.
- **D-04:** The health signal should be a **green pulse accent** rather than a checkmark badge or quiet status dot.

### Visual Style
- **D-05:** The icon should feel like a **native macOS utility**: polished, restrained, and suitable for a local SwiftUI desktop app.
- **D-06:** Use a **cool graphite plus green** color direction: neutral utility base with a clear health accent.
- **D-07:** Use **soft 3D depth** with gentle highlights and shadows, not a flat vector mark or high-gloss decorative finish.
- **D-08:** The icon may loosely echo the app's dark navigation/status feel, but should not copy tiny sidebar/list UI.
- **D-09:** Do not include letters, app initials, calendar numbers, or other text in the icon.

### Prompt Workflow
- **D-10:** Codex should produce one final copy-paste-ready ChatGPT image prompt, plus short notes explaining rationale and negative constraints.
- **D-11:** The prompt should ask ChatGPT to generate **4 variants** of the same concept with small composition/material differences so the maintainer can manually choose the best one.
- **D-12:** Commit the selected original source PNG as the stable source art for deterministic icon builds.
- **D-13:** Documentation should focus on manual ChatGPT generation only. Do not frame paid API/CLI generation as part of the expected workflow for this phase.
- **D-14:** Record short selection notes for the chosen PNG, focused on small-size legibility, clean metaphor, no text, and no private data.

### the agent's Discretion
Downstream agents may choose the exact asset directory names, icon-generation script implementation, generated icon sizes, `.icns` tooling, documentation file placement, and build-script wiring as long as the decisions above and Phase 5 success criteria are honored. The deterministic pipeline must be local, documented, and must not require secrets.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` - Defines Phase 5 goal, success criteria, planned waves, and boundary.
- `.planning/REQUIREMENTS.md` - Defines visual identity requirements `VIS-01`, `VIS-02`, and `VIS-03`; `VIS-04` is Phase 9 documentation-visual polish and should not be pulled into Phase 5.
- `.planning/PROJECT.md` - Captures project value, read-only/privacy constraints, milestone focus, and prior open-source/publication decisions.
- `.planning/STATE.md` - Current GSD state and warning to preserve unrelated working-tree changes.

### Existing Build And Documentation Surface
- `script/build_and_run.sh` - Current local `.app` bundle builder and primary integration point for `CFBundleIconFile`, resources, and generated icon assets.
- `docs/development.md` - Existing local build/bundle documentation and neutral bundle identifier reference.
- `README.md` - Public quick-start and local app bundle documentation that may need a concise icon/regeneration pointer.
- `docs/privacy-scrub-checklist.md` - Public asset safety checklist; icon docs and source art must avoid personal data and accidental local metadata.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `script/build_and_run.sh`: already centralizes `.app` bundle assembly, `Info.plist` generation, bundle identifier, and `dist/AutomationHealth.app` output. This is the natural place to copy icon resources and declare the app icon.
- `docs/development.md`: already documents local bundle generation and can host or link to deterministic icon regeneration steps.
- `README.md`: already explains source-built distribution and the generated bundle; it can link to the icon workflow without becoming a full visual refresh.
- `docs/privacy-scrub-checklist.md`: already defines public asset and screenshot privacy rules that apply to generated icon artifacts.

### Established Patterns
- The repository uses SwiftPM plus Bash scripts for local build workflows, with no third-party Swift dependencies.
- Generated outputs belong outside git in `dist/` and `.build/`; committed inputs and deterministic scripts should live in stable source/docs/script locations.
- Public docs use concise, plain language and emphasize local-only/privacy-safe behavior.
- Phase 4 established that public examples, fixtures, screenshots, and sample output should stay synthetic and scrubbed.

### Integration Points
- Icon assets should integrate with the generated app bundle under `dist/AutomationHealth.app/Contents`, likely through `Contents/Resources` plus an `Info.plist` icon key written by `script/build_and_run.sh`.
- Asset regeneration should be callable from the repo root and fit the existing `script/` and `Makefile` style if a developer shortcut is added.
- Verification should continue to use the existing local quality gate, with icon-specific checks added only where they are deterministic and low-noise.

</code_context>

<specifics>
## Specific Ideas

- Final icon prompt should describe a cool graphite rounded macOS calendar tile with subtle schedule marks and a green pulse line.
- Prompt negative constraints should exclude text, letters, logos, tiny UI rows, complex node graphs, personal data, screenshots, terminal output, and clutter that fails at small sizes.
- Selection notes should be short and practical: which generated variant was chosen and why it remains legible and on-metaphor at small icon sizes.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within Phase 5 scope. Public screenshot/docs visual refresh remains Phase 9.

</deferred>

---

*Phase: 05-visual-identity-and-icon-pipeline*
*Context gathered: 2026-05-08*
