// Tetris by Eithanz

// Save Row Counts
// Save Column Counts
// Play area 10x20y

// ram:
// 0-31 L piece
// 32-63 reverse L piece
// 64-95 T piece
// 96-111 Z piece
// 112-127 reverse Z piece
// 128-143 long piece
// 144-151 square piece

// 152-159 piece bag

// 160-179 line counts

// 180-181 score

// 182-191 heighest piece per column

// 192-199 3 bit map

// 200 - tile bag counter
// 201-203 - random numbers

// 212-223 rotation map right
// 223-235 rotation map left

// 237 last hard drop
// 238 score
// 239 r7 holder

define LEFT 1
define DOWN 2
define RIGHT 4
define UP 8
define B 16
define A 32

JMP .setup

.setup 
LDI r15 clear_screen_buffer // clear screen buffer
STR r15 r0
LDI r15 240
LDI r1 30
LDI r2 2
LDI r3 10
LDI r4 21
.x_loop
SUB r3 r4 r0
BRH eq .x_loop_end
STR r15 r3 0
STR r15 r1 1 
STR r15 r0 2
STR r15 r2 1
STR r15 r0 2
ADI r3 1
JMP .x_loop
.x_loop_end
LDI r1 31
LDI r3 10
.y_loop
SUB r2 r1 r0
BRH eq .y_loop_end
STR r15 r3 0
STR r15 r2 1 
STR r15 r0 2
STR r15 r4 0
STR r15 r0 2
ADI r2 1
JMP .y_loop
.y_loop_end
LDI r1 20
LDI r2 23
STR r15 r1 0
STR r15 r2 1
STR r15 r0 2
LDI r1 11
STR r15 r1 0
STR r15 r2 1
STR r15 r0 2
LDI r15 buffer_screen // save cleared buffer to screen
STR r15 r0
LDI r15 clear_number // write 0 to number display
STR r15 r0
LDI r15 unsigned_mode
STR r15 r0
LDI r15 show_number
STR r15 r0
LDI r15 clear_chars_buffer // write "tetris"
STR r15 r0
LDI r15 write_char
LDI r14 "T"
STR r15 r14
LDI r14 "E"
STR r15 r14
LDI r14 "T"
STR r15 r14
LDI r14 "R"
STR r15 r14
LDI r14 "I"
STR r15 r14
LDI r14 "S"
STR r15 r14
LDI r14 " "
STR r15 r14
LDI r14 " "
STR r15 r14
LDI r14 " "
STR r15 r14
LDI r14 " "
STR r15 r14
LDI r15 buffer_chars
STR r15 r0
JMP .load_pieces

