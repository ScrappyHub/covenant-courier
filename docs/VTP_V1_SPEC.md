\# VTP v1 Specification



\## Definition

VTP (Verifiable Transport Protocol) is a deterministic, signed, node-to-node transport layer with receipt-backed verification.



\## Guarantees

\- Payload integrity (sha256)

\- Signature verification (OpenSSH allowed\_signers)

\- Deterministic rejection paths

\- Node / network / session enforcement

\- Append-only receipt proofs



\## Transport Model

\- Frame-based

\- Filesystem-drop reference transport

\- Non-mutating verification

\- Explicit accept/reject directories



\## Required Components

\- registry/

\- scripts/

\- test\_vectors/

\- proofs/



\## Success Tokens

\- VTP\_TIER0\_FULL\_GREEN

\- VTP\_CROSS\_NODE\_OK

\- VTP\_M2M\_EXPORT\_OK

\- VTP\_M2M\_IMPORT\_ACCEPT\_OK

\- VTP\_MACHINE\_TO\_MACHINE\_OK

