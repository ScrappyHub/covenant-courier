# Covenant Courier

Covenant Courier is a governed secure message and notification courier system.

It is built around a simple rule:

    no delivery without policy, receipts, and traceability

Covenant Courier is the product layer. VTP is the transport/protocol substrate underneath it.

## What this is

Covenant Courier packages product messages, sends them through VTP, receives and policy-gates frames, emits product-level receipts, and builds a tamper-evident receipt chain.

It is not a general chat app.

It is not only a packet transport.

It is not meant to run invisibly in the background by default.

The current product core is local-first and CLI-driven. Runtime/proof state is intentionally ignored by git.

## Current status

Current checkpoint:

    covenant-courier-receipt-chain-v1-green

Current product core:

    schema-test          GREEN
    prepare              GREEN
    send                 GREEN
    receive              GREEN
    receive-negative     GREEN
    receipts             GREEN
    receipt-chain        GREEN
    verify               GREEN
    VTP substrate         GREEN

Primary product proof:

    .\courier.ps1 verify

Expected:

    COVENANT_COURIER_VERIFY_OK

Protocol substrate proof:

    .\vtp.ps1 verify

Expected:

    VTP_VERIFY_ALL_OK

## Command map

### Product CLI

Show help:

    .\courier.ps1 help

Verify schemas:

    .\courier.ps1 schema-test

Prepare a product message:

    .\courier.ps1 prepare

Send a product message through VTP:

    .\courier.ps1 send

Receive and accept the latest sent product frame:

    .\courier.ps1 receive

Run the product receive negative test:

    .\courier.ps1 receive-negative

Inspect product receipts:

    .\courier.ps1 receipts

Build and verify the product receipt chain:

    .\courier.ps1 receipt-chain

Run the full product proof:

    .\courier.ps1 verify

### VTP protocol CLI

Run VTP verification:

    .\vtp.ps1 verify

Run local transmit:

    .\vtp.ps1 transmit -To node-beta

Run UDP wire smoke:

    .\vtp.ps1 wire-smoke

Run DLP test:

    .\vtp.ps1 dlp-test

Inspect VTP receipts:

    .\vtp.ps1 receipts

## Product flow

The current product flow is:

    prepare product message
    send through VTP
    receive through VTP node policy loop
    accept or reject
    emit product receipt
    chain product receipts
    verify product + VTP substrate

Product receipts link:

    message_id
    frame_id
    payload_sha256
    event_type
    decision
    reason_code

## Receipts

Product receipts are written to:

    proofs\receipts\covenant_courier_product.ndjson

Product receipt chain is written to:

    proofs\receipts\covenant_courier_product.chain.ndjson

Transport receipts are written to:

    proofs\receipts\courier_transport.ndjson

UDP wire ingest receipts are written to:

    proofs\receipts\vtp_udp_wire_ingest.ndjson

The proofs directory is intentionally ignored by git.

## Schemas

Product schemas live in:

    schemas\covenant_courier.message.v1.json
    schemas\covenant_courier.notification.v1.json
    schemas\covenant_courier.policy_decision.v1.json
    schemas\covenant_courier.product_receipt.v1.json

Schema test:

    .\courier.ps1 schema-test

## Docs

Product spec:

    docs\COVENANT_COURIER_PRODUCT_SPEC_V1.md

Threat model:

    docs\COVENANT_COURIER_THREAT_MODEL_V1.md

Release checklist:

    docs\COVENANT_COURIER_RELEASE_CHECKLIST_V1.md

Wire trace model:

    docs\VTP_WIRE_TRACE_MODEL.md

Wire key and receipts:

    docs\VTP_WIRE_KEY_AND_RECEIPTS.md

Roadmap:

    docs\ROADMAP.md

## Runtime and git hygiene

Expected ignored runtime state:

    !! proofs/
    !! registry/
    !! runtime/

These directories contain local proof outputs, sessions, receipts, runtime frames, and generated state.

They should not be committed.

## Current limitations

This is a local CLI product-core checkpoint, not a polished public app release.

Known remaining work:

    fixed binary wire header
    product receive rejection cases
    product receipt schema hardening
    production key/session model
    replay protection
    service mode only if explicit
    UI/workbench
    public release package

## Release posture

Current state:

    product-core green checkpoint

Not yet:

    public v1 release

Before public release, the release checklist and threat model must be reviewed and the command surface must remain simple for non-developer users.
## Release status

Current release status:

    docs\RELEASE_STATUS.md

Final product-core checkpoint tag:

    covenant-courier-product-core-v1-finalized
## Tags

Tag guidance:

    docs\TAGS.md

Authoritative final product-core tag:

    covenant-courier-product-core-v1-finalized-green-fixed
