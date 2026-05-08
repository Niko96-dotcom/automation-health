# Privacy Scrub Checklist

Use this checklist before public releases, screenshots, fixture updates, sample output, or documentation changes that mention local scheduler data.

## When To Run

- Before publishing a release or announcement.
- Before adding screenshots, fixtures, examples, or sample output.
- Before merging pull requests that touch public docs, issue templates, PR templates, `Sources`, `.github`, or `script`.
- After renaming bundle identifiers, scheduler examples, or fixture paths.

## Checklist

- [ ] Replace usernames and personal paths with synthetic examples such as `/Users/example`.
- [ ] Replace hostnames with generic placeholders.
- [ ] Replace real job names with synthetic names such as `example-daily-report`.
- [ ] Remove raw logs, scheduler output, screenshots, fixtures, and sample output that reveal local workflows.
- [ ] Remove tokens, secrets, passwords, API keys, and private command output.
- [ ] Check bundle identifiers for personal namespaces such as `com.niko`.
- [ ] Remove accidental macOS metadata such as `.DS_Store` files.
- [ ] Confirm public examples use synthetic scheduler definitions and output.
- [ ] Run `./script/ci.sh` after fixture or script changes.

## Search Commands

```sh
find . -name .DS_Store -print
```

```sh
rg -n "niko|com\\.niko|/Users/niko" README.md CONTRIBUTING.md docs .github Sources script
```

```sh
rg -n "token|secret|password|hostname|screenshot|scheduler output" README.md CONTRIBUTING.md docs .github Sources script
```

Resolve unexpected hits before publishing. When a hit is intentional guidance, make sure it is framed as something not to share publicly.

## Sensitive Categories

- Usernames and personal paths.
- Hostnames and device names.
- Bundle identifiers with personal namespaces.
- Screenshots that reveal local jobs, paths, hostnames, or output.
- Fixtures and sample output copied from real local automations.
- Scheduler output, job names, commands, prompts, and logs.
- Tokens, secrets, passwords, API keys, and private command output.
- `.DS_Store` files and other local metadata.

## Expected False Positives

- `SECURITY.md`, `SUPPORT.md`, `CONTRIBUTING.md`, issue templates, and this checklist intentionally mention tokens, secrets, screenshots, scheduler output, paths, hostnames, and job names as categories to avoid sharing.
- The `niko|com\\.niko|/Users/niko` command may match this checklist because it documents the scrub target.
- Synthetic paths such as `/Users/example` are acceptable.
