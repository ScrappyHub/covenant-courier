# Covenant Courier

Covenant Courier contains the reference implementation of VTP, the Verifiable Transport Protocol.

## VTP v1 quickstart

Primary local development command:

    cd C:\dev\covenant-courier
    .\vtp.ps1 transmit -To node-beta

transmit performs the full local reference flow in one command:

    open session -> send frame -> activate receiver once -> DLP policy gate -> accept/reject -> status

Expected success tokens:

    VTP_SEND_OK
    VTP_POLICY_ALLOW_OK
    COURIER_TRANSPORT_LISTEN_ACCEPT_OK
    VTP_TRANSMIT_OK

## Status

    .\vtp.ps1 status

Status shows queue depth and latest frame IDs.

## DLP proof

    .\vtp.ps1 dlp-test

Expected:

    VTP_DLP_NEGATIVE_REJECT_OK
    VTP_DLP_TEST_OK

## Full green proof

    .\vtp.ps1 full-green

Expected:

    VTP_FULL_GREEN_OK
    VTP_CLI_FULL_GREEN_OK

## UDP wire smoke proof

    .\vtp.ps1 wire-smoke

Expected:

    VTP_UDP_WIRE_SEND_OK
    VTP_UDP_WIRE_LISTEN_OK
    VTP_UDP_WIRE_SELFTEST_OK
    VTP_WIRE_SMOKE_OK

Wireshark display filter:

    udp.port == 47731

## UDP wire ingest proof

    .\vtp.ps1 wire-ingest

wire-ingest proves the real receive-side shape:

    UDP packet -> verify/decrypt -> materialize frame -> DLP policy gate -> accept/reject -> receipt

Expected:

    VTP_UDP_WIRE_INGEST_ACCEPT_OK
    VTP_UDP_WIRE_INGEST_RECEIPT_OK
    VTP_UDP_WIRE_INGEST_SELFTEST_OK
    VTP_WIRE_INGEST_OK

The UDP wire ingest receipt is written to:

    proofs\receipts\vtp_udp_wire_ingest.ndjson

## Optional dev runtime

    .\vtp.ps1 run-node -NodeId node-beta

This is optional. The primary local user flow is transmit, not a two-terminal workflow.

## Runtime state

Local runtime/proof state is ignored by Git:

    proofs/
    registry/
    runtime/

## Checkpoint tags

    vtp-v1-dev-runtime-dlp
    vtp-v1-udp-wire-smoke
    vtp-v1-queue-claim-wire-green
    vtp-v1-udp-wire-ingest-green

## Wire key envelope and receipts

See:

    docs\VTP_WIRE_KEY_AND_RECEIPTS.md

Commands:

    .\vtp.ps1 wire-key-test
    .\vtp.ps1 receipts

## Product spec

Covenant Courier product definition:

    docs\COVENANT_COURIER_PRODUCT_SPEC_V1.md

VTP remains the proven protocol substrate. Covenant Courier is the product layer on top.

## Product safety docs

Product threat model:

    docs\COVENANT_COURIER_THREAT_MODEL_V1.md

Release checklist:

    docs\COVENANT_COURIER_RELEASE_CHECKLIST_V1.md

## Product schema test

Run:

    .\courier.ps1 schema-test

Expected:

    COVENANT_COURIER_SCHEMA_TEST_OK
## Product message prepare

Run:

    .\courier.ps1 prepare

Expected:

    COVENANT_COURIER_PREPARE_OK
## Product message send

Run:

    .\courier.ps1 send

Expected:

    COVENANT_COURIER_SEND_OK

Product receipts:

    proofs\receipts\covenant_courier_product.ndjson
## Product receipt inspection

Run:

    .\courier.ps1 receipts

Expected:

    COVENANT_COURIER_RECEIPTS_OK
## Product verification

Run:

    .\courier.ps1 verify

Expected:

    COVENANT_COURIER_VERIFY_OK
## Product message receive

Run:

    .\courier.ps1 receive

Expected:

    COVENANT_COURIER_RECEIVE_OK
## Product receive negative test

Run:

    .\courier.ps1 receive-negative

Expected:

    COVENANT_COURIER_RECEIVE_NEGATIVE_OK
## Product receipt chain

Run:

    .\courier.ps1 receipt-chain

Expected:

    COVENANT_COURIER_RECEIPT_CHAIN_OK
