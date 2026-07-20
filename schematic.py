import mcschematic

def make_schematic(mc_filename, schem_filename):
    mc_file = open(mc_filename, 'r')
    schem = mcschematic.MCSchematic()

    # +90度顺时针旋转：(x,y,z) -> (-z, y, x)，east->south, south->west, west->north, north->east
    _orig_setBlock = schem.setBlock
    def rotated_setBlock(pos, block_data):
        rotated_pos = (-pos[2], pos[1], pos[0])
        if 'facing=east' in block_data:
            block_data = block_data.replace('facing=east', 'facing=south')
        elif 'facing=south' in block_data:
            block_data = block_data.replace('facing=south', 'facing=west')
        elif 'facing=west' in block_data:
            block_data = block_data.replace('facing=west', 'facing=north')
        elif 'facing=north' in block_data:
            block_data = block_data.replace('facing=north', 'facing=east')
        _orig_setBlock(rotated_pos, block_data)
    schem.setBlock = rotated_setBlock
    
    # Generate 1024 xz positions
    # Layout: 32x32 grid
    # X axis: 32 columns, each instruction 2 apart (1 gap)
    # Z axis: 32 rows, each pair (north+south) spaced 3 apart (z, z+1, then +2 gap)
    # address 0~511: north-facing, address 512~1023: south-facing (paired, same column)

    mem_start_pos = [0, -1, 0]
    pos_list_north = []  # address 0~511
    pos_list_south = []  # address 512~1023

    for row in range(32):       # X direction, 32 columns
        for col in range(32):   # Z direction, 32 rows
            pos = mem_start_pos.copy()
            # pos[0] -= col * 2           # each column 2 apart in X
            pos[0] -= row * 3           # each pair 3 apart in Z
            x_offset =  col * 2
            if col >= 16:
                x_offset += 4           # second half of columns are 36 apart in X
            pos[2] += x_offset
            pos_list_north.append(pos.copy())

            pos_south = pos.copy()
            pos_south[0] += 1           # south is 1 behind north in Z
            pos_list_south.append(pos_south)

    pos_list = pos_list_north + pos_list_south
    # Write instruction to each position

    lines = [line.strip() for line in mc_file]
    while len(lines) < 1024:
        lines.append('0000000000000000')
        # add nop to fill space which may be used by the program previously (flash it)
    
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

        new_pos[1] -= 4

        for i, char in enumerate(byte2):
            if char == '1':
                schem.setBlock(tuple(new_pos), f'minecraft:repeater[facing={face}]')
            else:
                schem.setBlock(tuple(new_pos), 'minecraft:purple_wool')
            new_pos[1] -= 2

    # Reset program counter
    """
    pc_start_pos = [-21, -1, -16]
    pos = pc_start_pos.copy()
    
    for _ in range(10):
        schem.setBlock(tuple(pos), 'minecraft:repeater[facing=north,locked=true,powered=false]')
        pos[1] -= 2

    # Reset call stack

    push_start_pos = [-9, -1, -22]
    pull_start_pos = [-8, -1, -21]
    
    for i in range(16):
        pos = push_start_pos.copy()
        pos[2] -= i * 3
        for _ in range(10):
            schem.setBlock(tuple(pos), 'minecraft:repeater[facing=south,locked=true,powered=false]')
            pos[1] -= 2

    for i in range(16):
        pos = pull_start_pos.copy()
        pos[2] -= i * 3
        for _ in range(10):
            schem.setBlock(tuple(pos), 'minecraft:repeater[facing=north,locked=true,powered=false]')
            pos[1] -= 2

    # Reset flags

    flag_start_pos = [-26, -17, -60]
    pos = flag_start_pos.copy()

    schem.setBlock(tuple(pos), 'minecraft:repeater[facing=west,locked=true,powered=false]')
    pos[2] -= 4
    schem.setBlock(tuple(pos), 'minecraft:repeater[facing=west,locked=true,powered=false]')

    # Reset data mem

    data_start_pos = [-47, -3, -9]
    pos_list_north = []
    
    for i in range(4):
        pos = data_start_pos.copy()
        pos[2] -= 16 * i
        for j in range(16):
            pos_list_north.append(pos.copy())
            pos[0] -= 2
            if j % 2 == 0:
                pos[1] += 1
            else:
                pos[1] -= 1
        
        pos = data_start_pos.copy()
        pos[2] -= 16 * i
        pos[0] -= 36
        pos[1] += 1
        for j in range(16):
            pos_list_north.append(pos.copy())
            pos[0] -= 2
            if j % 2 == 0:
                pos[1] -= 1
            else:
                pos[1] += 1

    for pos in pos_list_north[:-3]:
        x = pos.copy()
        for _ in range(8):
            schem.setBlock(tuple(x), 'minecraft:repeater[facing=north,locked=true,powered=false]')
            x[1] -= 2

    for pos in pos_list_north:
        x = pos.copy()
        x[2] -= 2
        for _ in range(8):
            schem.setBlock(tuple(x), 'minecraft:repeater[facing=south,locked=true,powered=false]')
            x[1] -= 2
    
    # Reset registers

    reg_start_pos = [-35, -3, -12]
    pos_list_east = []

    pos = reg_start_pos.copy()
    for i in range(15):
        pos_list_east.append(pos.copy())
        pos[2] -= 2
        if i % 2 == 0:
            pos[1] -= 1
        else:
            pos[1] += 1

    for pos in pos_list_east:
        x = pos.copy()
        for _ in range(8):
            schem.setBlock(tuple(x), 'minecraft:repeater[facing=east,locked=true,powered=false]')
            x[1] -= 2

        x = pos.copy()
        x[0] += 2
        for _ in range(8):
            schem.setBlock(tuple(x), 'minecraft:repeater[facing=west,locked=true,powered=false]')
            x[1] -= 2
    """
    # Save

    if schem_filename[-6:] == '.schem':
        schem_filename = schem_filename[:-6]

    schem.save('.', schem_filename, version=mcschematic.Version.JE_1_18_2)


if __name__ == '__main__':
    import sys
    if len(sys.argv) != 3:
        print("Usage: python schematic.py <input.mc> <output.schem>")
        sys.exit(1)
    make_schematic(sys.argv[1], sys.argv[2])