.load_pieces
LDI r15 0
//load_l_piece
LDI r14 -1
STR r15 r14 0
LDI r14 0
STR r15 r14 1
LDI r14 1
STR r15 r14 2
LDI r14 1
STR r15 r14 3
LDI r14 1
STR r15 r14 4
LDI r14 0
STR r15 r14 5
ADI R15 8
LDI r14 0 
STR r15 r14 0
LDI r14 1 
STR r15 r14 1
LDI r14 0
STR r15 r14 2
LDI r14 -1
STR r15 r14 3
LDI r14 1
STR r15 r14 4
LDI r14 -1
STR r15 r14 5
ADI R15 8
LDI r14 -1
STR r15 r14 0
LDI r14 0 
STR r15 r14 1
LDI r14 1 
STR r15 r14 2
LDI r14 0 
STR r15 r14 3
LDI r14 -1
STR r15 r14 4
LDI r14 -1
STR r15 r14 5
ADI R15 8
LDI r14 0
STR r15 r14 0
LDI r14 1
STR r15 r14 1
LDI r14 -1
STR r15 r14 2
LDI r14 1
STR r15 r14 3
LDI r14 0
STR r15 r14 4
LDI r14 -1
STR r15 r14 5
ADI R15 8
//load_reverse_l_piece
LDI r14 -1
STR r15 r14 0
LDI r14 0
STR r15 r14 1
LDI r14 1
STR r15 r14 2
LDI r14 0
STR r15 r14 3
LDI r14 -1
STR r15 r14 4
LDI r14 1
STR r15 r14 5
ADI r15 8
LDI r14 0
STR r15 r14 0
LDI r14 1
STR r15 r14 1
LDI r14 0
STR r15 r14 2
LDI r14 -1
STR r15 r14 3
LDI r14 1
STR r15 r14 4
LDI r14 1
STR r15 r14 5
ADI r15 8
LDI r14 -1
STR r15 r14 0
LDI r14 0
STR r15 r14 1
LDI r14 1
STR r15 r14 2
LDI r14 -1
STR r15 r14 3
LDI r14 1
STR r15 r14 4
LDI r14 0
STR r15 r14 5
ADI r15 8
LDI r14 0
STR r15 r14 0
LDI r14 1
STR r15 r14 1
LDI r14 -1
STR r15 r14 2
LDI r14 -1
STR r15 r14 3
LDI r14 0
STR r15 r14 4
LDI r14 -1
STR r15 r14 5
ADI r15 8
//load_t_piece
LDI r14 -1
STR r15 r14 0
LDI r14 0
STR r15 r14 1
LDI r14 1
STR r15 r14 2
LDI r14 0
STR r15 r14 3
LDI r14 0
STR r15 r14 4
LDI r14 1
STR r15 r14 5
ADI r15 8
LDI r14 1
STR r15 r14 0
LDI r14 0
STR r15 r14 1
LDI r14 0
STR r15 r14 2
LDI r14 1
STR r15 r14 3
LDI r14 0
STR r15 r14 4
LDI r14 -1
STR r15 r14 5
ADI r15 8
LDI r14 -1
STR r15 r14 0
LDI r14 0
STR r15 r14 1
LDI r14 0
STR r15 r14 2
LDI r14 -1
STR r15 r14 3
LDI r14 1
STR r15 r14 4
LDI r14 0
STR r15 r14 5
ADI r15 8
LDI r14 0
STR r15 r14 0
LDI r14 1
STR r15 r14 1
LDI r14 -1
STR r15 r14 2
LDI r14 0
STR r15 r14 3
LDI r14 0
STR r15 r14 4
LDI r14 -1
STR r15 r14 5
ADI r15 8
//load_z_piece
LDI r14 -1
STR r15 r14 0
LDI r14 0
STR r15 r14 1
LDI r14 0
STR r15 r14 2
LDI r14 -1
STR r15 r14 3
LDI r14 1
STR r15 r14 4
LDI r14 -1
STR r15 r14 5
ADI r15 8
LDI r14 1
STR r15 r14 0
LDI r14 1
STR r15 r14 1
LDI r14 1
STR r15 r14 2
LDI r14 0
STR r15 r14 3
LDI r14 0
STR r15 r14 4
LDI r14 -1
STR r15 r14 5
ADI r15 8
//load_reverse_z_piece
LDI r14 -1
STR r15 r14 0
LDI r14 -1
STR r15 r14 1
LDI r14 0
STR r15 r14 2
LDI r14 -1
STR r15 r14 3
LDI r14 1
STR r15 r14 4
LDI r14 0
STR r15 r14 5
ADI r15 8
LDI r14 0
STR r15 r14 0
LDI r14 1
STR r15 r14 1
LDI r14 1
STR r15 r14 2
LDI r14 0
STR r15 r14 3
LDI r14 1
STR r15 r14 4
LDI r14 -1
STR r15 r14 5
ADI r15 8
//load_long_piece
LDI r14 -1
STR r15 r14 0
LDI r14 0
STR r15 r14 1
LDI r14 -2
STR r15 r14 2
LDI r14 0
STR r15 r14 3
LDI r14 1
STR r15 r14 4
LDI r14 0
STR r15 r14 5
ADI r15 8
LDI r14 0
STR r15 r14 0
LDI r14 1 
STR r15 r14 1
LDI r14 0
STR r15 r14 2
LDI r14 2
STR r15 r14 3
LDI r14 0
STR r15 r14 4
LDI r14 -1
STR r15 r14 5
ADI r15 8
//load_square_piece
LDI r14 0
STR r15 r14 0
LDI r14 1
STR r15 r14 1
LDI r14 -1
STR r15 r14 2
LDI r14 1
STR r15 r14 3
LDI r14 -1
STR r15 r14 4
LDI r14 0
STR r15 r14 5
//height data
LDI r15 182
LDI r14 2
STR r15 r14 0
STR r15 r14 1
STR r15 r14 2
STR r15 r14 3
STR r15 r14 4
STR r15 r14 5
STR r15 r14 6
STR r15 r14 7
ADI r15 8
STR r15 r14 0
STR r15 r14 1
//rotation map
LDI r15 212
LDI r14 0
STR r15 r14 1
LDI r14 0
STR r15 r14 0
LDI r14 0
STR r15 r14 2
LDI r14 -1
STR r15 r14 3
LDI r14 1
STR r15 r14 4
LDI r14 -1
STR R15 r14 5
LDI r14 -1
STR R15 r14 6
LDI r14 -1
STR R15 r14 7
ADI r15 8
LDI r14 1
STR r15 r14 0
LDI r14 0
STR r15 r14 1
LDI r14 -1
STR r15 r14 2
LDI r14 0
STR r15 r14 3
LDI r14 0
STR r15 r14 4
LDI r14 0
STR r15 r14 5
LDI r14 0
STR r15 r14 6
LDI r14 -1
STR r15 r14 7
ADI r15 8
LDI r14 -1
STR r15 r14 0
LDI r14 -1
STR R15 r14 1
LDI r14 1
STR R15 r14 2
LDI r14 -1
STR R15 r14 3
LDI r14 -1
STR r15 r14 4
LDI r14 0
STR r15 r14 5
LDI r14 1
STR r15 r14 6
LDI r14 0
STR r15 r14 7
LDI r15 153
LDI r11 1
STR r15 r11 0
ADI r11 32
STR r15 r11 1
ADI r11 32
STR r15 r11 2
ADI r11 32
STR r15 r11 3
ADI r11 16
STR r15 r11 4
ADI r11 16
STR r15 r11 5
ADI r11 16
STR r15 r11 6
LDI r15 192
LDI r11 4
STR r15 r11 0
LDI r11 5
STR r15 r11 1
LDI r11 7
STR r15 r11 2
LDI r11 1
STR r15 r11 3
LDI r11 0
STR r15 r11 4
LDI r11 6
STR r15 r11 5
LDI r11 3
STR r15 r11 6
LDI r11 2
STR r15 r11 7
JMP .main_loop

