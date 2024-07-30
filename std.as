// Ports
DEFINE pixel_x 240
DEFINE pixel_y 241
DEFINE draw_pixel 242
DEFINE clear_pixel 243
DEFINE load_pixel 244
DEFINE buffer_screen 245
DEFINE clear_screen_buffer 246
DEFINE write_char 247
DEFINE buffer_chars 248
DEFINE clear_chars_buffer 249
DEFINE show_number 250
DEFINE clear_number 251
DEFINE signed_mode 252
DEFINE unsigned_mode 253
DEFINE rng 254
DEFINE controller_input 255

// Conditions
DEFINE EQ 0
DEFINE = 0
DEFINE Z 0
DEFINE ZERO 0
DEFINE NE 1
DEFINE != 1
DEFINE NZ 1
DEFINE NOTZERO 1
DEFINE GE 2
DEFINE >= 2
DEFINE C 2
DEFINE CARRY 2
DEFINE LT 3
DEFINE < 3
DEFINE NC 3
DEFINE NOTCARRY 3

// Macros
MACRO CMP A B
    SUB %A% %B% r0
ENDM

MACRO MOV A C
    ADD %A% r0 %C%
ENDM

MACRO LSH A C
    ADD %A% %A% %C%
ENDM

MACRO INC A
    ADI %A% 1
ENDM

MACRO DEC A
    ADI %A% -1
ENDM

MACRO NOT A C
    NOR %A% r0 %C%
ENDM
