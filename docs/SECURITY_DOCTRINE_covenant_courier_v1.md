# Covenant Courier Security Doctrine v1

## Purpose

This document locks the standalone security doctrine for Covenant Courier.

Covenant Courier is a standalone, identity-bound, receipt-bearing governed
communication instrument. It must remain secure by design through narrow surface,
strict trust enforcement, lexical governance, signature verification, deterministic
receipts, and deterministic failure behavior.

Courier does not depend on deeper systems for standalone correctness.

---

## 1. Standalone-first law

Courier must stand completely alone before any deeper integration work.

This means standalone correctness must not depend on:
- NeverLost
- WatchTower
- SoteriaVault
- Rebound
- NFL
- Index Lens
- any external directory, identity plane, or hosted relay

Integrations may come later, but they are not required for standalone operation.

---

## 2. No public-mail dependency law

Courier must not require public mail infrastructure.

Courier must not depend on:
- SMTP
- IMAP
- POP
- MX routing
- public mailbox discovery
- webmail-compatible service exposure
- public mail metadata patterns

Courier is not email. Courier must not drift toward behaving like email.

---

## 3. Narrow-surface law

Courier security must rely on minimal exposed surface.

Courier transport endpoints, listeners, and operator commands must expose only the
minimum required functionality. Any surface added must be justified by standalone
operator need and must be bounded by deterministic verification and receipt rules.

The goal is not “many features behind auth.”
The goal is “almost no useful surface before trust is established.”

---

## 4. Identity-before-utility law

Courier must provide no meaningful value before trust validation.

Before identity and trust are established, Courier must not expose:
- message content
- dictionary content
- trust material
- routing metadata with operational value
- semantic context
- privileged pipeline outputs

Meaningful operations must be attributable to an identity, trust state, or explicit
operator action.

---

## 5. Signature-and-trust law

Courier message usefulness must depend on valid trust material.

All meaningful standalone message handling must remain compatible with:
- local trust bootstrap
- allowed_signers
- identity-bound signatures
- deterministic signature verification
- deterministic failure on trust mismatch

If trust is absent, wrong, or tampered, Courier must fail explicitly.

---

## 6. Lexical-governance law

Courier is not only an encryption surface. It is a lexical-governed communication instrument.

Lexical structures must remain:
- deterministic
- dictionary-bound
- context-aware
- longest-match tokenized
- auditable through receipts and selftests

Courier lexical handling must not drift into arbitrary or nondeterministic replacement behavior.

---

## 7. Tamper-evident access law

Courier security is not based on magical invisibility.

Courier security is based on this rule:

If a meaningful artifact is accessed, one of two things must be true:
1. the access produced no useful value
2. or the access path, trust state, mutation, or verification result becomes provable

Courier must prefer tamper-evidence and controlled usefulness over claims of perfect invisibility.

---

## 8. Dedicated-port law

If Courier later adds active transport listeners, they must obey dedicated-port discipline.

Dedicated-port discipline means:
- Courier listeners use dedicated protocol-specific ports only
- no accidental reuse of public mail ports
- no SMTP/IMAP/POP compatibility
- no useful response before trust gate
- no fallback behavior that increases exposure
- malformed input handling must be explicit and deterministic
- transport boundary actions must be receipt-capable where applicable

A dedicated port alone is not enough.
A dedicated port without strict admission control is not secure.

---

## 9. Deterministic-failure law

Courier must fail deterministically.

Missing fields, trust mismatch, signature mismatch, lexical mismatch, pipeline mismatch,
and transport mismatch must produce explicit and stable failure tokens.

Courier must not crash on malformed or incomplete input when classification is possible.
It must classify bad input deterministically.

---

## 10. Receipt law

Meaningful standalone operations must remain evidence-bearing.

Courier should emit deterministic receipts for:
- compose
- trust bootstrap
- sign
- verify
- lexical build
- tokenize
- decode
- pipeline runs
- negative selftests
- future transport-boundary actions

Receipts are part of the security posture, not optional logging fluff.

---

## 11. Offline-capable law

Courier standalone must remain usable in constrained environments.

Courier should preserve the ability to operate:
- offline
- on isolated networks
- on dedicated nodes
- without browser dependency
- without UI dependency
- without hosted service dependency

The CLI and deterministic runners are the canonical operator surface before any UI work.

---

## 12. Anti-drift law

Courier must not drift into:
- a generic chat app
- a public messaging service
- a social communication product
- an email clone
- a convenience-first hosted surface that weakens trust and verification

Courier remains a governed communication instrument first.

---

## 13. Standalone launch definition

Courier standalone launch is achieved when:
- standalone all-green runner is deterministic
- CLI selftest is green
- CLI negative suite is green
- lexical dictionary selftest is green
- message pipeline selftest is green
- message pipeline negative suite is green
- local trust bootstrap and signature lane are green
- docs freeze the standalone doctrine clearly

Standalone launch does not require ecosystem integration.

---

## 14. Operator principle

Courier should remain operable by disciplined command execution.

UI is optional.
Proof is not optional.
Determinism is not optional.
Trust enforcement is not optional.
Surface minimization is not optional.

---

## 15. Final doctrine statement

Covenant Courier is a standalone governed messaging instrument whose security comes
from narrow surface, identity-before-utility, lexical governance, signature enforcement,
deterministic receipts, and deterministic failure behavior.

Courier must stand on these laws before it is allowed to integrate with deeper systems.