// 1-copied piece, 2-final x, 3-final y, 4-x, 5-y
// 6-piece, 7-rotation, 14-bit mask, 15-ram/bit mask
.place_piece 
ADD r0 r6 r1 // copy piece type
CAL .rotate_piece
LDI r15 240 // pixel x address
STR r15 r4 0
STR r15 r5 1
STR r15 r0 2
.place_piece_loop
LOD r1 r2 0
LOD r1 r3 1
ADD r3 r2 r0 // if both combines sum up to 0 its end of piece
BRH ne .place_continue
BRH lt .go_back_buffer
.place_continue
ADD r4 r2 r2 // x
ADD r5 r3 r3 // y
STR r15 r2 0
STR r15 r3 1
STR r15 r0 2
ADI r1 2
JMP .place_piece_loop

.erase_piece // 4-x, 5-y, 6-piece, 7-rotation
ADD r0 r6 r1 // copy piece type
CAL .rotate_piece
LDI r15 240 // pixel x address
STR r15 r4 0
STR r15 r5 1
STR r15 r0 3
.erase_piece_loop
LOD r1 r2 0
LOD r1 r3 1
ADD r3 r2 r0 // if both combines sum up to 0 its end of piece
BRH ne .erase_continue
BRH lt .go_back
.erase_continue
ADD r4 r2 r2 // x
ADD r5 r3 r3 // y
STR r15 r2 0
STR r15 r3 1
STR r15 r0 3
ADI r1 2
JMP .erase_piece_loop

