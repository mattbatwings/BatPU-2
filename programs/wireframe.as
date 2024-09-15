// Wireframe Demo by Dave Walker

// A basic implementation of a CORDIC function operating in rotation mode.  A CORDIC can be
// used to iteratively calculate sine and cosine of an angle. Due to the limitations of this
// 8-bit computer, the CORDIC isn't particularly accurate.  A number of values in this code are
// represented as fixed point representations.  Therefore, you'll see notations like u2.5 and
// s1.6.  These notations denote signed/unsigned, the number of integer bits, and the number of
// fractional bits.  For example, the sine/cosine outputs are all s1.6.
//
// In addition to the CORDIC, a draw_line function is included based on Bresenham's Algorithm.
//
// (Note: I'm not crazy with how I pass inputs to functions in this code using registers.  I think
// I'd prefer to pass them via memory (i.e. a stack).  I'd also possibly like to dedicate a
// register as a stack pointer.  I haven't written assembly in years so I'm not accustomed
// to dealing with this stuff directly.  Perhaps I'll change it later... perhaps not.)


// Memory mapped IO port mapping offsets
// from memory_mapped_io_addr (248)
define memory_mapped_io_addr     248
define pixel_x_offset             -8
define pixel_y_offset             -7
define draw_pixel_offset          -6
define clear_pixel_offset         -5
define load_pixel_offset          -4
define buffer_screen_offset       -3
define clear_screen_buffer_offset -2
define write_char_offset          -1
define buffer_chars_offset         0
define clear_chars_buffer_offset   1
define show_number_offset          2
define clear_number_offset         3
define signed_mode_offset          4
define unsigned_mode_offset        5
define rng_offset                  6
define controller_input_offset     7

// Various RAM addresses
define x2_coord                    0
define y2_coord                    1
define register_stack_pointer      50
define shape_vertices_edges_addr   100
define projected_points_addr       150
define atan_LUT_strt_addr          232

// Other constants
define y_axis                      0
define x_axis                      1
define z_axis                      2
define focal_length               127


// Load the arctan LUT into RAM.
CAL .load_atan_lut

// Load shape data into RAM.
CAL .load_shape_vertices_edges

// Clear the screen and number display
LDI r15 memory_mapped_io_addr
STR r15 r0 clear_screen_buffer_offset
STR r15 r0 buffer_screen_offset
STR r15 r0 unsigned_mode_offset
STR r15 r0 clear_chars_buffer_offset
STR r15 r0 buffer_chars_offset

// Write "3DROTATION"
STR r15 r0 clear_chars_buffer_offset
LDI r14 " "
STR r15 r14 write_char_offset
LDI r14 "R"
STR r15 r14 write_char_offset
LDI r14 "O"
STR r15 r14 write_char_offset
LDI r14 "T"
STR r15 r14 write_char_offset
LDI r14 "A"
STR r15 r14 write_char_offset
LDI r14 "T"
STR r15 r14 write_char_offset
LDI r14 "I"
STR r15 r14 write_char_offset
LDI r14 "O"
STR r15 r14 write_char_offset
LDI r14 "N"
STR r15 r14 write_char_offset
LDI r14 " "
STR r15 r14 write_char_offset
STR r15 r0 buffer_chars_offset


// Initialze rotation angle
LDI r1 28
.main_loop

    // Point to 3D share vertice/edge table
    LDI r15 shape_vertices_edges_addr
    LOD r15 r14 0   // Load number of vertices in r14
    INC r15         // And point to first vertice

    // Load 2D projected points table address
    LDI r13 projected_points_addr

    // Now loop through all of the 3D vertices in memory to
    // rotate and project them onto a 2D plane for display.
    .vertice_loop
        LOD r15 r2 0
        LOD r15 r3 1
        LOD r15 r4 2
        ADI r15 3
        LDI r5 y_axis      // Rotation axis

        LDI r12 0
        STR r12 r1  0 // Store angle in RAM
        STR r12 r14 1 // Store number of vertices RAM
        STR r12 r15 2 // Store vertice pointer in RAM
        // TODO: Change rotation function so it doesn't call CORDIC
        // i.e. move CORDIC call outside of vertice loop since I don't
        // need to calculate it again each time
        CAL .rotation
        LDI r7 focal_length
        CAL .pixel_projection
        ADI r1 16
        ADI r2 16

        LDI r15 memory_mapped_io_addr
        STR r15 r1 pixel_x_offset
        STR r15 r2 pixel_y_offset
        STR r15 r0 draw_pixel_offset

        LDI r12 0
        LOD r12 r1  0 // Store angle in RAM
        LOD r12 r14 1 // Store number of vertices RAM
        LOD r12 r15 2 // Store vertice pointer in RAM

        DEC r14
        BRH nz .vertice_loop

    LDI r12 0
    STR r12 r1  0 // Store angle in RAM
    STR r12 r14 1 // Store number of vertices RAM
    STR r12 r15 2 // Store vertice pointer in RAM

    LDI r15 memory_mapped_io_addr
    STR r15 r0 buffer_screen_offset
    STR r15 r0 clear_screen_buffer_offset

    LDI r12 0
    LOD r12 r1  0 // Store angle in RAM
    LOD r12 r14 1 // Store number of vertices RAM
    LOD r12 r15 2 // Store vertice pointer in RAM




