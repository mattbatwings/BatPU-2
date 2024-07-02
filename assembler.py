# All rights to this code go to the original owner, @MattBatWings
from common import *

###- CONSTANTS -###
# Operand separators
OPERAND_SEPARATORS = ', \t'
# Space characters for inbetween operands and instruction
INSTRUCTION_SPACING = ' \t'
# Opcode position in first word; how much to shift opcode relative to the first word (in bits, left)
OPCODE_POSITION = 12
# Word length in bits
WORD_LENGTH = 16
# Max length an instruction can have (in words)
INSTRUCTION_MAX_LENGTH = 1

###- ALL POSSIBLE OPERANDS -###
# Operands
# Format : '<1 char label>':[<position in word>, <word position>, <bit length>, <1: signed, 0: unsigned>, "<full name>"]
OPERANDS= {
           'F' : [0,  0, 4,  0, "register C"],     # Register C
           'A' : [8,  0, 4,  0, "register A"],     # Register A
           'B' : [4,  0, 4,  0, "register B"],     # Register B
           'I' : [0,  0, 8,  1, "immediate"],      # Immediate
           'C' : [10, 0, 2,  0, "condition"],      # Condition
           'O' : [0,  0, 4,  1, "offset"],         # Offset
           'M' : [0,  0, 10, 0, "memory address"], # Memory address
          }

###- NATIVE INSTRUCTIONS -###
# Format: '<mnemonic>':[<opcode>, '<operand flags in order of use in opcode>', <opcode specific mask>, <size in user-defined words>]
# [A=0] means operand A is optional and defaults to 0
OPCODES = {
           'nop':[0x0, '', 0x0000, 1],        # nop                     : Does nothing
           'hlt':[0x1, '', 0x0000, 1],        # hlt                     : Halts machine
           'add':[0x2, 'ABF', 0x0000, 1],     # add A B C               : pseudo-code: C <- A + B
           'sub':[0x3, 'ABF', 0x0000, 1],     # sub A B C               : pseudo-code: C <- A - B
           'nor':[0x4, 'ABF', 0x0000, 1],     # nor A B C               : pseudo-code: C <- !(A | B)
           'and':[0x5, 'ABF', 0x0000, 1],     # and A B C               : pseudo-code: C <- A & B
           'xor':[0x6, 'ABF', 0x0000, 1],     # xor A B C               : pseudo-code: C <- A ^ B
           'rsh':[0x7, 'AF', 0x0000, 1],      # rsh A C                 : pseudo-code: C <- A >> 1 (logical shift)
           'ldi':[0x8, 'AI', 0x0000, 1],      # ldi A immediate         : pseudo-code: A <- immediate
           'adi':[0x9, 'AI', 0x0000, 1],      # adi A immediate         : pseudo-code: A <- A + immediate
           'jmp':[0xA, 'M', 0x0000, 1],       # jmp address             : pseudo-code: PC <- address
           'brh':[0xB, 'CM', 0x0000, 1],      # brh condition address   : pseudo-code: PC <- condition ? address : PC + 1
           'cal':[0xC, 'M', 0x0000, 1],       # cal address             : pseudo-code: PC <- address (and push PC + 1 to stack)
           'ret':[0xD, '', 0x0000, 1],        # ret                     : pseudo-code: PC <- top of stack (and pop stack)
           'lod':[0xE, 'AB[O=0]', 0x0000, 1], # lod A B [offset=0]      : pseudo-code: B <- mem[A + offset]
           'str':[0xF, 'AB[O=0]', 0x0000, 1]  # str A B [offset=0]      : pseudo-code: mem[A + offset] <- B
          } # Opcodes

