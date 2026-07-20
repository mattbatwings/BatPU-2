# BEFORE TRYING TO MAKE AND/OR RUN A PROGRAM, READ THIS WHOLE PAGE!
DISCLAIMER: Basic assembly knowledge is assumed.

>If you've never done assembly, you can learn online, learn from talking to people in my [discord](https://discord.gg/V5KFaF63mV), or you can watch my [video series](https://www.youtube.com/playlist?list=PL5LiOvrbVo8nPTtdXAdSmDWzu85zzdgRT) on this computer.

## What's in this repo?

All the supporting code I wrote for my new [redstone computer](https://youtu.be/3gBZHXqnleU?si=brgAO4tlePdB6vPR)

programs - A folder containing all the programs that were in the showcase \
assembler.py - A script to convert .as (assembly) files to .mc (machine code) files \
schematic.py - A script to convert .mc files to .schem (worldedit schematic) files \
main.py - A script to convert .as files to .schem files (Using assembler.py, then schematic.py)

## How can I create a program?

To create a new program, simply create a text file, change the extension type to .as, and open the file with your favorite text editor.

Programs are written in my custom assembly language, described by this [ISA](https://docs.google.com/spreadsheets/d/1Bj3wHV-JifR2vP4HRYoCWrdXYp3sGMG0Q58Nm56W4aI/edit?gid=0#gid=0). 
**I recommend reading over it thoroughly before continuing.**

### Syntax

Every instruction is written with an opcode followed by the operands. The order of operands remains exactly the same between assembly and machine code. For example, according to the ISA, the add instruction has opcode mnemonic ADD and operands Reg A, Reg B, Reg C. So,

```ADD r1 r2 r3``` 

will compute r1 + r2 and put it into r3, as described by the pseudocode column.

### Labels

Labels are supported. Labels must have a dot as the first character. Labels can be on their own line, or before an instruction on the same line. A label will always resolve to its absolute address, as all jumps are absolute.

```
LDI r1 10
.loop // I'm a label on my own line
DEC r1
BRH zero .exit
JMP .loop
.exit HLT // I'm a label on the same line as an instruction
```

### Definitions

Definitions of integer values are supported. Definitions are written with the following syntax:

```
define my_value 3
```

This makes any future reference to my_value resolve to 3.

### Symbols

Opcodes can be written as their 3-letter mnemonic

Registers can be written as r0 through r15

Immediates can be written in decimal or in binary/hex using the 0b/0x prefix 

Zero flag true condition can be written as eq, =, z, zero \
Zero flag false condition can be written as ne, !=, nz, notzero \
Carry flag true condition can be written as ge, >=, c, carry \
Carry flag false condition can be written as lt, <, nc, notcarry

Single characters can be written using single or double quotes. This will resolve to their character code in the ISA (Notes on box AB10)

Ports can be written as their name with underscores between them. For example, port 246 has name "Clear Screen Buffer", so clear_screen_buffer will resolve to 246

## Running a program on the emulator

- Grab the [latest release](https://github.com/AdoHTQ/Batpu2-VM/releases)
- Drag and drop the .as file onto the righthand side
- Start!

## Running a program on the minecraft cpu

DISCLAIMER: This will be **extremely slow**, as the cpu completes 1 instruction every 10 seconds at vanilla speed. See the next section for speedup methods.

>REQUIRED PREREQUISITES \
A copy of Minecraft Java Edition 1.18.2 \
[Worldedit](https://www.curseforge.com/minecraft/mc-mods/worldedit) (Fabric Mod) \
[RedstoneTools](https://modrinth.com/mod/redstone-tools) (Fabric Mod) \
A python installation

- Clone this repository
- Put the desired [program].as into the programs folder
- Open main.py and change helloworld in ```program = 'helloworld'``` to the name of your program
- Run main.py (Note: You may need to import mcschematic with the command "pip install mcschematic". If that doesn't work, try "python -m pip install mcschematic")
- Drag and drop the resulting [program].schem into .minecraft/config/worldedit/schematics
- Download the cpu from the [world download](https://www.planetminecraft.com/project/new-redstone-computer/)
- Go to coordinate point 190.5, 154, -0.5. You should be standing on a light gray wool with two repeaters coming out of it (Note: Press F3 to view coordinates)
- Run ```//schem load [program]```
- Run ```//paste -as```
- Run ```//update```
- Head to the input controller and press the "Run Program" button!

### Speedup  Method #1 - Carpet Mod

[Carpet](https://www.curseforge.com/minecraft/mc-mods/carpet) is a fabric mod that allows you to speed up the game. Vanilla minecraft runs at 20 game ticks per second, but running ```/tick rate [X]``` will change the speed to X game ticks per second instead. 

500 is the maximum allowed tick rate, which results in a 25x speedup. This tick rate will execute 2.5 instructions per second rather than the vanilla 0.1 instructions per second.

### Speedup Method #2 - MCHPRS

[MCHPRS](https://github.com/MCHPR/MCHPRS/releases) is a custom server designed to speedup redstone to incredible speeds. This is what I used for the showcase.

- NOTE THAT THESE INSTRUCTIONS ARE FOR WINDOWS ONLY
- Grab the [latest release](https://github.com/MCHPR/MCHPRS/releases)
- Run the .exe in a new folder
- A server console should launch. Test connecting to the server by joining the multiplayer ip ```localhost```. Also, new folders/files should have also been created. One of these folders should be called "schems"
- Go back to the cpu in singleplayer. You should have your program already pasted in and updated. Create a worldedit selection of the entire computer. Run ``//minsel``, ``//copy``, and ```//schem save [name]```
- Transfer the newly created schematic from .minecraft/config/worldedit/schematics to the MCHPRS schems folder
- Join the server again. Run ```//load [name]```, and ```//paste```
- You're ready to run the program! Use ```/rtps [X]``` to set the redstone ticks per second, or ```/rtps unlimited``` for maximum speed.

## Example programs

Hello world! 
```
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
STR r15 r0

HLT
```

Plot a single pixel
```
// r1 - X
// r2 - Y

LDI r1 3
LDI r2 4

// Clear screen buffer
LDI r15 clear_screen_buffer
STR r15 r0

// Store coordinates
LDI r15 pixel_x
STR r15 r1
LDI r15 pixel_y
STR r15 r2

// Draw pixel
LDI r15 draw_pixel
STR r15 r0

// Push screen buffer
LDI r15 buffer_screen
STR r15 r0

HLT
```

Fill the screen using a nested for loop

```
// Useful ports
LDI r12 pixel_x 
LDI r13 pixel_y 
LDI r14 draw_pixel 
LDI r15 buffer_screen 

LDI r2 32 
.outer_loop
LDI r1 32 
STR r13 r2                 // update Pixel Y 
.inner_loop 
STR r12 r1                 // update Pixel X 
STR r14 r0                 // draw pixel 
STR r15 r0                 // push buffer to screen 
DEC r1 
BRH ge .inner_loop 
DEC r2 
BRH ge .outer_loop 
HLT
```