//    // Push the r13 angle value to RAM since it gets modified inside the draw_line function
//    LDI r15 register_stack_pointer
//    STR r15 r13
//    CAL .draw_line
//    // And pop it back off when finished
//    LDI r15 register_stack_pointer
//    LOD r15 r13

//    // Store the x1/y1 coordinates to RAM so they can be x2/y2 next iteration
//    LDI r15 x2_coord
//    STR r15 r3 x2_coord
//    STR r15 r4 y2_coord

    // Display current angle
    LDI r15 memory_mapped_io_addr
    STR r15 r1 show_number_offset

    // Increment the angle and loop
    ADI r1 1
    LDI r14 201  // Ending angle
    CMP r1 r14
    BRH lt .main_loop
    SUB r1 r14 r1
    JMP .main_loop
HLT


.cordic
// CORDIC function computes sine and cosine of angle.
// Input:
//  r1  = angle in radians (fixed point in the form u2.5)
//        (Values between 0 and 2*pi are supported.)
// Outputs:
//  r2  = sine  (r1)
//  r3  = cosine(r1)
// Register usage
//  r1  - angle in radians (s1.6)
//  r2  - x (s1.6)
//  r3  - y (s1.6)
//  r4  - iteration counter (i)
//  r5  - temp iteration counter/scratch
//  r6  - shifted x
//  r7  - shifted y
//  r8  - total iterations
//  r9  - holds current iteration atan value
//  r10 - sign bit mask/scatch
//  r11 - pointer to arctan table
//  r12 - quadrant flag (determines whether to negate x and/or y result)
//  r13 - scratch
// The input angle comes in the form u2.5 with a
// range of 0 to 2*pi. CORDICs only work for
// +pi/2 to -pi/2 angles.  To keep things simple,
// we'll only operate in one quadrant of the unit
// circle (0 to +pi/2). For the other quadrants,
// we'll modify the angle and outputs appropriately.

    LDI r5 50   // Load +pi/2   (1.5708*2^5 = ~50)
    CMP r5 r1
    BRH ge .quadrant_0
    LDI r5 100  // Load +pi     (3.1416*2^5 = ~100)
    CMP r5 r1
    BRH ge .quadrant_1
    LDI r5 150  // Load +3/2*pi (4.7124*2^5 = ~150)
    CMP r5 r1
    BRH ge .quadrant_2
    JMP .quadrant_3

    // For each quadrant, set the quadrant flag, which will be used
    // at the end to negate the sine/cosine outputs accordingly.
    // Also, adjust the input angle to all calculations are performed
    // as if in quadrant 0.
    .quadrant_0
        LDI r12 0b00    // Set quadrant flag to leave xy untouched
        JMP .cordic_setup
    .quadrant_1
        LDI r12 0b10    // Set quadrant flag to negate x
        SUB r5 r1 r1
        JMP .cordic_setup
    .quadrant_2
        LDI r12 0b11    // Set quadrant flag to negate x&y
        LDI r5 100      // Load +pi (3.1416*2^5 = ~100)
        SUB r1 r5 r1
        JMP .cordic_setup
    .quadrant_3
        LDI r12 0x01    // Set quadrant flag to negate y
        LDI r5 200      // Load +2*pi (6.2832*2^5 = ~200)
        SUB r5 r1 r1

    .cordic_setup
        LSH r1 r1       // adjust input angle from u2.6 to s1.6; this step is needed because negative angles are needed during CORDIC operation
        LDI r2 38       // x = 0.6072 (s1.6) = ~38/2^6 (this value has scaling factor K pre-applied)
        LDI r3 0        // y = 0
        LDI r4 0        // iteration counter (i)
        LDI r8 7        // total iterations
        LDI r10 128     // angle sign bit mask
        LDI r11 atan_LUT_strt_addr  // Point to start of atan LUT

        .cordic_loop
            // Make temporary copies of the i,x,y values for shifting
            MOV r4 r5
            MOV r2 r6
            MOV r3 r7

            // The current computer ALU does not support arithmetic shifting
            // with RSH instruction, which presents a problem for negative
            // numbers.  When shifting a negative value right, ones should
            // get shifted into the sign bit.  That doesn't happen so
            // negative shifts aren't handled properly.  To get around this
            // problem, I'll ADD in the sign bit after shifting.
            // Note: The fact that the ALU only supports single bit shifts
            // necessitates a loop and therefore slows down the CORDIC
            // significantly.  Multi-bit shifts are certainly possible but
            // would make the ALU much larger... as always, tradeoffs. :)
            AND r6 r10 r13  // Grab the sign bit for x
            AND r7 r10 r10  // Grab the sign bit for y
            .shift_loop
                CMP r5 r0
                BRH eq .shift_done
                RSH r6 r6
                ADD r6 r13 r6   // Add the sign bit after shifting
                RSH r7 r7
                ADD r7 r10 r7   // Add the sign bit after shifting
                DEC r5
                JMP .shift_loop
            .shift_done
            LOD r11 r9 // Load atan value for current iteration

            // Determine rotation direction
            LDI r10 128   // Sign bit mask
            AND r1 r10 r0 // Check the sign bit
            BRH z .positive_rotation

                .negative_rotation // Clockwise
                ADD r2 r7 r2
                SUB r3 r6 r3
                ADD r1 r9 r1
                JMP .next_iteration

                .positive_rotation // Counter clockwise
                SUB r2 r7 r2
                ADD r3 r6 r3
                SUB r1 r9 r1

            .next_iteration
            INC r11     // Point to next atan value
            INC r4      // Increment iteration (i)
            CMP r4 r8   // Check against total iterations
            BRH nz .cordic_loop

        // Adjust xy outputs accordingly based on quadrant

        // Adjust x?
        .check_x_negate
        LDI r5 0b10
        AND r12 r5 r0
        BRH nz .negate_x
        JMP .check_y_negate
        .negate_x
            SUB r0 r2 r2

        .check_y_negate
        LDI r5 0b01
        AND r12 r5 r0
        BRH nz .negate_y
        JMP .cordic_done
        .negate_y
            SUB r0 r3 r3
    .cordic_done
     RET


