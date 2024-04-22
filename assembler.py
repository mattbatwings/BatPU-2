# All rights to this code go to the original owner, @MattBatWings

def assemble(assembly_filename, output_filename):
    assembly_file = open(assembly_filename, 'r')
    machine_code_file = open(output_filename, 'w')
    lines = (line.strip() for line in assembly_file)

    def remove_comment(comment_symbols, line):
        for c in comment_symbols:
            line=line.split(c)[0]
        return line
    def ffind(str, chars):
        v=[]
        for c in chars:
            v.append(str.find(c))
        v=[x for x in v if(x!=-1)]
        if(len(v)==0):
            return len(str)
        else:
            return min(v)

    # Remove comments and blanklines
    lines = [remove_comment("/;#", line).strip() for line in lines]

    # Populate symbol table
    symbols = {}

    # Generate register names
    registers = ['r{0}'.format(x) for x in range(16)]
    for index, symbol in enumerate(registers):
        symbols[symbol] = index

    # Operands
    # Format : '<1 char label>':[<position>, <bit length>, <1: signed, 0: unsigned>, "<full name>"]
    ops     = {
               'F' : [8,  4, 0, "first register"], # First register
               'A' : [4,  4, 0, "register A"],     # Register A
               'B' : [0,  4, 0, "register B"],     # Register B
               'I' : [0,  8, 1, "immediate"],      # Immediate
               'C' : [10, 2, 0, "condition"],      # Condition
               'O' : [0,  4, 1, "offset"],         # Offset
               'M' : [0, 10, 0, "memory address"], # Memory address
              }
    
    # Pseudo-instructions
    # Format : 'label':['<resolution as formatted string>']
    pseudoins = {
                 'cmp':['sub r0 {0} {1}'],  # cmp : sub r0 A B
                 'mov':['add {0} {1} r0'],  # mov : add dest A r0
                 'lsh':['add {0} {1} {1}'], # lsh : add dest A A
                 'inc':['adi {0} 1'],       # inc : adi dest 1
                 'dec':['adi {0} -1'],      # dec : adi dest -1
                 'not':['nor {0} {1} r0'],  # not : nor dest A r0
                }
    # Calculate number of operands and add to pseudo-instruction element
    for pop in pseudoins:
        popcodeinfo=pseudoins[pop]
        nums=[int(word[1:len(word)-1]) for word in popcodeinfo[0].split() if word[0]=='{']
        if(len(nums)==0):
            pseudoins[pop].insert(0, 0)
        else:
            pseudoins[pop].insert(0, max(nums)+1)
    
    # Macros
    # Format : 'label':['<resolution as formatted string>']
    # - formatted string must be separated by newlines ('\n')
    macros = {
              'nnd':['and {0} {1} {2}\n'+   # nnd dest A B : and dest A B
                     'not {0} {0}'       ], #                not dest dest   # do the bitwise "not AND" operation on registers A, B and store the result in dest

              'xnr':['xor {0} {1} {2}\n'+   # xnr dest A B : xor dest A B
                     'not {0} {0}'       ], #                not dest dest   # do the bitwise "not XOR" operation on registers A, B and store the result in dest

              'orr':['nor {0} {1} {2}\n'+   # orr dest A B : nor dest A B
                     'not {0} {0}'       ], #                not dest dest   # do the bitwise "OR" operation on registers A, B and store the result in dest

              'nim':['not {0} {2}\n'+       # nim dest A B : not dest B
                     'and {0} {0} {1}'   ], #                and dest dest A # do the bitwise "not IMPLIES" operation on registers A, B and store the result in dest
                                            # !(A -> B) = A & (!B)

              'imp':["nim {0} {1} {2}\n"+   # imp dest A B : nim dest A B
                     "not {0} {0}"       ], #                not dest dest   # do the bitwise "IMPLIES" operation on registers A, B and store the result in dest
                                            # A -> B = !(!(A -> B))
#--------------------------------------------------------------------------------#
              'use_display':      ['ldi {0} 240'],      # use_display rbp : ldi rbp 240         # store pixel display's base pointer in rbp

              'set_x':            ['str {1} {0} 0'],    # set_x rbp rX : str rX rbp 0           # store value at rX into pixel display's X port

              'set_xi':           ['ldi {1} {2}\n'+     # set_xi rbp rBuf imm : ldi rBuf imm
                                   'set_x {0} {1}' ],   #                       set_x rbp rBuf  # store immediate value into pixel display's X port

              'set_y':            ['str {1} {0} 1'],    # set_y rbp rY : str rY rbp 1           # store value at rY into pixel display's Y port

              'set_yi':           ['ldi {1} {2}\n'+     # set_yi rbp rBuf imm : ldi rBuf imm
                                   'set_y {0} {1}' ],   #                       set_y rbp rBuf  # store immediate value into pixel display's Y port

              'set_pixel':        ['str r0 {0} 2'],     # set_pixel rbp : str r0 rbp 2          # trigger pixel display's Draw Pixel port to draw current pixel

              'clr_pixel':        ['str r0 {0} 3'],     # clr_pixel rbp : str r0 rbp 3          # trigger pixel display's Clear Pixel port to clear current pixel

              'get_pixel':        ['lod {1} {0} 4'],    # get_pixel rbp rDest : lod rDest rbp 4 # load pixel at current pixel position

              'cpy_disp_buffer':  ['str r0 {0} 5'],     # cpy_disp_buffer rbp : str r0 rbp 5    # copy pixel display buffer to screen

              'clr_disp_buffer':  ['str r0 {0} 6'],     # clr_disp_buffer rbp : str r0 rbp 6    # clear pixel display buffer

              'clr_display':['clr_disp_buffer {0}\n'+   # clr_display rbp : clr_disp_buffer rbp
                             'cpy_disp_buffer {0}'   ], #                   cpy_disp_buffer rbp # clear both display and display buffer
#--------------------------------------------------------------------------------#
              'use_char_display': ['ldi {0} 247'],      # use_char_display rbp : ldi rbp 247    # store character display's base pointer in rbp

              'add_char':         ['str {1} {0} 0'],    # add_char rbp rChar  : str rChar rbp 0 # append character at rChar to character display buffer

              'add_chari':        ['ldi {1} {2}\n'+     # add_chari rbp rBuf imm : ldi rBuf imm
                                   'add_char {0} {1}']  #                          add_char rbp rBuf
                                                                                                # append immediate character imm to character display buffer

              'cpy_char_buffer':  ['str r0 {0} 1'],     # cpy_char_buffer rbp : str r0 rbp 1    # copy character display buffer to char display

              'clr_char_buffer':  ['str r0 {0} 2'],     # clr_char_buffer rbp : str r0 rbp 2    # clear character display buffer

              'clr_char_display': ['clr_char_buffer {0}\n'+   # clr_char_display rbp : clr_char_buffer rbp
                                   'cpy_char_buffer {0}'   ], #                        cpy_char_buffer rbp
                                                                                                # clear both char display and buffer
#--------------------------------------------------------------------------------#
              'use_num_display':  ['ldi {0} 250'],      # use_num_display rbp : ldi rbp 250     # store number display's base pointer in rbp

              'set_num':          ['str {1} {0} 0'],    # set_num rbp rNum : str rNum rbp       # set number display's buffer to number in rNum

              'set_numi':         ['ldi {1} {2}\n'+     # set_numi rbp rBuf imm : ldi rBuf imm
                                   'set_num {0} {1}'],  #                         set_num rbp rBuf
                                                                                                # set number display's buffer to immediate imm

              'clr_num_display':  ['str r0 {0} 1'],     # clr_num_display rbp : str r0 rbp 1    # clear number display

              'num_mode_signed':  ['str r0 {0} 2'],     # num_mode_signed rbp : str r0 rbp 2    # set number display to signed mode

              'num_mode_unsigned':['str r0 {0} 3'],     # num_mode_unsigned rbp : str r0 rbp 3  # set number display to unsigned mode
#--------------------------------------------------------------------------------#
              'use_cont_rng':     ['ldi {0} 254'],      # use_cont_rng rbp : ldi rbp 254        # store controller/RNG's base pointer to rbp

              'get_rng':          ['lod {1} {0} 0'],    # get_rng rbp rDest : lod rDest rbp     # put a random number in rDest

              'get_cont_state':   ['lod {1} {0} 1'],    # get_cont_state rbp rDest : lod rDest rbp
                                                                                                # put the controller's current state in rDest
             }
    # Calculate number of operands and add to macro element
    for macro in macros:
        macroinfo=macros[macro]
        nums=[int(word[1:len(word)-1]) for word in macroinfo[0].split() if word[0]=='{']
        if(len(nums)==0):
            macros[macro].insert(0, 0)
        else:
            macros[macro].insert(0, max(nums)+1)
    
    # Format: '<label>':'<operand flags in order of use in opcode>'
    opcodes = {
               'nop':'',    # nop                   : Does nothing
               'hlt':'',    # hlt                   : Halts computer
               'add':'FAB', # add dest A B          : pseudo-code: dest <- A + B
               'sub':'FAB', # sub dest A B          : pseudo-code: dest <- A - B
               'nor':'FAB', # nor dest A B          : pseudo-code: dest <- !(A | B)
               'and':'FAB', # and dest A B          : pseudo-code: dest <- A & B
               'xor':'FAB', # xor dest A B          : pseudo-code: dest <- A ^ B
               'rsh':'FA',  # rsh dest A            : pseudo-code: dest <- A >> 1 (logical shift)
               'ldi':'FI',  # ldi dest immediate    : pseudo-code: dest <- immediate
               'adi':'FI',  # adi dest immediate    : pseudo-code: dest <- dest + immediate
               'jmp':'M',   # jmp address           : pseudo-code: PC <- address
               'brh':'CM',  # brh condition address : pseudo-code: PC <- condition ? address : PC + 1
               'cal':'M',   # cal address           : pseudo-code: PC <- address (and push PC + 1 to stack)
               'ret':'',    # ret                   : pseudo-code: PC <- top of stack (and pop stack)
               'lod':'FAO', # lod dest A offset     : pseudo-code: dest <- mem[A + offset]
               'str':'FAO'  # str source A offset   : pseudo-code: mem[A + offset] <- source
              } # Opcodes
    for index, symbol in enumerate(opcodes):
        symbols[symbol] = index  # Add corresponding numeral opcode

    conditions = [ 'eq'  , 'ne'     , 'ge'   , 'lt'      ,
                   '='   , '!='     , '>='   , '<'       ,
                   'z'   , 'nz'     , 'c'    , 'nc'      ,
                   'zero', 'notzero', 'carry', 'notcarry', ] # Possible conditions
    for index, symbol in enumerate(conditions):
        symbols[symbol] = index & 3 #0b11
    
    def is_definition(word):
        return word == 'define'
    
    def is_label(word):
        return word[0] == '.'
    
    def is_macro(word):
        return word in macros
    
    # Resolve macros
    cont=True
    while(cont):
        cont=False
        for index, line in enumerate(lines):
            words = [word.lower() for word in line.split()]
            if(len(words)==0): continue
            if is_macro(words[0]):
                cont=True
                macroinfo=macros[words[0]]
                if macroinfo[0] != (len(words)-1):
                    exit(f"Incorrect number of operands for macro \'{words[0]}\' at line {index+1}")
                gen_lines= macroinfo[1].format(*words[1:]).split('\n')
                gen_lines.reverse()
                lines.pop(index)
                for gline in gen_lines:
                    lines.insert(index, gline)
    
    offset = 0
    for index, line in enumerate([line for line in lines if line!='']):
        words = [word.lower() for word in line.split()]

        if is_definition(words[0]):
            symbols[words[1]] = int(words[2])
            offset += 1
        elif is_label(words[0]):
            symbols[words[0]] = index - offset # This assumes we put code after the label, which many don't
            if(len(words)<2):
                offset+=1
    
    # Generate machine code
    def resolve(word):
        if word[0] in '-0123456789':
            return int(word)
        if symbols.get(word) is None:
            exit(f'Could not resolve {word}')
        return symbols[word]
    
    # Clean lines of definitions and labels for machine code translation step
    for i, b in enumerate(lines):
        words = [word.lower() for word in b.split()]
        if(len(words)==0): continue
        if(is_label(words[0])):
            lines[i]=b[ffind(b," \t")+1:].strip()
        elif(is_definition(words[0])):
            lines[i]=''
    lines=[line.strip() for line in lines]

    for i in range(len(lines)):
        words = [word.lower() for word in lines[i].split()]
        if len(words)==0: continue
        
        # Pseudo-instructions
        if words[0] in pseudoins:
            popcode     = words[0]
            popcodeinfo = pseudoins[popcode]
            if popcodeinfo[0] != len(words)-1:
                exit(f"Incorrect number of operands for pseudo-instruction \'{popcode}\' at line {i+1}")
            words=popcodeinfo[1].format(*words[1:]).split()
        
        # Begin machine code translation
        opcode = words[0]
        try:
            machine_code = symbols[opcode] << 12
        except KeyError:
            exit(f"Unknown opcode \'{opcode}\' at line {i+1}")
        words = [resolve(word) for word in words]

        # Number of operands check
        if len(opcodes[opcode]) != (len(words)-1):
            exit(f'Incorrect number of operands for \'{opcode}\' on line {i+1}')

