# Security Policy

Automation Health is a local, read-only scanner for scheduled jobs on this Mac. It reads supported scheduler definitions and readable output so users can inspect automation health, but it does not create, edit, enable, disable, or delete jobs.

## Reporting Security Or Privacy Issues

Please report security or privacy issues through a sanitized GitHub security advisory if available, or through the configured private maintainer contact for the repository.

Do not include raw logs, screenshots, scheduler output, local paths, hostnames, job names, tokens, secrets, or other private automation details in public issues, discussions, pull requests, or attachments. Summaries and minimal sanitized snippets are much safer.

Useful reports usually include:

- The affected Automation Health version or commit.
- macOS version.
- Scanner source involved, such as launchd or Hermes cron.
- A sanitized description of the scheduler definition or output shape.
- Steps to reproduce with synthetic paths, job names, and output.

## Scope

In scope:

- Bugs that expose private scheduler data in public-facing docs, templates, fixtures, examples, screenshots, or output.
- Scanner behavior that reads outside the documented local read-only boundaries.
- CI or repository workflow changes that grant unnecessary write permissions.

Out of scope:

- Diagnosing private local automations from raw output.
- Support for unsupported scheduler sources unless the report demonstrates a security or privacy impact.
- Issues caused by local job definitions, scripts, or scheduler configuration outside Automation Health.
