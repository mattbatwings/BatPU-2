// 2048 made by eithanz, and ProtoSebastian
//
// respective GitHubs: https://github.com/E1thanz & https://github.com/ProtoSebastian

// 0 - 11 piece map
// 12 - 107 piece bytes
// 108-123 - number map
// 124-125 - random number
// 126 - count

// 224 - 239 board

define number_map_base_pointer 108
define rendom_number_base_pointer 124
define count_pointer 126

define base_board_pointer 224

define base_devices_pointer 248
define px -8
define py -7
define draw_p -6
define clear_p -5
define load_p -4
define push_screen -3
define clear_screen -2
define put_char -1
define push_chars 0
define clear_chars 1
define show_num 2
define clear_num 3
define signed 4
define unsigned 5
define RNJesus 6
define controller_inp 7

define LEFT 1  // increment
define DOWN 2  // increment
define RIGHT 4 // decrement
define UP 8    // decrement

// ---------------------
// |    |    |    |    |
// |12  |13  |14  |15  |
// ---------------------
// |    |    |    |    |
// |8   |9   |10  |11  |
// ---------------------
// |    |    |    |    |
// |4   |5   |6   |7   |
// ---------------------
// |    |    |    |    |
// |0   |1   |2   |3   |
// ---------------------

.setup
  LDI r15 base_devices_pointer
  STR r15 r0 clear_screen // clear screen buffer
  STR r15 r0 push_screen  // save cleared buffer to screen
  STR r15 r0 clear_num    // write 0 to number display
  STR r15 r0 unsigned     // set to unsigned
  STR r15 r0 show_num     // show number
  STR r15 r0 clear_chars  // clear char display
  LDI r14 "t"             // two
  STR r15 r14 put_char    // ..
  LDI r14 "t"             // thousand (and)
  STR r15 r14 put_char    // ..
  LDI r14 "f"             // forty
  STR r15 r14 put_char    // ..
  LDI r14 "e"             // eight
  STR r15 r14 put_char    // ..
  LDI r14 " "             // buncha spaces
  STR r15 r14 put_char    // ..
  STR r15 r14 put_char    // ..
  STR r15 r14 put_char    // ..
  STR r15 r14 put_char    // ..
  STR r15 r14 put_char    // ..
  STR r15 r14 put_char    // ..
  STR r15 r0 push_chars
  JMP .load_square_data_to_ram

.game_loop
// if bit 8 is set in r8, win condition. else if non-zero, change made, so spawn new cell. else, don't spawn new cell.
  LDI r1 0b11110000
  AND r8 r1 r0
  BRH notzero .win_condition

  CMP r8 r0
  BRH eq .no_new_square
  CAL .create_random_square
.no_new_square
  LDI r8 0
  STR r15 r0 push_screen
// check everything
// >>>>>>>>>>>>>>>>>>>>>>>>
  LDI r1 16 // loop limit
  LDI r3 0 // change detection save
  LDI r4 0b10000000 // sign bit mask (check if negative)
  LDI r14 base_board_pointer
.negator_loop
  LOD r14 r2
  SUB r0 r2 r2
  BRH ne .negator_not_empty
  LDI r3 1             // atleast 1 empty square
.negator_not_empty
  AND r2 r4 r0
  BRH ne .negator_skip // only save if turns out positive
  STR r14 r2
.negator_skip
  INC r14
  DEC r1
  BRH notzero .negator_loop
  
  ADD r3 r0 r0
  BRH ne .negator_board_not_full

  // lose condition check goes here
  LDI r1 16         // iterations
  LDI r4 0b00000011 // mask for X
  LDI r5 0b00001100 // mask for Y
  LDI r14 base_board_pointer
.lose_condition_check_loop
  LOD r14 r13
  // don't check for empty squares, as the board is assumed full
  AND r14 r4 r2
  BRH zero .no_left_check
  
  LOD r14 r12 -1                 // load cell other value
  SUB r13 r12 r0                 // compare cell values
  BRH eq .negator_board_not_full // if both are equal, then combine possible
.no_left_check
  XOR r2 r4 r0
  BRH zero .no_right_check
  
  LOD r14 r12  1                 // load cell other value
  SUB r13 r12 r0                 // compare cell values
  BRH eq .negator_board_not_full // if both are equal, then combine possible