.draw_line
// This function draws a line between two points
// utilizing Bresenham's Algorithm.  I ported the
// algorithm to assembly using MattBatWing's python
// implementation as a guide (a.k.a. I swiped it).
// Inputs:
//  r1 = x1
//  r2 = y1
//  r3 = x2
//  r4 = y2
// Register Usage:
//  r5 = dx = abs(x2 - x1)
//  r6 = dy = abs(y2 - y1)
//  r7 = sx = sign(x2 - x1)
//  r8 = sy = sign(y2 - y1)
//  r9 = Error = 2*dy - dx
//  r10 = scratch
//  r11 = A = 2*dy
//  r12 = B = 2*dy - 2*dx
//  r13 = interchange flag

    // Set sx/sy slope bits to 1 for positive slope (default)
    LDI r7 1
    LDI r8 1

    // Calculate x values dx and sx.
    .calc_x
        LDI r10 128       // Sign bit mask
        SUB r3 r1 r5      // x2 - x1
        AND r5 r10 r0     // sx = sign(x2 - x1)
        BRH nz .negate_x_dl
        JMP .calc_y
        .negate_x_dl
            SUB r0 r5 r5      // dx = abs(x2 - x1)
            LDI r7 -1         // sx = -1 (negative slope)

    // Calculate y values dy and sy.
    .calc_y
        SUB r4 r2 r6      // y2 - y1
        AND r6 r10 r0     // sy = sign(y2 - y1)
        BRH nz .negate_y_dl
        JMP .calc_interchange
        .negate_y_dl
            SUB r0 r6 r6      // dy = abs(y2 - y1)
            LDI r8 -1         // sy = -1 (negative slope)

    .calc_interchange
        LDI r13 0         // Set interchange flag to 0 (false)
        SUB r5 r6 r0      // Is dx or dy is greater?
        BRH ge .calc_err  // If dx >= dy, proceed to calc error, A and B
        MOV r5 r10        // If dy < dx, swap dx and dy
        MOV r6 r5
        MOV r10 r6
        LDI r13 1         // and set interchange flag to 1 (true)

    .calc_err
        LSH r6 r11        // A = 2*dy
        LSH r5 r12        // 2*dx
        SUB r0 r12 r12    // -2*dx
        ADD r11 r12 r12   // B = 2*dy - 2*dx
        SUB r0 r5 r9      // -dx
        ADD r11 r9 r9     // Error = 2*dy - dx

    // Draw first pixel
    LDI r15 memory_mapped_io_addr
    STR r15 r1 pixel_x_offset
    STR r15 r2 pixel_y_offset
    STR r15 r0 draw_pixel_offset

    LDI r14 0   // Set i to 0 for loop
    .draw_line_loop
        LDI r10 128     // Sign bit mask
        AND r9 r10 r0   // Is Error < 0?
        BRH z .error_ge_zero
        .error_lt_zero
            ADD r9 r11 r9   // Error =+ A
            CMP r13 r0      // Check interchange flag
            BRH eq .inc_x   // ... and increment either x or y
            .inc_y
                ADD r2 r8 r2    // y =+ s2
                JMP .draw_pixel
            .inc_x
                ADD r1 r7 r1    // x =+ s1
                JMP .draw_pixel
        .error_ge_zero
            ADD r2 r8 r2    // y =+ s2
            ADD r1 r7 r1    // x =+ s1
            ADD r9 r12 r9   // Error =+ B

        .draw_pixel
            // Make sure we're in the range of the screen before
            // drawing a pixel.
            LDI r10 32
            CMP r1 r10
            BRH ge .next_pixel
            CMP r2 r10
            BRH ge .next_pixel
            STR r15 r1 pixel_x_offset
            STR r15 r2 pixel_y_offset
            STR r15 r0 draw_pixel_offset

        .next_pixel
            INC r14       // Increment loop counter
            CMP r14 r5    // Exit loop when i > dx
            BRH ge .buffer_screen
            JMP .draw_line_loop

    .buffer_screen
        STR r15 r0 buffer_screen_offset
        RET


.mult
// This function multiplies a 16-bit multiplicand with an
// 8-bit multiplier resulting in a 16-bit product.
// Inputs:
//    r2:r1 = multiplicand
//    r3 = multiplier
// Outputs:
//    r5:r4 = 16-bit product
//
// Register usage:
//    r6 = LSB mask
//    r7 = carry flag (need separate flag because of oddity with LSH pseudo instruction)
//    r8 = loop counter
//    r9 = product sign flag

    // First things first... convert multiplicand and multiplier to positive
    // values since this routinee doesn't handle negative 2's complement values
    // properly.
