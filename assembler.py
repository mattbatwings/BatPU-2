def assemble(assembly_filename, output_filename):
    assembly_file = open(assembly_filename, 'r')
    machine_code_file = open(output_filename, 'w')
    lines = (line.strip() for line in assembly_file)

    def remove_comment(comment_symbol, line):
        return line.split(comment_symbol)[0]

    # remove comments and blanklines
    lines = [remove_comment("/", line) for line in lines]
    lines = [line for line in lines if line.strip()]
    
    symbols = {}
    
    registers = ['r0', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7']
    for index, symbol in enumerate(registers):
        symbols[symbol] = index

    opcodes = ['nop', 'hlt', 'jmp', 'bif', 'cal', 'ret', 'pld', 'pst', 'mld', 'mst', 'adi', 'add', 'sub', 'bit', 'rsh', 'mul']
    for index, symbol in enumerate(opcodes):
        symbols[symbol] = index

    flags = ['zero', 'carry', 'even', 'msb']
    for index, symbol in enumerate(flags):
        symbols[symbol] = index

    bitwise_types = ['or', 'and', 'xor', 'implies', 'nor', 'nand', 'xnor', 'nimplies']
    for index, symbol in enumerate(bitwise_types):
        symbols[symbol] = index

    shift_types = ['logical', 'arithmetic']
    for index, symbol in enumerate(shift_types):
        symbols[symbol] = index
    
    def is_definition(word):
        return word == 'define'
    
    def is_label(word):
        return word[0] == '.'
    
    # add definitions and labels to symbol table
    # expects all definitions to be above assembly
    offset = 0
    for index, line in enumerate(lines):
        words = line.split()
        if is_definition(words[0]):
            if words[2][0] != '#':
                exit('Invalid definition')
            symbols[words[1]] = int(words[2][1:])
            offset += 1
        elif is_label(words[0]):
            symbols[words[0]] = index - offset
    
    # generate machine code
    def resolve(word):
        if word[0] == '#':
            return int(word[1:])
        if symbols.get(word) is None:
            exit(f'Could not resolve {word}')
        return symbols[word]

    for i in range(offset, len(lines)):
        line = lines[i]
        words = line.split()

        # remove label, we have it in symbols now
        if is_label(words[0]):
            words = words[1:]
        
        # special ops
        if words[0] == 'lsh':
            words = ['add', words[1], words[2], words[2]]
        elif words[0] == 'cmp':
            words = ['sub', registers[0], words[1], words[2]]
        elif words[0] == 'mov':
            words = ['add', words[1], words[2], registers[0]]
        elif words[0] == 'not':
            words = ['nor', words[1], words[2], registers[0]]
        elif words[0] == 'inc':
            words = ['adi', words[1], words[2], '#1']
        elif words[0] == 'dec':
            words = ['adi', words[1], words[2], '#-1']

        # begin machine code translation
        opcode = words[0]
        if not (opcode in symbols):
            exit(f'Unknown symbol "{opcode}" on line {i}')
        machine_code = (symbols[opcode] << 12)
        words = [resolve(word) for word in words]

        if opcode in ['bif']: # Flag
            if words[1] != (words[1] % (2 ** 2)):
                exit(f'Invalid flag on line {i}')
            machine_code |= (words[1] << 10)

        if opcode in ['jmp', 'bif', 'cal', 'ret']: # Instruction Memory Address
            if words[-1] != (words[-1] % (2 ** 10)):
                exit(f'Invalid instruction memory address on line {i}')
            machine_code |= (words[-1])

        if opcode in ['pld', 'mld', 'adi', 'add', 'sub', 'bit', 'rsh', 'mul']: # Destination / Source
            if words[1] != (words[1] % (2 ** 3)):
                exit(f'Invalid destination / source on line {i}')
            machine_code |= (words[1] << 9)

        if opcode in ['pld', 'pst']: # Port
            if words[2] != (words[2] % (2 ** 8)):
                exit(f'Invalid port on line {i}')
            machine_code |= (words[2])

        if opcode in ['pld', 'pst']: # Offset
            if words[2] != (words[2] % (2 ** 8)):
                exit(f'Invalid offset on line {i}')
            machine_code |= (words[2])

        if opcode in ['adi', 'add', 'sub', 'bit', 'rsh', 'mul']: # Source A
            if words[2] != (words[2] % (2 ** 3)):
                exit(f'Invalid source A on line {i}')
            machine_code |= (words[2] << 6)

        if opcode in ['adi', 'add', 'sub', 'bit', 'rsh', 'mul']: # Source B
            if words[-1] != (words[-1] % (2 ** 3)):
                exit(f'Invalid source A on line {i}')
            machine_code |= (words[-1])
        
        if opcode in ['adi']: # Immediate
            if words[-1] != (words[-1] % (2 ** 6)):
                exit(f'Invalid immediate A on line {i}')
            machine_code |= (words[-1])

        if opcode in ['bit']: # Type
            if words[3] != (words[3] % (2 ** 3)):
                exit(f'Invalid type on line {i}')
            machine_code |= (words[3] << 3)

        if opcode in ['bit']: # E
            if words[3] != (words[3] % (2 ** 1)):
                exit(f'Invalid E on line {i}')
            machine_code |= (words[3] << 3)

        as_string = bin(machine_code)[2:].rjust(16, '0')
        machine_code_file.write(f'{as_string}\n')