.no_right_check
  AND r14 r5 r2
  BRH zero .no_down_check
  
  LOD r14 r12 -4                 // load cell other value
  SUB r13 r12 r0                 // compare cell values
  BRH eq .negator_board_not_full // if both are equal, then combine possible
.no_down_check
  XOR r2 r5 r0
  BRH zero .no_up_check
  
  LOD r14 r12  4                 // load cell other value
  SUB r13 r12 r0                 // compare cell values
  BRH eq .negator_board_not_full // if both are equal, then combine possible
.no_up_check
  INC r14
  DEC r1
  BRH notzero .lose_condition_check_loop
  // if reached then end, no combines are possible and board is full, so no moves possible.
  JMP .lose_condition
.negator_board_not_full
// <<<<<<<<<<<<<<<<<<<<<<<<

  CAL .get_input
  STR r15 r0 push_screen
  JMP .game_loop
  
.win_condition  // win condition
  STR r15 r0 clear_chars
  LDI r1 'Y'
  STR r15 r1 put_char
  LDI r1 'O'
  STR r15 r1 put_char
  LDI r1 'U'
  STR r15 r1 put_char
  LDI r1 ' '
  STR r15 r1 put_char
  LDI r1 'W'
  STR r15 r1 put_char
  LDI r1 'I'
  STR r15 r1 put_char
  LDI r1 'N'
  STR r15 r1 put_char
  LDI r1 '!'
  STR r15 r1 put_char
  LDI r1 ' '
  STR r15 r1 put_char
  LDI r1 ' '
  STR r15 r1 put_char
  STR r15 r0 push_chars
  STR r15 r0 clear_screen
  LDI r1 0b00011000
  LDI r2 0b00011000
  RSH r8 r8
  AND r8 r1 r1
  RSH r8 r8
  RSH r8 r8
  AND r8 r2 r2
  RSH r8 r8
  LDI r5 11
  LDI r6 25 // limit
  LDI r7 1 // change x
  LDI r9 1 // change y
  
  .dvd_loop
  CAL .paint_square
  STR r15 r0 push_screen
  CAL .clear_square
  ADD r1 r7 r1
  SUB r1 r6 r0
  BRH lt .x_skip
  SUB r0 r7 r7
  ADD r1 r7 r1
  ADD r1 r7 r1
  .x_skip
  
  ADD r2 r9 r2
  SUB r2 r6 r0
  BRH lt .y_skip
  SUB r0 r9 r9
  ADD r2 r9 r2
  .y_skip
  JMP .dvd_loop

.lose_condition // lose condition
  STR r15 r0 clear_chars
  LDI r1 'Y'
  STR r15 r1 put_char
  LDI r1 'O'
  STR r15 r1 put_char
  LDI r1 'U'
  STR r15 r1 put_char
  LDI r1 ' '
  STR r15 r1 put_char
  LDI r1 'L'
  STR r15 r1 put_char
  LDI r1 'O'
  STR r15 r1 put_char
  LDI r1 'S'
  STR r15 r1 put_char
  LDI r1 'E'
  STR r15 r1 put_char
  LDI r1 '!'
  STR r15 r1 put_char
  LDI r1 ' '
  STR r15 r1 put_char
  STR r15 r0 push_chars
  HLT // end

// waits for input and when received returns with register 12 as the input given
// r12 r14 r7 modified
.get_input
  ADD r14 r0 r7
  LOD r15 r14 controller_inp
  ADD r7 r0 r0
  BRH ne .get_input     // patience (wait for player to let go of button)
  ADD r14 r0 r0
  BRH eq .get_input     // patience 2: electric boogaloo (wait for player to press a button)
  ldi r1 base_board_pointer
  
  LDI r12 UP          // check for up
  AND r12 r14 r12     // ..
  BRH ne .switch_up   // when zero
  
  LDI r12 DOWN        // check for down
  AND r12 r14 r12     // ..
  BRH ne .switch_down // when zero I.II
  
  LDI r12 LEFT        // check for left
  AND r12 r14 r12     // ..
  BRH ne .switch_left // when zero 3.4
  
  LDI r12 RIGHT       // check for right
  AND r12 r14 r12     // ..
  BRH ne .switch_right // when zero eleven and a half
  
  JMP .get_input      // no movement buttons pressed

