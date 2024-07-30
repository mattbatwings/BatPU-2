import os
import sys

from assembler import Assembler
from linker import link
from parse import Parser
from tokens import Tokenizer


def main():
    if len(sys.argv) < 2:
        exit("Not enough arguments.")
    
    cur_dir = os.path.dirname(sys.argv[0])
    with open(os.path.join(cur_dir, "std.as"), "r") as f:
        std = f.read()
    with open(sys.argv[1], "r") as f:
        lines = f.read()
    
    lines = std + lines
    
    tokens = Tokenizer(lines).tokenize()
    ast = Parser(tokens).parse()
    object_file_contents = Assembler().visit_program(ast)
    byte_code = link(object_file_contents)
    
    with open(sys.argv[2] if len(sys.argv) >= 3 else "output.mc", "w") as f:
        f.write(byte_code)


if __name__ == '__main__':
    main()
