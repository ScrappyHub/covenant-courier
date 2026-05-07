# Covenant Courier Release Status

## Current checkpoint

Covenant Courier is at a stable product-core checkpoint.

Current finalization tag:

    covenant-courier-product-core-v1-finalized

Latest prior green checkpoint:

    covenant-courier-product-cleanup-v1-green

## Product core status

The following commands are implemented and verified:

    .\courier.ps1 schema-test
    .\courier.ps1 prepare
    .\courier.ps1 send
    .\courier.ps1 receive
    .\courier.ps1 receive-negative
    .\courier.ps1 receipts
    .\courier.ps1 receipt-chain
    .\courier.ps1 verify

Primary proof command:

    .\courier.ps1 verify

Expected token:

    COVENANT_COURIER_VERIFY_OK

VTP substrate proof command:

    .\vtp.ps1 verify

Expected token:

    VTP_VERIFY_ALL_OK

## What is finalized

This checkpoint finalizes the local CLI product core.

Finalized:

    product schemas
    product message prepare
    product send
    product receive
    product receive negative test
    product receipt inspection
    product receipt hash chain
    product verification command
    VTP substrate verification
    README product command map
    roadmap
    release status document

## What is not finalized

This is not yet a polished public v1 application release.

Not finalized:

    installer
    workbench UI
    fixed binary wire header
    production key/session model
    replay protection
    service mode
    product rejection receipt vectors
    release archive

## Runtime state

The following directories are local runtime/proof surfaces and must remain ignored:

    proofs/
    registry/
    runtime/

Expected git ignored state:

    !! proofs/
    !! registry/
    !! runtime/

## Finalization rule

A checkpoint may be treated as product-core finalized only when:

    .\courier.ps1 verify

prints:

    COVENANT_COURIER_VERIFY_OK

and git status shows no source changes other than ignored runtime/proof directories.
