# Depth-first search maze generator by VIBaJ

ldi r15 buffer_chars
define x -8
define y -7
define draw -6
define load -4
define buffer -3
define write -1
define clear_chars 1
define random 6

# write "DFS MAZE"
ldi r4 'D'
str r15 r4 write
ldi r4 'F'
str r15 r4 write
ldi r4 'S'
str r15 r4 write
ldi r4 ' '
str r15 r4 write
ldi r4 'M'
str r15 r4 write
ldi r4 'A'
str r15 r4 write
ldi r4 'Z'
str r15 r4 write
ldi r4 'E'
str r15 r4 write
str r15 r0

# r1: x, r2: y, r3: stack pointer
str r15 r0 draw
.loop
    # find open directions
    mov r3 r7 # r7: direction stack pointer
    ldi r5 -1
    ldi r6 0
    cal .check_direction
    ldi r5 1
    cal .check_direction
    ldi r5 0
    ldi r6 -1
    cal .check_direction
    ldi r6 1
    cal .check_direction

    sub r7 r3 r7
    brh z .backtrack
        # pick random direction
        rsh r7 r7
        ldi r5 0b11
        .rejection_loop
            lod r15 r4 random
            and r4 r5 r4
            cmp r4 r7
            brh ge .rejection_loop
        lsh r4 r4
        add r3 r4 r4
        # draw path in chosen direction
        lod r4 r5
        lod r4 r6 1
        cal .make_path
        cal .make_path
        str r15 r0 buffer
        # push to stack; -1 -> left, 1 -> right, -2 -> down, 2 -> up
        lsh r6 r6
        add r5 r6 r4
        str r3 r4
        inc r3
        jmp .loop
    .backtrack
    # if back to (0, 0), write "DONE" and halt
    cmp r1 r0
    brh ne .continue
        cmp r2 r0
        brh ne .continue
        str r15 r0 clear_chars
        ldi r4 'D'
        str r15 r4 write
        ldi r4 'O'
        str r15 r4 write
        ldi r4 'N'
        str r15 r4 write
        ldi r4 'E'
        str r15 r4 write
        str r15 r0
        hlt
    .continue
    # pop from stack; -1 -> right, 1 -> left, -2 -> up, 2 -> down
    dec r3
    lod r3 r4
    ldi r5 -1
    cmp r4 r5
    brh ne .not_right
        adi r1 2
        jmp .loop
    .not_right
    ldi r5 1
    cmp r4 r5
    brh ne .not_left
        adi r1 -2
        jmp .loop
    .not_left
    ldi r5 -2
    cmp r4 r5
    brh ne .not_up
        adi r2 2
        jmp .loop
    .not_up
    adi r2 -2
    jmp .loop

.make_path # make path in direction (r5, r6); affects r1-2
    add r1 r5 r1
    add r2 r6 r2
    str r15 r1 x
    str r15 r2 y
    str r15 r0 draw
    ret

.check_direction # check if direction (r5, r6) is blocked; if not, push direction to direction stack; affects r4, r7-9
    add r1 r5 r8
    add r8 r5 r8
    add r2 r6 r9
    add r9 r6 r9
    ldi r4 32
    cmp r8 r4
    brh ge .blocked
    cmp r9 r4
    brh ge .blocked
    str r15 r8 x
    str r15 r9 y
    lod r15 r4 load
    cmp r4 r0
    brh ne .blocked
        str r7 r5
        str r7 r6 1
        adi r7 2
    .blocked
    ret