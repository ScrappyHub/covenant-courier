# Covenant Courier Standalone WBS v1

## CC-ST-01 Core verify lane
Status: GREEN
- message verification
- negative tamper coverage
- deterministic failure tokens

## CC-ST-02 Signature lane
Status: GREEN
- local trust bootstrap
- sign
- verify
- missing signature negative

## CC-ST-03 Lexical dictionary lane
Status: GREEN
- dictionary build
- tokenize
- decode
- longest-match precedence

## CC-ST-04 Message pipeline lane
Status: GREEN
- compose
- tokenize
- sign
- verify
- decode

## CC-ST-05 Message pipeline negative suite
Status: GREEN
- missing plaintext
- missing recipients
- missing dictionary
- disallowed context
- tamper after sign
- mismatched decode dictionary
- missing signature

## CC-ST-06 Standalone all-green runner
Status: IN PROGRESS
- aggregate all standalone lanes
- emit final standalone success token
- ready for operator launch

## CC-ST-07 Standalone docs freeze
Status: IN PROGRESS
- README
- spec
- WBS
- runbook follow-up