###- PSEUDO-INSTRUCTIONS -###
# Pseudo-instructions
# Format : 'label':['<resolution as formatted string>']
# - instructions must be separated by newlines ('\n')
PSEUDO_INSTRUCTIONS = {
        # pseudo-instructions from Matt's assembler
          'cmp':['sub {0} {1} r0'],  # cmp A B : sub A B r0 # do a comparison between registers A, B and set the flags accordingly
          'mov':['add {0} r0 {1}'],  # mov A C : add A r0 C # move contents of register A to register C
          'lsh':['add {0} {0} {1}'], # lsh A C : add A A C  # do a "left-shift by 1" operation on register A and store the result in C
          'inc':['adi {0} 1'],       # inc A   : adi A  1   # increment register A by 1
          'dec':['adi {0} -1'],      # dec A   : adi A -1   # decrement register A by 1
          'not':['nor {0} {1} r0'],  # not A C : nor A r0 C # do the bitwise "NOT" operation on register A and store the result in C
#--------------------------------------------------------------------------------#
          'nnd':['and {0} {1} {2}\n'+   # nnd A B C    : and A B C
                 'not {2} {2}'       ], #                not C C         # do the bitwise "not AND" operation on registers A, B and store the result in C

          'xnr':['xor {0} {1} {2}\n'+   # xnr A B C    : xor A B C
                 'not {2} {2}'       ], #                not C C         # do the bitwise "not XOR" operation on registers A, B and store the result in C

          'orr':['nor {0} {1} {2}\n'+   # orr A B C    : nor A B C
                 'not {2} {2}'       ], #                not C C         # do the bitwise "OR" operation on registers A, B and store the result in C

          'nim':['nor {0} r0 {2}\n'+    # nim A B C    : nor B
                 'and {2} {1} {2}'   ], #                and C A C       # do the bitwise "not IMPLIES" operation on registers A, B and store the result in C
                                        # !(A -> B) = A & (!B)

          'imp':['nim {0} {1} {2}\n'+   # imp A B C    : nim A B C
                 'not {2} {2}'       ], #                not C C         # do the bitwise "IMPLIES" operation on registers A, B and store the result in C
                                        # A -> B = !(!(A -> B))
#--------------------------------------------------------------------------------#
          'use_devices':      ['ldi {0} 248'],      # use_display rbp : ldi rbp 240         # store pixel display's base pointer in rbp

          'set_x':            ['str {0} {1} -8'],   # set_x rbp rX : str rX rbp 0           # store value at rX into pixel display's X port

          'set_xi':           ['ldi {1} {2}\n'+     # set_xi rbp rBuf imm : ldi rBuf imm
                               'set_x {0} {1}' ],   #                       set_x rbp rBuf  # store immediate value into pixel display's X port

          'set_y':            ['str {0} {1} -7'],   # set_y rbp rY : str rY rbp 1           # store value at rY into pixel display's Y port

          'set_yi':           ['ldi {1} {2}\n'+     # set_yi rbp rBuf imm : ldi rBuf imm
                               'set_y {0} {1}' ],   #                       set_y rbp rBuf  # store immediate value into pixel display's Y port

          'set_pixel':        ['str {0} r0 -6'],    # set_pixel rbp : str r0 rbp 2          # trigger pixel display's Draw Pixel port to draw current pixel

          'clr_pixel':        ['str {0} r0 -5'],    # clr_pixel rbp : str r0 rbp 3          # trigger pixel display's Clear Pixel port to clear current pixel

          'get_pixel':        ['lod {0} {1} -4'],   # get_pixel rbp rDest : lod rDest rbp 4 # load pixel at current pixel position

          'cpy_disp_buffer':  ['str {0} r0 -3'],    # cpy_disp_buffer rbp : str r0 rbp 5    # copy pixel display buffer to screen

          'clr_disp_buffer':  ['str {0} r0 -2'],    # clr_disp_buffer rbp : str r0 rbp 6    # clear pixel display buffer

          'clr_display':['clr_disp_buffer {0}\n'+   # clr_display rbp : clr_disp_buffer rbp
                         'cpy_disp_buffer {0}'   ], #                   cpy_disp_buffer rbp # clear both display and display buffer
#--------------------------------------------------------------------------------#
          'add_char':         ['str {0} {1} -1'],   # add_char rbp rChar  : str rChar rbp 0 # append character at rChar to character display buffer

          'add_chari':        ['ldi {1} {2}\n'+     # add_chari rbp rBuf imm : ldi rBuf imm
                               'add_char {0} {1}'], #                          add_char rbp rBuf
                                                                                            # append immediate character imm to character display buffer

          'cpy_char_buffer':  ['str {0} r0 0'],     # cpy_char_buffer rbp : str r0 rbp 1    # copy character display buffer to char display

          'clr_char_buffer':  ['str {0} r0 1'],     # clr_char_buffer rbp : str r0 rbp 2    # clear character display buffer

          'clr_char_display': ['clr_char_buffer {0}\n'+   # clr_char_display rbp : clr_char_buffer rbp
                               'cpy_char_buffer {0}'   ], #                        cpy_char_buffer rbp
                                                                                            # clear both char display and buffer
#--------------------------------------------------------------------------------#
          'set_num':          ['str {0} {1} 2'],    # set_num rbp rNum : str rNum rbp       # set number display's buffer to number in rNum

          'set_numi':         ['ldi {1} {2}\n'+     # set_numi rbp rBuf imm : ldi rBuf imm
                               'set_num {0} {1}'],  #                         set_num rbp rBuf
                                                                                            # set number display's buffer to immediate imm

          'clr_num_display':  ['str {0} r0 3'],     # clr_num_display rbp : str r0 rbp 1    # clear number display

          'num_mode_signed':  ['str {0} r0 4'],     # num_mode_signed rbp : str r0 rbp 2    # set number display to signed mode

          'num_mode_unsigned':['str {0} r0 5'],     # num_mode_unsigned rbp : str r0 rbp 3  # set number display to unsigned mode
#--------------------------------------------------------------------------------#
          'get_rng':          ['lod {0} {1} 6'],    # get_rng rbp rDest : lod rDest rbp     # put a random number in rDest

          'get_cont_state':   ['lod {0} {1} 7'],    # get_cont_state rbp rDest : lod rDest rbp
                                                                                            # put the controller's current state in rDest
         }
###- STARTING SYMBOLS -###
# Dictionary that the assembler starts with
STARTING_SYMBOLS = {
                    'r0':  0,  'r1':  1,  'r2':  2,  'r3':  3, # Registers
                    'r4':  4,  'r5':  5,  'r6':  6,  'r7':  7,
                    'r8':  8,  'r9':  9,  'r10': 10, 'r11': 11,
                    'r12': 12, 'r13': 13, 'r14': 14, 'r15': 15,

                    'eq': 0, 'ne': 1, 'ge': 2, 'lt': 3, # Conditions
                    '=': 0, '!=': 1, '>=': 2, '<': 3,
                    'z': 0, 'nz': 1, 'c': 2, 'nc': 3,
                    'zero': 0, 'notzero': 1, 'carry': 2, 'notcarry': 3,

                    'pixel_x':             240, # Screen
                    'pixel_y':             241,
                    'draw_pixel':          242,
                    'clear_pixel':         243,
                    'load_pixel':          244,
                    'buffer_screen':       245,
                    'clear_screen_buffer': 246,

                    'write_char':         247, # Char display
                    'buffer_chars':       248,
                    'clear_chars_buffer': 249,
                    'show_number':        250,
                    'clear_number':       251,
                    'signed_mode':        252,
                    'unsigned_mode':      253,

                    'rng':              254, # Controller
                    'controller_input': 255,
                   }

###- UTILITY -###
# Define check
def is_define(word):
    if(len(word) == 0):
        return 0
    return word == 'define'
# Label check
def is_label(word):
    if(len(word) == 0):
        return 0
    return (word[0] == '.') | ((word[-1] == ':') << 1)
# Definition check
def is_definition(word, symbols):
    if(len(word) == 0):
        return 0
    return word in symbols
# Pseudo-instruction check
def is_pseudo(word):
    if(len(word) == 0):
        return 0
    return word in PSEUDO_INSTRUCTIONS
# Turn label as it appears in code into how it'll be used in instructions ('Done:' -> '.Done')
def to_label(word, filename, line, caller):
    if(len(word) == 0):
        return 0
    result = is_label(word)
    if(result != 0):
        if(result == 1):
            return word
        elif(result == 2):
            return ('.' + word[:-1])
        elif(result == 3):
            return word[:-1]
    else:
        fatal_error('assembler', f"{caller}: {filename}:{line}: Could not interpret label \'{word}\'")
# Convert label from many syntaxes into 1 syntax
def convert_label(word):
    result = is_label(word)
    if(result != 0):
        if(result == 1):
            return (word[1:] + ':')
        elif(result == 2):
            return word
        elif(result == 3):
            return word[1:]
    else:
        fatal_error('assembler debug', f"convert_label: Could not interpret label \'{word}\'")
# Resolve symbols
# symbols = [symbols, labels, definitions]
def resolve(word, filename, line, symbols, caller):
    # Return unmodified if is an int
    if(type(word) == int):
        return word
    # labels
    elif(is_label(word) == 1):
        try:
            return symbols[1][word]
        except KeyError as _ERR:
            print('Labels table dump:')
            print(dump_dict(symbols[1]))
            fatal_error('assembler', f"{caller}: {filename}:{line}: Could not resolve label \'{word}\'\n{_ERR}")
    # definitions
    elif(is_definition(word, symbols[2])):
        try:
            return symbols[2][word]
        except KeyError as _ERR:
            fatal_error('assembler', f"{caller}: {filename}:{line}: Could not resolve definitioon-.. whaat? I checked! It's inside the table I swear! Take a look!\nDump:\n{dump_dict(symbols[2])}\n{_ERR}")
    # everything else
    try:
        return symbols[0][word]
    except KeyError as _ERR:
        print('Symbol table dump:')
        print(dump_dict(symbols[0]))
        fatal_error('assembler', f"{caller}: {filename}:{line}: Could not resolve symbol \'{word}\'\n{_ERR}")
