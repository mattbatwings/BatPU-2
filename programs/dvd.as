// Bouncing DVD by zPippo

ldi r15 clear_chars_buffer
str r15 r0
ldi r15 write_char
ldi r1 "D"
str r15 r1
ldi r1 "V"
str r15 r1
ldi r1 "D"
str r15 r1
ldi r1 " "
str r15 r1
ldi r1 " "
str r15 r1
ldi r1 " "
str r15 r1
ldi r1 " "
str r15 r1
ldi r1 " "
str r15 r1
ldi r1 " "
str r15 r1
ldi r1 " "
str r15 r1
ldi r15 buffer_chars
str r15 r0

ldi r1 0
ldi r2 79
str r1 r2
inc r1
ldi r2 201
str r1 r2
inc r1
ldi r2 230
str r1 r2
inc r1
ldi r2 224
str r1 r2
inc r1
ldi r2 231
str r1 r2
inc r1
ldi r2 168
str r1 r2
inc r1
ldi r2 231
str r1 r2
inc r1
ldi r2 224
str r1 r2
inc r1
ldi r2 239
str r1 r2
inc r1
ldi r2 105
str r1 r2
inc r1
ldi r2 70
str r1 r2
inc r1

ldi r1 0 // X position
ldi r2 0 // Y position
ldi r3 1 // X velocity
ldi r4 1 // Y velocity

ldi r11 clear_screen_buffer
ldi r12 pixel_x
ldi r13 pixel_y
ldi r14 draw_pixel
ldi r15 buffer_screen

.loop
str r11 r0
cal .draw_logo
str r15 r0
cal .movement
cal .collision

jmp .loop


.draw_logo
ldi r8 0
ldi r9 11
ldi r10 1
.next_byte
	lod r8 r7
	ldi r6 8
	add r8 r1 r8
	str r12 r8
	sub r8 r1 r8
	.next_pixel
		dec r6
		
		and r7 r10 r0
		brh zero .skip_pixel
		add r6 r2 r6
		str r13 r6
		sub r6 r2 r6
		str r14 r0
		.skip_pixel
		rsh r7 r7
		
		mov r6 r6
		brh notzero .next_pixel
	
	inc r8
	cmp r8 r9
	brh notzero .next_byte

ret


.movement
add r1 r3 r1
add r2 r4 r2
ret


.collision
ldi r5 21
ldi r6 24
cmp r1 r5
brh zero .invert_x
cmp r1 r0
brh zero .invert_x
.y_check
cmp r2 r6
brh zero .invert_y
cmp r2 r0
brh zero .invert_y
ret

.invert_x
sub r0 r3 r3
jmp .y_check

.invert_y
sub r0 r4 r4
ret