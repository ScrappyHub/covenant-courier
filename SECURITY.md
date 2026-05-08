# Security Policy

## Supported release

Current supported preview release:

    covenant-courier-v0.1.5-product-core

Earlier v0.1.0 through v0.1.4 release assets are superseded.

## Reporting security issues

Please report security issues privately.

Do not open a public issue with exploit details, private keys, tokens, or sensitive operational data.

## Sensitive files

Do not commit or publish:

    private keys
    API tokens
    webhook secrets
    service role keys
    local runtime outputs
    local proof receipts that contain sensitive operational context

Generated local folders should remain ignored:

    proofs/
    registry/
    runtime/
    release/

## Preview limitations

This release is a local CLI developer preview.

It is not a production key-management system, hosted service, or polished end-user application.

## Signature verification

Covenant Courier uses OpenSSH signature verification for the local preview flow.

The release includes public allowed-signers material for verifying bundled preview test vectors.

Do not treat preview trust material as production identity infrastructure.