.rotate_piece // 1-piece type, 7-rotation type, 13-holder
LDI r13 96
SUB r1 r13 r0
BRH lt .four_type_rotation
LDI r13 144
SUB r1 r13 r0
BRH lt .two_type_rotation
RET
.two_type_rotation
LDI r13 8 // bit map 00001000
AND r7 r13 r13
ADD r1 r13 r1
RET
.four_type_rotation
LDI r13 24 // bit map 00011000
AND r7 r13 r13
ADD r1 r13 r1
RET
//X - check if rotation possible

//1 2 3 6 7 8 9 11 13 14 15
.get_random_piece
LDI r15 200
LDI r14 4
LOD r15 r9
ADD r9 r0 r0
BRH ne .skip_random_piece_setup 
LDI r15 254
LDI r13 7
LOD r15 r1 
AND r1 r13 r1
LOD r15 r2
AND r2 r13 r2
LOD r15 r3
AND r3 r13 r3
LDI r9 8
LDI r15 200
STR r15 r1 1
STR r15 r2 2
STR r15 r3 3
.skip_random_piece_setup
ADI r9 -1
STR r15 r9 0 // store bag count
.random_piece_loop
LDI r15 200
ADD r15 r14 r15 // offset address by loop count
LOD r15 r1 1 // load random number 1
ADI r14 -1
BRH eq .random_piece_end
LDI r15 192
ADD r15 r9 r15
LOD r15 r9 // load mapped number
XOR r1 r9 r9
JMP .random_piece_loop
.random_piece_end
ADD r9 r0 r0
BRH eq .get_random_piece // if we get a 0 redo it
LDI r15 152
ADD r15 r9 r15 // offset piece bag by the number 1-7
LOD r15 r9 0
ADI r9 -1
RET

.collision_check // 8-x, 12-y
ADD r0 r6 r1 // copy piece type
CAL .rotate_piece
// check if a piece is under x0
LDI r15 -1
SUB r8 r15 r0
BRH ne .collision_check_loop_start_a
ADD r4 r0 r8
RET 
.collision_check_loop_start_a
LDI r15 240 // pixel x address
STR r15 r8 0
STR r15 r5 1
LOD r15 r13 4
// check if a piece already exists in this position
ADD r13 r0 r0
BRH eq .collision_check_loop
ADD r4 r0 r8
RET
.collision_check_loop
LOD r1 r2 0
LOD r1 r3 1
ADD r3 r2 r0 // if both combines sum up to 0 its end of piece
BRH ne .collision_continue
BRH lt .go_back
.collision_continue
ADD r8 r2 r2 // x
ADD r5 r3 r3 // y
// check if a piece is over x10
LDI r15 21
SUB r2 r15 r0
BRH ne .collision_check_loop_end_a
ADD r4 r0 r8
RET
.collision_check_loop_end_a
// check if a piece is under x0
LDI r15 10
SUB r2 r15 r0
BRH ne .collision_check_loop_end_b
ADD r4 r0 r8
RET
.collision_check_loop_end_b
LDI r15 240 // pixel x address
STR r15 r2 0
STR r15 r3 1
LOD r15 r13 4
// check if a piece already exists in this position
ADD r13 r0 r0
BRH eq .collision_check_loop_end_c
ADD r4 r0 r8
RET
.collision_check_loop_end_c
ADI r1 2
JMP .collision_check_loop

