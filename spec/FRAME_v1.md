# FRAME_v1

## Canonical Frame Fields
- frame_id
- created_utc
- sender_identity
- recipient_identity
- sender_node_id
- recipient_node_id
- network_id
- session_id
- sender_role
- message_rel
- signature_rel
- payload_sha256

## Acceptance Requirements
A frame is accepted only when:
- structure is complete
- payload artifact exists
- signature artifact exists
- payload hash matches
- sender identity matches expected sender
- sender node exists and is active
- recipient node exists and is active
- network exists and is active
- session exists and is open
- session sender/recipient/network/role all match frame values
- both sender and recipient are allowed on the network
- signature verification succeeds
- frame_id has not been seen before
