from assembler import assemble, formatter, WORD_LENGTH
import sys
from common import *
from math import log2

# Help message
help_mess = """Usage: python main.py <options> -s <ROM size> file...
Options:
  -O --output <file>        Set output file.
  -s --rom-size <size>      Set ROM size in words. May be followed by suffixes-
                            for KiB, MiB, GiB, TiB, PiB, EiB, ZiB, YiB. (the-
                            'iB' is optional. case-insensitive)
  -p --padding-word <word>  Set what the padding should be. defaults to all 0s.
                            hexadecimal or binary inputs should be prefixed-
                            with '0x' and '0b' respectively.
  -f --output-format <format>
                            Set the output format, possible formats are: (default is Matt)
                            Matt, Raw, Image, Hexdump, Logisim3, Logisim2, DEBUG.
                            (case-insensitive)
     --dump-labels          Dump labels after assembly.
     --dump-definitions     Dump definitions after assembly.
  -v                        Verbose output. (more v's means higher-
                            verbosity. above level 4 there is no effect)
  -h --help                 Print this message and quit.
  -V --version              Print version and quit.
Notes:
  Parameters for single character options can be separated and unseparated, so:
  "-Ooutput.bin" and "-O output.bin" are both valid."""

# Credits/license message (TODO: Add license from original once it's licensed)
credits_mess = """Credits:
  Original code & ISA author is @MattBatWings at
   GitHub: https://github.com/MattBatWings
   YouTube: https://youtube.com/@MattBatWings

  Modifications to Matt's code by @ProtoSebastian at
   GitHub: https://github.com/ProtoSebastian"""

def print_version():
    print(credits_mess)

    version_string, version_format = render_version(VERSION, VER_FMT)

    print(f"\nVersion format: {version_format}")
    print(f"Version.......: {version_string}")

def print_help():
    print(help_mess)

def handle_unknown_switch(statement: str):
    print_help()
    fatal_error('main', f"Unknown switch statement '{statement}'.")

def calculate_size(SIZE_PARAM: str, verbosity: int):
    ROM_size = 0 # La output
    # Separate number and prefix
    SIZE_PARAM  = SIZE_PARAM.lower()
    SIZE_PREFIX = SIZE_PARAM[-3:]
    if(SIZE_PREFIX.isdecimal()):
        SIZE = SIZE_PARAM
    elif(SIZE_PREFIX[0] in SIZE_PREFIX_DEFS):
        SIZE_PREFIX = SIZE_PARAM[-3]
        SIZE = SIZE_PARAM[:-3]
    else:
        SIZE_PREFIX = SIZE_PARAM[-1]
        SIZE = SIZE_PARAM[:-1]
    # Verify both
    if(not SIZE.isdecimal()):
        fatal_error('main', f"\'{SIZE}\' is not numeric")
    if((SIZE_PREFIX not in SIZE_PREFIX_DEFS) and (not SIZE_PREFIX.isdecimal())):
        fatal_error('main', f"Could not understand size suffix \'{SIZE_PREFIX}\', known suffixes: {', '.join(SIZE_PREFIX_DEFS)} (case insensitive)")
    
    # Calculate size
    if(SIZE_PREFIX.isdecimal()):
        ROM_size = int(SIZE)
    else:
        ROM_size = int(SIZE) * (1024 ** SIZE_PREFIX_DEFS[SIZE_PREFIX])
    if(verbosity >= 1):
        print(f"main: ROM size set to {str(ROM_size)} words", end='')
        if(not SIZE_PREFIX.isdecimal()):
            print(f" or {SIZE} {SIZE_PREFIX_FULL[SIZE_PREFIX]}words", end='')
        print('.')

    return ROM_size

def interpret_int(input_string: str):
    try:
        return int(input_string, 0)
    except ValueError as _ERR:
        fatal_error('main', f"Could not interpret \'{input_string}\' as an integer.\n{_ERR}")

def main():
    # Fancy switch processing
    input_file  = ''          # no defaults. I mean, why would you default an input file??
    output_file = 'output.mc' # default to 'output.mc'
    ROM_size    = None
    padding_word= 0
    format_style= 'matt'
    debug_flags = 0
    verbosity   = 0
    input_files = 0

    idx=1
    while(idx < len(sys.argv)):
        # Handle options
        term = sys.argv[idx]
        if(term.startswith('--')):
            match(term):
                # Help
                case '--help':
                    print_help()
                    exit()
                # Version
                case '--version':
                    print_version()
                    exit()
                # Output file
                case '--output':
                    idx += 1
                    output_file=sys.argv[idx]
                # ROM size
                case '--rom-size':
                    idx += 1
                    ROM_size = calculate_size(sys.argv[idx], verbosity)
                # Padding
                case '--padding-word':
                    idx += 1
                    padding_word = interpret_int(sys.argv[idx])
                # Dump labels
                case '--dump-labels':
                    debug_flags |= 1
                # Dump definitions
                case '--dump-definitions':
                    debug_flags |= 2
                # Format
                case '--output-format':
                    idx += 1
                    format_style = sys.argv[idx]
                # Unknown
                case other:
                    handle_unknown_switch(term)
        elif(term.startswith('-')):
            match(term[:2]):
                # Help
                case '-h':
                    print_help()
                    exit()
                # Version
                case '-V':
                    print_version()
                    exit()
                # Output file
                case '-O':
                    if(len(sys.argv[idx])!=2):
                        output_file=sys.argv[idx][2:]
                    else:
                        idx += 1
                        output_file=sys.argv[idx]
                # ROM size
                case '-s':
                    SIZE_PARAM = ''
                    if(len(sys.argv[idx])!=2):
                        SIZE_PARAM = sys.argv[idx][2:]
                    else:
                        idx += 1
                        SIZE_PARAM = sys.argv[idx]
                    ROM_size = calculate_size(SIZE_PARAM, verbosity)
                # Padding
                case '-p':
                    PARAM = ''
                    if(len(sys.argv[idx])!=2):
                        PARAM = sys.argv[idx][2:]
                    else:
                        idx += 1
                        PARAM = sys.argv[idx]
                    padding_word = interpret_int(PARAM)
                # Format
                case '-f':
                    PARAM = ''
                    if(len(sys.argv[idx])!=2):
                        PARAM = sys.argv[idx][2:]
                    else:
                        idx += 1
                        PARAM = sys.argv[idx]
                    format_style = PARAM
                # Verbosity
                case '-v':
                    PARAM = sys.argv[idx][1:]
                    verbosity = PARAM.count('v')
                    if(verbosity != len(PARAM)):
                        fatal_error('main', f"Unknown use of the verbose option \'{sys.argv[idx]}\'")
                # Unknown
                case other:
                    handle_unknown_switch(term[:2])
        else:
            if(input_files!=0):
                # ruh roh
                fatal_error('main', "More than 1 input file specified.")
            input_file=term
            input_files+=1
        idx += 1
    if(input_file==''):
        print_help()
        fatal_error('main', "No input files were specified.")

    # Assemble
    if(ROM_size == None):
        fatal_error('main', "No ROM size specified, cannot continue.\nPlease specify a ROM size.")
    if(verbosity >= 1):
        print("main: Padding word is \'0x%04X\'"%padding_word)
    machine_code_output = assemble(input_file, ROM_size, verbosity - 1, debug_flags)
    formatter(machine_code_output, output_file, ROM_size, padding_word, format_style, verbosity)

    # Success message
    print("main: Assembly successful.")
    # simulate('output.mc')


if __name__ == '__main__':
    main()