.switch_left
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  LDI r1 8     // X (make jump by 8)
  LDI r9 8     // X duplicate
  LDI r2 0     // Y (make jump by 8)
  LDI r6 32    // limit
.switch_left_loop
  ADD r1 r0 r9 // duplicate X
  RSH r1 r13   // put X as an index in the array in r13 (X/8)
  RSH r13 r13  // ..
  RSH r13 r13  // ..
  LDI r14 base_board_pointer // load base board pointer into r14
  ADD r14 r13 r14 // turn (X/8) from an index into a pointer into RAM
  RSH r2 r13      // now put (Y/2) in r13
  ADD r14 r13 r14 // turn (Y/2) from an index into a pointer into RAM
  LOD r14 r13     // load value from cell
  ADD r13 r0 r0   // check r13; check cell value (check if empty)
  BRH eq .switch_left_postskip // if empty, skip push

  CAL .clear_square  // clear square
.switch_left_push
  LDI r12 0b00000011 // mask for X
  ADI r14 -1         // current index - 1 (go left wing)
  ADI r9 -8          // go left on screen
  AND r14 r12 r5     // r5 = least significant 2 bits
  XOR r12 r5 r0      // check if it rolled back around (stop! criminal scum)
  BRH eq .switch_left_preskip
  LOD r14 r12        // load new cell value
  CMP r12 r0         // check if cell is empty
  BRH ne .switch_left_push_skip // if not empty, skip push
  // r13 is non-zero.. right? yup!
  NOR r8 r13 r8
  NOR r8 r8 r8       // OR r8 and r13 to indicate change, but not overwrite a win condition
  
  STR r14 r13        // store value at our current square, shifted left
  STR r14 r0 1       // store 0 at current square
  JMP .switch_left_push // loop
.switch_left_push_skip
  CMP r12 r13        // compare both cells
  BRH ne .switch_left_preskip // if cells dont match, dont combine
  // r12 is non-zero.. right? use it before negation so number stays positive
  NOR r8 r12 r8
  NOR r8 r8 r8       // OR r8 and r12 to indicate change, but not overwrite a win condition
  
  ADI r12 1          // combine (add 1 to 'exponent' aka multiply by 2)
  SUB r0 r12 r12     // then negate (NO TOUCH)
  STR r14 r12        // store new value into cell
  STR r14 r0 1       // set other cell to 0
  ADD r12 r0 r5      // copy value into r5 (to update square with it)
  JMP .switch_left_skip // skip preskip
.switch_left_preskip
  ADI r14 1          // move 1 column to the right, aka undo rolling back
  ADI r9 8           // .. (do it on the screen)
  SUB r0 r13 r13     // negate number (so when it gets un-negated it doesn't accidentally negate)
  ADD r13 r0 r5      // copy value into r5 (to update square with it)
.switch_left_skip
  SUB r0 r5 r5       // un-negate number
  MOV r1 r12         // save r1 in r12
  MOV r9 r1          // put r9 into r1 (aka X in screenspace)
  CAL .paint_square  // update square
  ADD r12 r0 r1      // load back r1 from r12
.switch_left_postskip
  ADI r2 8                 // move to next row in column
  SUB r6 r2 r0             // check if Y is still within bounds
  BRH ne .switch_left_loop // keep going if so
  LDI r2 0                 // reset Y
  ADI r1 8                 // move to next column
  SUB r6 r1 r0             // check if X is still within bounds
  BRH ne .switch_left_loop // keep going if so
  RET // return
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.switch_down
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  LDI r2 8     // Y (make jump by 8)
  LDI r9 8     // Y duplicate
  LDI r1 0     // X (make jump by 8)
  LDI r6 32    // Y limit
