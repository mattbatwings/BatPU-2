# Calculator by VIBaJ
# Run with 300 ips for a somewhat bearable experience, 5-10k for decent responsiveness, 20k for pretty much instant response.

# left/right/up/down to choose a button, select to press it
# type an expression ('<' button is backspace), press '=' button, and the result will appear on the number display
# the calculator display that shows the expression only fits 7 characters, but you can type much more. It'll scroll as you type past 7 characters
# only supports 8 bit integers written in decimal. Can be signed or unsigned depending on mode (shown on character display, toggle with '+-' button)
# has addition, subtraction (and negation for a unary minus), multiplication, division, order of operations, and parentheses
# very large expressions will cause bugs once the data representing them runs out of space in RAM. Any normal expression won't be this large
# doesn't detect invalid syntax. Invalid syntax can cause many fun bugs

ldi r15 buffer_chars
define x -8
define y -7
define draw -6
define clear -5
define load -4
define buffer -3
define write -1
define clear_chars 1
define number 2
define clear_num 3
define signed 4
define unsigned 5
define inputs 7

define select 64
define up 8
define right 4
define down 2
define left 1

ldi r1 8
# 0
ldi r2 0b01010110
str r1 r2 -8
ldi r2 0b11010100
str r1 r2 -7
# 1
ldi r2 0b11101001
str r1 r2 -6
ldi r2 0b01100100
str r1 r2 -5
# 2
ldi r2 0b11110001
str r1 r2 -4
ldi r2 0b00011100
str r1 r2 -3
# 3
ldi r2 0b11000111
str r1 r2 -2
ldi r2 0b00011100
str r1 r2 -1
# 4
ldi r2 0b00100111
str r1 r2
ldi r2 0b11011010
str r1 r2 1
# 5
ldi r2 0b11000111
str r1 r2 2
ldi r2 0b01001110
str r1 r2 3
# 6
ldi r2 0b01010111
str r1 r2 4
ldi r2 0b01000110
str r1 r2 5
# 7
ldi r2 0b10001001
str r1 r2 6
ldi r2 0b00011110
str r1 r2 7

ldi r1 24
# 8
ldi r2 0b01010101
str r1 r2 -8
ldi r2 0b01010100
str r1 r2 -7
# 9
ldi r2 0b00100101
str r1 r2 -6
ldi r2 0b11010110
str r1 r2 -5
# +
ldi r2 0b00001011
str r1 r2 -4
ldi r2 0b10100000
str r1 r2 -3
# -
ldi r2 0b00000011
str r1 r2 -2
ldi r2 0b10000000
str r1 r2 -1
# *
ldi r2 0b00010101
str r1 r2
ldi r2 0b01010000
str r1 r2 1
# /
ldi r2 0b01000011
str r1 r2 2
ldi r2 0b10000100
str r1 r2 3
# (
ldi r2 0b00101001
str r1 r2 4
ldi r2 0b00100010
str r1 r2 5
# )
ldi r2 0b10001001
str r1 r2 6
ldi r2 0b00101000
str r1 r2 7

define plus 20
define minus 22
define times 24
define divide 26
define unary_minus 27
define left_paren 28
define right_paren 30

# draw buttons
    # digits
    ldi r1 0
    ldi r2 2
    ldi r3 2
    cal .char
    ldi r1 2
    ldi r3 8
    ldi r9 20
    ldi r10 26
    cal .char_grid
    # backspace
    ldi r1 minus
    ldi r2 8
    ldi r3 2
    cal .char
    ldi r1 left_paren
    cal .char
    ldi r1 plus
    ldi r2 9
    cal .char
    ldi r2 11
    str r15 r2 x
    ldi r2 4
    str r15 r2 y
    str r15 r0 clear
    # toggle signedness
    ldi r2 14
    ldi r3 3
    cal .char
    ldi r1 minus
    ldi r3 0
    cal .char
    # operations/parentheses
    ldi r1 plus
    ldi r2 21
    ldi r3 8
    ldi r9 33
    ldi r10 26
    cal .char_grid
    # equals
    ldi r1 minus
    ldi r2 24
    ldi r3 1
    cal .char
    ldi r3 3
    cal .char
ldi r13 1 # r13: selection x
ldi r14 2 # r14: selection y
cal .highlight
str r15 r0 buffer

str r15 r0 signed
adi r0 0
cal .write_signedness

define display_stack_pointer 32

