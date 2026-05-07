# Covenant Courier Tags

## Authoritative product-core final tag

Use this tag as the current verified product-core checkpoint:

    covenant-courier-product-core-v1-finalized-green-fixed

This tag supersedes the earlier finalization tags because it was created after:

    VTP_PARSE_OK
    VTP_TRANSMIT_OK
    COVENANT_COURIER_VERIFY_OK
    VTP_VERIFY_ALL_OK

## Superseded tags

The following tags exist but should not be treated as the authoritative final product-core checkpoint:

    covenant-courier-product-core-v1-finalized
    covenant-courier-product-core-v1-finalized-green

Reason:

    These were pushed before the VTP transmit count-check issue was fully repaired and re-proven.

## Current trusted checkpoint

Trusted final checkpoint:

    covenant-courier-product-core-v1-finalized-green-fixed

Expected repo state after checkout and local verify:

    .\courier.ps1 verify
    COVENANT_COURIER_VERIFY_OK

Expected ignored runtime state:

    !! proofs/
    !! registry/
    !! runtime/
