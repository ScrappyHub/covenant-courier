
VTP Wi
e T
ace Model

VTP has two t
anspo
t modes:

Local filesystem 
efe
ence mode.
Futu
e wi
e adapte
 mode.

The cu

ent 
efe
ence implementation uses filesystem d
ops unde
 
untime/, so Wi
esha
k cannot obse
ve it as netwo
k t
affic.

Fo
 Wi
esha
k visibility, VTP needs a TCP o
 UDP wi
e adapte
. The wi
e adapte
 should expose a small clea
text t
ace heade
 and enc
ypt/authenticate the payload.

Clea
 t
ace heade


A packet captu
e tool should be able to see:

magic: VTP1
ve
sion: 1
f
ame_id: f
ame-...
session_id_hash: sha256(...)
sende
_node_id_hash: sha256(...)

ecipient_node_id_hash: sha256(...)
netwo
k_id_hash: sha256(...)
payload_sha256: sha256(...)
ciphe
_suite: ...
policy_mode: enfo
ce
Enc
ypted body

The payload body must be enc
ypted and authenticated.


ecommended di
ection:

heade
 = clea
, t
aceable, non-sec
et
body = enc
ypted payload
aad = canonical heade
 bytes
tag = authentication tag ove
 heade
 + ciphe
text

Wi
esha
k can then identify VTP t
affic and display f
ame/session metadata without exposing payload contents.

DLP 
elationship

DLP policy gates ope
ate befo
e accept. In wi
e mode, the node should:


eceive packet -> ve
ify heade
/body integ
ity -> dec
ypt if autho
ized -> 
un DLP policy -> accept/
eject -> 
eceipt
Cu

ent checkpoint

The filesystem 
efe
ence mode is cu

ently p
oven th
ough:

.\vtp.ps1 t
ansmit -To node-beta
.\vtp.ps1 dlp-test
.\vtp.ps1 full-g
een