# Resolve integers, ignores everything else
def resolve_integer(word, filename, line, caller):
    # Return unmodified if is an int, or empty
    if((type(word) == int) or (len(word) == 0)):
        return word
    # Auto-detect format
    if(word[0] in '-0123456789'):
        try:
            offset = 0
            if(word[0] == '-'):
                offset = 1
            if(word[offset:offset + 2] == '0x'):
                return int(word[:offset] + word[offset + 2:], 16)
            elif(word[offset:offset + 2] == '0o'):
                return int(word[:offset] + word[offset + 2:], 8)
            elif(word[offset:offset + 2] == '0b'):
                return int(word[:offset] + word[offset + 2:], 2)
            else:
                return int(word, 10)
        except ValueError as _ERR:
            fatal_error('assembler', f"{caller}: {filename}:{line}: Could not resolve number \'{word}\'\n{_ERR}")
    # $ prefixed hexadecimal
    elif(word[0] == '$'):
        try:
            return int(word[1:], 16)
        except ValueError as _ERR:
            fatal_error('assembler', f"{caller}: {filename}:{line}: Could not resolve hexadecimal \'{word}\'\n{_ERR}")
    # Return unmodified if not an integer
    return word
# Handle character constant
def char_constant(string, idx, filename, line, caller, resolve_strings=True):
    idx_end=strfind_escape(string, '\'', idx + 1)
    if(idx_end==-1):
        fatal_error('assembler', f"{caller}: {filename}:{line}:{idx + 1}: Missing terminating \' character.\n{string}\n{' ' * idx}^{'~' * (len(string) - idx - 1)}")
    idx_end += 1
    if(not resolve_strings):
        return (idx, idx_end, [string[idx:idx_end]])
    try:
        evaluated = eval(string[idx:idx_end])
    except Exception as _ERR:
        fatal_error('assembler', f"{caller}: {filename}:{line}:{idx + 1}: Could not evaluate character constant.\n{string}\n{' ' * idx}^{'~' * (idx_end - idx - 1)}\n{_ERR}")
    if(len(evaluated) > 1):
        fatal_error('assembler', f"{caller}: {filename}:{line}:{idx + 1}: Too many characters in character constant.\n{string}\n{' ' * idx}^{'~' * (idx_end - idx - 1)}")
    elif(len(evaluated) == 0):
        fatal_error('assembler', f"{caller}: {filename}:{line}:{idx + 1}: Empty character constant.\n{string}\n{' ' * idx}^~")
    return (idx, idx_end, [ord(evaluated) & ((1 << WORD_LENGTH) - 1)])
# Handle string constant
def string_constant(string, idx, filename, line, caller, resolve_strings=True):
    idx_end=strfind_escape(string, '\"', idx + 1)
    if(idx_end==-1):
        fatal_error('assembler', f"{caller}: {filename}:{line}:{idx + 1}: Missing terminating \" character.\n{string}\n{' ' * idx}^{'~' * (len(string) - idx - 1)}")
    idx_end += 1
    if(not resolve_strings):
        return (idx, idx_end, [string[idx:idx_end]])
    try:
        evaluated = eval(string[idx:idx_end])
    except Exception as _ERR:
        fatal_error('assembler', f"{caller}: {filename}:{line}:{idx + 1}: Could not evaluate string constant.\n{string}\n{' ' * idx}^{'~' * (idx_end - idx - 1)}\n{_ERR}")
    if(len(evaluated) == 0):
        fatal_error('assembler', f"{caller}: {filename}:{line}:{idx + 1}: Empty string constant.\n{string}\n{' ' * idx}^~")
    return (idx, idx_end, [(ord(char) & ((1 << WORD_LENGTH) - 1)) for char in evaluated])
# Decompose instruction + character constants
def decompose_instruction(string, filename, line, caller, resolve_strings=True):
    idx=0
    output=[]
    while(idx<len(string)):
        idx=inverted_strfind(string, OPERAND_SEPARATORS, idx)
        if(idx==-1):
            break
        if(string[idx] == '\''):
            idx, idx_end, constant = char_constant(string, idx, filename, line, caller, resolve_strings)
            output = output + constant
        elif(string[idx] == '\"'):
            idx, idx_end, constants = string_constant(string, idx, filename, line, caller, resolve_strings)
            if(len(constants) != 1):
                fatal_error('assembler', f"{caller}: {filename}:{line}:{idx + 1} There must be exactly 1 character in string constant. (for instruction operands)\n{string}\n{' ' * idx}^{'~' * (idx_end - idx - 1)}")
            output = output + constants
        else:
            idx_end=strfind(string, OPERAND_SEPARATORS, idx)
            if(idx_end==-1):
                output.append(string[idx:])
                break
            output.append(string[idx:idx_end])
        idx=idx_end
    if(resolve_strings):
        return [resolve_integer(x, filename, line, caller) for x in output]
    return output
# Decompose instruction + character constants + strings
def decompose_instruction_multi(string, filename, line, caller, resolve_strings=True):
    idx=0
    output=[]
    while(idx<len(string)):
        idx=inverted_strfind(string, OPERAND_SEPARATORS, idx)
        if(idx==-1):
            break
        if(string[idx] == '\''):
            idx, idx_end, constant = char_constant(string, idx, filename, line, caller, resolve_strings)
            output = output + constant
        elif(string[idx] == '\"'):
            idx, idx_end, constants = string_constant(string, idx, filename, line, caller, resolve_strings)
            output = output + constants
        else:
            idx_end=strfind(string, OPERAND_SEPARATORS, idx)
            if(idx_end==-1):
                output.append(string[idx:])
                break
            output.append(string[idx:idx_end])
        idx=idx_end
    if(resolve_strings):
        return [resolve_integer(x, filename, line, caller) for x in output]
    return output
