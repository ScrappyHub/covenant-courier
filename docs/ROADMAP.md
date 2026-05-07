# Covenant Courier Roadmap

## Current checkpoint

Current tag:

    covenant-courier-receipt-chain-v1-green

Current proof command:

    .\courier.ps1 verify

Expected:

    COVENANT_COURIER_VERIFY_OK

## Completed product core

The following product core is now implemented and proven:

    schema-test
    prepare
    send
    receive
    receive-negative
    receipts
    receipt-chain
    verify

The VTP substrate is also proven through:

    .\vtp.ps1 verify

Expected:

    VTP_VERIFY_ALL_OK

## Near-term hardening

### 1. Product receive rejection vectors

Add product-layer negative cases beyond "no unaccepted sent frame":

    rejected frame produces product rejected receipt
    missing product receipt file behavior
    malformed product receipt line
    bad payload hash
    unknown node target
    stale/replayed sent frame

### 2. Receipt chain verification mode

Current receipt-chain command builds and verifies a chain from the product receipt ledger.

Next:

    add verify-only mode
    detect tampered product receipt line
    detect missing chain entry
    detect reordered receipt
    emit stable negative reason tokens

### 3. Wire header spec

Lock a fixed header for VTP traffic so network tools can recognize traffic without exposing encrypted payloads.

Target visible metadata:

    protocol magic
    version
    frame id or frame hash
    cipher suite
    payload hash
    timestamp or nonce field

Payload remains encrypted.

### 4. Key/session hardening

Move from dev session assumptions toward a documented production session model.

Needed:

    session identity
    recipient node identity
    key rotation
    replay protection
    expiration
    revocation

### 5. Product release packaging

Prepare a public-safe release package.

Needed:

    clean README
    release checklist complete
    threat model reviewed
    command examples verified
    no runtime/proof files committed
    version tag
    archive bundle

## Medium-term product surface

### CLI

Desired command surface:

    courier help
    courier verify
    courier prepare
    courier send
    courier receive
    courier receipts
    courier inspect
    courier export

### Workbench

A future workbench should show:

    message flow
    send status
    receive status
    policy decision
    receipt trail
    receipt chain
    VTP substrate health

### Service mode

Service mode should remain optional.

Rules:

    no hidden always-on runtime
    no scheduled task by default
    explicit install
    visible status
    activation receipts
    easy stop/uninstall

## Public release gate

A public release candidate requires:

    COVENANT_COURIER_VERIFY_OK
    VTP_VERIFY_ALL_OK
    product docs present
    threat model present
    release checklist present
    no untracked source files
    runtime/proof state ignored
    known limitations documented
    version tag pushed