.under_collision_check
ADD r0 r6 r1 // copy piece type
CAL .rotate_piece
LDI r15 -1
SUB r12 r15 r0
BRH ne .under_collision_check_loop_start_a
ADD r5 r0 r12
RET
.under_collision_check_loop_start_a
LDI r15 240 // pixel x address
STR r15 r8 0
STR r15 r12 1
LOD r15 r13 4
// check if a piece already exists in this position
ADD r13 r0 r0
BRH eq .under_collision_check_loop
ADD r5 r0 r12
RET
.under_collision_check_loop
LOD r1 r2 0
LOD r1 r3 1
ADD r3 r2 r0 // if both combines sum up to 0 its end of piece
BRH ne .under_collision_continue
BRH lt .go_back
.under_collision_continue
ADD r8 r2 r2 // x
ADD r12 r3 r3 // y
// check if a piece is under y0
LDI r15 2
SUB r3 r15 r0
BRH ne .under_collision_check_loop_end_b
ADD r5 r0 r12
RET
.under_collision_check_loop_end_b
LDI r15 240 // pixel x address
STR r15 r2 0
STR r15 r3 1
LOD r15 r13 4
// check if a piece already exists in this position
ADD r13 r0 r0
BRH eq .under_collision_check_loop_end_c
ADD r5 r0 r12
RET
.under_collision_check_loop_end_c
ADI r1 2
JMP .under_collision_check_loop

.rotation_check // 11-rotation, 8-x, 12-y
ADD r0 r6 r1 // copy piece type
LDI r15 239 // pixel x address
STR r15 r7 0
ADI r14 128
ADD r11 r7 r7 // replace rotation with wanted rotation
LDI r11 210
AND r7 r14 r0 // check rotation direction (check sign)
BRH eq .right_rotation
ADI r11 12
.right_rotation
CAL .rotate_piece
.rotation_offset_loop
ADI r11 2
LDI r15 232
SUB r11 r15 r0
BRH eq .rotation_check_bad_end
LOD r11 r10 0
LOD r11 r14 1
LDI r15 240
ADD r8 r0 r2
ADD r5 r0 r3
ADD r10 r2 r2
ADD r14 r3 r3
STR r15 r2 0
STR r15 r3 1
LOD r15 r13 4 // fetch current block
ADD r13 r0 r0
BRH ne .rotation_offset_loop // if piece occupied
LDI r15 2
SUB r3 r15 r0
BRH eq .rotation_offset_loop // if piece under y0
.rotation_check_loop
LOD r1 r2 0
LOD r1 r3 1
ADD r3 r2 r0 // if both combines sum up to 0 its end of piece
BRH ne .rotation_continue
BRH lt .rotation_check_good_end
.rotation_continue
ADD r8 r2 r2 // x
ADD r5 r3 r3 // y
ADD r10 r2 r2 // rotation push offset
ADD r14 r3 r3 // rotation push offset
// check if a piece is under x0
LDI r15 11
SUB r2 r15 r0
BRH lt .rotation_offset_loop
// check if a piece is under x10
LDI r15 21
SUB r2 r15 r0
BRH ge .rotation_offset_loop
// check if a piece is under y0
LDI r15 2
SUB r3 r15 r0
BRH eq .rotation_offset_loop
LDI r15 240 // pixel x address
STR r15 r2 0
STR r15 r3 1
LOD r15 r13 4
// check if a piece already exists in this position
ADD r13 r0 r0
BRH ne .rotation_offset_loop
ADI r1 2
JMP .rotation_check_loop
.rotation_check_good_end
ADD r8 r10 r8
ADD r5 r14 r12
ADD r7 r0 r11
LDI r15 239
LOD r15 r7
SUB r11 r7 r11
RET
.rotation_check_bad_end
LDI r15 239
LOD r15 r7
LDI r11 0
RET

