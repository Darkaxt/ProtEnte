# Windows baseline build and delivery

ProtEnte 0.1.0 is an unsigned packaging baseline. It does not include the proposed
security hardening. The source derives from Ente Auth 4.4.26+1118 at
`9684542adf1881515c49a60685cbf53423223e63`.

## Build

Use the **ProtEnte Windows packaging** workflow, select `codex/protente-windows`
and run it manually. It uses Windows Server 2022 / Visual Studio 2022, the
upstream SHA-256-verified Flutter 3.47.2 archive, and `mobile/pubspec.lock`.
Only this fork-specific workflow is active in the fork's default branch.
It requires no Ente signing, store, cloud deployment or Sentry secrets.
Leave `artifact_run_id` empty for a complete build. When changing only verification
or documentation, the same workflow can verify an existing run's immutable package.
It refuses reuse if application source, dependencies, SDK setup, license, package
notice, metadata or build/installer scripts differ from that package's source.
The package manifest and release tag retain the original build source revision;
the verification run separately identifies the current verifier revision.

Runtime prerequisites follow upstream: Windows 10 or later with x64 app support
and the Microsoft Visual C++ x64 runtime for the VS2022 toolchain. The installer
does not install a system-wide runtime. See
[Ente's Windows installation guidance](https://ente.com/help/auth/faq/installing).
The hosted-runner smoke test does not prove operation on a bare Windows image.

Local equivalent, in PowerShell 7 on a Windows checkout with VS2022 C++ desktop
tools, Flutter 3.47.2 and Inno Setup 6:

```powershell
git submodule update --init --depth 1 mobile/apps/auth/assets/simple-icons
./protente/build-windows.ps1 -Flutter D:/Tools/flutter/bin/flutter.bat -OutputDirectory D:/Temp/ProtEnte-build/release
./protente/verify-windows-package.ps1 -ArtifactDirectory D:/Temp/ProtEnte-build/release
```

Use task-owned scratch for TEMP/TMP/PUB_CACHE when preparing a disposable local
build. Never change global environment settings. The script builds Windows only;
Git long paths are enabled for the build's child processes and restored on exit.
It does not invoke Android/Gradle or install on the local machine. `-SmokeTest`
is deliberately restricted to a disposable GitHub Actions runner. It tests real
silent installation, executable identity/native window startup, URL-handler
isolation and uninstall. It does not claim full Flutter UI, account or vault
workflow verification.

Artifacts: portable `ProtEnte-0.1.0-windows-x64.zip`, per-user
`ProtEnte-0.1.0-windows-x64-installer.exe`, `release-manifest.json`, `SHA256SUMS`
and `package-verification.json`. Installer source remains in the build output
for diagnosis. Packages are retained after a smoke-test failure for diagnosis;
an uploaded artifact alone is not a passed gate or permission to release.
All are built from one source revision. PE membership is checked
against the reviewed Windows allowlist. The portable directory includes the
license, baseline notice and source/version manifest. Both executable and
installer are unsigned; do not represent them as Ente-signed or hardened.

## Identity and compatibility

- Executable / window / Start menu: `protente.exe` / `ProtEnte`.
- Native resource company/product: `Darkaxt` / `ProtEnte`. Windows path-provider,
  preferences and secure-storage files therefore use `%APPDATA%/Darkaxt/ProtEnte`.
- Credential Manager plugin prefix: `protente_VGhpcyBpcyB0aGUgcHJlZml4IGZv_`.
  This is namespacing, not stronger encryption or app-exclusive credential access.
- Installer ID: `EA53EBAB-98A0-4AB1-9DA6-5B76AC1E972F`; installation is per-user
  under `%LOCALAPPDATA%/Programs/ProtEnte` unless explicitly overridden.
- URL handler: `protente://`, including search and configured passkey callback.
  The existing `enteauth://` registration is not changed. The pinned Accounts web
  source's `isAllowedRedirectScheme` rejects `protente://`; hosted Ente-account
  passkey sign-in is therefore explicitly unsupported in this baseline, as
  authorized by the user on 2026-10-24; it is not simply untested.
  Email/password login and account synchronization retain upstream implementation,
  not live-account proof. See the scope decision in `SPEC.md`.
- Existing Ente data is not auto-migrated. Import explicitly using a supported
  backup if desired. Standard OTP and 2FAS import behavior remains upstream.
- Upstream Windows update discovery is disabled; use this fork's GitHub releases.
  Windows crash reports do not use Ente's Sentry DSN. Existing service-specific
  support links and upstream artwork remain attributed to Ente.

## Release

After the full baseline acceptance gate passes, download the successful workflow's
`ProtEnte-windows-x64` artifact. Verify checksums, source revision and executable
metadata, then publish tag `protente-v0.1.0` at that exact source revision with the
five output files. Explain its unchanged security properties and unsigned status
in the release notes. Re-download the actual public release and verify again.
Do not publish every intermediate build. Keep future version/build changes in
`protente/windows.json` and update package verification expectations accordingly.

## Resume

Delivered baseline:
[ProtEnte 0.1.0](https://github.com/Darkaxt/ProtEnte/releases/tag/protente-v0.1.0),
published 2026-10-24 local time as a normal release, with all five required assets.
Tag `protente-v0.1.0` resolves to built source
`629dad28601ce899be7ee136960afd4f1ea8ddcf`.
[Build run](https://github.com/Darkaxt/ProtEnte/actions/runs/40039971760)
passed compilation, analysis, isolation checks and packaging; its original smoke
test was cancelled for a launcher conflict. The
[successful package verification](https://github.com/Darkaxt/ProtEnte/actions/runs/40041560093)
used verifier revision `576671b9876ce24affd89319349cddeac21a86b3`, proved build inputs
unchanged and passed the real install/show/normal-close/uninstall round trip on
the same package bytes. The checked-in release notes explain this provenance.

All five release files were independently downloaded through public URLs without
authentication and matched the tested CI artifacts. Static verification was repeated
against the public package, confirming ProtEnte 0.1.0+1, its source manifest,
credential prefix and **NotSigned** status for both EXEs. Runtime round-trip
evidence comes from the disposable runner; the local check only inspected files.
No full rendered Flutter UI, real account, personal seeds or production vault
was used or verified. Later documentation/verifier/workflow commits do not change
the released application or package inputs.

| Public asset | SHA-256 |
| --- | --- |
| `ProtEnte-0.1.0-windows-x64-installer.exe` | `a027e28691f392858d689bb422afb35d98b5ba1a303552c14ee9444fa86f000b` |
| `ProtEnte-0.1.0-windows-x64.zip` | `43b09ba2a861ef98eb98909e2d8ed82a5e7f5f93f2f77c61bc0e59f8f7229ff8` |
| `release-manifest.json` | `2460cc3706fcce9cc150a0970e2aed3c6978dc0ab410d876effd9e83953134ab` |
| `SHA256SUMS` | `759bc749fa15980814090f079a53faa29919aff692678be6c022c9d8133a924e` |
| `package-verification.json` | `aadb016a82aee265f5c3064399578ff6cedc19f44b0049846ed5e054d4a3f558` |

Read `SPEC.md`, this document and the root README. Preserve the audited source
baseline and separate Windows namespaces. Inspect the current branch, worktree
and release evidence before modifying code. The next project is security
hardening, requiring its own agreed specification and migration/recovery tests.
Do not treat the baseline version or rename as a security improvement.
