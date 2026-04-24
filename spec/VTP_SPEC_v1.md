# Verifiable Transport Protocol (VTP) v1

## Status
Spec Freeze Candidate

## Purpose
VTP is a transport protocol for signed, verifiable, policy-bound frame delivery between nodes, with deterministic receipts and non-ambiguous enforcement surfaces.

## VTP is
- a transport and enforcement protocol
- a node-to-node frame delivery law layer
- a verifiable receipt-producing substrate
- a referenceable standard candidate

## VTP is not
- a chat application
- a social feed
- an AI agent framework
- a business workflow engine
- a UI standard

## Core Objects
- transport frame
- node registry
- network registry
- session registry
- transport receipt

## Required Protocol Laws
1. A frame must contain a stable frame_id.
2. A frame must bind sender_identity, sender_node_id, recipient_node_id, network_id, session_id, and sender_role.
3. A frame payload must be signed.
4. Signature verification is mandatory before acceptance.
5. Verification is non-mutating.
6. Sender node must exist.
7. Recipient node must exist.
8. Network must exist.
9. Session must exist and be open.
10. Sender and recipient must both be allowed on the network.
11. Session role must match sender role.
12. Replay of an existing frame_id must reject.
13. Send, accept, and reject must emit append-only receipts.

## Reference Names
- Protocol: VTP
- Reference implementation: Courier Reference Engine
- Reference operator UI: Courier Workbench

## Required Receipts
- vtp.transport.send.v1
- vtp.transport.accept.v1
- vtp.transport.reject.v1

## Receipt Law
Receipts are append-only NDJSON, UTF-8 without BOM, LF normalized, one canonical JSON object per line.

## Registries
### Node Registry
Defines node identity, role, principal, allowed namespaces, and status.

### Network Registry
Defines network identity, transport kind, listener port, visibility, status, and allowed_nodes.

### Session Registry
Defines sender_node_id, recipient_node_id, network_id, session_role, transport_namespace, opened_utc, closed_utc, and status.

## Transport/Application Boundary
VTP handles delivery law only.
Application semantics, messaging semantics, encryption semantics, AI coordination semantics, and UI semantics are layered above VTP.

## Versioning Rule
Any incompatible change to object shape or enforcement law requires v2.
