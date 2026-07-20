// define boundary 224 // 11100000 32x32
define boundary 248 // 11111000 8x8
// define boundary 252 // 11111100 4x4

// r1 - x
// r2 - y
// r3 - neighbor sum
// r4 - state
// r5 - neighbor x
// r6 - neighbor y
// r7 - gen counter
// r8 - temp I/O
// r9 - boundary
// r11 - scratch
// r12 - buffer cell state
// r13 - scratch
// r14 - scratch
// r15 - I/0

// RAM 0-31 first row buffer
// RAM 32-63 second row buffer

define pixel_x_port -8
define pixel_y_port -7
define draw_pixel_port -6
define clear_pixel_port -5
define load_pixel_port -4
define buffer_screen_port -3
define clear_screen_buffer_port -2
define write_char_port -1
define buffer_chars_port 0
define clear_chars_buffer_port 1
define show_number_port 2
define clear_number_port 3
define signed_mode_port 4
define unsigned_mode_port 5
define rng_port 6
define controller_input_port 7

  LDI r15 buffer_chars // 248

  LDI r9 boundary

// write "LIFE"
  STR r15 r0 clear_chars_buffer_port
  LDI r14 "L"
  STR r15 r14 write_char_port
  LDI r14 "I"
  STR r15 r14 write_char_port
  LDI r14 "F"
  STR r15 r14 write_char_port
  LDI r14 "E"
  STR r15 r14 write_char_port
  STR r15 r0 buffer_chars_port
// gen counter to 0
  STR r15 r0 unsigned_mode_port
  STR r15 r0 show_number_port

// initial pattern
  STR r15 r0 clear_screen_buffer_port
  CAL .initial_pattern
  STR r15 r0 buffer_screen_port

// init x/y
  LDI r1 0
  LDI r2 0

.gol_loop
// get neighbor sum
  CAL .sum_neighbors
// combine sum with self
  STR r15 r1 pixel_x_port
  STR r15 r2 pixel_y_port
  LOD r15 r4 load_pixel_port
  NOR r4 r3 r14
// test for alive
  LDI r13 252 // 11111100
  CMP r14 r13
  BRH ne .not_birth
// write to first row buffer
  LDI r13 1
  STR r1 r13
.not_birth

// test if x within bounds
  ADI r1 1
  AND r1 r9 r14
  CMP r14 r0
  BRH eq .gol_loop
// x out of bounds, row complete
// test if y is 0
  CMP r2 r0
  BRH eq .is_first_row
// apply buffer if y isn't first row
  CAL .apply_row_buffer
.is_first_row
// move data from fisrt to second row buffer
  CAL .shift_buffers
// start at first cell of next row
  LDI r1 0
  ADI r2 1
// test if y in bounds
  AND r2 r9 r14
  CMP r14 r0
  BRH eq .gol_loop
// y out of bounds, last row done
// apply last row
  CAL .apply_row_buffer
// back to first row
  LDI r2 0
// inc gen counter, refresh screen, repeat
  ADI r7 1
  STR r15 r7 show_number_port
  STR r15 r0 buffer_screen_port
  JMP .gol_loop


.sum_neighbors
  MOV r1 r5
  MOV r2 r6
  LDI r3 0 // reset neightbor count
  ADI r5 1
  CAL .sum_neighbor
  ADI r6 1
  CAL .sum_neighbor
  ADI r5 -1
  CAL .sum_neighbor
  ADI r5 -1
  CAL .sum_neighbor
  ADI r6 -1
  CAL .sum_neighbor
  ADI r6 -1
  CAL .sum_neighbor
  ADI r5 1
  CAL .sum_neighbor
  ADI r5 1
  CAL .sum_neighbor
  RET


.sum_neighbor
// test bounds
  AND r5 r9 r14
  BRH ne .sum_neighbor_ret
  AND r6 r9 r14
  BRH ne .sum_neighbor_ret
// x and y in bounds
  STR r15 r5 pixel_x_port
  STR r15 r6 pixel_y_port
  LOD r15 r14 load_pixel_port
  ADD r14 r3 r3
.sum_neighbor_ret
  RET


.shift_buffers
  LDI r13 0
  LDI r14 32
.buffer_shift_loop
  ADD r13 r14 r11
  LOD r13 r12
  STR r11 r12
  STR r13 r0
  ADI r13 1
  CMP r13 r14
  BRH ne .buffer_shift_loop
  RET


.apply_row_buffer
  LDI r13 0
  LDI r14 32
  ADI r2 -1
.buffer_shift_loop_2
  STR r15 r13 pixel_x_port
  STR r15 r2 pixel_y_port
  STR r15 r0 clear_pixel_port
  ADD r13 r14 r11
  LOD r11 r12
  CMP r12 r0
  BRH eq .no_birth_from_buffer
  STR r15 r0 draw_pixel_port
.no_birth_from_buffer
  ADI r13 1
  CMP r13 r14
  BRH ne .buffer_shift_loop_2
  ADI r2 1
  RET


.initial_pattern
  LDI r14 0
  STR r15 r14 pixel_x_port
  LDI r14 0
  STR r15 r14 pixel_y_port
  STR r15 r0 draw_pixel_port

  LDI r14 1
  STR r15 r14 pixel_x_port
  LDI r14 1
  STR r15 r14 pixel_y_port
  STR r15 r0 draw_pixel_port

  LDI r14 1
  STR r15 r14 pixel_x_port
  LDI r14 2
  STR r15 r14 pixel_y_port
  STR r15 r0 draw_pixel_port

  LDI r14 2
  STR r15 r14 pixel_x_port
  LDI r14 0
  STR r15 r14 pixel_y_port
  STR r15 r0 draw_pixel_port

  LDI r14 2
  STR r15 r14 pixel_x_port
  LDI r14 1
  STR r15 r14 pixel_y_port
  STR r15 r0 draw_pixel_port

  RET