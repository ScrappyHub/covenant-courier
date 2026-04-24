# RECEIPTS_v1

## Required Receipt Types
- vtp.transport.send.v1
- vtp.transport.accept.v1
- vtp.transport.reject.v1

## Common Fields
- schema
- event_type
- timestamp_utc
- details

## Send Receipt Details
- frame_id
- sender_identity
- recipient_identity
- sender_node_id
- recipient_node_id
- network_id
- session_id
- sender_role
- drop_root
- frame_root
- payload_sha256

## Accept Receipt Details
- frame_id
- sender_node_id
- recipient_node_id
- network_id
- session_id
- sender_role
- accepted_root
- payload_sha256

## Reject Receipt Details
- frame_root
- reason

## Receipt Discipline
- append-only
- deterministic serialization
- never rewrite prior lines
- suitable for downstream witness ingestion
