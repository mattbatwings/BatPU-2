// clock_test.as - clock tuning program for the redstone computer
//
// Counts 0..255 forever on the number display.
//   stable clock  -> count rises by exactly 1 each step, wraps 255 -> 0 cleanly
//   clock too fast -> skipped numbers, frozen display, or garbage
// Every delay step does a SUB (ALU + zero flag) and a conditional branch,
// which hits the CPU's critical timing path.

ldi r1 0                // r1 = display counter
ldi r2 show_number      // r2 = number display port (250)
ldi r4 1                // r4 = 1  (delay decrement step)
ldi r15 unsigned_mode   // r15 = unsigned mode port (253)
str r15 r0              // set number display to unsigned 0..255

.loop
    str r2 r1           // show counter on the number display
    adi r1 1            // counter++  (wraps 255 -> 0)

    ldi r3 50           // delay length: raise if it counts too fast to read,
                        //               lower if too slow  (range 1..255)
.delay
    sub r3 r4 r3        // r3 = r3 - 1  (SUB reliably sets the zero flag)
    brh nz .delay       // repeat until r3 reaches 0

    jmp .loop           // never halts - keep running while you tune
