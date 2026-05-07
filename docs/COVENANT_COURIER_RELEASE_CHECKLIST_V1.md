# Covenant Courier Release Checklist v1

## Purpose

This checklist defines what must be true before Covenant Courier is treated as a public product release.

## Current proof command

Run:

    .\vtp.ps1 verify

Required:

    VTP_VERIFY_ALL_OK

## Product docs

Required docs:

    docs\COVENANT_COURIER_PRODUCT_SPEC_V1.md
    docs\COVENANT_COURIER_THREAT_MODEL_V1.md
    docs\COVENANT_COURIER_RELEASE_CHECKLIST_V1.md
    docs\VTP_WIRE_TRACE_MODEL.md
    docs\VTP_WIRE_KEY_AND_RECEIPTS.md

## Git hygiene

Before release:

    git status --short --ignored

Allowed ignored state:

    !! proofs/
    !! registry/
    !! runtime/

No untracked source files may remain.

## Required VTP lanes

The verify command must include:

    wire-key-test
    wire-smoke
    wire-ingest
    wire-negative
    transmit
    dlp-test
    full-green
    receipts

## Required negative vectors

Required current negative vectors:

    BAD_MAGIC
    BAD_AUTH_TAG
    PAYLOAD_HASH_MISMATCH

Required future negative vectors:

    DLP_DENIED_OVER_UDP
    REPLAYED_PACKET
    EXPIRED_SESSION
    UNKNOWN_RECIPIENT
    MALFORMED_HEADER
    TRUNCATED_PACKET

## Runtime rules

Release runtime rules:

    no hidden always-on runtime
    no scheduled task by default
    no background polling by default
    explicit transmit activates receive once
    optional service mode must be explicitly installed

## Security rules

Before public release:

    production cipher suite must be named
    key exchange/session model must be documented
    replay protection must be defined
    receipt hash chain must be defined
    product message schema must be locked

## Product commands

Future product CLI should expose:

    courier prepare
    courier send
    courier receive
    courier inspect
    courier receipts
    courier verify

Current protocol CLI:

    .\vtp.ps1 verify

## Release gate

A release candidate may be tagged only when:

    VTP_VERIFY_ALL_OK is present
    product docs are present
    runtime/proof state is not versioned
    no untracked source files remain
    threat model open risks are known
    release version is documented

## Current release state

Current state is product-spec checkpoint, not public v1 release.

The VTP substrate is proven enough to continue Covenant Courier product buildout.