# Parse line
def parse_line(line, filename, caller, resolve_strings=True):
    decomposed_lines = []
    decomposed_definitions = []
    split_A = 0
    split_B = 0
    instruction = ''
    # Labels and finding instruction
    while(is_label(instruction) or (split_A == 0)):
        split_B = strfind(line[0], INSTRUCTION_SPACING, split_A)
        if(split_B == -1):
            instruction = line[0][split_A:]
        else:
            instruction = line[0][split_A:split_B]
        if(is_label(instruction)):
            decomposed_lines.append([[instruction], line[1]])
        if(split_B == -1):
            break
        split_A = inverted_strfind(line[0], INSTRUCTION_SPACING, split_B)
    if(split_B != -1):
        parameters  = line[0][split_A:]
    else:
        parameters = ""
    if(is_label(instruction)):
        return decomposed_lines, decomposed_definitions
    instruction = instruction.lower()
    # Definition
    if(is_define(instruction)):
        decomposed_definitions.append([[instruction] + decompose_instruction(parameters, filename, line[1], caller, resolve_strings), line[1]])
    # ORG
    elif(instruction == 'org'):
        decomposed_lines.append([[instruction] + decompose_instruction(parameters, filename, line[1], caller, resolve_strings), line[1]])
    # DB
    elif(instruction == 'db'):
        decomposed_lines.append([[instruction] + decompose_instruction_multi(parameters, filename, line[1], caller, resolve_strings), line[1]])
    # Assume it's an instruction
    else:
        decomposed_lines.append([[instruction] + decompose_instruction(parameters, filename, line[1], caller, resolve_strings), line[1]])
    return decomposed_lines, decomposed_definitions
# Recompose line
def recompose_line(line):
    instruction = line[0][0]
    if(is_label(instruction)):
        return convert_label(instruction)
    return instruction.upper() + ' ' + ', '.join(str(x) for x in line[0][1:])
# Display multiple lines of Assembly
def print_assembly(lines, last_was, line_width):
    last_line = 0
    special_case = False
    for line in lines:
        if(last_line == line[1]):
            print("%s: "%(' ' * line_width), end='')
        else:
            print("%0*d: "%(line_width, line[1]), end='')
        if((line[0][0] not in ['org', 'db', 'define']) and (is_label(line[0][0]) == 0)):
            print("  ", end='')
        print(recompose_line(line), end='')
        # I don't even know
        if(((line[1] in last_was) and (last_line != line[1])) or special_case):
            if(is_label(line[0][0]) != 0):
                special_case = True
            else:
                print(" ; resolved from ; %s"%(recompose_line(last_was[line[1]])), end='')
                special_case = False
        last_line = line[1]
        print()
# Display multiple lines of Assembly with machine code positions
def print_assembly_wordpos(lines, last_was, line_width, hex_width):
    last_line = 0
    special_case = False
    for line in lines:
        if(last_line == line[1]):
            print("%s:%0*X: "%(' ' * line_width, hex_width, line[2]), end='')
        else:
            print("%0*d:%0*X: "%(line_width, line[1], hex_width, line[2]), end='')
        if((line[0][0] not in ['org', 'db', 'define']) and (is_label(line[0][0]) == 0)):
            print("  ", end='')
        print(recompose_line(line), end='')
        # I don't even know
        if(((line[1] in last_was) and (last_line != line[1])) or special_case):
            if(is_label(line[0][0]) != 0):
                special_case = True
            else:
                print(" ; resolved from ; %s"%(recompose_line(last_was[line[1]])), end='')
                special_case = False
        elif(line[0][0] == 'org'):
            print(" ; jump to 0x%0*X"%(hex_width, line[2]), end='')
        last_line = line[1]
        print()
# Strip line of comments
def remove_comment(comment_symbols, line):
    index=strfind(line, comment_symbols)
    if(index==-1):
        return line
    return line[:index]

###- MAIN THING -###
# Assemble function
def assemble(assembly_filename, ROM_size, verbose_level, debug_flags):
    try:
        assembly_file = open(assembly_filename, 'r')
    except FileNotFoundError as _ERR:
        fatal_error('assembler', f"{assembly_filename}: File not found.\n{_ERR}")
    if(verbose_level >= 0):
        print(f"assembler: Reading from \'{assembly_filename}\'")
    lines = [line.strip() for line in assembly_file]

    # DEBUG: ROM address size constant
    ROM_address_size = int(log2(ROM_size) + 3) >> 2
    if(verbose_level >= 2):
        print("Address hex width: %d (%s)"%(ROM_address_size, ''.join(hex(x%16).upper()[2] for x in range(ROM_address_size))))
    line_address_size = int(log(len(lines), 10) + 1)
    if(verbose_level >= 2):
        print("Line address width: %d (%s)"%(line_address_size, ''.join(chr(0x30 + (x%10)) for x in range(line_address_size))))

    # Remove comments and blanklines, and add line number
    lines = [[remove_comment("/;#", line).strip(), idx+1] for idx, line in enumerate(lines)]

    # Remove empty lines & add line numbers
    lines = [line for line in lines if(len(line[0]) != 0)]

    # Populatesymbol table
    symbols = STARTING_SYMBOLS
    # Definitions table
    definitions = {}
    # Labels table
    labels = {}

    # Calculate number of operands and add to macro element
    for pop in PSEUDO_INSTRUCTIONS:
        popinfo=PSEUDO_INSTRUCTIONS[pop]
        # sketch sketch
        words=[]
        for line in popinfo[0].split('\n'):
            for decomposed in parse_line([line, 0], assembly_filename, 'pseudo-instruction prepper')[0]:
                words += decomposed[0]
        nums=[int(word[1:len(word)-1]) for word in words if str(word)[0]=='{']
        if(len(nums)==0):
            PSEUDO_INSTRUCTIONS[pop].insert(0, 0)
        else:
            PSEUDO_INSTRUCTIONS[pop].insert(0, max(nums)+1)
    
    # Check operands
    for operand in OPERANDS:
        if(OPERANDS[operand][1] >= INSTRUCTION_MAX_LENGTH):
            fatal_error('assembler', f"loading stage: wtf: Operand \'{OPERANDS[operand][4]}\' defined in a word outside set maximum length, are you sure it\'s correct?")
        if(OPERANDS[operand][0] >= WORD_LENGTH):
            fatal_error('assembler', f"loading stage: wtf: Operand \'{OPERANDS[operand][4]}\' shift amount is bigger than a word, are you sure it\'s correct?")
        if((((OPERANDS[operand][1] + 1) * WORD_LENGTH) - OPERANDS[operand][0] - OPERANDS[operand][2]) < 0):
            fatal_error('assembler', f"loading stage: wtf: Operand \'{OPERANDS[operand][4]}\' is defined outside the instruction, are you sure it\'s correct?")

    # Make instructions more machine-friendly and check instruction lengths
    for opcode in OPCODES:
        # Error and prompt user if instruction's length exceeds max length
        if((OPCODES[opcode][3] * WORD_LENGTH) > (INSTRUCTION_MAX_LENGTH * WORD_LENGTH)):
            fatal_error('assembler', f"loading stage: wtf: Instruction \'{opcode}\' exceeds set maximum length, are you sure it\'s correct?")

        processed_opcode=[]
        operands=OPCODES[opcode][1]

        idx=0
        minimum_operands=0
        while(idx<len(operands)):
            # Process optional operand
            if(operands[idx]=='['):
                idx_end=operands.find(']', idx)
                if(idx_end==-1):
                    fatal_error('assembler', f"loading stage: syntax error: No closing brace for operand \'{operands[idx+1]}\' in instruction \'{opcode}\'.")
                substr=operands[idx+1:idx_end]
                if(substr[2:]==''):
                    fatal_error('assembler', f"loading stage: wtf: No default defined for operand \'{substr[0]}\' for instruction \'{opcode}\'.")
                processed_opcode.append([substr[0], int(substr[2:])])
                idx=idx_end+1
                minimum_operands-=1
            # Process sequence of mandatory operands
            else:
                idx_end=operands.find('[', idx)
                if(idx_end==-1):
                    idx_end += len(operands) + 1
                substr=operands[idx:idx_end]
                processed_opcode = processed_opcode + [[x] for x in substr]
                idx=idx_end

        # Check operands used in instruction; make sure operands don't go outside the instruction
        for index in range(len(processed_opcode)):
            operand = processed_opcode[index][0]
            if(OPERANDS[operand][1] >= OPCODES[opcode][3]):
                fatal_error('assembler', f"loading stage: wtf: Operand \'{OPERANDS[operand][4]}\' in instruction \'{opcode}\' is defined in a word outside the instruction\'s length, are you sure it\'s correct?")

        maximum_operands=len(processed_opcode)
        minimum_operands=minimum_operands+maximum_operands
        processed_opcode=[processed_opcode, minimum_operands, maximum_operands]
        OPCODES[opcode][1]=processed_opcode

    # Validity check
    for opcode in OPCODES:
        operands=OPCODES[opcode][1][0]
        maxim=1
        for idx, operand in enumerate(operands):
            if(maxim <= len(operand)):
                maxim=len(operand)
            else:
                fatal_error('assembler', f"loading stage: wtf: Optional operand \'{operands[idx-1][0]}\' declared inbetween mandatory ones in instruction \'{opcode}\'! (Will cause problems later)")

