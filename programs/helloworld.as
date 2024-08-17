// Simple Hello World Program by mattbatwings

// Clear character buffer
LDI r15 clear_chars_buffer
STR r15 r0

// Write "HELLOWORLD"
LDI r15 write_char

LDI r14 "H"
STR r15 r14
LDI r14 "E"
STR r15 r14
LDI r14 "L"
STR r15 r14
LDI r14 "L"
STR r15 r14
LDI r14 "O"
STR r15 r14
LDI r14 "W"
STR r15 r14
LDI r14 "O"
STR r15 r14
LDI r14 "R"
STR r15 r14
LDI r14 "L"
STR r15 r14
LDI r14 "D"
STR r15 r14

// Push character buffer
LDI r15 buffer_chars
STR r15 0

HLT