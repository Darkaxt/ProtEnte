# ProtEnte Windows baseline

Authorization: user requested only “Fork, rename and establish Windows packaging”
on 2026-10-24. The remaining security work is a separate, later project scope.

## Required outcome

- R1: Publish a real GitHub fork named `Darkaxt/ProtEnte`, preserving upstream
  source history, AGPL license and attribution. Base the Windows work on audited
  Ente Auth 4.4.26 (`9684542adf1881515c49a60685cbf53423223e63`).
- R2: Identify the Windows application, executable, installer, shortcuts and
  release as ProtEnte. Give it its own installer ID, application-data/credential
  namespace and URL scheme. Never auto-import existing Ente files or overwrite
  Ente's URL handler. Non-Windows app identities and OTP formats remain upstream.
- R3: Establish a repeatable Windows x64 Release build and packaging workflow
  using the upstream pinned Flutter version and dependencies. Deliver a portable
  ZIP, per-user installer, source/version manifest and SHA-256 checksums.
- R4: Route Windows release discovery to this fork (or explicitly disable the
  upstream updater); never offer upstream Ente as a ProtEnte update. Do not send
  fork crash reports to Ente's Sentry project. Preserve Ente account/API behavior.
- R5: Verify the completed baseline against real build/package outputs, commit
  and push it, publish one baseline release and independently retrieve/check its
  assets. State Authenticode status accurately; Ente's signing identity cannot be
  reused. Do not read or modify any personal vault or installed app settings.
- R6: Leave reproducible build instructions, provenance, verification evidence
  and concrete continuation notes. Clearly state that this release adds no
  security hardening and has not received an independent security audit.

## Stages and reconciliation

| Stage | Status | Requirements | Acceptance |
| --- | --- | --- | --- |
| Windows baseline | ACTIVE | R1-R4, R6 | Fork exists; identity/data/protocol isolation implemented; documented build produces the renamed app and packages; appropriate focused checks and Windows startup/package checks pass. |
| Baseline delivery | NOT STARTED | R5, R6 | Current implementation verified and committed; remote source verified; release assets published and independently downloaded/checked; resume notes reflect actual results. |

Identity and packaging implementation is present. Baseline acceptance is blocked
on the real Windows build/package checks (internal verification work). Initial CI
identified SDK bootstrap output before JSON and then Git dependency checkout paths
over Windows' legacy limit. SDK initialization passed on run `40034622802`; Git
long paths are now enabled through a process-scoped configuration override, as
required by upstream's Windows recipe. Run `40035322923` passed both Windows
isolation checks, analysis of the changed Dart paths and native Release compilation.
Its packaging check exposed relative .NET path resolution against the process
directory; the payload now uses an explicit path from the repository root.
Package/installer/startup acceptance remains pending. Repository, source ancestry,
PowerShell parsing, Dart formatting and static namespace/workflow checks have
been inspected.
Tracked deferrals: none. Final delivery belongs to the second named stage.

## Explicit exclusions

No new automatic locking, cryptographic vault-session lifecycle, local password
key wrapping, Windows Hello redesign, clipboard hardening or HTML-export fix in
this baseline. No phone migration, 2FAS changes, vault import, automatic upstream
maintenance, account login, or installation on the user's normal Windows profile.
Retain the upstream application icon for now; a new visual identity is not part
of this stage. ProtEnte is independent of both Proton and Ente.

## Later security work (not authorized for this baseline)

Start with an authoritative threat model and the reviewed storage comparison.
Then specify and implement automatic desktop lock triggers, a genuinely locked
cryptographic vault session, password-wrapped local keys, safer clipboard handling
and the independently validated HTML-export escaping fix. Treat authentication-
bound Windows Hello key operations separately from a prompt followed by generic
Credential Manager retrieval. Review migration/recovery and interrupted sync before
calling any later release hardened.