// (TODO... add flag for signed vs unsigned operation)

    LDI r4 128        // Sign bit mask
    LDI r5 0xFF       // All ones mask 
    LDI r9 0          // Set product sign to 0 (positive)
    LDI r6 1          // LSB mask
    AND r2 r4 r0      // Determine if r2 is negative
    BRH z .multiplicand_pos
        XOR r9 r6 r9  // Toggle the product sign flag
        XOR r5 r2 r2  // Invert all bits
        XOR r5 r1 r1
        INC r1        // And add 1 to low byte after negation (2's complement)
        BRH nc .multiplicand_pos
            INC r2    // Handle carry into high byte
    .multiplicand_pos
    AND r3 r4 r0      // Determine if r3 is negative
    BRH z .multiplier_pos
        XOR r9 r6 r9  // Toggle the product sign flag
        SUB r0 r3 r3  // And negate it
    .multiplier_pos

    LDI r4 0          // Clear the product registers
    LDI r5 0
    LDI r8 8          // Initialize loop counter

    .mult_loop
        AND r3 r6 r0            // Check least significant bit of multiplier
        RSH r3 r3               // and shift it to the right by 1
        BRH zero .mult_no_add   // If least significant bit is 0, skip addition
        .mult_add
            ADD r1 r4 r4        // otherwise add multiplicand to product
            BRH nc .prod_nc
            ADI r5 1            // And handle carries into the upper 8-bits if needed
            .prod_nc
                ADD r2 r5 r5
        .mult_no_add
        LDI r7 0                // Initialize carry flag to 0
        LSH r1 r1               // Shift multiplicand left to prep for next round
        BRH nc  .multiplicand_nc
            LDI r7 1            // If a carry occurs, flag it
        .multiplicand_nc
        LSH r2 r2               // Now shift the upper 8-bits of the multiplicand
        ADD r2 r7 r2            // And add back the carry bit
        DEC r8                  // Decrement the loop counter
        BRH nz .mult_loop

    // TODO - add logic to handle multiplicand saturation

    CMP r9 r0         // Determine if product sign flag is set
    BRH z .mult_done
        LDI r2 0xFF
        XOR r2 r4 r4  // Negate the product
        XOR r2 r5 r5
        INC r4        // And add 1 to low byte after negation (2's complement)
        BRH nc .mult_done
        INC r5        // Handle carry into high byte
    .mult_done
    RET


