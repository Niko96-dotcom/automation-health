# External Integrations

**Analysis Date:** 2026-05-08

## APIs & External Services

**Local macOS schedulers:**
- launchd - read-only inventory of scheduled jobs from launchd property lists and best-effort runtime status.
  - SDK/Client: `FileManager`, `PropertyListSerialization`, and `/bin/launchctl` via `Process` in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`.
  - Auth: current macOS user filesystem and `launchctl` permissions; no environment variable is used in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`.
- Hermes cron - read-only inventory of Hermes scheduled jobs and recent markdown output.
  - SDK/Client: `FileManager`, `JSONDecoder`, and `TextSnippetReader` in `Sources/ActiveJobsCore/Services/HermesCronScanner.swift` and `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`.
  - Auth: current macOS user filesystem permissions for `~/.hermes/cron/jobs.json` and `~/.hermes/cron/output/<job-id>`; no environment variable is used in `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`.

**Desktop OS integration:**
- Finder reveal - opens the selected output path in Finder from the details view.
  - SDK/Client: `NSWorkspace.shared.activateFileViewerSelecting` in `Sources/AutomationHealth/Views/DetailView.swift`.
  - Auth: current macOS user desktop session; no environment variable is used in `Sources/AutomationHealth/Views/DetailView.swift`.
- App activation - brings the SwiftUI app to the foreground on launch.
  - SDK/Client: `NSApplicationDelegate`, `NSApp.setActivationPolicy`, and `NSApp.activate` in `Sources/AutomationHealth/App/AutomationHealthApp.swift`.
  - Auth: local macOS app process; no environment variable is used in `Sources/AutomationHealth/App/AutomationHealthApp.swift`.

**Developer and CI services:**
- GitHub Actions - builds and runs the local CI gate on pull requests, pushes to `main`, and manual dispatch.
  - SDK/Client: workflow YAML in `.github/workflows/ci.yml`; checkout uses `actions/checkout@v4`.
  - Auth: GitHub Actions default token with `contents: read` permission in `.github/workflows/ci.yml`; no repository secrets are referenced.
- Dependabot - checks GitHub Actions updates weekly.
  - SDK/Client: `.github/dependabot.yml`.
  - Auth: GitHub-managed Dependabot permissions; no repository secrets are referenced in `.github/dependabot.yml`.

**Network APIs:**
- Not detected - `Sources` contains no `URLSession`, HTTP client, webhook, OAuth, Firebase, Supabase, Stripe, AWS, Sentry, or analytics SDK usage.

## Data Storage

**Databases:**
- Not detected - there is no Core Data model, SQLite client, CloudKit integration, ORM, database package dependency, or database connection configuration in `Package.swift` or `Sources`.
  - Connection: Not applicable.
  - Client: Not applicable.

**File Storage:**
- Local filesystem only - `LaunchAgentScanner` reads `~/Library/LaunchAgents`, `/Library/LaunchAgents`, `/Library/LaunchDaemons`, and configured stdout/stderr log paths in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`.
- Local filesystem only - `HermesCronScanner` reads `~/.hermes/cron/jobs.json` and `~/.hermes/cron/output/<job-id>/*.md` in `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`.
- Local filesystem only - `TextSnippetReader` reads up to the last 24 KB of output files in `Sources/ActiveJobsCore/Support/TextSnippetReader.swift`.
- Local build artifacts - SwiftPM output lives in `.build/` and app bundles live in `dist/`, both ignored by `.gitignore`.

**Caching:**
- In-memory UI state only - `JobStore` stores `jobs`, `selectedJobID`, `errorMessage`, `isScanning`, and `lastScannedAt` in `Sources/AutomationHealth/Stores/JobStore.swift`.
- External cache: None detected in `Package.swift`, `Sources`, `script/ci.sh`, or `script/build_and_run.sh`.

## Authentication & Identity

**Auth Provider:**
- None - the app has no login, account model, OAuth flow, Keychain usage, or authentication dependency in `Package.swift` or `Sources`.
  - Implementation: local macOS permissions determine access to launchd plists, Hermes cron files, log files, Finder reveal, and `launchctl` status calls in `Sources/ActiveJobsCore/Services/LaunchAgentScanner.swift`, `Sources/ActiveJobsCore/Services/HermesCronScanner.swift`, and `Sources/AutomationHealth/Views/DetailView.swift`.

## Monitoring & Observability

**Error Tracking:**
- None - no Sentry, crash reporting, analytics, telemetry SDK, or error tracking dependency appears in `Package.swift` or `Sources`.

**Logs:**
- App-facing scan errors are stored as `errorMessage` in `Sources/AutomationHealth/Stores/JobStore.swift` and rendered by `Sources/AutomationHealth/Views/DetailView.swift`.
- Developer log streaming is provided by `/usr/bin/log stream` modes in `script/build_and_run.sh`.
- Application logging API usage such as `Logger` or `os_log`: Not detected in `Sources`.

## CI/CD & Deployment

**Hosting:**
- Not detected - the product is a local macOS app packaged by `script/build_and_run.sh`; no hosted backend, web app deployment, or app distribution pipeline is configured.

**CI Pipeline:**
- GitHub Actions - `.github/workflows/ci.yml` runs `./script/ci.sh` on `macos-latest`.
- Local CI command - `script/ci.sh` runs `swift build` and `./script/test.sh`.
- Dependency update automation - `.github/dependabot.yml` checks GitHub Actions updates weekly.

## Environment Configuration

**Required env vars:**
- None for the app runtime - `Sources/AutomationHealth` and `Sources/ActiveJobsCore` do not read environment variables.
- Optional `TZ` - defaults to `Europe/Berlin` in `script/ci.sh` and `script/test.sh`; `.github/workflows/ci.yml` sets `TZ: Europe/Berlin` for CI.

**Secrets location:**
- Not detected - no `.env*` files are present and no secret file is read by `Package.swift`, `Sources`, `script/ci.sh`, `script/test.sh`, or `.github/workflows/ci.yml`.
- `.gitignore` excludes `.env` and `.env.*`; `!.env.example` is allowed but no `.env.example` file is present.
- GitHub Actions secrets are not referenced in `.github/workflows/ci.yml`.

## Webhooks & Callbacks

**Incoming:**
- None - the app is a desktop process with no server, route handlers, HTTP listener, or callback endpoints in `Sources`.

**Outgoing:**
- None - no `URLSession`, `curl`, webhook client, HTTP request code, or cloud scheduler client appears in `Sources`, `script`, or `.github/workflows/ci.yml`.

---

*Integration audit: 2026-05-08*
