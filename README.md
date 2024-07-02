# Intro
A fork of [@MattBatWings](https://github.com/MattBatWings)'s assembler that I kept adding features to while keeping it a superset of the original.

Original project: https://github.com/MattBatWings/newcpu

Link to ISA spreadsheet: https://docs.google.com/spreadsheets/d/1Bj3wHV-JifR2vP4HRYoCWrdXYp3sGMG0Q58Nm56W4aI/edit?usp=sharing

# Usage
Run main.py with python (in a <u>command-line/terminal!!!)</u> and pass the options <u>after</u> 'main.py'.

`python main.py <options> <input filename>`

Example:

`python main.py -vv -s1KiB -fMatt -Ooutput.txt test.s`

 Verbosity: 2

 ROM size: 1 Kibi-words

 Output format: Matt

 Output: output.txt

 Input file: test.s

## Options
> Note: Single character options can be used without separating the parameter.
> '-s1k' is as valid as '-s 1k'

`-O --output <file>`

  Sets output filename.

  Example:

   `-O output.bin`

   will output to 'output.bin'

`-s --rom-size <size>`

  Set ROM size in [words](#word). May be followed by suffixes for KiB, MiB, GiB, TiB, PiB, EiB, ZiB, YiB. (the 'iB' is optional. case-insensitive)

  Example:

   `-s 64k`/`-s 64kib`

   will set ROM size to 64 kibi-[words](#word). (64 * 1024 words, or 65,536 words)

   `-s 64`

   will set ROM size to 64 words.

`-p --padding-word <word>`

  Set what the padding [word](#word) should be, defaults to all 0s. hexadecimal or binary inputs should be prefixed with '0x' and '0b' respectively.
  
  Example:
  
   `-p 16`/`-p 0x10`/`-p 0b00010000`/`-p 0o020`

   will set padding word to 16/0x10/0b00010000/0o020


`-f --output-format <format>`

  Set the output format, possible [formats](#formats) are: (default is Matt)

   [Matt](#format-matt), [Raw](#format-raw), [Image](#format-image), [Hexdump](#format-hexdump), [Logisim3](#format-logisim3), [Logisim2](#format-logisim2), [DEBUG](#format-debug). (case-insensitive)

  Example:
  
   `-f raw`

   will set output format to 'raw'


`   --dump-labels`

  Dumps label table after assembly.

`   --dump-definitions`

  Dumps definition table after assembly.

`-v`

  Verbose output. (more v's means higher verbosity. above level 4 there is no effect)

   `<none>`
   verbosity is 0.

   `-v`
   verbosity is 1, +info about parameters.

   `-vv`
   verbosity is 2, +info about current assembly stage.

   `-vvv`
   verbosity is 3, +info about current process and the calculated widths used for displaying lines and addresses, and displays the raw & readable versions of the assembler's final output.

   `-vvvv`
   verbosity is 4, +displays all assembly lines after each process, and current saved definitions & labels if changed.

`-h --help`

  Prints a shorter version of this.

`-V --version`

  Prints version and credits.

## <a id="formats">Formats</a>
<a id="format-matt">Matt</a>
  The Matt format is the same as Raw, but writes binary as ASCII characters. (like Matt's assembler)

  There are no options for this format.

<a id="format-raw">Raw</a>
  The Raw format outputs pure binary.

  There are no options for this format.

<a id="format-image">Image</a>
  The Image format is the Raw format, but it gets [fattened](#fattening) to take up the entire ROM, creating a flashable ROM image.

  There are no options for this format.

<a id="format-hexdump">Hexdump</a>
  The Hexdump format outputs the program as addresses and hexadecimal data:

   '\<address in hex\>: \<data in hex, separated by words\>'

  Data is left-justified with 0s to make them neat.

  has a few options to enable/disable certain features if needed:
  - 'ns' (no squeeze) can be appended to disable [squeezing](#squeezing).
  - 'sp' (squeeze pad) can be appended to only squeeze padding and fat.
  - 'nf' (no fat) can be appended to disable [fattening](#fattening).
  - 'np' (no pad) can be appended to disable padding. (disables fattening too)

  Example: '-f hexdump-sp' (separator can be anything)

<a id="format-logisim3">Logisim3</a>
  The Logisim3 format outputs the program as addresses and hexadecimal data, like Hexdump, but with 16 words per line:

   '\<address in hex\>: \<16 words of data in hex, separated by words\>'

  Data is left-justified with 0s to make them neat.

  has a few options to enable/disable certain features if needed:

  - 'ys' (yes squeeze) can be appended to enable [squeezing](#squeezing). (Makes it incompatible with Logisim as of v3.8.0!!!)
  - 'nf' (no fat) can be appended to disable [fattening](#fattening).

  Example: '-f logisim3-nf' (separator can be anything)

<a id="format-logisim2">Logisim2</a>
  The Logisim2 format outputs the program as just hexadecimal data, but if a word repeats 4 or more times, it compacts them (different from [squeezing](#squeezing)) like so:

  `<number of repetitions>*<word as hex>`

  It also doesn't bother to left-justify the data with 0s, making it more compact but less neat.

  Each line will contain a maximum of 8 of either squeezed words or normal words.

  There are no options for this format.

<a id="format-debug">DEBUG</a>
  The DEBUG format is meant to test the output of the assembler, and is not meant to be used for normal assembling purposes.
  Output looks like:

   '\<line number in assembly file\>:\<address in hex\>: \<data in hex, separated by words\> ; \<original assembly line\>'

  There are no options for this format.

# Syntax
## Instructions and Pseudo-instructions
`<MNEMONIC> <OPERAND 1>, <OPERAND 2>, <OPERAND 3>`

Operands may be separated by commas or space characters.

`<MNEMONIC> <OPERAND 1> <OPERAND 2> <OPERAND 3>`

Mnemonics are case-insensitive.

An operand may be a character literal (`'A'`), a 1-char string constant (`"B"`), integer (`123456`), 0x, 0o, 0b prefixed hexadecimal, octal, or binary integer (`0xC0FFEE`, `0o2431`, `0b01100101`), `$` prefixed hexadecimal (`$DEADBEEF`), an ISA-defined symbol (`r0`, `r15`), a `.` prefixed label (`.START`), or a previously defined symbol with DEFINE (`DEFINE A, 8`, `A`)

Character literals and string constants may contain escaped characters.
`"\n", '\t', '\0'`

Examples:

`cmp r5, r0`

`ldi r15 'H'`

`LDI r1 $51`

`adi r0, 0x60`

`LDI r5, "A"`

## DEFINE
`DEFINE <LABEL>, <OPERAND>`

The operand may be anything an instruction operand can be.

LABEL and OPERAND may be separated by commas or space characters.

'DEFINE' is case-insensitive.

Labels are case-sensitive.

Examples:

`DEFINE A, 8`

`define Terminal $8000`

`define MODE_B, 0x30`

`DEFINE SPACE, ' '`

`DEFINE CHAR_A, "A"`

`define nl, '\n'`

## DB directive
`DB <OPERANDS>`

Like instructions, operands may be separated by commas or space characters.

Specially for DB directives, the operand may be a multi-char string constant as well as everything an instruction operand can be.

`DB "Hello, World!", 0x10, 0x00`

The backslash may be used to insert characters that would be normally detected as a string constant/character literal termination.

`"No, Sam I am, I do not like \"Green Eggs and Ham\". I would not like them here or there, I would not like them anywhere."`

`'\''`

'DB' is case-insensitive.

Examples:

`DB 'c'`

`db 0x30, 49, 0b00110010, 0o0063`

`DB "ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"`

`DB "The quick brown fox jumped over the " "lazy dog." 0x10 0`

`db "H" "e" "l" 'l' "o" ' ' ":" "3"`

## ORG directive
`ORG <OPERAND>`

ORG directives take a single operand. It can be anything an instruction's operand can be, except labels.

'ORG' is case-insensitive.

Examples:

`ORG $8000`

`ORG 0x000`

`org 2469`

`ORG 0o8123`

`ORG 'C'`

`org "A"`

`define TERMINAL, $5001` (then, later in the code) `org TERMINAL`

# Specifics

## Pseudo-instructions
Pseudo-instructions get resolved into native instructions (instructions the CPU actually runs) as if they were macros, though they're written as normal instructions.

If you want to see that process, run the assembler with a verbosity of at least 3 (4 for assembly dump) and look under the "RESOLVING PSEUDO-INSTRUCTIONS" line.

## <a id="specifics-db">DB directive</a>
Standing for Define Byte, it actually defines each operand as a [word](#word), or a string of words if it's a string. (1 word for each character)

If a word is 2 bytes, the assembler will assemble like:
`DB "Hello"`
```
+0: 00 48 | . H |
+1: 00 65 | . e |
+2: 00 6C | . l |
+3: 00 6C | . l |
+4: 00 6F | . o |
```
(2 bytes per character)

It's assembled this way so iterating through the addresses will fetch 1 character at a time.

If a word is 3 bytes, it'll be assembled like shown below, for the same reasons:
`DB "Hello"`
```
+0: 00 00 48 | . . H |
+1: 00 00 65 | . . e |
+2: 00 00 6C | . . l |
+3: 00 00 6C | . . l |
+4: 00 00 6F | . . o |
```
(3 bytes per character)

## ORG directive
Sets current position to the operand after resolution.

If you need to set the position to 0x8000 to perhaps store some information you want to access later in the ROM, you'd do:
`ORG $8000` or `ORG 0x8000`
then use DB directives to store that information.
```
DB "Hello, World!", 0x10, 0x00 ; some data
```
or if your machine starts at position 0x8000, you write your code after the ORG directive setting it to position 0x8000:
```
ORG $8000   ; ORG directive
  LDI r1, 2 ; code
  LDI r2, 2
  ADD r1, r2, r3
  STR r3, 0x00
```

# Special definitions
<a id="fattening">[Fattening]</a>
Fattening means that the output is padded at the end to be the size of the entire ROM to make a flashable image.

<a id="word">[Word]</a>
A word isn't always defined as 2 bytes in this case. depending on the current ISA params, it may be 8 bits, 24 bits, 32 bits, or even 31 bits.
It's defined as how many bits your ROM stores at each address. so:

The word should be set as the amount of bits your machine's ROM stores at any address. If it stores/reads 2 bytes for every address, a word should be defined as 16 bits, if 1 byte, a word should be defined as 8 bits.
If it's set wrong, the instructions and DB data will be at the wrong addresses. Further, DB data might be assembled in an undesired way, like the case in [Specifics of directives \> DB directive](#specifics-db).

<a id="squeezing">[Squeezing]</a>
Squeezing means that the output's lines are replaced with an asterisk '\*' if the lines are repeating.

Example:
```
000: 00
001: 00
002: 00
003: 00
004: 00
005: 00
006: 00 ; padding
007: 42 60 09 ; code
```
with squeezing would be reduced to
```
000: 00 ; padding
* ; squeezed
007: 42 60 09 ; code
```

The same information is conveyed but in a more compact manner, though extra code will be needed to interpret it. (Logisim-evolution as of v3.8.0 can't)

