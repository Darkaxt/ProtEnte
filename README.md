# ProtEnte

Independent Windows fork of [Ente Auth](https://github.com/ente/ente), maintained
by Darkaxt. Not affiliated with or endorsed by Proton or Ente.

**0.1.0 is a Windows packaging baseline. No additional security controls have
been implemented. The application and installer are unsigned.**

Known compatibility limitation: Ente's hosted account-passkey page rejects this
fork's callback URL. This does not affect standard OTP generation. See the scope
document for the current acceptance/delivery status.

This fork starts from Ente Auth 4.4.26+1118
(`9684542adf1881515c49a60685cbf53423223e63`) and preserves upstream source history,
the AGPL-3.0 license and existing OTP/import formats. The Android application is
not being developed or released here; 2FAS on your phone can remain unchanged.

## Windows baseline

- ProtEnte executable, native window, tray label and installer identity.
- Separate application-data and Credential Manager namespaces, with no automatic
  copying of an existing Ente vault.
- Separate `protente://` handler; upstream `enteauth://` remains untouched.
- Per-user installer and portable x64 ZIP with source/version manifest and hashes.
- Pinned Flutter/dependency build on Windows 2022 with package verification.
- Upstream Windows update discovery and Ente Sentry reporting disabled.
- One manually dispatched Windows workflow; upstream deployment/store/nightly
  automation is not retained in the fork branch.

[Build and release instructions](protente/WINDOWS.md) ·
[Scope and current stage status](protente/SPEC.md) ·
[Security review context for resuming](protente/SECURITY-COMPARISON.md) ·
[Baseline notice](protente/BASELINE-NOTICE.txt) ·
[Releases](https://github.com/Darkaxt/ProtEnte/releases)

## Security work for a later project

Planned areas are desktop automatic locking, a cryptographic vault-session
lifecycle, password-wrapped local keys, clipboard protection and export safety.
These are proposals, not features of this baseline. Windows Hello key operations
need their own design; a Hello prompt followed by generic Credential Manager
retrieval does not establish authentication-bound key protection.

The baseline retains Ente's existing app-lock and storage behavior. Do not infer
security assurance from the fork name, a successful build or package checks.
No personal vault or real account is used during packaging verification.

## Upstream and license

[Ente Auth documentation](https://ente.com/help/auth/) describes inherited
features. Ente account synchronization continues to use Ente's service.
Artwork, applicable notices and upstream copyrights are retained.
Source is distributed under the [GNU AGPL version 3](LICENSE).