.switch_down_loop
  ADD r2 r0 r9 // duplicate Y
  RSH r2 r13   // put Y as an index in the array in r13 (Y/2)
  LDI r14 base_board_pointer // load base board pointer into r14
  ADD r14 r13 r14 // turn (Y/2) from an index into a pointer into RAM
  RSH r1 r13      // now put (X/8) in r13
  RSH r13 r13     // ..
  RSH r13 r13     // ..
  ADD r14 r13 r14 // turn (X/8) from an index into a pointer into RAM
  LOD r14 r13     // load value from cell
  ADD r13 r0 r0   // check r13; check cell value (check if empty)
  BRH eq .switch_down_postskip // if empty, skip push
  
  CAL .clear_square  // clear square

.switch_down_push
  LDI r12 0b00001100 // mask for Y
  ADI r14 -4         // current index - 1 (go down)
  ADI r9  -8         // go down on screen
  AND r14 r12 r5     // r5 = least significant 2 bits
  XOR r12 r5 r0      // check if it rolled back around (stop! criminal scum)
  BRH eq .switch_down_preskip
  LOD r14 r12        // load new cell value
  CMP r12 r0         // check if cell is empty
  BRH ne .switch_down_push_skip // if not empty, skip push
  // r13 is non-zero.. right?
  NOR r8 r13 r8
  NOR r8 r8 r8       // OR r8 and r13 to indicate change, but not overwrite a win condition
  
  STR r14 r13        // store value at our current square, shifted down
  STR r14 r0 4       // store 0 at current square
  JMP .switch_down_push // loop
.switch_down_push_skip
  CMP r12 r13        // compare both cells
  BRH ne .switch_down_preskip // if cells dont match, dont combine
  // r12 is non-zero.. right? use it before negation so number stays positive
  NOR r8 r12 r8
  NOR r8 r8 r8       // OR r8 and r12 to indicate change, but not overwrite a win condition
  
  ADI r12 1          // combine (add 1 to 'exponent' aka multiply by 2)
  SUB r0 r12 r12     // then negate (NO TOUCH)
  STR r14 r12        // store new value into cell
  STR r14 r0 4       // set other cell to 0
  ADD r12 r0 r5      // copy value into r5 (to update square with it)
  JMP .switch_down_skip // skip preskip
.switch_down_preskip
  ADI r14 4          // move 1 row up, aka undo rolling back
  ADI r9 8           // .. (do it on the screen)
  SUB r0 r13 r13     // negate number (so when it gets un-negated it doesn't accidentally negate)
  ADD r13 r0 r5      // copy value into r5 (to update square with it)
.switch_down_skip
  SUB r0 r5 r5       // un-negate number
  MOV r2 r12         // save r1 in r12
  MOV r9 r2          // put r9 into r1 (aka Y in screenspace)
  CAL .paint_square  // update square
  ADD r12 r0 r2      // load back r1 from r12
.switch_down_postskip
  ADI r1 8                 // move to next column in row
  SUB r6 r1 r0             // check if X is still within bounds
  BRH ne .switch_down_loop // keep going if so
  LDI r1 0                 // reset X
  ADI r2 8                 // move to next row
  SUB r6 r2 r0             // check if Y is still within bounds
  BRH ne .switch_down_loop // keep going if so
  RET // return
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.switch_right
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  LDI r1 16    // X (make jump by 8)
  LDI r9 16    // X duplicate
  LDI r2 0     // Y (make jump by 8)
.switch_right_loop
  ADD r1 r0 r9 // duplicate X
  RSH r1 r13   // put X as an index in the array in r13 (X/8)
  RSH r13 r13  // ..
  RSH r13 r13  // ..
  LDI r14 base_board_pointer // load base board pointer into r14
  ADD r14 r13 r14 // turn (X/8) from an index into a pointer into RAM
  RSH r2 r13      // now put (Y/2) in r13
  ADD r14 r13 r14 // turn (Y/2) from an index into a pointer into RAM
  LOD r14 r13     // load value from cell
  ADD r13 r0 r0   // check r13; check cell value (check if empty)
  BRH eq .switch_right_postskip // if empty, skip push
  
  CAL .clear_square  // clear square

