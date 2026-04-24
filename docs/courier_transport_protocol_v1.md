# Covenant Courier Transport Protocol v1

## Purpose

This document defines the first standalone Courier transport surface.

Transport v1 is a local drop/inbox protocol for moving signed Courier message artifacts
between isolated nodes or controlled operator surfaces without relying on public mail
infrastructure.

## Core law

Transport v1 is standalone and doctrine-compliant:
- no SMTP/IMAP/POP
- no public mail dependency
- no useful content before trust and verification
- deterministic receipt-bearing ingestion
- deterministic failure tokens
- dedicated protocol artifact only

## Transport frame

A transport frame is a canonical JSON object containing:
- schema
- frame_id
- created_utc
- sender_identity
- recipient_identity
- message_rel
- signature_rel
- payload_sha256

The frame points to a message artifact and its signature inside a frame directory.

## Directory layout

frame_root/
- frame.json
- payload/
  - message.tokenized.json
  - message.tokenized.json.sig

## Listener contract

The listener:
1. loads frame.json
2. validates required fields
3. validates referenced files exist
4. verifies payload hash
5. verifies Courier signature
6. writes accepted frame into accepted/
7. writes rejected frame into rejected/ on failure
8. appends deterministic receipt

## Security posture

Transport v1 is not secure because it is invisible.
It is secure because:
- artifacts are signed
- payload hash is bound in frame.json
- ingest is deterministic
- failures classify explicitly
- admitted content remains attributable

## Success token

COURIER_TRANSPORT_POSITIVE_SELFTEST_OK

## Negative token family

COURIER_TRANSPORT_FAIL:*
