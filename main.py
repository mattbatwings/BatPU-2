import argparse
import os
from typing import List, TextIO, BinaryIO

from assembler import Assembler
from linker import link
from parse import Parser
from tokens import Tokenizer


def main():
    arg_parser = argparse.ArgumentParser("BatPuAsm", description="BatPU Assembler and Linker by NoName_Official")
    arg_parser.add_argument("-l", "--link", action="store_true", help="Link instead of assemble")
    arg_parser.add_argument("-o", "--output", type=argparse.FileType("wb"), help="Output file")
    arg_parser.add_argument("files", nargs="+", type=argparse.FileType("r", encoding="utf-8"), help="The list of files to assemble or link")
    args = arg_parser.parse_args()
    link_file: bool = args.link
    output_file: BinaryIO = args.output
    files: List[TextIO] = args.files
    
    output_file = output_file or open("output.bin" if link_file else "output.o", "wb", encoding="utf-8")
    cur_dir = os.path.dirname(__file__)
    if not link_file:
        files.insert(0, open(os.path.join(cur_dir, "std.as"), "r", encoding="utf-8"))
    
    lines = ""
    for file in files:
        with file:
            lines += file.read()
    
    if not link_file:
        tokens = Tokenizer(lines).tokenize()
        ast = Parser(tokens).parse()
        output = Assembler().visit_program(ast).encode("utf-8")
    else:
        output = link(lines)
    
    with output_file:
        output_file.write(output)


if __name__ == '__main__':
    main()
