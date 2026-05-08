# Covenant Courier Quickstart

Covenant Courier is a local CLI preview for governed message transport, local verification, and receipt-producing delivery flows.

Current release:

    covenant-courier-v0.1.5-product-core

GitHub release:

    https://github.com/ScrappyHub/covenant-courier/releases/tag/covenant-courier-v0.1.5-product-core

## Requirements

Windows PowerShell 5.1 or later.

OpenSSH `ssh-keygen.exe` is required for signature verification. On supported Windows systems it is normally available at:

    C:\Windows\System32\OpenSSH\ssh-keygen.exe

## Download

Download the ZIP from the current GitHub release.

Unzip it.

Open PowerShell inside the extracted `covenant-courier` folder.

## Verify the release

Run:

    .\courier.ps1 verify

Expected final token:

    COVENANT_COURIER_VERIFY_OK

## Fast local smoke test

For quick local checks, run:

    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\scripts\_smoke_covenant_courier_release_fast_v1.ps1 -RepoRoot .

Expected final token:

    COVENANT_COURIER_RELEASE_FAST_SMOKE_OK

## What the verify command proves

The verify command checks the current local CLI product core:

    schemas
    message prepare
    send
    receive-negative
    receive
    receipt inspection
    receipt-chain
    VTP verification

## Runtime folders

The following folders are created locally during verification:

    proofs/
    registry/
    runtime/

These are local proof, registry, and runtime folders. They should not be committed as source.

## Release status

This release is a developer preview of the local CLI product core.

It is not a polished installer, hosted service, or production key-management system.