.main_loop
LDI r4 16 // starting x value
LDI r5 27 // y value
LDI r7 0 // starting rotation
CAL .get_random_piece // pick a random piece
ADD r0 r9 r6
CAL .place_piece
LDI r14 100
CAL .wait
JMP .play_loop_start

.play_loop
CAL .handle_line_counts
.play_loop_start
LDI r4 16 // starting x value
LDI r5 27 // y value
LDI r7 0 // starting rotation
ADD r0 r9 r6
CAL .erase_piece
ADD r0 r9 r12
CAL .get_random_piece
LDI r7 0 // reset r7
ADD r0 r9 r6
CAL .place_piece
ADD r0 r12 r6
LDI r5 23 // starting y value
CAL .place_piece

.piece_loop
CAL .erase_piece
LDI r11 0
LDI r15 255
LOD r15 r10
ADD r4 r0 r8
ADD r10 r0 r0
BRH eq .no_rotation_check
//up movement
LDI r15 237
LOD r15 r15
AND r15 r10 r0
BRH ne .faster_down
//down movement
LDI r15 DOWN
AND r15 r10 r0
BRH ne .fast_down
//left movement
LDI r15 LEFT
AND r15 r10 r0
BRH eq .skip_change_left
ADI r8 -1
.skip_change_left
//right movement
LDI r15 RIGHT
AND r15 r10 r0
BRH eq .skip_change_right
ADI r8 1
.skip_change_right
SUB r8 r4 r0
BRH eq .no_collision_check
//COLLISION DETECTION
CAL .collision_check
.no_collision_check
//rotation
LDI r15 A
AND r15 r10 r0
BRH eq .skip_change_rotation_a
ADI r11 8
.skip_change_rotation_a
LDI r15 B
AND r15 r10 r0
BRH eq .skip_change_rotation_b
ADI r11 -8
.skip_change_rotation_b
//ROTATION COLLISION DETECTION
ADD r11 r0 r0
BRH eq .no_rotation_check
CAL .rotation_check
.no_rotation_check
ADD r11 r7 r7
ADI r12 1
SUB r12 r5 r0
BRH eq .already_gone_down
LDI r12 -1
ADD r5 r12 r12
//UNDER COLLISION DETECTION
CAL .under_collision_check
JMP .gone_down_naturally
.faster_down // free regs: r8, r10, r11, r12, r13, r14, r15,

ADD r0 r6 r1 // copy piece type
CAL .rotate_piece
LDI r15 171
ADD r15 r4 r15
LOD r15 r11 // get top distance
SUB r5 r11 r12 // save the distance to r12
ADI r12 -1
.faster_down_loop
LOD r1 r2 0
LOD r1 r3 1
ADD r3 r2 r0 // if both combines sum up to 0 its end of piece
BRH ne .faster_down_continue
BRH lt .faster_down_end
.faster_down_continue
ADD r4 r2 r2 // x
ADD r5 r3 r3 // y
LDI r15 171
ADD r15 r2 r15
LOD r15 r11 // get top distance
SUB r3 r11 r14 // save the distance to r14
ADI r14 -1
SUB r12 r14 r0
BRH lt .faster_down_skip
ADD r14 r0 r12 
.faster_down_skip
ADI r1 2
JMP .faster_down_loop
.faster_down_end
SUB r5 r12 r12
ADD r12 r0 r5
JMP .gone_down_naturally

.fast_down
LDI r12 -1
ADD r5 r12 r12
CAL .under_collision_check
ADD r12 r0 r5
CAL .place_piece
CAL .erase_piece
ADI r12 -1
CAL .under_collision_check
JMP .gone_down_naturally

.already_gone_down
ADI r12 -1
.gone_down_naturally

LDI r1 UP
AND r1 r10 r1
LDI r15 UP
XOR r15 r1 r1
LDI r15 237
STR r15 r1 

