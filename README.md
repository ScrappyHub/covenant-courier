# Covenant Courier

Covenant Courier contains the reference implementation of VTP, the Verifiable Transport Protocol.

## VTP v1 quickstart

Primary local development command:

 cd C:\dev\covenant-courier
 .\vtp.ps1 transmit -To node-beta

transmit performs the full local reference flow in one command:

 open session -> send frame -> activate receiver once -> DLP policy gate -> accept/reject -> status

Expected success tokens:

 VTP_SEND_OK
 VTP_POLICY_ALLOW_OK
 COURIER_TRANSPORT_LISTEN_ACCEPT_OK
 VTP_TRANSMIT_OK

## Status

 .\vtp.ps1 status

Status shows queue depth and latest frame IDs.

## DLP proof

 .\vtp.ps1 dlp-test

Expected:

 VTP_DLP_NEGATIVE_REJECT_OK
 VTP_DLP_TEST_OK

## Full green proof

 .\vtp.ps1 full-green

Expected:

 VTP_FULL_GREEN_OK
 VTP_CLI_FULL_GREEN_OK

## Optional dev runtime

 .\vtp.ps1 run-node -NodeId node-beta

This is optional. The primary local user flow is transmit, not a two-terminal workflow.

## Runtime state

Local runtime/proof state is ignored by Git:

 proofs/
 registry/
 runtime/

## Checkpoint tag

 vtp-v1-dev-runtime-dlp