ldi r1 33
str r1 r1 -1
.get_input
    ldi r4 0
    ldi r5 0
    lod r15 r1 inputs
    ldi r2 up
    and r1 r2 r0
    brh nz .up
    ldi r2 right
    and r1 r2 r0
    brh nz .right
    ldi r2 down
    and r1 r2 r0
    brh nz .down
    ldi r2 left
    and r1 r2 r0
    brh nz .left
    ldi r2 select
    and r1 r2 r0
    brh nz .select
    jmp .get_input
    .up
        ldi r1 20
        cmp r14 r1
        brh eq .get_input
        ldi r5 6
        jmp .move_selection
    .right
        ldi r4 7
        ldi r1 13
        cmp r13 r1
        brh eq .move_selection
        ldi r1 2
        cmp r14 r1
        brh ne .right_continue
            ldi r1 20
            cmp r13 r1
            brh eq .get_input
        .right_continue
        ldi r1 26
        cmp r13 r1
        brh eq .get_input
        ldi r4 6
        jmp .move_selection
    .down
        ldi r1 2
        cmp r14 r1
        brh eq .get_input
        ldi r1 8
        cmp r14 r1
        brh ne .down_continue
            ldi r4 -6
            ldi r1 26
            cmp r13 r1
            brh eq .down_continue
            ldi r4 0
        .down_continue
        ldi r5 -6
        jmp .move_selection
    .left
        ldi r1 1
        cmp r13 r1
        brh eq .get_input
        ldi r4 -7
        ldi r1 20
        cmp r13 r1
        brh eq .move_selection
        ldi r4 -6
        jmp .move_selection
    .select
        # add char
        ldi r1 display_stack_pointer # r1: display stack pointer
        lod r1 r2 # r2: display pointer
        # selection to char; r3: char
            ldi r4 2
            cmp r14 r4
            brh ne .continue_0
                ldi r3 0 # 0
                ldi r4 1
                cmp r13 r4
                brh eq .matched
                ldi r4 7 # backspace
                cmp r13 r4
                brh ne .not_backspace
                    ldi r4 33
                    cmp r2 r4
                    brh eq .backspace
                        dec r2
                        jmp .backspace
                .not_backspace
                ldi r4 13 # toggle signedness
                cmp r13 r4
                brh ne .equals
                    str r15 r0 clear_chars
                    ldi r4 239
                    lod r4 r3
                    not r3 r3
                    str r4 r3
                    cal .write_signedness
                    jmp .wait_for_release
                .equals
                    ldi r3 33
                    cmp r2 r3
                    brh ne .not_blank
                        str r15 r0 clear_num
                        jmp .wait_for_release
                    .not_blank
                    # calculate result w/ shunting yard algorithm; r1: chars index, r2: numbers pointer, r3: operators pointer
                    ldi r3 238
                    mov r2 r4 # r4: chars end
                    ldi r7 0 # r7: result from bcd to binary conversion
                    ldi r9 0 # r9: getting number
                    .equals_loop
                        inc r1
                        cmp r1 r4
                        brh eq .end_equals_loop
                        lod r1 r6 # r6: current char
                        ldi r5 20
                        cmp r6 r5
                        brh ge .not_number
                            ldi r9 1
                            rsh r6 r6 # char to digit
                            # multiply r7 by 10 and add digit
                            lsh r7 r7
                            add r7 r6 r8
                            lsh r7 r7
                            lsh r7 r7
                            add r7 r8 r7
                            jmp .equals_loop
                        .not_number
                        cmp r9 r0
                        brh eq .not_getting_number_0
                            str r2 r7
                            inc r2
                            ldi r7 0
                            ldi r9 0
                        .not_getting_number_0
                        ldi r5 left_paren
                        cmp r6 r5
                        brh ne .not_left_paren
                            str r3 r6
                            dec r3
                            jmp .equals_loop
                        .not_left_paren
                        ldi r5 right_paren
                        cmp r6 r5
                        brh ne .not_right_paren
                            .paren_loop
                                inc r3
                                lod r3 r6
                                ldi r5 left_paren
                                cmp r6 r5
                                brh eq .equals_loop
                                cal .use_operator
                                jmp .paren_loop
                        .not_right_paren
                        ldi r5 minus
                        cmp r6 r5
                        brh ne .not_minus_0
                            # check for unary minus
                            dec r1
                            ldi r5 display_stack_pointer
                            cmp r1 r5
                            brh eq .unary_minus
                            lod r1 r5
                            ldi r6 plus
                            cmp r5 r6
                            brh lt .binary_minus
                            ldi r6 right_paren
                            cmp r5 r6
                            brh eq .binary_minus
                            .unary_minus
                            inc r1
                            ldi r6 unary_minus
                            str r3 r6
                            dec r3
                            jmp .equals_loop
                            .binary_minus
                            inc r1
                            ldi r6 plus
                        .not_minus_0
                        ldi r5 divide
                        cmp r6 r5
                        brh ne .not_divide
                            ldi r6 times
                        .not_divide
                        .shunting_yard_loop
                            inc r3
                            ldi r8 239
                            cmp r3 r8
                            brh eq .end_shunting_yard_loop
                            lod r3 r5
                            ldi r8 left_paren
                            cmp r5 r8
                            brh eq .end_shunting_yard_loop
                            cmp r5 r6
                            brh lt .end_shunting_yard_loop
                            mov r5 r6
                            cal .use_operator
                            jmp .shunting_yard_loop
                        .end_shunting_yard_loop
                        lod r1 r6
                        dec r3
                        str r3 r6
                        dec r3
                        jmp .equals_loop
                    .end_equals_loop
                    cmp r9 r0
                    brh eq .not_getting_number_1
                        str r2 r7
                        inc r2
                    .not_getting_number_1
                    # pop all operators
                    .pop_ops_loop
                        ldi r4 238
                        cmp r3 r4
                        brh eq .end_pop_ops_loop
                        inc r3
                        lod r3 r6
                        cal .use_operator
                        jmp .pop_ops_loop
                    .end_pop_ops_loop
                    # display result
                    ldi r4 239
                    lod r4 r4
                    cmp r4 r0
                    brh ne .unsigned
                        str r15 r0 signed
                        jmp .signed
                    .unsigned
                        str r15 r0 unsigned
                    .signed
                    lod r1 r1
                    str r15 r1 number
                jmp .wait_for_release
            .continue_0
            ldi r4 8
            cmp r14 r4
            brh ne .continue_1
                ldi r3 2 # 1
                ldi r4 1
                cmp r13 r4
                brh eq .matched
                ldi r3 4 # 2
                ldi r4 7
                cmp r13 r4
                brh eq .matched
                ldi r3 6 # 3
                ldi r4 13
                cmp r13 r4
                brh eq .matched
                ldi r3 plus
                ldi r4 20
                cmp r13 r4
                brh eq .matched
                ldi r3 minus
                jmp .matched
            .continue_1
            ldi r4 14
            cmp r14 r4
            brh ne .continue_2
                ldi r3 8 # 4
                ldi r4 1
                cmp r13 r4
                brh eq .matched
                ldi r3 10 # 5
                ldi r4 7
                cmp r13 r4
                brh eq .matched
                ldi r3 12 # 6
                ldi r4 13
                cmp r13 r4
                brh eq .matched
                ldi r3 times
                ldi r4 20
                cmp r13 r4
                brh eq .matched
                ldi r3 divide
                jmp .matched
            .continue_2
            ldi r3 14 # 7
            ldi r4 1
            cmp r13 r4
            brh eq .matched
            ldi r3 16 # 8
            ldi r4 7
            cmp r13 r4
            brh eq .matched
            ldi r3 18 # 9
            ldi r4 13
            cmp r13 r4
            brh eq .matched
            ldi r3 left_paren
            ldi r4 20
            cmp r13 r4
            brh eq .matched
            ldi r3 right_paren
        .matched
        str r2 r3
        inc r2
        .backspace
        str r1 r2
        # clear display
        ldi r2 25 # r2: y
        ldi r3 30 # end
        .display_y_loop
            inc r2
            ldi r1 3 # r1: x
            .display_x_loop
                str r15 r1 x
                str r15 r2 y
                str r15 r0 clear
                inc r1
                cmp r1 r3
                brh lt .display_x_loop
            cmp r2 r3
            brh lt .display_y_loop
        # draw display
        ldi r9 display_stack_pointer # r9: display stack pointer
        lod r9 r10 # r10: display pointer
        ldi r2 27 # r2: x
        ldi r3 26 # r3: y
        .display_loop
            dec r10
            cmp r10 r9
            brh eq .exit_display_loop
            lod r10 r1
            cal .char
            adi r2 -4
            brh c .display_loop
        .exit_display_loop

        str r15 r0 buffer
        jmp .wait_for_release

