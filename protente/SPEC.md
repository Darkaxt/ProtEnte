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
  fork crash reports to Ente's Sentry project. Preserve upstream account API
  identity and token/data formats. Hosted Ente-account passkey sign-in is excluded
  by the explicit scope revision below; other account flows retain upstream code
  and are not claimed as live-account verified.
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
Run `40036832594` passed the build, reviewed 19-PE payload membership, executable
identity/version, credential namespace, ZIP/checksum/signature checks and actual
silent installation. Its registry assertion used forward slashes, which the
PowerShell registry provider does not accept (locally reproduced against the
non-secret Software root). The verifier now uses native registry paths; native
startup/uninstall and the corrected complete smoke test await re-verification.
Run `40038415919` verified installation and the isolated protocol registration,
then the test's raw WM_QUIT bypassed upstream's existing Windows quit handler and
the process exited abnormally. The test now waits for the native show event and
sends WM_CLOSE through the actual application close path; application behavior
is unchanged. This corrected smoke check is the current internal acceptance
blocker, resolved only by a passing real runner check, before delivery can start.
Run `40039971760` passed compilation/packaging but revealed a test setup conflict:
the application was launched hidden while the new test awaited a visible window.
The run was explicitly cancelled for that conflict. The CI-only interactive app
launch now uses normal visibility. Diagnostic milestones identify input readiness,
window visibility and normal exit. The manual workflow can recheck an immutable
package only after proving its application/build inputs match the checkout; this
avoids recompiling unchanged application code when correcting verifier behavior.
Repository, source ancestry, PowerShell parsing, Dart formatting and static
namespace/workflow checks have been inspected.
R4 scope revision, explicitly authorized on 2026-10-24: user answered “Yes,
document passkey sign-in as unsupported for this baseline.” Hosted Ente-account
passkey sign-in is therefore excluded from this baseline, with the limitation
recorded in the package notice, manifest, README and continuation notes. The
provider callback restriction is not a baseline blocker or a tracked deferral.
Resolving it would require a separately scoped provider integration. The remaining
baseline advancement blocker is completion of the corrected smoke/package checks.
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
