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
| Windows baseline | COMPLETE | R1-R4, R6 | Fork/history verified; isolation and branding implemented; Release build, focused checks, package identity and real Windows install/show/close/uninstall checks passed. |
| Baseline delivery | COMPLETE | R5, R6 | Published 0.1.0 at the exact built source tag; all five public downloads matched tested artifacts; downloaded package metadata, namespace, checksums and unsigned status verified; continuation evidence recorded. |

R1: GitHub confirms the public `Darkaxt/ProtEnte` fork and Ente parent. The audited
upstream revision remains an ancestor; AGPL license and attribution are retained.
R2-R4: build run `40039971760` produced source
`629dad28601ce899be7ee136960afd4f1ea8ddcf` with the reviewed 19-PE allowlist,
ProtEnte identity/version, distinct credential prefix, pinned dependencies,
passing isolation checks and clean changed-path Dart analysis. Its original smoke
attempt was cancelled because a hidden test launch conflicted with a visibility
predicate. Verification run `40041560093` at verifier revision
`576671b9876ce24affd89319349cddeac21a86b3` proved application/build inputs unchanged,
then passed checksum/identity/signature checks and real silent installation,
isolated protocol registration, visible native window startup, normal close
(exit 0), and uninstall. Retrieved artifacts from both runs match byte for byte.
Local static inspection also passed, without executing the app. Full Flutter UI,
real-account and vault behavior are not claimed as verified.
R6: build instructions, source comparison, explicit exclusions and resume notes
are present. Stage-closure assessment found no material refactoring needed for
this scope: one metadata file, canonical build/installer scripts and one manual
workflow own the packaging path; no new runtime framework was introduced.
R4 scope revision, explicitly authorized on 2026-10-24: user answered “Yes,
document passkey sign-in as unsupported for this baseline.” Hosted Ente-account
passkey sign-in is therefore excluded from this baseline, with the limitation
recorded in the package notice, manifest, README and continuation notes. The
provider callback restriction is not a baseline blocker or a tracked deferral.
Resolving it would require a separately scoped provider integration.
R5: normal published release `protente-v0.1.0` is neither draft nor pre-release;
its annotated tag resolves to the exact built source revision above. All five
assets were independently retrieved from public download URLs without credentials
and matched the tested artifacts byte for byte. Static inspection of the public
ZIP/installer again passed version/identity, source-manifest, credential namespace,
mandatory-file, checksum and NotSigned checks. See `WINDOWS.md` for hashes and
verification links. No application was installed or executed on the user's PC.
Final reconciliation: R1-R6 satisfied within the explicit scope revision; the
unchanged stage-closure assessment still applies. Blockers: none. Tracked
deferrals: none. Future security work remains outside this completed baseline.

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
