import mcschematic

def make_schematic(mc_filename, schem_filename):
    mc_file = open(mc_filename, 'r')
    schem = mcschematic.MCSchematic()
    
    # Generate 1024 xz positions
    
    pos_list = []
    start_pos = [-4, -1, 2]

    for i in range(2):
        for j in range(32):
            pos = start_pos.copy() 
            if i == 1:
                pos[0] -= 2

            pos[2] += 2 * j
            if j >= 16:
                pos[2] += 4
            
            for k in range(16):
                pos_list.append(pos.copy())
                    
                if k % 2 == 0:
                    pos[0] -= 7
                    pos[2] += 1 if j < 16 else -1
                else:
                    pos[0] -= 7
                    pos[2] -= 1 if j < 16 else -1
    
    # Write instruction to each position

    lines = [line.strip() for line in mc_file]
    
    for address, line in enumerate(lines):
        if len(line) != 16:
            exit("Invalid machine code file")
        
        face = 'east' if address < 512 else 'west'
        new_pos = pos_list[address].copy()

        byte1 = line[8:]
        byte2 = line[:8]

        for i, char in enumerate(byte1):
            if char == '1':
                schem.setBlock(tuple(new_pos), f'minecraft:repeater[facing={face}]')
            else:
                schem.setBlock(tuple(new_pos), 'minecraft:purple_wool')
            new_pos[1] -= 2

        new_pos[1] -= 2

        for i, char in enumerate(byte2):
            if char == '1':
                schem.setBlock(tuple(new_pos), f'minecraft:repeater[facing={face}]')
            else:
                schem.setBlock(tuple(new_pos), 'minecraft:purple_wool')
            new_pos[1] -= 2

    if schem_filename[-6:] == '.schem':
        schem_filename = schem_filename[:-6]

    schem.save('.', schem_filename, version=mcschematic.Version.JE_1_18_2)


