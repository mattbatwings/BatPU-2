from __future__ import annotations

from typing import List, TypeVar, Type, Dict

import tokens
from nodes import Program, Item, Macro, Instruction, Arg, VarArg, Register, Label, Immediate, Define
from tokens import Token, Symbol, Eof, NewLine, Int, Char


class Parser:
    def __init__(self, tokens_list: List[Token]):
        self.tokens = tokens_list
        self.index = 0
        self.defines: Dict[str, Immediate] = {}
    
    def advance(self) -> Token:
        if self.index < len(self.tokens):
            self.index += 1
        return self.tokens[self.index - 1]
    
    _T = TypeVar("_T", bound=Token)
    
    def consume(self, cls: Type[_T], msg: str) -> _T:
        token = self.advance()
        if not isinstance(token, cls):
            exit(f"Expected token '{cls}' but got '{type(token)}': " + msg)
        return token
    
    def parse(self) -> Program:
        items = []
        while self.index < len(self.tokens) - 1:
            items.append(self.parse_item())
            while self.index < len(self.tokens) and isinstance(self.tokens[self.index], NewLine):
                self.index += 1
        self.consume(Eof, "Unreachable")
        return Program(items)
    
    def parse_item(self) -> Item:
        cur_token = self.tokens[self.index]
        if isinstance(cur_token, Symbol):
            if cur_token.name.upper() == "MACRO":
                return self.parse_macro()
            elif cur_token.name.upper() == "DEFINE":
                return self.parse_define()
        elif isinstance(cur_token, tokens.Label):
            self.index += 1
            return Label(cur_token)
        return self.parse_instruction()
    
    def parse_define(self) -> Define:
        self.index += 1
        name = self.consume(Symbol, "Expected name for define")
        token = self.advance()
        if not isinstance(token, (Int, tokens.Label)):
            exit(f"Expected Immediate for definition, found '{token}'")
        value = Immediate(token)
        if name.name.upper() in self.defines:
            exit(f"Duplicate definition '{name.name}'")
        self.defines[name.name.upper()] = value
        return Define(name, value)
    
    def parse_macro(self) -> Macro:
        macro = self.consume(Symbol, "Expected 'MACRO' symbol")
        if macro.name.upper() != "MACRO":
            exit(f"Expected 'macro', found '{macro}'")
        name = self.consume(Symbol, "Expected name for macro")
        args = []
        while not (isinstance(self.tokens[self.index], NewLine)):
            args.append(self.consume(Symbol, "Expected Arg for macro"))
        self.consume(NewLine, "Expected NewLine after macro definition")
        body = []
        while True:
            cur_token = self.tokens[self.index]
            if isinstance(cur_token, NewLine):
                self.index += 1
                continue
            if isinstance(cur_token, Symbol) and cur_token.name.upper() == "ENDM":
                break
            if isinstance(cur_token, tokens.Label):
                body.append(Label(cur_token))
                self.index += 1
                continue
            body.append(self.parse_instruction())
        endm = self.consume(Symbol, "Expected 'endm'")
        if endm.name.upper() != "ENDM":
            exit(f"Expected 'endm', found '{endm}'")
        self.consume(NewLine, "Expected NewLine after macro")
        return Macro(name, args, body)
    
    def parse_instruction(self) -> Instruction:
        mnemonic = self.consume(Symbol, f"Expected mnemonic for instruction")
        args = []
        while not isinstance(self.tokens[self.index], NewLine):
            args.append(self.parse_arg())
        self.consume(NewLine, "Expected NewLine after instruction")
        return Instruction(mnemonic, args)
    
    def parse_arg(self) -> Arg:
        token = self.advance()
        if isinstance(token, Symbol):
            if token.name[0] == "%":
                if token.name[-1] != "%":
                    exit("Expected '%' at the end of VarArg")
                return VarArg(token)
            elif token.name.upper() in self.defines:
                return self.defines[token.name.upper()]
            elif token.name[0] != "r":
                exit(f"Expected register, VarArg, define or immediate, got '{token.name}' instead")
            num = int(token.name[1:])
            if not (0 <= num < 16):
                exit(f"Invalid register '{token.name}'")
            return Register(token)
        elif isinstance(token, (tokens.Label, Int, Char)):
            return Immediate(token)
        else:
            exit(f"Expected Symbol, Label or Int for argument, but got '{token}'")