.div
// This function divides a 16-bit dividend by a 16-bit divisor.
// It results in an 16-bit quotient and 8-bit remainder.
// Inputs:
//    r2:r1 = Dividend (numerator)
//    r4:r3 = Divisor  (denominator)
// Outputs:
//    r2:r1 = Quotient
//    r3    = Remainder
// Register usage:
//    r6:r5 = Remainder temp
//    r8:r7 = Quotient temp (TODO... can use dividend register to use less resources)
//    r9-10 = scratch
//    r11   = loop counter
//    r12   = quotient_sign
//
// This code implements a non-restoring division algorithm, which is detailed in the
// following video:
//    www.youtube.com/watch?v=7m6I7_3XdZ8
//
// Below is a rough block diagram:
//
//        +---------------------+
//        |   16-bit Divisor    | (r4:r3)
//        +---------------------+
//                |
//                |    +------------+
//                +--->|     ALU    |
//    +--------------->| (subtract) |
//    |                +------------+
//    |                    |       
//    |                    |       
//    |   +-----------------------------------------------+
//    +---| Remainder Reg (r6:r5) | Dividend Reg (r2:r1)  |<-- Quotient (shifted in)
//        +-----------------------------------------------+
//                       <-- shifted left  
//        
//
    // Check to see if both bytes of divisor are zero; if so,
    // a divide-by-zero error occurred.  Use of the NOR instruction
    // here necessitates a comparison to all ones.
    LDI r8 0xFF
    NOR r3 r4 r6
    CMP r8 r6
    BRH z .div_by_zero

    // This divide algorithm only works for unsigned values.  Therefore,
    // if the dividend and/or divisor are negative, convert them
    // to positive numbers and set a flag to convert the results
    // appropriately at the end.
    LDI r9 128        // Sign bit mask
    LDI r12 0         // Set quotient sign to 0 (positive by default)
    LDI r6 1          // LSB mask

    // abs(Dividend)
    AND r2 r9 r0      // Check dividend sign bit
    BRH z .dividend_pos
        XOR r12 r6 r12 // Toggle the quotient sign flag
        XOR r8 r1 r1  // Negate the dividend by inverting all bits...
        XOR r8 r2 r2
        INC r1        // ...and add 1 to low byte (2's complement)
        BRH nc .dividend_pos
        INC r2        // Handle carry into high byte
    .dividend_pos

    // abs(Divisor)
    AND r4 r9 r0      // Check divisor sign bit
    BRH z .divisor_pos
        XOR r12 r6 r12 // Toggle the quotient sign flag
        XOR r8 r3 r3  // Negate the divisor by inverting all bits...
        XOR r8 r4 r4
        INC r3        // ...and add 1 to low byte (2's complement)
        BRH nc .divisor_pos
        INC r4        // Handle carry into high byte
    .divisor_pos

    // Initialize
    LDI r5  0      // Clear registers utilized for calculations
    LDI r6  0
    LDI r7  0
    LDI r8  0
    LDI r9  0      // Carry flag for low byte shifts
    LDI r10 0      // Carry flag for high byte shifts
    LDI r11 16     // Initialize loop counter to 16

    .div_loop
        // Shift dividend left
        LDI r9 0                // Clear low byte carry flag
        LSH r1 r1               // Shift dividend low byte left
        BRH nc .dividend_lh_nc
            LDI r9 1            // If a carry occurs, flag it
        .dividend_lh_nc
        LDI r10 0                // Clear high byte carry flag
        LSH r2 r2               // Shift dividend high byte left
        BRH nc .dividend_h_nc
            LDI r10 1            // If a carry occurs, flag it
        .dividend_h_nc
        ADD r2 r9 r2            // And add the carry bit

        // Shift the remainder left with carry out from dividend shift
        LDI r9 0                // Clear carry flag
        LSH r5 r5               // Shift remainder low byte left
        BRH nc .remainder_lh_nc
            LDI r9 1            // If a carry occurs, flag it
        .remainder_lh_nc
        ADD r5 r10 r5            // And add carry from dividend high byte
        LDI r10 0
        LSH r6 r6               // Shift remainder high byte left
        ADD r6 r9 r6            // And add the carry bit

        // Compare the remainder with the divisor to determine if
        // a subtraction is possible.  First, compare the high
        // bytes
        CMP r6 r4
        BRH lt .div_no_subtract // If remainder high byte < divisor high byte, skip subtract
        BRH eq .cmp_low         // If equal, compare the low bytes
        JMP .div_subtract

        // The upper bytes are equal so the lower bytes need to be compared
        // Note: I've seen code that skips the low byte comparison and proceeds
        // with subtraction anyway potentially resulting in a negative remainder.
        // Apparently, this negative remainder handles itself later but I had
        // trouble getting it to work (and it's confusing).  I'll take a small
        // performance hit with the low byte comparison to keep things simple.
        .cmp_low
        CMP r5 r3
        BRH lt .div_no_subtract // If remainder low byte < divisor low byte, skip subtract

            // Perform remainder - divisor 16-bit subtraction (emulating SBB)
            .div_subtract
            LDI r9 0                // Clear borrow flag
            SUB r5 r3 r5            // Subtract low bytes
            BRH c .div_no_borrow
                LDI r9 1            // If a borrow occurs, flag it
            .div_no_borrow
            SUB r6 r4 r6            // Subtract high bytes
            SUB r6 r9 r6            // Handle borrow

            LDI R9 0
            INC r7                  // Increment the quotient
                                    // Note: it'll never carry into the higher byte
                                    // because there will always be 'room' to add 1 due to
                                    // the shift from the previous cycle.

        .div_no_subtract
        // Shift Quotient left (TBD - again... I'll likely get rid of this since I'll use dividend instead but...
        LDI r9 1                    // Skip quotient shift if final iteration (i.e. i=1)
        CMP r11 r9
        BRH z .no_quotient_shift    // Skip quotient shift if final iteration (i.e. i=1)
        LDI r9 0                    // Clear low byte carry flag
        LSH r7 r7                   // Shift quotient low byte left
        BRH nc .quotient_lh_nc
            LDI r9 1                // If a carry occurs, flag it
        .quotient_lh_nc
        LSH r8 r8                   // Shift quotient high byte left
        ADD r8 r9 r8
        .no_quotient_shift

        // Next iteration
        DEC r11                  // Decrement loop counter
        BRH nz .div_loop

    // Move results to appropriate output registers
    MOV r8 r2
    MOV r7 r1
    MOV r5 r3

    // Determine if the final quotient result should be negative.
    // (We'll go ahead and leave the remainder as an unsigned value)
    CMP r12 r0         // Determine if quotient sign flag is set
    BRH z .div_done
        LDI r9 0xFF
        XOR r9 r2 r2  // Negate the quotient
        XOR r9 r1 r1
        INC r1        // And add 1 to low byte after negation (2's complement)
        BRH nc .div_done
        INC r2        // Handle carry into high byte
    .div_done

    RET

    // Halt when divide by zero encountered
    .div_by_zero
        HLT


.pixel_projection
// The following function is used to project a 3D point in space onto a 2D plane.
//
// Given a 3D coordinate [x,y,z], it'll return x_projected and y_projected by
// calculating the following:
//
// x_projected = (focal_length * x)/(focal length + z)
// y_projected = (focal_length * y)/(focal length + z)
//
// Inputs:
//    r2:r1 = x
//    r4:r3 = y
//    r6:r5 = z
//    r7 = focal_length
//
// Outputs:
//    r1 = x_projected
//    r2 = y_projected
//
// Registers:
//    r9:r8 = focal_length + z
//    r14 = stack pointer
//    r15 = stack pointer

    // RAM offsets for temporary RAM storage (from r15)
    define pp_x_low           -8  // x_low
    define pp_x_high          -7  // x_high
    define pp_y_low           -6  // y_low
    define pp_y_high          -5  // y_high
    define pp_z_low           -4  // z_low
    define pp_z_high          -3  // z_high
    define pp_x_projected     -2  // x projected
    define pp_y_projected     -1  // y projected
    define pp_fl               0   // focal_length
    define pp_fl_plus_z_low    1   // focal_length + z (low)
    define pp_fl_plus_z_high   2   // focal_length + z (high)

    MOV r6 r9       // Move z high byte to r9
    ADD r7 r5 r8    // r8 = focal_length + z
    BRH nc .fl_z_nc  // Handle carries into upper byte (TODO)
        INC r9
    .fl_z_nc

    // Push registers on the stack
    LDI r15 register_stack_pointer
    ADI r15 8
    STR r15 r1 pp_x_low
    STR r15 r2 pp_x_high
    STR r15 r3 pp_y_low
    STR r15 r4 pp_y_high
    STR r15 r7 pp_fl
    STR r15 r8 pp_fl_plus_z_low
    STR r15 r9 pp_fl_plus_z_high

    // Calculate x_projected
    LOD r15 r3 pp_fl
    CAL .mult
    MOV r5 r2
    MOV r4 r1
    LOD r15 r3 pp_fl_plus_z_low
    LOD r15 r4 pp_fl_plus_z_high
    CAL .div

    // Trunc the results
    LDI r3 2
    CAL .trunc
    STR r15 r1 pp_x_projected

    // Calculate y_projected
    LOD r15 r1 pp_y_low
    LOD r15 r2 pp_y_high
    LOD r15 r3 pp_fl
    CAL .mult
    MOV r5 r2
    MOV r4 r1
    LOD r15 r3 pp_fl_plus_z_low
    LOD r15 r4 pp_fl_plus_z_high
    CAL .div

    // Now truncate the results
    LDI r3 2
    CAL .trunc
    STR r15 r1 pp_y_projected

    // Move x_projected and y_projected to output registers
    MOV r1 r2                   // y_projected -> r2
    LOD r15 r1 pp_x_projected  // x_projected -> r1
    RET


