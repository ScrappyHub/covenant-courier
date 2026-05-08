# Covenant Courier Distribution

## Current distributable release

Use:

    covenant-courier-v0.1.5-product-core

GitHub release:

    https://github.com/ScrappyHub/covenant-courier/releases/tag/covenant-courier-v0.1.5-product-core

ZIP SHA-256:

    a9db880a10df925880ea72862d68ea18b16b7481677825d82455bd9dce3369ab

## What to download

Download:

    covenant-courier-v0.1.5-product-core.zip

Do not use earlier release ZIPs.

## Superseded release attempts

The following releases exist but are superseded:

    covenant-courier-v0.1.0-product-core
    covenant-courier-v0.1.1-product-core
    covenant-courier-v0.1.2-product-core
    covenant-courier-v0.1.3-product-core
    covenant-courier-v0.1.4-product-core

Reason:

    They were uploaded before clean extracted ZIP verification fully passed.

## How to verify after download

Unzip the release.

Open PowerShell inside the extracted covenant-courier folder.

Run:

    .\courier.ps1 verify

Expected final token:

    COVENANT_COURIER_VERIFY_OK

## Fast local proof

For development work, run:

    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\scripts\_smoke_covenant_courier_release_fast_v1.ps1 -RepoRoot .

Expected final token:

    COVENANT_COURIER_RELEASE_FAST_SMOKE_OK

## Full release proof

The release was proven by clean extracted ZIP smoke.

Expected release proof tokens:

    VTP_VERIFY_ALL_OK
    COVENANT_COURIER_VERIFY_OK
    COVENANT_COURIER_RELEASE_ZIP_SMOKE_OK

## Runtime folders

The following folders are generated locally and should not be committed or shared as source:

    proofs/
    registry/
    runtime/
    release/

They are local runtime, receipt, proof, and build-output surfaces.

## Release posture

Covenant Courier v0.1.5 product-core is a CLI developer preview.

It is not yet:

    a polished installer
    a background service
    a public app UI
    a hosted SaaS
    a production key-management system

It is:

    a clean-ZIP-smoke-gated local CLI product-core preview
    a governed message transport proof
    a receipt-producing product core
    a VTP-backed verification surface
