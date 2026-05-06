# VTP Wire Key Envelope and Receipt Inspection

This document covers the current local runtime key envelope and receipt inspection commands.

## Runtime wire key envelope

The UDP wire send, listen, and ingest proof paths use a local runtime key envelope.

Command:

    .\vtp.ps1 wire-key-test

Expected:

    VTP_WIRE_KEY_ENVELOPE_SELFTEST_OK
    VTP_WIRE_KEY_TEST_OK

Current local runtime envelope path:

    runtime\wire_keys\session-alpha-beta-001.node-alpha.node-beta.keyenv.json

The runtime key envelope is local state and is not versioned by Git.

## Current proof commands

Run these to prove the current surface:

    .\vtp.ps1 wire-key-test
    .\vtp.ps1 wire-smoke
    .\vtp.ps1 wire-ingest
    .\vtp.ps1 transmit -To node-beta
    .\vtp.ps1 dlp-test
    .\vtp.ps1 full-green

## Receipt inspection

Command:

    .\vtp.ps1 receipts

The receipt inspector reads:

    proofs\receipts\courier_transport.ndjson
    proofs\receipts\vtp_udp_wire_ingest.ndjson

Expected:

    VTP_RECEIPTS_LATEST_OK

## Notes

The latest rejected reason shown by status may reference historical runtime state. Current proof validity is established by fresh success tokens from the proof commands.
