# VTP Wire Trace Model

VTP has two transport modes:

1. Local filesystem reference mode.
2. Future wire adapter mode.

The current reference implementation uses filesystem drops under runtime/, so Wireshark cannot observe it as network traffic.

For Wireshark visibility, VTP needs a TCP or UDP wire adapter.

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
 cipher_suite: ...
 policy_mode: enforce

## Encrypted body

The payload body must be encrypted and authenticated.

Recommended direction:

 header = clear, traceable, non-secret
 body = encrypted payload
 aad = canonical header bytes
 tag = authentication tag over header + ciphertext

Wireshark can identify VTP traffic and display frame/session metadata without exposing payload contents.

## DLP relationship

DLP policy gates operate before accept.

In wire mode, the node should:

 receive packet -> verify header/body integrity -> decrypt if authorized -> run DLP policy -> accept/reject -> receipt

## Current checkpoint

The filesystem reference mode is currently proven through:

 .\vtp.ps1 transmit -To node-beta
 .\vtp.ps1 dlp-test
 .\vtp.ps1 full-green
