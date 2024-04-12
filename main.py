from assembler import assemble
# from simulator import simulate

def main():
    program = 'test'

    assemble(f'programs/{program}.as', 'output.mc')
    # simulate('output.mc')


if __name__ == '__main__':
    main()