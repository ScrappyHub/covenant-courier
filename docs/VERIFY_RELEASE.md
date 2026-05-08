# Verify Covenant Courier Release

## Current release

Use:

    covenant-courier-v0.1.5-product-core

## Verify ZIP hash

Expected SHA-256:

    a9db880a10df925880ea72862d68ea18b16b7481677825d82455bd9dce3369ab

PowerShell command:

    Get-FileHash .\covenant-courier-v0.1.5-product-core.zip -Algorithm SHA256

The hash should match the expected SHA-256 above.

## Verify after unzip

Open PowerShell inside the extracted `covenant-courier` folder.

Run:

    .\courier.ps1 verify

Expected final token:

    COVENANT_COURIER_VERIFY_OK

## Fast check

Run:

    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\scripts\_smoke_covenant_courier_release_fast_v1.ps1 -RepoRoot .

Expected final token:

    COVENANT_COURIER_RELEASE_FAST_SMOKE_OK

## Expected generated folders

Verification creates local folders:

    proofs/
    registry/
    runtime/

These folders are expected. They are local generated state.

## Troubleshooting

If PowerShell blocks script execution, run from a PowerShell prompt using:

    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\courier.ps1 verify

If signature verification fails, confirm that OpenSSH `ssh-keygen.exe` exists at:

    C:\Windows\System32\OpenSSH\ssh-keygen.exe
