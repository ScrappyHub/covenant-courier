# Covenant Courier Standalone Specification v1

## Purpose

Covenant Courier is a standalone governed messaging instrument intended to launch
before integration with deeper systems. It provides deterministic compose, lexical
transformation, signature enforcement, verification, and receipts.

## Standalone scope

Courier standalone Tier-0 includes:

1. Compose message object creation
2. Lexical dictionary normalization
3. Tokenization under local dictionary rules
4. Deterministic decode
5. Local trust bootstrap
6. Signature generation
7. Signature verification
8. Verification negatives
9. Pipeline negatives
10. Deterministic receipts and run directories

## Explicit non-scope for standalone Tier-0

The following are not required for standalone launch:

- NeverLost integration
- Watchtower integration
- SoteriaVault integration
- Rebound integration
- NFL export
- Index Lens export

## Core artifacts

- schemas/courier_compose_message_v1.json
- schemas/courier_lexical_dictionary_v1.json
- schemas/courier_lexical_message_v1.json
- scripts/FULL_GREEN_RUNNER_COURIER_STANDALONE_v1.ps1
- proofs/receipts/courier.ndjson
- proofs/receipts/courier_tier0/<timestamp>/

## Standalone success condition

Courier standalone is GREEN when one command deterministically runs:

- verification lane
- signature lane
- lexical dictionary lane
- message pipeline lane
- message pipeline negative suite

and prints:

COURIER_STANDALONE_ALL_GREEN