ADD r5 r0 r14 
ADD r8 r0 r4
ADD r12 r0 r5
CAL .place_piece
SUB r12 r14 r0
BRH eq .play_loop // if after check y doesnt decrement make new piece
LDI r14 75
CAL .wait
JMP .piece_loop

.wait // waits 3 * r14 instructions
ADI r14 -1
BRH eq .end_wait
JMP .wait
.end_wait
RET

.handle_line_counts
LDI r11 0
ADD r0 r6 r1 // copy piece type
CAL .rotate_piece
LDI r15 23
SUB r5 r15 r0 // if piece is at y 20 we lost
BRH eq .lose
LDI r15 157
ADD r5 r15 r15 // offset by Y

LDI r14 171
ADD r4 r14 r14 // offset by X
LOD r14 r8 0 // load value to r8
SUB r5 r8 r0
BRH lt .skip_height_increment_a
STR r14 r5 0
.skip_height_increment_a

LOD r15 r8 0 // load value to r8
ADI r8 1 // increment
LDI r14 10
SUB r8 r14 r0
BRH ne .not_filled // if line isnt filled
ADI r11 1
.not_filled
STR r15 r8 0 // store
.handle_line_loop
LOD r1 r2 0
LOD r1 r3 1
ADD r2 r3 r0 // if both combines sum up to 0 its end of piece
BRH ne .handle_line_continue
BRH lt .clear_lines
.handle_line_continue
ADD r4 r2 r2 // x
ADD r5 r3 r3 // y
LDI r15 23
SUB r3 r15 r0 
BRH eq .lose // if piece is at y20 we lost
LDI r15 157
ADD r3 r15 r15 // offset by Y

LDI r14 171
ADD r2 r14 r14 // offset by X
LOD r14 r8 0 // load value to r8
SUB r3 r8 r0
BRH lt .skip_height_increment_b
STR r14 r3 0
.skip_height_increment_b

LOD r15 r8 0
ADI r8 1
LDI r14 10
SUB r8 r14 r0
BRH ne .not_filled_b
ADI r11 1
.not_filled_b
STR r15 r8 0
ADI r1 2
JMP .handle_line_loop

.clear_lines
ADD r11 r0 r10
BRH eq .go_back // if no line was filled, we can skip clearing lines
LDI r15 238
LOD r15 r8 0
CAL .score_change
LDI r2 11
LDI r15 159
JMP .clear_lines_loop_b
.clear_lines_loop_a
ADD r11 r0 r10
LDI r15 245
STR r15 r0 0
ADI r2 1
LDI r3 21
SUB r2 r3 r0
BRH eq .push_down_lines // if we got to x10 we can start pushing
LDI r15 159
.clear_lines_loop_b
ADI r15 1
LDI r3 23
SUB r15 r3 r0
BRH eq .clear_lines_loop_a // if we reached line 20
LOD r15 r8 0
ADD r8 r0 r0
BRH eq .clear_lines_loop_a // if we reached an empty line
LDI r3 10
SUB r8 r3 r0
BRH ne .skip_remove_box // if the line isnt full
LDI r14 240
STR r14 r2 0
ADI r15 99 // 10100000 + 01100011 = 00000011 (259)
STR r14 r15 1
ADI r15 157
STR r14 r0 3
ADI r10 -1
BRH eq .clear_lines_loop_a
.skip_remove_box
JMP .clear_lines_loop_b

.push_down_lines
LDI r15 159
LDI r3 10
LDI r10 1
ADD r11 r0 r5
.push_search_loop
ADD r11 r0 r0
BRH eq .push_end
ADI r15 1
LOD r15 r8 0
ADD r8 r0 r0
BRH eq .push_end // if line has no blocks we pushed everything.
LDI r3 10
SUB r8 r3 r0
BRH ne .push_search_loop // if line is not full, loop again
ADI r11 -1
ADD r15 r0 r10
STR r15 r0 0 // reset that line count

