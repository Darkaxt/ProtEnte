# Security review context for resuming ProtEnte

This is a source-review handoff, not an independent certification or a statement
that the baseline is hardened. The Windows baseline intentionally preserves the
upstream key/storage/locking model. Do not import production seeds merely to
test future changes; use synthetic entries and verify recovery first.

Reviewed Ente source: Auth 4.4.26+1118,
`9684542adf1881515c49a60685cbf53423223e63`.
Reviewed Proton source: desktop tag `proton-pass@1.42.0`,
`08bbb1ccdaeeabdad8a831932a148b12ad5dc2b1` in
[ProtonMail/WebClients](https://github.com/ProtonMail/WebClients/tree/08bbb1ccdaeeabdad8a831932a148b12ad5dc2b1).
Installed binaries were not proved equivalent to those source revisions.

## Ente boundaries to revisit

- `mobile/apps/auth/lib/main.dart` initializes configuration/services before the
  app-lock interface. `core/configuration.dart` loads Auth/offline keys through
  FlutterSecureStorage; the shared `packages/configuration` loads master keys.
- `mobile/packages/lock_screen/lib/ui/app_lock.dart` handles automatic background
  locking on Flutter's `paused` state, which is mobile-only. Desktop window hiding
  does not invoke a cryptographic lock. Manual and startup app locks do exist.
- App-lock PIN/password checks are separate from vault-key wrapping. Showing the
  lock screen does not clear configuration keys or decrypted `CodeStore` entries.
  [Ente documents this UI-only boundary](https://ente.com/help/auth/features/).
- Pinned `flutter_secure_storage_windows` 3.1.2 encrypts files using AES-GCM and
  keeps its wrapping key in generic Windows Credential Manager. File paths derive
  from executable company/product metadata, and credential prefixes derive from
  CMake's binary/storage prefix. ProtEnte changes those namespaces only.
- Generic Credential Manager storage is not an app-exclusive or user-presence-
  bound security boundary against another process running as the Windows user.

## What Proton actually provides

- Lock dispatches `stateDestroy`; its root reducer calls `PassCrypto.clear()` and
  zeroizes supported byte buffers in prior Redux state. Password/biometric lock
  adapters also remove OfflineKD and the session-lock token.
- That does **not** prove complete memory erasure. The ordinary lock paths do not
  explicitly remove every auth-store secret, including keyPassword/clientKey.
  JavaScript strings and dropped crypto-object references are not proven wiped.
- Desktop password unlock uses Argon2-derived OfflineKD to unlock offline cache
  material. This is a genuine password/crypto relationship, unlike Ente's local
  app-lock password hash. Proton also has persisted encrypted sessions and
  server-assisted session keys; copied caches and live authenticated profiles
  must not be conflated.
- The Windows biometric route verifies Hello, then separately calls
  `CredReadW(CRED_TYPE_GENERIC)` for a stored random secret. The native retrieval
  function itself does not require Hello. Do not copy this and call it
  authentication-bound or TPM-backed vault-key access.
- Desktop close-to-tray explicitly locks. Lock lifetime probing treats a visible
  document as active; it is not established as strict keyboard/mouse idle locking.
- The Windows browser extension's normal lock is server-assisted PIN/session
  locking. Its desktop biometric integration is macOS-gated at this revision;
  desktop password/Hello assumptions do not transfer to the Windows extension.

Relevant Proton source paths under the pinned revision:
`packages/pass/store/reducers/index.ts`, `packages/pass/lib/crypto/pass-crypto.ts`,
`packages/pass/lib/auth/{store,session}.ts`,
`packages/pass/lib/auth/lock/{password,biometrics,session}/adapter.ts`,
`packages/pass/lib/cache/crypto.ts`,
`applications/pass-desktop/native/shared/src/biometrics/windows.rs`,
`applications/pass/src/app/AppGuard.tsx`,
`packages/pass/components/Core/LockProbeProvider.tsx`,
`packages/pass/hooks/useVisibleEffect.ts`,
`applications/pass-extension/src/app/worker/services/auth/auth.service.ts`.

## Dependency warning observed during the baseline build

The workspace resolver reports
[GHSA-cr65-55v9-xhvv](https://github.com/advisories/GHSA-cr65-55v9-xhvv), concerning
cross-origin header forwarding in `dio_http2_adapter` through 2.7.1 (fixed in
2.8.0). The pinned workspace includes 2.7.1 for Photos; its import/adapter use is
in `mobile/apps/photos/lib/core/network/network.dart`. Auth's shared networking
instead selects `NativeAdapter` in `mobile/packages/network/lib/network.dart`.
This warning has not been validated as an exploitable Windows Auth finding.
The baseline retains the upstream lockfile; revisit reachability/dependencies
in the later security review rather than blindly upgrading the entire workspace.

## Next project specification

Define the protected scenarios before selecting controls: unattended Windows
session, copied files, same-user malware, or a compromised unlocked process.
Sharing OTP seeds with a desktop adds a copy of the second factor on that machine;
separate apps do not preserve separate-device isolation. 2FAS may remain on Android,
but it does not automatically synchronize with Ente/ProtEnte.

The next specification should cover real cryptographic lock/unlock transitions,
coordination with in-flight sync/storage operations, clearing decrypted entry
caches and releasable key buffers, password-wrapped local keys, explicit Windows
lock triggers, clipboard history/cloud exclusion and clearing, migration and
recovery. Review HTML-export escaping separately. Do not weaken recovery to
obtain a superficial memory-cleanup claim, and do not equate added UI prompts
with stronger key protection. Prototype authentication-bound Hello operations
separately if that guarantee is required.

Real account login, Ente passkey callback acceptance, production-vault migration
and memory-extraction resistance were not validated by the packaging baseline.
