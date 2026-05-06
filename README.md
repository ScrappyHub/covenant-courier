# Covenant Cou
ie


Covenant Cou
ie
 contains the 
efe
ence implementation of VTP, the Ve
ifiable T
anspo
t P
otocol.

## VTP v1 quicksta
t

P
ima
y local development command:

```powe
shell
cd C:\dev\covenant-cou
ie

.\vtp.ps1 t
ansmit -To node-beta
t
ansmit pe
fo
ms the full local flow in one command:

open session -> send f
ame -> activate 
eceive
 once -> DLP policy gate -> accept/
eject -> status

Expected success tokens:

VTP_SEND_OK
VTP_POLICY_ALLOW_OK
COU
IE
_T
ANSPO
T_LISTEN_ACCEPT_OK
VTP_T
ANSMIT_OK
Status
.\vtp.ps1 status

Status shows queue depth and latest f
ame IDs:

Inbox d
op: 0
Latest accepted: f
ame-...
Latest 
ejected: f
ame-...
Latest 
eject 
eason: ...
DLP p
oof
.\vtp.ps1 dlp-test

Expected:

VTP_DLP_NEGATIVE_
EJECT_OK
VTP_DLP_TEST_OK
Full g
een p
oof
.\vtp.ps1 full-g
een

Expected:

VTP_FULL_G
EEN_OK
VTP_CLI_FULL_G
EEN_OK
Optional dev 
untime

A fo
eg
ound dev node loop exists fo
 continuous local testing:

.\vtp.ps1 
un-node -NodeId node-beta

This is optional. The p
ima
y local use
 flow is t
ansmit, not a two-te
minal wo
kflow.


untime state

Local 
untime/p
oof state is igno
ed by Git:

p
oofs/

egist
y/

untime/
Checkpoint tag
vtp-v1-dev-
untime-dlp