.rotation
// This function applies the following rotation matrix to
// a set of two coordinates:
//
//           +-               -+
//           | cos(A)  -sin(A) |
//      Rz = |                 |
//           | sin(A)   cos(A) |
//           +-               -+
//
// Given a 3D coordinate (composed of xyz values), the
// coordinate pair utilized can be selected based on the
// coordinate pair selection input as follows:
//    0 = [x,y]
//    1 = [x,z]
//    2 = [y,z]
//
// Inputs:
//    r1  = rotation angle in radians (fixed point in the form u2.5)
//          (Values between 0 and 2*pi are supported.)  // TODO... make input and outputs consistent
//    r2 = x
//    r3 = y
//    r4 = z
//    r5 = rotation axis
//
// Outputs:   
//    r2:r1 = rotated_x
//    r4:r3 = rotated_y
//    r6:r5 = rotated_z
// Registers:
//    r1 - r7 = scratch
//    r14 = stack pointer (offset 8 from r15)
//    r15 = stack pointer

    // RAM offsets for temporary storage (offset from r15)
    define rot_coord1          0 // 1st rotation coordinate
    define rot_coord2          1 // 2nd rotation coordinate
    define rot_coord3          2 // 3rd rotation coordinate (fixed)
    define rot_axis_sel        3 // rotation axis
    define rot_cosine_high     4 // Cosine
    define rot_cosine_low      5
    define rot_sine_high       6 // Sine
    define rot_sine_low        7

    define coord1_x_cosine_low  -1
    define coord1_x_cosine_high -2
    define coord2_x_sine_low    -3
    define coord2_x_sine_high   -4
    define coord1_x_sine_low    -5
    define coord1_x_sine_high   -6
    define coord2_x_cosine_low  -7
    define coord2_x_cosine_high -8

    // RAM offset for temp storage (offset from r14)
    define rot_x_high       -8
    define rot_x_low        -7
    define rot_y_high       -6
    define rot_y_low        -5
    define rot_z_high       -4
    define rot_z_low        -3
    define rot_coord1_high  -2
    define rot_coord1_low   -1
    define rot_coord2_high   0
    define rot_coord2_low    1
    define rot_coord3_high   2
    define rot_coord3_low    3

    // Set up pointer for temporary storage
    LDI r15 register_stack_pointer
    ADI r15 8
    MOV r15 r14
    ADI r14 8
    ADI r14 8

    // Organize input coordinates in RAM according to the
    // rotation axis selection input (r5)
    STR r15 r5 rot_axis_sel
    LDI r6 x_axis
    CMP r5 r6
    BRH z .go_x_axis_sel
    LDI r6 z_axis
    CMP r5 r6
    BRH z .go_z_axis_sel
    .go_y_axis_sel  // Default
        STR r15 r2 rot_coord1 
        STR r15 r4 rot_coord2
        STR r15 r3 rot_coord3 
        JMP .calc_cordic
    .go_z_axis_sel
        STR r15 r2 rot_coord1 
        STR r15 r3 rot_coord2
        STR r15 r4 rot_coord3
        JMP .calc_cordic
    .go_x_axis_sel
        STR r15 r3 rot_coord1 
        STR r15 r4 rot_coord2
        STR r15 r2 rot_coord3

    .calc_cordic
    // Call the CORDIC function to calculate sine and cosine for the
    // rotation angle
    CAL .cordic

    // Convert them to 16-bit values for the multiplications below.
    LDI r12 128
    LDI r1 0
    AND r12 r2 r0     // Check sign bit
    BRH z .cosine_pos
        LDI r1 0xFF
    .cosine_pos
    STR r15 r1 rot_cosine_high 
    STR r15 r2 rot_cosine_low
    LDI r1 0
    AND r12 r3 r0     // Check sign bit
    BRH z .sine_pos
        LDI r1 0xFF
    .sine_pos
    STR r15 r1 rot_sine_high 
    STR r15 r3 rot_sine_low

    // Now... calculate the four terms in the rotation and store in RAM
    // Calculate coord1 * cosine
    LOD r15 r1 rot_cosine_low
    LOD r15 r2 rot_cosine_high
    LOD r15 r3 rot_coord1
    CAL .mult
    STR r15 r4 coord1_x_cosine_low
    STR r15 r5 coord1_x_cosine_high

    // Calculate coord1 * sine
    LOD r15 r1 rot_sine_low
    LOD r15 r2 rot_sine_high
    LOD r15 r3 rot_coord1
    CAL .mult
    STR r15 r4 coord1_x_sine_low
    STR r15 r5 coord1_x_sine_high

    // Calculate coord2 * sine
    LOD r15 r1 rot_sine_low
    LOD r15 r2 rot_sine_high
    LOD r15 r3 rot_coord2
    CAL .mult
    STR r15 r4 coord2_x_sine_low
    STR r15 r5 coord2_x_sine_high

    // Calculate coord2 * cosine
    LOD r15 r1 rot_cosine_low
    LOD r15 r2 rot_cosine_high
    LOD r15 r3 rot_coord2
    CAL .mult
    STR r15 r4 coord2_x_cosine_low
    STR r15 r5 coord2_x_cosine_high

    // Calculate coord1_rotation = coord1*cosine(A) +/- coord2*sine(A)
    LOD r15 r3 coord1_x_cosine_low
    LOD r15 r4 coord1_x_cosine_high
    LOD r15 r5 coord2_x_sine_low
    LOD r15 r6 coord2_x_sine_high

    // Perform 16-bit addition/subtraction (emulating SBB)
    // Addition/subtraction depends on the axis of rotation TODO better comments
    LOD r15 r8 rot_axis_sel   // Restore axis selection
    LDI r9 y_axis
    CMP r8 r9
    BRH z .coord1_add
    .coord1_sub           // For rotations around axis x & z, subtraction is performed
        LDI r7 0
        SUB r3 r5 r3      // Subtract low bytes
        BRH c .rotx_no_borrow
            LDI r7 1
        .rotx_no_borrow
        SUB r4 r6 r4      // Subtract high bytes
        SUB r4 r7 r4      // Handle borrow
        JMP .coord1_trunc
    .coord1_add           // For rotations around y, the two terms are added together
        LDI r7 0
        ADD r3 r5 r3      // Add low bytes
        BRH nc .rotx_no_carry
            LDI r7 1
        .rotx_no_carry
        ADD r4 r6 r4      // Add the high bytes
        ADD r4 r7 r4      // Handle carry

    .coord1_trunc
    // Move and truncate the results (TODO remove truncation here)
    MOV r3 r1
    MOV r4 r2
    LDI r3 6
    CAL .trunc
    STR r14 r1 rot_coord1_low
    STR r14 r2 rot_coord1_high

    // Calculate coord2_rotation = coord2*cosine(A) +- coord1*sine(A)
    LOD r15 r3 coord1_x_sine_low
    LOD r15 r4 coord1_x_sine_high
    LOD r15 r5 coord2_x_cosine_low
    LOD r15 r6 coord2_x_cosine_high

    // Perform 16-bit addition/subtraction TODO better comments
    LOD r15 r8 rot_axis_sel   // Restore axis selection
    LDI r9 y_axis
    CMP r8 r9
    BRH z .coord2_sub
    .coord2_add     // For rotations around axis x & z, adding is performed
        LDI r7 0
        ADD r3 r5 r3      // Add low bytes
        BRH nc .roty_no_carry
            LDI r7 1
        .roty_no_carry
        ADD r4 r6 r4      // Add high bytes
        ADD r4 r7 r4      // And handle carry
        JMP .coord2_trunc
    .coord2_sub           // For rotations around axis y, subtraction is performed
        LDI r7 0
        SUB r5 r3 r3      // Subtract low bytes
        BRH c .roty_no_borrow
            LDI r7 1
        .roty_no_borrow
        SUB r6 r4 r4      // Subtract high bytes
        SUB r4 r7 r4      // Handle borrow
    .coord2_trunc

    // Move and truncate the results (TODO remove truncation here)
    MOV r3 r1
    MOV r4 r2
    LDI r3 6
    CAL .trunc
    STR r14 r1 rot_coord2_low
    STR r14 r2 rot_coord2_high

    // Multiply the fixed coordinate by 2^6 to match bit growth of
    // rotated coordinates TODO FIX
