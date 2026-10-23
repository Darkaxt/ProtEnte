ProtEnte 0.1.0 establishes an independent Windows identity and repeatable packaging
for Ente Auth. **This is an unsigned packaging baseline with no additional
security hardening.** It is not affiliated with Proton or Ente.

- Download the per-user x64 installer or extract the portable x64 ZIP.
- Windows 10 or later with x64 application support and the Visual C++ x64 runtime
  for the VS2022 toolchain are required. The installer does not install the runtime.
- Windows executable, window, tray and installer identify as ProtEnte. Application
  data and Credential Manager names are separate from Ente; existing Ente data
  is not imported automatically. The existing `enteauth://` handler is untouched.
- Upstream Windows update discovery and Ente Sentry reporting are disabled.
  Updates are distributed through this repository's releases.
- **Hosted Ente-account passkey sign-in is unsupported in this baseline** because
  Ente's hosted page rejects the separate `protente://` callback. Standard OTP
  generation and import formats retain upstream behavior. 2FAS can remain on
  your phone; it does not automatically synchronize with ProtEnte.

The executable and installer are both Authenticode **NotSigned**. No new automatic
lock, cryptographic vault lock lifecycle, password-wrapped local keys, Windows
Hello redesign, clipboard hardening or HTML-export fix is included. This release
has not received an independent security audit.

Source: `629dad28601ce899be7ee136960afd4f1ea8ddcf`, based on Ente Auth
4.4.26+1118 (`9684542adf1881515c49a60685cbf53423223e63`), preserving upstream
history, attribution and AGPL-3.0 licensing.

[Build run](https://github.com/Darkaxt/ProtEnte/actions/runs/40039971760) passed
the pinned-dependency Release build, focused isolation checks, changed-path Dart
analysis and reviewed PE membership. Its initial smoke step was cancelled for a
test launcher conflict. The
[successful verification run](https://github.com/Darkaxt/ProtEnte/actions/runs/40041560093)
proved application/build inputs unchanged and tested those same immutable package
bytes: checksums, executable identity/version, credential namespace, signature
status, real silent installation, isolated URL registration, visible native
window startup, normal close (exit 0) and uninstall on a disposable Windows runner.
Full rendered Flutter UI, real-account login and production-vault behavior were
not verified. No personal account, OTP seeds or installed vault was used.

Assets include the installer, portable ZIP, source/version manifest, SHA-256
checksums and the runner's package verification report. Build and continuation
instructions are in `protente/WINDOWS.md`; later security work is scoped separately
in `protente/SPEC.md` and `protente/SECURITY-COMPARISON.md`.
