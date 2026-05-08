# Covenant Courier FAQ

## What is Covenant Courier?

Covenant Courier is a local CLI preview for governed message transport, verification, and receipt-producing delivery flows.

## Is this a finished app?

No. This release is a developer preview of the local CLI product core.

## What should I download?

Use:

    covenant-courier-v0.1.5-product-core

Do not use v0.1.0 through v0.1.4. Those release assets are superseded.

## How do I know it works?

After unzipping, run:

    .\courier.ps1 verify

Expected final token:

    COVENANT_COURIER_VERIFY_OK

## Why does it create proofs, registry, and runtime folders?

Those folders are generated local state.

They hold local receipts, runtime messages, demo registry files, and proof outputs created during verification.

## Is this a hosted service?

No. This preview runs locally.

## Is this production key management?

No. This release includes public allowed-signers material and local demo trust sufficient for the preview verification flow. Production key management is future work.

## What should developers run during normal work?

Use the fast smoke test:

    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\scripts\_smoke_covenant_courier_release_fast_v1.ps1 -RepoRoot .

Expected:

    COVENANT_COURIER_RELEASE_FAST_SMOKE_OK

## What should maintainers run before publishing a release?

Run the full clean extracted ZIP smoke and confirm:

    COVENANT_COURIER_RELEASE_ZIP_SMOKE_OK