#    for symbol in OPCODES:
#        symbols[symbol] = OPCODES[symbol][0] # Add corresponding numeral opcode

    # Decompose instructions and separate labels
    decomposed = []
    decomposed_definitions = []
    original_lines = {}
    for line in lines:
        new_lines, new_definitions = parse_line(line, assembly_filename, 'parser')
        decomposed = decomposed + new_lines
        decomposed_definitions = decomposed_definitions + new_definitions
        new_lines, new_definitions = parse_line(line, assembly_filename, 'parser', False)
        original_lines[line[1]] = new_lines + new_definitions

    # DEBUG: display Assembly right now
    if(verbose_level >= 3):
        print("ASSEMBLY:")
        print_assembly(decomposed, {}, line_address_size)

    # DEBUG: display definitions
    if(verbose_level >= 3):
        print("\nDEFINITIONS:")
        print_assembly(decomposed_definitions, {}, line_address_size)

    # Resolve pseudo-instructions
    # DEBUG: show current action
    if(verbose_level >= 1):
        print("\nRESOLVING PSEUDO-INSTRUCTIONS..")
    last_was = {}
    cont=True
    while(cont):
        cont=False
        index = 0

        while(index < len(decomposed)):
            line = decomposed[index]
            line_number=line[1]
            words=line[0]

            if(is_pseudo(words[0])):
                if(line_number not in last_was):
                    last_was[line_number] = line
                cont=True
                popinfo=PSEUDO_INSTRUCTIONS[words[0]]
                if(popinfo[0] != (len(words) - 1)):
                    fatal_error('assembler', f"pre-assembly stage: {assembly_filename}:{line_number}: Incorrect number of operands for pseudo-instruction \'{words[0]}\'")
                gen_lines = popinfo[1].format(*words[1:]).split('\n')
                parsed = []
                for gline in gen_lines:
                    new_lines, new_definitions = parse_line([gline, line_number], assembly_filename, 'parser')
                    parsed = parsed + new_lines
                    decomposed_definitions = decomposed_definitions + new_definitions
                # DEBUG: display resolved line
                if(verbose_level >= 2):
                    print('%0*d: %s -> %s'%(line_address_size, line_number, recompose_line(line), '\\n'.join(recompose_line(gline) for gline in parsed)))
                decomposed = decomposed[:index] + parsed + decomposed[index + 1:]
            else:
                index += 1

    # DEBUG: display Assembly after resolving pseudo-instructions
    if(verbose_level >= 3):
        print("\nASSEMBLY NOW:")
        print_assembly(decomposed, last_was, line_address_size)

    # DEBUG: display definitions after resolving pseudo-instructions
    if(verbose_level >= 3):
        print("\nDEFINITIONS NOW:")
        print_assembly(decomposed_definitions, last_was, line_address_size)

    # Memorize definitions
    # DEBUG: show current action
    if(verbose_level >= 1):
        print("\nMEMORIZING DEFINITIONS:")
    for index in range(len(decomposed_definitions)):
        line = decomposed_definitions[index]
        line_number = line[1]
        words = line[0]
        if(len(words) == 1):
            fatal_error('assembler', f"pre-assembly stage: {assembly_filename}:{line_number}: No parameters given for definition.")
        elif(len(words) == 2):
            fatal_error('assembler', f"pre-assembly stage: {assembly_filename}:{line_number}: Only name given for definition.")
        elif(len(words) > 3):
            fatal_error('assembler', f"pre-assembly stage: {assembly_filename}:{line_number}: Too many parameters given for definition.")
        elif((words[1][0] in "0123456789") or (not words[1].isalnum())):
            fatal_error('assembler', f"pre-assembly stage: {assembly_filename}:{line_number}: Invalid name for definition \'{words[1]}\'")
        elif(type(words[2]) != int):
            fatal_error('assembler', f"pre-assembly stage: {assembly_filename}:{line_number}: Definition resolution couldn\'t be resolved as an integer \'{words[2]}\'")
        # 2000 error handling, 1 functional
        definitions[words[1]] = words[2]
        # DEBUG: display definition
        if(verbose_level >= 2):
            print(f"\'{words[1]}\' = {words[2]}")

    # DEBUG: display definitions table
    if(verbose_level >= 3):
        print(f"\nDEFINITIONS TABLE:\n{dump_dict(definitions)}", end='')

    # Resolve definitions
    # DEBUG: show current action
    if(verbose_level >= 1):
        print("\nRESOLVING DEFINITIONS (USER-DEFINED & ISA-DEFINED)..")
    for index in range(len(decomposed)):
        line = deep_copy(decomposed[index])
        line_number = line[1]
        params = line[0]
        changed = False
        for index2 in range(1, len(params)):
            if(params[index2] in definitions):
                changed = True
                decomposed[index][0][index2] = definitions[params[index2]]
            elif(params[index2] in symbols):
                changed = True
                decomposed[index][0][index2] = symbols[params[index2]]
        # DEBUG: show resolved line
        if(verbose_level >= 2):
            if(changed):
                print("%0*X: %s -> %s"%(line_address_size, line_number, recompose_line(line), recompose_line(decomposed[index])))

    # DEBUG: display Assembly after resolving definitions
    if(verbose_level >= 3):
        print("\nASSEMBLY NOW:")
        print_assembly(decomposed, last_was, line_address_size)

    # Calculate positions of lines in the machine code file, using the user-defined instruction lengths
    # Resolves & removes ORG directives too
    # DEBUG: show current action
    if(verbose_level >= 1):
        print("\nCALCULATING POSITIONS IN MACHINE CODE..")
    position = 0 # Default is position 0
    for index in range(len(decomposed)):
        line = decomposed[index]
        words = line[0]
        line_number = line[1]
        # DEBUG: display current line
        if(verbose_level >= 2):
            spacing = ' ' * line_address_size
            print("%0*d: %s"%(line_address_size, line_number, recompose_line(line)))

        # Handle ORG directive
        if(words[0] == 'org'):
            if(len(words) == 1):
                fatal_error('assembler', f"position resolver: {assembly_filename}:{line_number}: No parameters given for ORG directive.")
            elif(len(words) > 2):
                fatal_error('assembler', f"position resolver: {assembly_filename}:{line_number}: Too many parameters given for ORG directive.")
            position = words[1]
            # DEBUG: show position jump
            if(verbose_level >= 2):
                print("%s: Encountered ORG directive, changing position to 0x%0*X"%(spacing, ROM_address_size, position))

        # Check if position is in ROM bounds
        if(position >= ROM_size):
            fatal_error('assembler', f"position resolver: {assembly_filename}:{line_number}: Position {'0x%X'%position} is out of bounds of the ROM. (ROM size = {ROM_size})")
        elif(position < 0):
            fatal_error('assembler', f"position resolver: {assembly_filename}:{line_number}: Position went negative ({'0x%X'%position}). What the fuck are you doing?")

        # Add current position to line
        decomposed[index].append(position)
        # DEBUG: show what position current line is in the machine code
        if(verbose_level >= 2):
            print("%s: is at 0x%0*X"%(spacing, ROM_address_size, position))

        # Handle known instruction
        if(words[0] in OPCODES):
            position += OPCODES[words[0]][3]
            # DEBUG: show how many words 'position' is incremented by
            if(verbose_level >= 2):
                print("%s: \'%s\' is a known instruction, and is %d words.\n%s: Incrementing position by %d words."%(spacing, words[0], OPCODES[words[0]][3], spacing, OPCODES[words[0]][3]))
        # Handle DB directive
        elif(words[0] == 'db'):
            if(len(words) == 1):
                fatal_error('assembler', f"position resolver: {assembly_filename}:{line_number}: No parameters given for DB directive.")
            position += len(words) - 1
            # DEBUG: show how many words 'position' is incremented by
            if(verbose_level >= 2):
                print("%s: Encountered DB directive, that defines %d words.\n%s: Incrementing position by %d words."%(spacing, len(words) - 1, spacing, len(words) - 1))

    # DEBUG: show assembly after calculating positions
    if(verbose_level >= 3):
        print("\nASSEMBLY NOW:")
        print_assembly_wordpos(decomposed, last_was, line_address_size, ROM_address_size)

    # Memorize labels
    # DEBUG: show current action
    if(verbose_level >= 1):
        print("\nMEMORIZING LABELS..")
    for index in range(len(decomposed)):
        line = decomposed[index]
        words = line[0]
        line_number = line[1]
        line_word_pos = line[2]

        result = is_label(words[0])
        if(result != 0):
            label = to_label(words[0], assembly_filename, line_number, 'label resolver')
            labels[label] = line_word_pos
            # DEBUG: show what position label is at
            if(verbose_level >= 2):
                print("\'%s\' (\'%s\') is at 0x%0*X"%(label, words[0], ROM_address_size, line_word_pos))

    # DEBUG: show label table
    if(verbose_level >= 3):
        print("\nLABEL TABLE:")
        print(dump_dict(labels))

    # Resolve labels
    # DEBUG: show current action
    if(verbose_level >= 1):
        print("\nRESOLVING LABELS..")
    for index in range(len(decomposed)):
        line = deep_copy(decomposed[index])
        line_number = line[1]
        params = line[0]
        changed = False
        for index2 in range(1, len(params)):
            if(type(params[index2]) == int):
                continue
            if(is_label(params[index2]) == 1):
                changed = True
                try:
                    decomposed[index][0][index2] = labels[params[index2]]
                except KeyError as _ERR:
                    fatal_error('assembler', f"label resolver: {assembly_filename}:{line_number}: Couldn\'t resolve label.\nLabel table dump:\n{dump_dict(labels)}")
        # DEBUG: show resolved line
        if(verbose_level >= 2):
            if(changed):
                print("%0*d:%0*X: %s -> %s"%(line_address_size, line_number, ROM_address_size, line[2], recompose_line(line), recompose_line(decomposed[index])))

    # DEBUG: display Assembly after resolving labels
    if(verbose_level >= 3):
        print("\nASSEMBLY NOW:")
        print_assembly_wordpos(decomposed, last_was, line_address_size, ROM_address_size)

    # Lines should be clean by now

    # Start assembling
    output_machine_code = []
    last_line = -1
    for i in range(len(decomposed)):
        # Decompose instruction
        line=decomposed[i]
        words=line[0]
        line_number=line[1]

        machine_code = 0
        current_instruction = words[0]
        words = words[1:]
        
        # Begin machine code translation
        # handle DB directive
        if(current_instruction == 'db'):
            output_machine_code.append([sum(words[len(words) - index - 1] << (index * WORD_LENGTH) for index in range(len(words))), line_number, line[2], len(words), original_lines[line_number][0]])
        # skip ORG directives
        elif(current_instruction == 'org'):
            continue
        # skip labels
        elif(is_label(current_instruction) != 0):
            continue
        # handle known instructions
        elif(current_instruction in OPCODES):
            # Resolve mnemonic
            try:
                current_opinfo = OPCODES[current_instruction]
            except KeyError as _ERR:
                fatal_error('assembler', f"assembly stage: {assembly_filename}:{line_number}: Unknown instruction mnemonic \'{current_instruction}\'\n{_ERR}")
            current_size = current_opinfo[3]

            # Assemble opcode
            machine_code |= current_opinfo[0] << (OPCODE_POSITION + ((current_opinfo[3] - 1) * WORD_LENGTH))

            # Number of operands check
            if(  current_opinfo[1][-2] > len(words)):
                fatal_error('assembler', f"assembly stage: {assembly_filename}:{line_number}: Not enough operands for instruction \'{current_instruction}\'")
            elif(current_opinfo[1][-1] < len(words)):
                fatal_error('assembler', f"assembly stage: {assembly_filename}:{line_number}: Too many operands for instruction \'{current_instruction}\'")

            # Check operands and assemble them
            for idx, opcode in enumerate(current_opinfo[1][0]):
                if(len(words)<=idx):
                    words.append(opcode[1])
                opinfo = OPERANDS[opcode[0]]
                mask   = (1<<opinfo[2]) - 1
                if opinfo[3] and (words[idx]<0):
                    words[idx]=(~words[idx])+1
                if words[idx] != (words[idx] & mask):
                    fatal_error('assembler', f"assembly stage: {assembly_filename}:{line_number}: Invalid {opinfo[4]} for instruction \'{current_instruction}\'")
                machine_code |= (words[idx] & mask) << (opinfo[0] + ((current_opinfo[3] - opinfo[1] - 1) * WORD_LENGTH))
                # Just to be safe, it's ANDed with the mask

            # OR with opcode-specific mask
            machine_code |= current_opinfo[2]

            # Length check
            if((int(log2(machine_code)) + 1) > (current_opinfo[3] * WORD_LENGTH)):
                fatal_error('assembler', f"assembly stage: {assembly_filename}:{line_number}: Uh-oh! the instruction at this line ended up bigger than expected, this should be investigated.. You should open an issue about this!\n" +
                "Relevant info:\n" +
                "  Version format: {1}\n  Version.......: {0}\n".format(*render_version(VERSION, VER_FMT)) +
                f"  {assembly_filename}:{line_number}: {lines[i][0]}\n")

            # Output
            # Format is: [<INSTRUCTION>, <LINE IN ASSEMBLY FILE>, <POSITION IN WORDS>, <SIZE IN WORDS>, [<ORIGINAL OPERANDS>]]
            if(last_line != line_number):
                output_machine_code.append([machine_code, line_number, line[2], current_size, original_lines[line_number][0]])
            else:
                output_machine_code.append([machine_code, line_number, line[2], current_size])
            last_line = line_number
        else:
            fatal_error('assembler', f"assembly stage: {assembly_filename}:{line_number}: \'{current_instruction.upper()}\' is not a valid instruction.")

    if(verbose_level >= 1):
        print("\nSORTING OUTPUT BY POSITION IN MACHINE CODE..")
    output_machine_code.sort(key = lambda x:x[2])

    # DEBUG: print machine code and their origins
    if(verbose_level >= 2):
        print("OUTPUT:\n%s\nDISAMBIGUATION:"%(dump_array(output_machine_code)))
        word_size = (WORD_LENGTH + 3) >> 2
        for machine_code in output_machine_code:
            print('%0*d:%0*X: %s'%(line_address_size, machine_code[1], ROM_address_size, machine_code[2], " ".join("%0*X"%(word_size, x) for x in word_dissect(machine_code[0], machine_code[3], WORD_LENGTH))), end='')
            if(len(machine_code) >= 5):
                print(' ; %s'%(recompose_line(machine_code[4])), end='')
            print()
    if(debug_flags & 1):
        print(f'Label table dump:\n{dump_dict(labels)}')
    if(debug_flags & 2):
        print(f'Definition table dump:\n{dump_dict(definitions)}')
    return output_machine_code

