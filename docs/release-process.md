# Release Process

The upstream project was retired on 2026-09-30. These instructions preserve the
workflow used for the final maintenance release and for independently maintained
forks. The archived repository does not run workflows or publish further updates.
See [the retirement record](retirement.md).

## Existing Pipeline

`script/release.sh` builds the release configuration, embeds Sparkle 2.9.1 and the
public update key, signs the bundle with Developer ID and hardened runtime,
packages a DMG, submits it to Apple, validates and staples notarization, and
creates an EdDSA-signed `appcast.xml`. `.github/workflows/release.yml` supplies
credentials in a temporary keychain and uploads the DMG and appcast to Releases.

The release script derives the version from the nearest Git tag. The CI release
workflow runs for `v*` tag pushes; use a version tag rather than a branch-based
manual dispatch. Its publication step uses the triggering ref as the release tag.

## Credentials For A Maintained Fork

Keep credentials in the fork's GitHub Actions secrets, never in the repository:

| Secret | Purpose |
| --- | --- |
| `APPLE_DEVELOPER_CERTIFICATE_P12` | Base64-encoded Developer ID certificate |
| `APPLE_DEVELOPER_CERTIFICATE_PASSWORD` | Certificate export password |
| `APPLE_DEVELOPER_TEAM_ID` | Apple Developer team |
| `APPLE_NOTARY_KEY` | App Store Connect private key contents |
| `APPLE_NOTARY_KEY_ID` | Notarization key identifier |
| `APPLE_NOTARY_KEY_ISSUER_ID` | Notarization issuer identifier |
| `SPARKLE_EDDSA_PRIVATE_KEY` | Base64-encoded Sparkle update signing key |
| `SU_PUBLIC_ED_KEY` | Matching public key embedded in the app |

The workflow already grants its release job `contents: write`; no global workflow
permission change is needed. The local script instead expects
`APPLE_DEVELOPER_IDENTITY`, `APPLE_DEVELOPER_TEAM_ID`, `APPLE_NOTARY_KEY_ID`,
`APPLE_NOTARY_KEY_FILE`, `APPLE_NOTARY_KEY_ISSUER_ID`, `SU_PUBLIC_ED_KEY`, and
`SPARKLE_EDDSA_PRIVATE_KEY` in its environment. Do not print secret values.

The existing public key must continue to match the installed application's
trust configuration. Changing keys or publishing from a fork requires a separate
update migration plan. The feed and artifact URLs currently refer to the upstream
GitHub repository and must be deliberately changed for a fork.

## Publish And Verify

Run `./script/ci.sh` before tagging a release. Push the approved version tag,
then wait for the release workflow to complete successfully. A tag push or
successful source build alone is not release proof.

Download the exact published DMG and appcast, compare their SHA-256 digests with
GitHub's asset metadata, and verify the appcast version, enclosure URL, size,
and EdDSA signature against the embedded public key. Validate the DMG:

```sh
xcrun stapler validate AutomationHealth-x.y.z.dmg
hdiutil attach -readonly -nobrowse AutomationHealth-x.y.z.dmg
```

Use the mountpoint reported by `hdiutil` to check the actual application:

```sh
codesign --verify --deep --strict --verbose=2 "/Volumes/Automation Health/AutomationHealth.app"
spctl --assess --verbose=2 --type execute "/Volumes/Automation Health/AutomationHealth.app"
```

Confirm the bundle version and installed launch, local scan, Settings, and live
update check. Record update download/install/relaunch separately if exercised.
Keep source validation, published artifact trust, and installed behavior distinct.

## Development Builds

`script/build_and_run.sh` creates an ad-hoc signed `0.0.0-dev` bundle. Development
builds intentionally explain that update checking is unavailable. They are not
notarized releases and should not be uploaded as distribution assets.
