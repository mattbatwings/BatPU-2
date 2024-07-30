DEFINE TEST 1

MACRO test reg
    add %reg% %reg% %reg%
    sub r1 r1 r1
    .T
    JMP .T
ENDM

test r2
test r15
and r3 r3 r3
LOD r6 r7
LOD r4 r5 TEST
inc r1

.T
JMP .T

LDI r15 0x12
LDI r15 12
