# VTP v1 Conformance

An implementation is VTP v1 conformant only if it emits the required tokens and produces a deterministic conformance run bundle.

## Required final token

VTP_CONFORMANCE_V1_PASS

## Required component tokens

VTP_TIER0_FULL_GREEN
VTP_TRUST_BOOTSTRAP_SELFTEST_OK
VTP_SECURE_JOIN_ENCRYPTED_SELFTEST_OK
VTP_SECURE_CRYPTO_NEGATIVE_SELFTEST_OK
VTP_REPLAY_GUARD_SELFTEST_OK
VTP_SESSION_KEY_UPGRADE_SELFTEST_OK
VTP_OUTBOX_PERSISTENCE_SELFTEST_OK
VTP_NODE_LOOP_SELFTEST_OK
VTP_SECURE_FULL_GREEN

## Required evidence bundle

proofs/conformance/vtp_conformance_<UTC>/
  stdout.log
  stderr.log
  meta.json
  sha256sums.txt

## Pass rule

PASS means:

1. Every component runner exits 0.
2. Every required token is present.
3. meta.json records result = PASS.
4. sha256sums.txt is written last and hashes the final evidence files.

## Fail rule

Any missing token, nonzero step exit, parse failure, or evidence hash mismatch is non-conformant.

## Reference implementation

Courier is the current VTP v1 reference implementation.
