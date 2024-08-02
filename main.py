from assembler import assemble
from schematic import make_schematic
import sys


def main():
    program = 'test'

    assemble(f'programs/{program}.as', f'programs/{program}.mc')
    make_schematic(f'programs/{program}.mc', f'programs/{program}.schem')

if __name__ == '__main__':
    main()