<<<<<<< HEAD
        if opcode in ['rsh', 'ldi', 'adi', 'brh'] and len(words) != 3:
            exit(f'Incorrect number of operands for {opcode} on line {i}')

        if opcode in ['add', 'sub', 'nor', 'and', 'xor', 'lod', 'str'] and len(words) != 4:
            exit(f'Incorrect number of operands for {opcode} on line {i}')

        # First register
        if opcode in ['add', 'sub', 'nor', 'and', 'xor', 'rsh', 'ldi', 'adi', 'lod', 'str']:
            if words[1] != (words[1] % (2 ** 4)):
                exit(f'Invalid first register for {opcode} on line {i}')
            machine_code |= (words[1] << 8)

        # Reg A
        if opcode in ['add', 'sub', 'nor', 'and', 'xor', 'rsh', 'lod', 'str']:
            if words[2] != (words[2] % (2 ** 4)):
                exit(f'Invalid reg A for {opcode} on line {i}')
            machine_code |= (words[2] << 4)

        # Reg B
        if opcode in ['add', 'sub', 'nor', 'and', 'xor']:
            if words[3] != (words[3] % (2 ** 4)):
                exit(f'Invalid reg B for {opcode} on line {i}')
            machine_code |= words[3]

        # Immediate
        if opcode in ['ldi', 'adi']:
            if words[2] < -128 or words[2] > 255: # 2s comp [-128, 127] or uint [0, 255]
                exit(f'Invalid immediate for {opcode} on line {i}')
            machine_code |= words[2] & (2 ** 8 - 1)
        
        # Instruction memory address
        if opcode in ['jmp', 'brh', 'cal']:
            if words[-1] != (words[-1] % (2 ** 10)):
                exit(f'Invalid instruction memory address for {opcode} on line {i}')
            machine_code |= words[-1]

        # Condition
        if opcode in ['brh']:
            if words[1] != (words[1] % (2 ** 2)):
                exit(f'Invalid condition for {opcode} on line {i}')
            machine_code |= (words[1] << 10)

        # Offset
        if opcode in ['lod', 'str']:
            if words[3] < -8 or words[3] > 7: # 2s comp [-7, 8]
                exit(f'Invalid offset for {opcode} on line {i}')
            machine_code |= words[3] & (2 ** 4 - 1)
=======
        # Check operands
        for idx,op in enumerate(opcodes[opcode]):
            opinfo = ops[op]
            mask   = (1<<opinfo[1]) - 1
            if opinfo[2] and (words[idx+1]<0):
                words[idx+1]=(~words[idx+1])+1
            if words[idx+1] != (words[idx+1] & mask):
                exit(f'Invalid {opinfo[3]} for \'{opcode}\' on line {i+1}')
            machine_code |= (words[idx+1] & mask) << opinfo[0] # Just to be safe, it's ANDEed with the mask
>>>>>>> f257704 (Update assembler.py)

        as_string = bin(machine_code)[2:].rjust(16, '0')
        machine_code_file.write(f'{as_string}\n')