.use_operator # apply operator r6 to numbers stack; affects r2, r5-6, r8, r10-12
    # r2: numbers pointer, r12: result
    dec r2
    lod r2 r10 # r10: 2nd operand (unary minus: only operand)
    ldi r5 unary_minus
    cmp r6 r5
    brh ne .not_unary_minus
        sub r0 r10 r12
        jmp .operator_done
    .not_unary_minus
    # binary operators
    dec r2
    lod r2 r8 # r8: 1st operand
    ldi r11 plus
    cmp r6 r11
    brh ne .not_plus
        add r8 r10 r12
        jmp .operator_done
    .not_plus
    ldi r11 minus
    cmp r6 r11
    brh ne .not_minus_1
        sub r8 r10 r12
        jmp .operator_done
    .not_minus_1
    ldi r11 times
    cmp r6 r11
    brh ne .not_times
        ldi r11 1 # r11: current bit of b
        ldi r12 0
        .mult_loop
            and r10 r11 r0
            brh z .mult_skip_add
                add r12 r8 r12
            .mult_skip_add
            lsh r8 r8
            lsh r11 r11
            brh nz .mult_loop
        jmp .operator_done
    .not_times
    # divide
    ldi r11 0 # r11: negative
    ldi r15 128 # r15: check 1st bit
    ldi r12 239
    lod r12 r12
    cmp r12 r0
    brh ne .divide_unsigned
        and r8 r15 r0
        brh z .positive_0
            sub r0 r8 r8
            not r11 r11
        .positive_0
        and r10 r15 r0
        brh z .positive_1
            sub r0 r10 r10
            not r11 r11
        .positive_1
    .divide_unsigned
    ldi r12 0
    ldi r5 0 # r5: subtract from
    ldi r6 128 # r6: current bit
    .divide_loop
        lsh r5 r5
        and r8 r15 r0
        brh z .zero
            inc r5
        .zero
        lsh r8 r8
        cmp r5 r10
        brh lt .too_small
            sub r5 r10 r5
            add r12 r6 r12
        .too_small
        rsh r6 r6
        cmp r6 r0
        brh ne .divide_loop
    cmp r11 r0
    brh eq .positive_2
        sub r0 r12 r12
    .positive_2
    .operator_done
    str r2 r12
    inc r2
    ldi r15 buffer_chars
    ret