.switch_right_push
  LDI r12 0b00000011 // mask for X
  ADI r14 1          // current index - 1 (go right)
  ADI r9  8          // go right on screen
  AND r14 r12 r5     // r5 = least significant 2 bits
  // check if it rolled back around (stop! criminal scum)
  BRH eq .switch_right_preskip
  LOD r14 r12        // load new cell value
  CMP r12 r0         // check if cell is empty
  BRH ne .switch_right_push_skip // if not empty, skip push
  // r13 is non-zero.. right?
  NOR r8 r13 r8
  NOR r8 r8 r8       // OR r8 and r13 to indicate change, but not overwrite a win condition
  
  STR r14 r13        // store value at our current square, shifted right
  STR r14 r0 -1      // store 0 at current square
  JMP .switch_right_push // loop
.switch_right_push_skip
  CMP r12 r13        // compare both cells
  BRH ne .switch_right_preskip // if cells dont match, dont combine
  // r12 is non-zero.. right? use it before negation so number stays positive
  NOR r8 r12 r8
  NOR r8 r8 r8  // OR r8 and r12 to indicate change, but not overwrite a win condition
  
  ADI r12 1          // combine (add 1 to 'exponent' aka multiply by 2)
  SUB r0 r12 r12     // then negate
  STR r14 r12        // store new value into cell
  STR r14 r0 -1      // set other cell to 0
  ADD r12 r0 r5      // copy value into r5 (to update square with it)
  JMP .switch_right_skip // skip preskip
.switch_right_preskip
  ADI r14 -1         // move 1 column to the right, aka undo rolling back
  ADI r9 -8          // .. (do it on the screen)
  SUB r0 r13 r13     // negate number (so when it gets un-negated it doesn't accidentally negate)
  ADD r13 r0 r5      // copy value into r5 (to update square with it)
.switch_right_skip
  SUB r0 r5 r5       // un-negate number
  MOV r1 r12         // save r1 in r12
  MOV r9 r1          // put r9 into r1 (aka X in screenspace)
  CAL .paint_square  // update square
  ADD r12 r0 r1      // load back r1 from r12
.switch_right_postskip
  ADI r2 8                 // move to next row in column
  LDI r6 32                // change limit for Y
  SUB r6 r2 r0             // check if Y is still within bounds
  BRH ne .switch_right_loop // keep going if so
  LDI r6 -8                // change limit for X
  LDI r2 0                 // reset Y
  ADI r1 -8                // move to next column
  SUB r6 r1 r0             // check if X is still within bounds
  BRH ne .switch_right_loop // keep going if so
  RET // return
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<

.switch_up
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  LDI r2 16    // Y (make jump by 8)
  LDI r9 16    // Y duplicate
  LDI r1 0     // X (make jump by 8)
  LDI r6 -8    // Y limit
.switch_up_loop
  ADD r2 r0 r9 // duplicate Y
  RSH r2 r13   // put Y as an index in the array in r13 (Y/2)
  LDI r14 base_board_pointer // load base board pointer into r14
  ADD r14 r13 r14 // turn (Y/2) from an index into a pointer into RAM
  RSH r1 r13      // now put (X/8) in r13
  RSH r13 r13     // ..
  RSH r13 r13     // ..
  ADD r14 r13 r14 // turn (X/8) from an index into a pointer into RAM
  LOD r14 r13     // load value from cell
  ADD r13 r0 r0   // check r13; check cell value (check if empty)
  BRH eq .switch_up_postskip // if empty, skip push
  
  CAL .clear_square  // clear square

.switch_up_push
  LDI r12 0b00001100 // mask for Y
  ADI r14 4          // current index - 1 (go up)
  ADI r9  8          // go up on screen
  AND r14 r12 r5     // r5 = least significant 2 bits
  BRH eq .switch_up_preskip
  LOD r14 r12        // load new cell value
  CMP r12 r0         // check if cell is empty
  BRH ne .switch_up_push_skip // if not empty, skip push
  // r13 is non-zero.. right?
  NOR r8 r13 r8
  NOR r8 r8 r8       // OR r8 and r13 to indicate change, but not overwrite a win condition
  
  STR r14 r13        // store value at our current square, shifted up
  STR r14 r0 -4      // store 0 at current square
  JMP .switch_up_push // loop
