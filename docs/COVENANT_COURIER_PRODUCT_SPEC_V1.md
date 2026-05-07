# Covenant Courier Product Spec v1

## Product identity

Covenant Courier is a governed secure message and notification courier system.

It is not a general chat app.
It is not only a packet transport.
It is not a passive inbox.

Covenant Courier provides controlled delivery between identified senders, recipients, devices, nodes, services, and organizations. It packages messages into verifiable transport frames, applies policy before acceptance, encrypts payloads in transit, emits receipts, and preserves traceable non-secret delivery metadata.

## Engine boundary

VTP is the transport/protocol engine underneath Covenant Courier.

Covenant Courier is the product layer:

    users
    organizations
    recipients
    policies
    message workflows
    notification UX
    admin controls
    audits

VTP is the protocol layer:

    frame
    send
    receive
    verify
    decrypt
    DLP gate
    accept/reject
    receipt

## Current proven VTP substrate

The current VTP proof command is:

    .\vtp.ps1 verify

Expected:

    VTP_VERIFY_ALL_OK

The green proof surface includes:

    wire-key-test
    wire-smoke
    wire-ingest
    wire-negative
    transmit
    dlp-test
    full-green
    receipts

Current checkpoint tag:

    vtp-v1-wire-negative-verify-green

## Product principles

1. No delivery without policy.
2. No payload exposure in transit.
3. No silent acceptance without receipts.
4. No hidden always-on runtime by default.
5. No untraceable routing.
6. No acceptance of malformed or tampered packets.
7. No conflation of notification metadata with encrypted message payload.

## Core user-facing concept

A sender prepares a governed message for an identified recipient.

Covenant Courier determines whether the sender is allowed to send, whether the recipient is allowed to receive, what policy applies to the payload, what notification may be exposed, what encrypted payload is transported, and what receipts are emitted.

## Message object model

A Covenant Courier message is composed of:

    message_id
    sender_identity
    recipient_identity
    sender_node_id
    recipient_node_id
    organization_id
    session_id
    policy_profile
    notification_preview
    encrypted_payload
    payload_sha256
    frame_id
    transport_receipts
    decision_receipts

## Payload and notification split

Payload and notification are separate.

Notification plane:

    minimal
    non-secret
    policy-shaped
    safe to display
    optionally generic

Payload plane:

    encrypted
    authenticated
    recipient-gated
    DLP-inspected before acceptance
    receipt-linked

## Delivery lifecycle

The canonical delivery lifecycle is:

    prepare message
    resolve recipient
    open or select session
    apply sender policy
    package VTP frame
    encrypt payload
    emit send receipt
    transmit
    receive
    verify header/authentication
    decrypt if authorized
    run DLP policy gate
    accept or reject
    emit decision receipt
    expose notification/result

## DLP and data protection role

Covenant Courier can serve as a DLP enforcement channel for data in transit and controlled intake.

Data in transit:

    classify before send
    encrypt payload
    expose traceable non-secret metadata
    verify on receipt
    deny tampered packets
    deny policy-forbidden payloads
    receipt every decision

Data at rest:

    store accepted payloads in controlled locations
    store rejected payloads separately
    preserve reason codes
    keep receipts append-only
    support later vault integration

## Policy decisions

The product policy layer must support at least:

    allow
    reject
    quarantine
    require approval
    redact notification
    require stronger session
    require recipient verification
    require retention rule

## Required product surfaces

### Sender surface

The sender can:

    prepare message
    select recipient
    see policy status
    transmit
    view send receipt
    view delivery decision

### Recipient surface

The recipient can:

    see safe notification
    unlock/decrypt authorized payload
    see sender identity
    see receipt trail
    report or reject

### Admin surface

The admin can:

    define nodes
    define recipient groups
    define allowed senders
    define DLP policies
    inspect receipts
    export evidence
    revoke sessions

## Runtime mode

The default product behavior must be explicit-run and silent at rest.

Default:

    no background loop
    no polling
    no scheduled task
    activate on transmit or explicit receive

Optional mode:

    service receive
    bounded listener
    visible admin toggle
    receipt every activation

## Wire visibility

Network inspection tools should be able to identify Covenant Courier/VTP traffic without exposing payload contents.

The intended wire contract:

    fixed header
    visible protocol magic
    visible version
    visible frame id or frame hash
    visible cipher suite
    visible payload hash
    encrypted body
    authenticated header/body

## Product milestones

### M1: Product spec lock

    product spec
    threat model
    command docs
    release checklist

### M2: Message object schema

    message schema
    notification schema
    policy schema
    receipt schema

### M3: Wire header lock

    fixed header bytes
    Wireshark-friendly inspection
    parser
    negative header vectors

### M4: Product CLI

    courier prepare
    courier send
    courier receive
    courier inspect
    courier receipts
    courier verify

### M5: UI/workbench

    sender view
    recipient view
    admin policy view
    receipt inspector
    node/session view

## Definition of done for product v1

Product v1 is complete when:

    one command verifies VTP
    one command verifies product schemas
    one command sends a product message
    one command receives and gates a product message
    positive and negative vectors pass
    receipts are readable
    docs are public-safe
    runtime is silent by default
    no runtime/proof state is versioned