//    LDI r1 64
    LDI r1 1
    LDI r2 0
    LOD r15 r3 rot_coord3
    CAL .mult
    STR r14 r4 rot_coord3_low
    STR r14 r5 rot_coord3_high

    // Organize outputs coordinates based on the rotation axis selection.
    LOD r15 r5 rot_axis_sel   // Restore axis selection
    LDI r6 y_axis
    CMP r5 r6
    BRH z .rstr_xz_sel
    LDI r6 x_axis
    CMP r5 r6
    BRH z .rstr_yz_sel
    .rstr_x_axis // Default selection
        LOD r14 r2 rot_coord1_high
        LOD r14 r1 rot_coord1_low
        LOD r14 r4 rot_coord2_high
        LOD r14 r3 rot_coord2_low
        LOD r14 r6 rot_coord3_high 
        LOD r14 r5 rot_coord3_low 
        JMP .rot_exit
    .rstr_xz_sel
        LOD r14 r2 rot_coord1_high
        LOD r14 r1 rot_coord1_low
        LOD r14 r4 rot_coord3_high 
        LOD r14 r3 rot_coord3_low 
        LOD r14 r6 rot_coord2_high
        LOD r14 r5 rot_coord2_low
        JMP .rot_exit
    .rstr_yz_sel
        LOD r14 r2 rot_coord2_high
        LOD r14 r1 rot_coord2_low
        LOD r14 r6 rot_coord3_high
        LOD r14 r5 rot_coord3_low
        LOD r14 r4 rot_coord1_high 
        LOD r14 r3 rot_coord1_low 
    .rot_exit
    RET