.full_line_count
ADI r10 1
LOD r10 r8 0
SUB r8 r3 r0
BRH ne .full_line_count_end
STR r10 r0 0
ADI r11 -1
JMP .full_line_count
.full_line_count_end
SUB r10 r15 r10

ADD r15 r0 r14
ADI r15 -1
ADD r14 r10 r14
LDI r3 180
SUB r14 r3 r0
BRH eq .push_search_loop // if we got to line 20 go search for another line
LOD r14 r8 0
ADD r8 r0 r0
BRH eq .push_search_loop // if line has no blocks go search for another line
LDI r2 10
JMP .push_loop_b
.push_loop_a
SUB r14 r10 r14
STR r14 r8 0 // move line count down
ADD r14 r10 r14
STR r14 r0 0 // reset line count
LDI r2 10
ADI r14 1
LDI r3 180
SUB r14 r3 r0
BRH eq .push_search_loop // if we got to line 20 go search for another line
LOD r14 r8 0
ADD r8 r0 r0
BRH eq .push_search_loop // if line has no blocks go search for another line
.push_loop_b
ADI r2 1
LDI r3 21
SUB r2 r3 r0
BRH eq .push_loop_a // if we reached x10 go push next line
ADI r14 99 // 10100000 + 01100000 = 00000000 (256)
LDI r7 240
STR r7 r2 0
STR r7 r14 1 
LOD r7 r12 4 // load pixel val
SUB r14 r10 r14
ADD r12 r0 r0
BRH eq .skip_pixel_push
STR r7 r0 3
STR r7 r14 1
STR r7 r0 2 // store pixel val in -1 y
.skip_pixel_push
ADD r14 r10 r14
ADI r14 157
JMP .push_loop_b
.push_end

LDI r15 245
STR r15 r0 0

// r13 r7
LDI r15 182
LDI r7 2
.height_map_update
LOD r15 r8 0
SUB r8 r5 r8 // remove the amount of lines we have because why not

ADI r8 1
.height_map_loop
ADI r8 -1
SUB r8 r7 r0
BRH eq .height_map_loop_end // if its 2 escape the loop we cant go lower
LDI r13 240
LDI r14 171
SUB r15 r14 r14
STR r13 r14 0
STR r13 r8 1
LOD r13 r13 4
ADD r13 r0 r0
BRH eq .height_map_loop // if we reached a square
.height_map_loop_end 
STR r15 r8 0
ADI r15 1
LDI r14 192
SUB r15 r14 r0
BRH ne .height_map_update

RET

.score_change
ADD r11 r0 r14
ADD r14 r14 r14
ADI r14 -1
ADD r8 r14 r8
STR r15 r8 0
LDI r15 show_number
STR r15 r8
RET

.lose
LDI r15 clear_chars_buffer
STR r15 r0
LDI r15 buffer_chars
STR r15 r0
LDI r15 write_char
LDI r14 " "
STR r15 r14
LDI r14 "G"
STR r15 r14
LDI r14 "A"
STR r15 r14
LDI r14 "M"
STR r15 r14
LDI r14 "E"
STR r15 r14
LDI r14 " "
STR r15 r14
LDI r14 "O"
STR r15 r14
LDI r14 "V"
STR r15 r14
LDI r14 "E"
STR r15 r14
LDI r14 "R"
STR r15 r14
LDI r15 buffer_chars
STR r15 r0
LDI r2 2 // start y
LDI r3 21 // end x
LDI r4 30 // end y
LDI r15 240
.lose_loop_a
LDI r1 10 // start x
ADI r2 1
SUB r2 r4 r0
BRH eq .lose_loop_end
.lose_loop_b
ADI r1 1
SUB r1 r3 r0
BRH eq .lose_loop_a
STR r15 r1 0
STR r15 r2 1
STR r15 r0 2
STR r15 r0 5
JMP .lose_loop_b
.lose_loop_end
HLT

.go_back_buffer // buffers screen and returns
STR r15 r0 5
RET

.go_back
RET