# Formats output of the assembler
def formatter(assembler_output, output_file, rom_size, padding_word, format_style, verbose_level):
    format_style = format_style.lower()
    ROM_address_size = int(log2(rom_size) + 3) >> 2
    word_size = (WORD_LENGTH + 3) >> 2
    if(format_style in ['raw', 'image']):
        output = open(output_file, 'wb')
    else:
        output = open(output_file, 'w')

    if(verbose_level >= 1):
        print(f"formatter: Outputting to \'{output_file}\'")
        print("formatter: Outputting as", end='')

    # Matt's assembler format
    ## Outputs binary as ASCII
    ## Output is as big as it needs to be
    ## Empty space is filled with provided padding_word
    if(format_style == 'matt'):
        print(" Matt\'s format.")
        head = 0
        for instruction in assembler_output:
            position = instruction[2]
            size = instruction[3]
            word = instruction[0]
            if(head != position):
                for _ in range(position - head):
                    output.write(bin(padding_word)[2:].zfill(WORD_LENGTH) + '\n')
                head = position
            output.write(bin(word)[2:].zfill(WORD_LENGTH * size) + '\n')
            head += size
    # Raw format
    ## Just raw binary, not human friendly
    ## Output is as big as it needs to be if raw format
    ## Output is fattened to be (rom_size * bytes_per_word) bytes with provided padding_word if image format
    ## Empty space is filled with provided padding_word
    elif(format_style in ['raw', 'image']):
        if(verbose_level >= 1):
            if(format_style == 'raw'):
                print(" raw format.")
            else:
                print(" ROM image format.")
        head = 0
        bytes_per_word = (WORD_LENGTH + 7) >> 3
        padding = bytes(word_dissect(padding_word, bytes_per_word, 8))

        if(format_style == 'image'):
            assembler_output.append([padding_word, -1, rom_size - 1, 1])

        for instruction in assembler_output:
            position = instruction[2]
            size = instruction[3]
            word = bytes(word_dissect(instruction[0], size * bytes_per_word, 8))
            if(head != position):
                for _ in range(position - head):
                    output.write(padding)
                head = position
            output.write(word)
            head += size
    # Hexdump formats
    ## Better human readability
    ## Output is fattened to be rom_size words (* Dependent on variation)
    ## Empty space is filled with provided padding_word (* Dependent on variation)
    ## Output is squeezed when a repeating line is detected to save space. (* Dependent on variation)
    elif(format_style[:7] == 'hexdump'):
        head = 0
        first_word = True
        # Disables squeezing
        no_squeeze = 'ns' in format_style
        # Disables squeezing for instructions
        squeeze_only_pad = 'sp' in format_style
        # Disables padding
        no_pad = 'np' in format_style
        # Disables fattening
        no_fat = ('nf' in format_style) or no_pad
        last_word = 0
        repeating = False
        address_length = int(log2(rom_size) + 3) >> 2

        if(verbose_level >= 1):
            print(" hexdump format", end='')

            if(no_squeeze):
                print(", without squeezing", end='')
            if(squeeze_only_pad):
                print(", squeezing only padding/fat", end='')
            if(no_pad):
                print(", without padding", end='')
            if(no_fat):
                print(", without file fattening", end='')
            print('.')

        if(not no_fat):
            assembler_output.append([padding_word, -1, rom_size - 1, 1])

        for instruction in assembler_output:
            position = instruction[2]
            size = instruction[3]
            word = instruction[0]
            if(head != position):
                for _ in range(position - head):
                    if(no_pad):
                        head = position
                        break
                    # if word isn't repeating, write
                    if((last_word != padding_word) or first_word or no_squeeze):
                        repeating = False
                        output.write('%0*X: %0*X\n'%(ROM_address_size, head, word_size, padding_word))
                        last_word = padding_word
                    # squeeze if haven't squeezed already
                    elif(not repeating):
                        output.write('*\n')
                        repeating = True
                        head = position
                        break
                    head += 1
            # if word isn't repeating, write
            if((last_word != word) or first_word or no_squeeze or squeeze_only_pad):
                repeating = False
                output.write('%0*X: %s\n'%(ROM_address_size, head, " ".join("%0*X"%(word_size, x) for x in word_dissect(word, size, WORD_LENGTH))))
                last_word = word
            # squeeze if haven't squeezed already
            elif(not repeating):
                output.write('*\n')
                repeating = True
            head += size
            first_word = False
        if(repeating):
            output.write('%0*X:\n'%(ROM_address_size, head))
    # Logisim3 format
    elif(format_style[:8] == 'logisim3'):
        current_line = [0] * 16
        last_line = [-1] * 16
        current_line_index = 0
        head = 0
        index = 0
        repeating = False
        do_squeeze = ('ys' in format_style[8:])
        no_fat = ('nf' in format_style[8:])
        if(verbose_level >= 1):
            print(" logisim v3.0 format", end='')
            if(do_squeeze):
                print(", with squeezing", end='')
            if(no_fat):
                print(", with no file fattening", end='')
            print('.')
        if(not no_fat):
            assembler_output.append([padding_word, -1, rom_size - 1, 1])
        output.write("v3.0 hex words addressed\n")
        while(index != len(assembler_output)):
            current = assembler_output[index]
            size = current[3]
            words = word_dissect(current[0], size, WORD_LENGTH)
            position = current[2]
            while((head + current_line_index) != position):
                if(current_line_index == 16):
                    if((current_line != last_line) or (not do_squeeze)):
                        output.write('%0*X: %s\n'%(ROM_address_size, head, " ".join("%0*X"%(word_size, x) for x in current_line)))
                        last_line = current_line.copy()
                        repeating = False
                    elif(not repeating):
                        output.write('*\n')
                        repeating = True
                    current_line_index = 0
                    head += 16
                current_line[current_line_index] = padding_word
                current_line_index += 1
            for word in words:
                if(current_line_index == 16):
                    if((current_line != last_line) or (not do_squeeze)):
                        output.write('%0*X: %s\n'%(ROM_address_size, head, " ".join("%0*X"%(word_size, x) for x in current_line)))
                        last_line = current_line.copy()
                        repeating = False
                    elif(not repeating):
                        output.write('*\n')
                        repeating = True
                    current_line_index = 0
                    head += 16
                current_line[current_line_index] = word
                current_line_index += 1
            index += 1
        if(current_line_index != 0):
            output.write('%0*X: %s\n'%(ROM_address_size, head, " ".join("%0*X"%(word_size, current_line[x]) for x in range(current_line_index))))
    # Logisim2 RLE format
    elif(format_style == 'logisim2'):
        index = 0
        head  = 0
        line_index   = 0
        current_word = -1
        repetition   = 0
        if(verbose_level >= 1):
            print(" logisim v2.0 RLE format.")
        output.write("v2.0 raw\n")
        while(index != len(assembler_output)):
            current = assembler_output[index]
            size = current[3]
            words = word_dissect(current[0], size, WORD_LENGTH)
            position = current[2]
            while(head != position):
                if(current_word == -1):
                    current_word = padding_word
                    head += 1
                    continue
                if(current_word == padding_word):
                    repetition += 1
                else:
                    if(repetition >= 3):
                        if(line_index == 8):
                            output.write('\n')
                            line_index = 0
                        if(line_index == 7):
                            output.write('%d*%X'%(repetition + 1, current_word))
                        else:
                            output.write('%d*%X '%(repetition + 1, current_word))
                        line_index += 1
                    else:
                        for _ in range(repetition + 1):
                            if(line_index == 8):
                                output.write('\n')
                                line_index = 0
                            if(line_index == 7):
                                output.write('%X'%(current_word))
                            else:
                                output.write('%X '%(current_word))
                            line_index += 1
                    repetition = 0
                    current_word = padding_word
                head += 1
            for word in words:
                if(current_word == -1):
                    current_word = word
                    head += 1
                    continue
                if(current_word == word):
                    repetition += 1
                else:
                    if(repetition >= 3):
                        if(line_index == 8):
                            output.write('\n')
                            line_index = 0
                        if(line_index == 7):
                            output.write('%d*%X'%(repetition + 1, current_word))
                        else:
                            output.write('%d*%X '%(repetition + 1, current_word))
                        line_index += 1
                    else:
                        for _ in range(repetition + 1):
                            if(line_index == 8):
                                output.write('\n')
                                line_index = 0
                            if(line_index == 7):
                                output.write('%X'%(current_word))
                            else:
                                output.write('%X '%(current_word))
                            line_index += 1
                    repetition = 0
                    current_word = word
                head += 1
            index += 1
        if(repetition >= 3):
            if(line_index == 8):
                output.write('\n')
                line_index = 0
            if(line_index == 7):
                output.write('%d*%X'%(repetition + 1, current_word))
            else:
                output.write('%d*%X '%(repetition + 1, current_word))
            line_index += 1
        else:
            for _ in range(repetition + 1):
                if(line_index == 8):
                    output.write('\n')
                    line_index = 0
                if(line_index == 7):
                    output.write('%X'%(current_word))
                else:
                    output.write('%X '%(current_word))
                line_index += 1
        output.write('\n')
    # DEBUG format
    ## Most human readability
    ## Not for normal use
    elif(format_style == 'debug'):
        if(verbose_level >= 1):
            print(" DEBUG format.")
        line_address_size = int(log(find_max(assembler_output, key = lambda x:x[1]), 10) + 1)
        for machine_code in assembler_output:
            output.write('%0*d:%0*X: %s'%(line_address_size, machine_code[1], ROM_address_size, machine_code[2], " ".join("%0*X"%(word_size, x) for x in word_dissect(machine_code[0], machine_code[3], WORD_LENGTH))))
            if(len(machine_code) >= 5):
                output.write(' ; %s'%(recompose_line(machine_code[4])))
            output.write('\n')
    else:
        fatal_error('formatter', f"Don\'t know format \'{format_style}\'")

    output.close()
