from assembler import assemble
import sys
# from simulator import simulate

def main():
    if(len(sys.argv)<2):
        exit("Not enough arguments.")
    assemble(sys.argv[1], sys.argv[2] if(len(sys.argv)>=3) else 'output.mc')
    # simulate('output.mc')


if __name__ == '__main__':
    main()