.switch_up_push_skip
  CMP r12 r13        // compare both cells
  BRH ne .switch_up_preskip // if cells dont match, dont combine
  // r12 is non-zero.. right? use it before negation so number stays positive
  NOR r8 r12 r8
  NOR r8 r8 r8  // OR r8 and r12 to indicate change, but not overwrite a win condition
  
  ADI r12 1          // combine (add 1 to 'exponent' aka multiply by 2)
  SUB r0 r12 r12     // then negate
  STR r14 r12        // store new value into cell
  STR r14 r0 -4      // set other cell to 0
  ADD r12 r0 r5      // copy value into r5 (to update square with it)
  JMP .switch_up_skip // skip preskip
.switch_up_preskip
  ADI r14 -4         // move 1 column to the up, aka undo rolling back
  ADI r9 -8          // .. (do it on the screen)
  SUB r0 r13 r13     // negate number (so when it gets un-negated it doesn't accidentally negate)
  ADD r13 r0 r5      // copy value into r5 (to update square with it)
.switch_up_skip
  SUB r0 r5 r5       // un-negate number
  MOV r2 r12         // save r1 in r12
  MOV r9 r2          // put r9 into r1 (aka Y in screenspace)
  CAL .paint_square  // update square
  ADD r12 r0 r2      // load back r1 from r12
.switch_up_postskip
  ADI r1 8                 // move to next column in row
  LDI r6 32                // change limit for X
  SUB r6 r1 r0             // check if X is still within bounds
  BRH ne .switch_up_loop   // keep going if so
  LDI r6 -8                // change limit for Y
  LDI r1 0                 // reset X
  ADI r2 -8                // move to next row
  SUB r6 r2 r0             // check if Y is still within bounds
  BRH ne .switch_up_loop   // keep going if so
  RET // return
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<

// r1, r2, r4, r5, r13 modified
.render_screen
  LDI r1 0  // always at (0, 0) (X)
  LDI r2 0  // .. (Y)
  LDI r4 32 // bounds
  LDI r13 base_board_pointer // board address pointer
.render_screen_loop
  LOD r13 r5                 // load current cell
  ADD r5 r0 r0
  BRH eq .render_screen_skip_paint
  CAL .paint_square          // paint square at (r1, r2)
.render_screen_skip_paint
  ADI r13 1                  // increment pointer
  ADI r1 8                   // move right by 8
  SUB r1 r4 r0               // check if 32
  BRH ne .render_screen_loop // continue if so
  LDI r1 0                   // clear r1
  ADI r2 8                   // move up by 8
  SUB r2 r4 r0               // check if 32
  BRH ne .render_screen_loop // return if so
  
  RET // return

// modifies r1 r2 r3 r5 r13 r14 
.create_random_square
  LDI r5 1           // random piece type
  LOD r15 r1 RNJesus // pray to RNJesus
  LDI r2 230         // 0.9*256 (~90% chance)
  SUB r1 r2 r0       // give weight to random number and turn it into a binary result, ~90% 2 cell, ~10% 4 cell.
  BRH lt .create_two // use weighted random number, create 2 if in 90% half
  LDI r5 2           // .. if in the other 10% half, create 4
.create_two                 
  LDI r13 count_pointer // random loop index count address
  LDI r14 3             // random loop iterations + 1
  LOD r13 r1            // load the current random loop count
  ADD r1 r0 r0          // compare it
  BRH ne .create_random_square_skip
  LDI r3 0b00001111     // 4 bit mask
  LOD r15 r1 RNJesus    // RNJesus save us
  AND r3 r1 r1          // cut off top 4 bits
  LOD r15 r2 RNJesus    // RNJesus is the lord
  AND r3 r2 r2          // cut off top 4 bits
  LDI r13 126           // random number save address
  STR r13 r1 -2         // save random number 1
  STR r13 r2 -1         // save random number 2
  LDI r1 15             // reset the random index count to 15
.create_random_square_skip
  ADI r1 -1             // decrement :3
  STR r13 r1            // store loop index count
