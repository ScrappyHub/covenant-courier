# Covenant Courier Threat Model v1

## Scope

This threat model covers Covenant Courier as a governed secure message and notification courier product.

VTP is the protocol substrate. Covenant Courier is the product surface that applies identity, policy, message workflows, receipts, and operator controls.

## Protected assets

Protected assets include:

    encrypted message payloads
    runtime wire key envelopes
    sender and recipient identities
    node identities
    policy configurations
    delivery receipts
    rejection reasons
    accepted payload storage
    rejected/quarantine storage
    notification metadata

## Trust boundaries

Current trust boundaries:

    sender CLI boundary
    local runtime boundary
    UDP wire boundary
    receive/ingest boundary
    DLP policy boundary
    accepted/rejected storage boundary
    receipt/audit boundary

Future trust boundaries:

    user account boundary
    organization boundary
    admin policy boundary
    cloud sync boundary
    mobile/device boundary
    vault integration boundary

## Attacker goals

An attacker may try to:

    read payload contents in transit
    modify ciphertext
    modify clear header metadata
    spoof sender or recipient
    replay an old packet
    bypass DLP policy
    cause unauthorized acceptance
    hide a rejection
    forge receipts
    delete or mutate receipt history
    confuse notification metadata with payload data
    force a hidden background runtime

## Current proven defenses

Current VTP proof command:

    .\vtp.ps1 verify

Expected:

    VTP_VERIFY_ALL_OK

Current proven positive lanes:

    local transmit
    DLP allow
    DLP reject
    UDP wire smoke
    UDP wire ingest
    runtime wire key envelope
    readable receipts

Current proven negative lanes:

    BAD_MAGIC
    BAD_AUTH_TAG
    PAYLOAD_HASH_MISMATCH

## Threat: payload exposure in transit

Risk: an observer captures traffic and reads sensitive payload content.

Current mitigation:

    payload body is encrypted
    packet has clear metadata only
    payload hash is exposed for verification, not content

Required hardening:

    replace dev cipher label with locked production cipher suite
    define session key lifecycle
    define key rotation

## Threat: tampered packet

Risk: an attacker changes header, ciphertext, authentication tag, or payload hash.

Current mitigation:

    BAD_MAGIC negative vector
    BAD_AUTH_TAG negative vector
    PAYLOAD_HASH_MISMATCH negative vector

Required hardening:

    add fixed binary header parser
    add malformed JSON negative vectors
    add truncated packet negative vectors

## Threat: DLP bypass

Risk: a forbidden sender role or restricted payload is accepted.

Current mitigation:

    DLP test proves reject path
    receive path gates before accept
    rejection reasons are preserved

Required hardening:

    add UDP ingest DLP-denied negative vector
    lock policy schema
    add classification fields

## Threat: hidden runtime behavior

Risk: the product runs silently or polls unexpectedly.

Current mitigation:

    no scheduled task required
    transmit activates receive once
    run-node is optional
    runtime state is ignored

Required hardening:

    service mode must require explicit install
    service mode must expose status
    service mode must emit activation receipts

## Threat: receipt forgery or loss

Risk: decisions cannot be audited or receipts are forged/mutated.

Current mitigation:

    NDJSON receipts
    readable receipt inspector
    send and accept receipts
    UDP ingest receipts

Required hardening:

    receipt schema lock
    receipt hash chain
    optional signature over receipts
    exportable evidence bundle

## Open risks

Open risks before public product v1:

    dev cipher suite naming still present
    session key envelope is local-dev runtime, not production key exchange
    no fixed binary wire header yet
    no replay protection yet
    no receipt hash chain yet
    no product message schema yet
    no public install/release package yet

## Threat model checkpoint

The current product spec can proceed because VTP now proves positive and negative protocol behavior with a single verification command.
