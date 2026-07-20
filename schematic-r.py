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
    my_pos_list = [None] * 1025
    for col in range(32):       # X direction, 32 columns
        for row in range(16):   # Z direction, 16 rows
            pos = mem_start_pos.copy()
            # pos[0] -= col * 2           # each column 2 apart in X
            if row % 2 == 0:
                pos[2] -= 1             # first row in each pair is 1 behind
            pos[0] -= row * 7
            x_offset =  col * 2
            if col >= 16:
                x_offset += 4           # second half of columns are 36 apart in X
            pos[2] += x_offset
            my_pos_list[row + col * 16] = pos.copy()      # north ( > )

            pos_south = pos.copy()
            pos_south[0] -= 2           # south 沿 X 落后 2 格(中间空 1 格),同一列 ( < )
            my_pos_list[512 + row + col * 16] = pos_south

    pos_list = my_pos_list
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
        line = line[::-1]  
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