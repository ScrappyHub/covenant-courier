# REGISTRIES_v1

## Node Registry
Fields:
- node_id
- node_name
- node_role
- principal
- status
- created_utc
- last_seen_utc
- allowed_namespaces
- tags

## Network Registry
Fields:
- network_id
- network_name
- transport_kind
- listener_port
- binding_mode
- visibility
- status
- allowed_nodes
- created_utc

Law:
- allowed_nodes is the sole network trust membership set
- binding_mode controls transport behavior only
- binding_mode must never be used as a node identity field

## Session Registry
Fields:
- session_id
- sender_node_id
- recipient_node_id
- network_id
- session_role
- session_policy_ref
- transport_namespace
- opened_utc
- closed_utc
- status

Law:
- status=open is required for frame acceptance
- closed sessions must reject