.random_piece_loop
  LDI r13 122           // random number addr ess - 2
  ADD r13 r14 r13       // offset address by loop count
  LOD r13 r2 1          // load random number 1
  ADI r14 -1            // decrement iteration 
  BRH eq .random_piece_end 
  LDI r13 108           // number map address
  ADD r13 r1 r13        // offset by number
  LOD r13 r1            // load mapped number
  XOR r2 r1 r1          // xor with random number
  JMP .random_piece_loop
.random_piece_end
  LDI r13 224        // board address
  ADD r13 r1 r13     // offset piece bag by the number 0-15
  LOD r13 r14        // fetch current number in that spot
  ADD r14 r0 r0
  BRH ne .create_two // if square isnt open, try again
  STR r13 r5         // store new number
  LDI r3 0b00000011
  AND r13 r3 r1
  LDI r3 0b00001100
  AND r13 r3 r2
  ADD r1 r1 r1
  ADD r1 r1 r1
  ADD r1 r1 r1
  ADD r2 r2 r2
  CAL .paint_square
  RET

// r1, r2 is the bottom left corner of the square
// r1, r2, r3, r4 used
// r3, r4 modified
.clear_square
  LDI r3 8     // load 8 into r3
  LDI r4 8     // load 8 into r4
  ADD r1 r3 r3 // r3 = r1 + 8 (right bound of the square being cleareD)
  ADD r2 r4 r4 // r4 = r2 + 8 (top bound of the square being cleared)
.clear_square_loop // it's on the label
  STR r15 r1 px      // set pixel X
  STR r15 r2 py      // set pixel Y
  STR r15 r0 clear_p // let me be clear
  ADI r1 1           // next column
  CMP r1 r3                 // keep going until X is right bound
  BRH ne .clear_square_loop //..
  ADI r1 -8          // reset X
  ADI r2 1           // next row
  CMP r2 r4                 // keep going until Y is upper bound
  BRH ne .clear_square_loop // ..
  ADI r2 -8 // reset Y (r1 and r2 are unharmed :3)
  RET       // return

// r1, r2 is the bottom left corner of the square
// r5 is exponent
// r3, r10, r11, r14 modified
.paint_square
  LOD r5 r14   // load number bitmask address
  LOD r14 r10  // load first bitmask byte
  LDI r11 1    // mask for LSB (Lumpy Space Brincess)
  LDI r3 8     // limit?
  ADD r1 r3 r3 // ..
.paint_square_loop // It's on the label (https://merriam-webster.com/dictionary/label)
  AND r11 r10 r0 // check LSB
  STR r15 r1 px  // set pixel X
  STR r15 r2 py  // set pixel Y
  BRH eq .paint_square_loop_erase // if LSB is 0, clear pixel
  STR r15 r0 draw_p               // draw else
  JMP .paint_square_loop_skip     // 
.paint_square_loop_erase
  STR r15 r0 clear_p
.paint_square_loop_skip
  ADI r2 1
  ADD r11 r11 r11 // left shift bit mask
  BRH ne .paint_square_loop
  LDI r11 1 // bit mask reset
  ADI r2 -8 // reset x
  ADI r14 1 // increment number byte address
  LOD r14 r10 // load byte
  ADI r1 1
  SUB r1 r3 r0
  BRH ne .paint_square_loop
  ADI r1 -8
  
  ADD r5 r0 r10
  ADI r10 -11  // if exponent is 11 (drawing a 2048 square), YOUR WINNER!!!
  BRH ne .not_win
  LSH r1 r8
  LSH r2 r2
  LSH r2 r2
  LSH r2 r2
  ADD r2 r8 r8
  RSH r2 r2
  RSH r2 r2
  RSH r2 r2
.not_win

  RET

// r13, r14 modified.. alot
.load_square_data_to_ram
  // pointers to number bitmasks
  LDI r13 0
  LDI r14 12
  STR r13 r14 0
  ADI r14 8
  STR r13 r14 1
  ADI r14 8
  STR r13 r14 2
  ADI r14 8
  STR r13 r14 3
  ADI r14 8
  STR r13 r14 4
  ADI r14 8
  STR r13 r14 5
  ADI r14 8
  STR r13 r14 6
  ADI r14 8
  STR r13 r14 7
  ADI r13 8
  ADI r14 8
  STR r13 r14 0
  ADI r14 8
  STR r13 r14 1
  ADI r14 8
  STR r13 r14 2
  ADI r14 8
  STR r13 r14 3
  LDI r13 12