.trunc
// The following function performs simple truncation of a
// 16-bit input value.  The number of bits truncated off
// is configurable.
// Inputs:
//    r2:r1 = 16-bit input
//    r3    = Number of bits to truncate
// Registers:
//    r4    = Bit shifted from high to low
//    r5    = Sign bit
//    r6    = scratch
//    TODO consider adding rounding to this logic and change name from trunc to round if so

    LDI r6 128
    AND r2 r6 r5        // Grab the sign bit
    LDI r6 1
    .trunc_loop
        CMP r3 r0
        BRH eq .trunc_done
        AND r2 r6 r4    // Grab bit shifted from high to low byte
        RSH r2 r2
        ADD r2 r5 r2    // Add the sign bit after shifting
        RSH r1 r1
        CMP r4 r6       // Did a '1' move from high to low byte?
        BRH ne .next_trunc_iteration
            ADI r1 128  // If so, add it back
        .next_trunc_iteration
        DEC r3
        JMP .trunc_loop
    .trunc_done
    RET


// Load the arctangent look-up table into RAM.
// Values are in the form S1.6
.load_atan_lut
    LDI r15 atan_LUT_strt_addr
    LDI r14 50     // arctan(2^0)  = ~50/2^6
    STR r15 r14 0
    LDI r14 30     // arctan(2^-1) = ~30/2^6
    STR r15 r14 1
    LDI r14 16     // arctan(2^-2) = ~16/2^6
    STR r15 r14 2
    LDI r14 8      // arctan(2^-3) = ~8/2^6
    STR r15 r14 3
    LDI r14 4      // arctan(2^-4) = ~4/2^6
    STR r15 r14 4
    LDI r14 2      // arctan(2^-5) = ~2/2^6
    STR r15 r14 5
    LDI r14 1      // arctan(2^-6) = ~1/2^6
    STR r15 r14 6
    RET

.load_shape_vertices_edges
    // Square pyramid shape
    LDI r15 shape_vertices_edges_addr
    LDI r14 8     // Number of vertices
    STR r15 r14 0 
    LDI r14 32    // x0
    STR r15 r14 1
    LDI r14 32    // y0
    STR r15 r14 2
    LDI r14 32   // z0
    STR r15 r14 3
    LDI r14 32   // x1
    STR r15 r14 4
    LDI r14 32    // y1
    STR r15 r14 5
    LDI r14 -32    // z1
    STR r15 r14 6
    LDI r14 32   // x2
    STR r15 r14 7

    ADI r15 8
    LDI r14 -32   // y2
    STR r15 r14 0
    LDI r14 32    // z2
    STR r15 r14 1
    LDI r14 32    // x3
    STR r15 r14 2
    LDI r14 -32   // y3
    STR r15 r14 3
    LDI r14 -32    // z3
    STR r15 r14 4
    LDI r14 -32     // x4
    STR r15 r14 5
    LDI r14 32     // y4
    STR r15 r14 6
    LDI r14 32  // z4
    STR r15 r14 7

    ADI r15 8
    LDI r14 -32   // x5
    STR r15 r14 0
    LDI r14 32    // y5
    STR r15 r14 1
    LDI r14 -32    // z5
    STR r15 r14 2
    LDI r14 -32   // x6
    STR r15 r14 3
    LDI r14 -32    // y6
    STR r15 r14 4
    LDI r14 32     // z6
    STR r15 r14 5
    LDI r14 -32     // x7
    STR r15 r14 6
    LDI r14 -32  // y7
    STR r15 r14 7

    ADI r15 8
    LDI r14 -32  // z7
    STR r15 r14 0

//
//
//
//    ADI r15 8
//    LDI r14 8     // Number of edges
//    STR r15 r14 0
//    LDI r14 0     // Edge 0 (vertices 0,1)
//    STR r15 r14 1
//    LDI r14 1
//    STR r15 r14 2
//    LDI r14 1     // Edge 1 (vertices 1,2)
//    STR r15 r14 3
//    LDI r14 2
//    STR r15 r14 4
//    LDI r14 2     // Edge 2 (vertices 2,3)
//    STR r15 r14 5
//    LDI r14 3
//    STR r15 r14 6
//    LDI r14 3     // Edge 3 (vertices 3,0)
//    STR r15 r14 7
//
//    ADI r15 8
//    LDI r14 0
//    STR r15 r14 0
//    LDI r14 0     // Edge 4 (vertices 0,4)
//    STR r15 r14 1
//    LDI r14 4
//    STR r15 r14 2
//    LDI r14 1     // Edge 5 (vertices 1,4)
//    STR r15 r14 3
//    LDI r14 4
//    STR r15 r14 4
//    LDI r14 2     // Edge 6 (vertices 2,4)
//    STR r15 r14 5
//    LDI r14 4
//    STR r15 r14 6
//    LDI r14 3     // Edge 7 (vertices 3,4)
//    STR r15 r14 7
//
//    ADI r15 8
//    LDI r14 4
//    STR r15 r14 0
    RET