.write_signedness # write "SIGNED", prefixed w/ "UN" if zero flag is 0; affects r3
    brh z .write_signed
        ldi r3 'U'
        str r15 r3 write
        ldi r3 'N'
        str r15 r3 write
    .write_signed
    ldi r3 'S'
    str r15 r3 write
    ldi r3 'I'
    str r15 r3 write
    ldi r3 'G'
    str r15 r3 write
    ldi r3 'N'
    str r15 r3 write
    ldi r3 'E'
    str r15 r3 write
    ldi r3 'D'
    str r15 r3 write
    str r15 r0
    ret

.move_selection # move selection by (r4, r5); affects r1-5, r11-14
    cal .highlight
    add r13 r4 r13
    add r14 r5 r14
    cal .highlight
    str r15 r0 buffer
    jmp .wait_for_release

.wait_for_release # wait until not pressing anything; affects r1
    .holding
        lod r15 r1 inputs
        cmp r1 r0
        brh ne .holding
    jmp .get_input

.highlight # flip pixels of selection; affects r1-3, r11-12
    # r12: x loop index
    ldi r12 5 # r12: x loop index
    ldi r1 2
    cmp r14 r1
    brh ne .highlight_continue
        ldi r1 20
        cmp r13 r1
        brh ne .highlight_continue
            ldi r12 11
    .highlight_continue
    mov r13 r1 # r1: pixel x
    .highlight_x_loop
        ldi r11 5 # r11: y loop index
        mov r14 r2 # r2: pixel y
        .highlight_y_loop
            str r15 r1 x
            str r15 r2 y
            lod r15 r3 load
            cmp r3 r0
            brh ne .highlight_clear
                str r15 r0 draw
                jmp .highlight_draw
            .highlight_clear
                str r15 r0 clear
            .highlight_draw
            inc r2
            dec r11
            brh nz .highlight_y_loop
        inc r1
        dec r12
        brh nz .highlight_x_loop
    ret

.char # print char r1 at (r2, r3); affects r4-8
    mov r2 r4 # r4: pixel x (r3: pixel y)
    lod r1 r5 # r5: current pixels
    ldi r6 128 # r6: current bit
    ldi r7 5 # r7: y loop index
    .char_y_loop
        ldi r8 3 # r8: x loop index
        .char_x_loop
            and r5 r6 r0
            brh z .char_skip_pixel
                str r15 r4 x
                str r15 r3 y
                str r15 r0 draw
            .char_skip_pixel
            rsh r6 r6
            cmp r6 r0
            brh ne .char_continue
                lod r1 r5 1
                ldi r6 128
            .char_continue
            inc r4
            dec r8
            brh nz .char_x_loop
        mov r2 r4
        inc r3
        dec r7
        brh nz .char_y_loop
    adi r3 -5
    ret

.char_grid # print char grid from (r2, r3) to (r9, r10), starting at r1; affects r1-8, r11
    mov r2 r11 # r11: x
    .char_grid_y_loop
        mov r11 r2
        .char_grid_x_loop
            cal .char
            adi r1 2
            adi r2 6
            cmp r2 r9
            brh lt .char_grid_x_loop
        adi r3 6
        cmp r3 r10
        brh lt .char_grid_y_loop
    ret