// 0 (wait how can 2^x be 0)
  ADI r13 8
// 2
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b11010111
  STR r13 r14 4
  LDI r14 0b10000111
  STR r13 r14 5
  LDI r14 0b11110111
  STR r13 r14 6
  LDI r14 0b11111111
  STR r13 r14 7
  ADI r13 8
// 4
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b10011111
  STR r13 r14 4
  LDI r14 0b11011111
  STR r13 r14 5
  LDI r14 0b10000111
  STR r13 r14 6
  LDI r14 0b11111111
  STR r13 r14 7
  ADI r13 8
// 8
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b10110111
  STR r13 r14 4
  LDI r14 0b10010111
  STR r13 r14 5
  LDI r14 0b10000111
  STR r13 r14 6
  LDI r14 0b11111111
  STR r13 r14 7
  ADI r13 8
// 16
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b10110111
  STR r13 r14 4
  LDI r14 0b10010111
  STR r13 r14 5
  LDI r14 0b10000111
  STR r13 r14 6
  LDI r14 0b11111111
  STR r13 r14 7
  ADI r13 8
// 32
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b10010111
  STR r13 r14 4
  LDI r14 0b10010111
  STR r13 r14 5
  LDI r14 0b10100111
  STR r13 r14 6
  LDI r14 0b11111111
  STR r13 r14 7
  ADI r13 8
// 64
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b10000111
  STR r13 r14 4
  LDI r14 0b10100111
  STR r13 r14 5
  LDI r14 0b10100111
  STR r13 r14 6
  LDI r14 0b11111111
  STR r13 r14 7
  ADI r13 8
// 128
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b10111111
  STR r13 r14 4
  LDI r14 0b10111111
  STR r13 r14 5
  LDI r14 0b10000111
  STR r13 r14 6
  LDI r14 0b11111111
  STR r13 r14 7
  ADI r13 8
// 256
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b10000111
  STR r13 r14 4
  LDI r14 0b10010111
  STR r13 r14 5
  LDI r14 0b10000111
  STR r13 r14 6
  LDI r14 0b11111111
  STR r13 r14 7
  ADI r13 8
// 512
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b10011111
  STR r13 r14 4
  LDI r14 0b10011111
  STR r13 r14 5
  LDI r14 0b10000111
  STR r13 r14 6
  LDI r14 0b11111111
  STR r13 r14 7
  ADI r13 8
// 1024
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b10001111
  STR r13 r14 4
  LDI r14 0b11111111
  STR r13 r14 5
  LDI r14 0b10001111
  STR r13 r14 6
  LDI r14 0b10001111
  STR r13 r14 7
  ADI r13 8
// 2048
  LDI r14 0b11111111
  STR r13 r14 0
  LDI r14 0b11101001
  STR r13 r14 1
  LDI r14 0b11100101
  STR r13 r14 2
  LDI r14 0b11111111
  STR r13 r14 3
  LDI r14 0b10001111
  STR r13 r14 4
  LDI r14 0b11111111
  STR r13 r14 5
  LDI r14 0b10001111
  STR r13 r14 6
  LDI r14 0b11111111
  STR r13 r14 7
  ADI r13 8
  LDI r14 8
  STR r13 r14 0
  LDI r14 13
  STR r13 r14 1
  LDI r14 9
  STR r13 r14 2
  LDI r14 5
  STR r13 r14 3
  LDI r14 11
  STR r13 r14 4
  LDI r14 7
  STR r13 r14 5
  LDI r14 15
  STR r13 r14 6
  LDI r14 4
  STR r13 r14 7
  ADI r13 8
  LDI r14 14
  STR r13 r14 0
  LDI r14 10
  STR r13 r14 1
  LDI r14 0
  STR r13 r14 2
  LDI r14 6
  STR r13 r14 3
  LDI r14 3
  STR r13 r14 4
  LDI r14 12
  STR r13 r14 5
  LDI r14 2
  STR r13 r14 6
  LDI r14 1
  STR r13 r14 7
  LDI r8 1
  CAL .create_random_square
  JMP .game_loop