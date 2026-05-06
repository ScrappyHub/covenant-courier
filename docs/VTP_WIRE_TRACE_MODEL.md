# VTP Wire Trace Model

VTP has two transport modes:

1. Local filesystem reference mode.
2. UDP wire smoke adapter mode.

The filesystem reference implementation uses drops under runtime/. Wireshark cannot observe that mode as network traffic.

The UDP wire smoke adapter emits actual localhost UDP traffic on port 47731.

## Wireshark

Start capture on the loopback adapter, then run:

    .\vtp.ps1 wire-smoke

Use this display filter:

    udp.port == 47731

## Clear trace header

A packet capture tool should be able to see non-secret metadata:

    magic: VTP1
    version: 1
    frame_id: frame-...
    session_id_hash: sha256(...)
    sender_node_id_hash: sha256(...)
    recipient_node_id_hash: sha256(...)
    network_id_hash: sha256(...)
    payload_sha256: sha256(...)
    cipher_suite: AES-CBC-256-HMAC-SHA256-DEV
    policy_mode: enforce

## Encrypted body

The payload body is encrypted and authenticated.

Current smoke adapter shape:

    header = clear, traceable, non-secret
    body = encrypted payload
    aad = canonical header bytes
    tag = authentication tag over header + ciphertext

Wireshark can identify VTP traffic and display packet/session metadata without exposing payload contents.

## DLP relationship

DLP policy gates operate before accept.

In wire mode, the node should:

    receive packet -> verify header/body integrity -> decrypt if authorized -> run DLP policy -> accept/reject -> receipt

## Current checkpoint

The current local/wire proof surface is:

    .\vtp.ps1 transmit -To node-beta
    .\vtp.ps1 dlp-test
    .\vtp.ps1 full-green
    .\vtp.ps1 wire-smoke
