from abc import ABC
from dataclasses import dataclass
from typing import List


class Token(ABC):
    pass


@dataclass
class Label(Token):
    name: str


@dataclass
class Int(Token):
    value: int


@dataclass
class Char(Token):
    value: str


@dataclass
class Symbol(Token):
    name: str


@dataclass
class NewLine(Token):
    pass


@dataclass
class Eof(Token):
    pass


class Tokenizer:
    def __init__(self, program: str):
        self.program = program
        self.index = 0
        self.tokens = []
    
    def tokenize(self) -> List[Token]:
        while self.index < len(self.program):
            if self.program[self.index] == "\n" and (len(self.tokens) == 0 or not isinstance(self.tokens[-1], NewLine)):
                self.tokens.append(NewLine())
            if self.program[self.index] in " \n\t":
                self.index += 1
            elif self.program[self.index] in "#;" or (self.program[self.index] == "/" and self.program[self.index] == "/"):
                while self.index < len(self.program) and self.program[self.index] != "\n":
                    self.index += 1
            elif self.program[self.index] == '.':
                self.parse_label()
            elif self.program[self.index] in "-1234567890":
                self.parse_int()
            elif self.program[self.index] == "'" or self.program[self.index] == '"':
                delimiter = self.program[self.index]
                char = self.program[self.index + 1]
                if self.program[self.index + 2] != delimiter:
                    exit(f"Expected end of string, got {self.program[self.index + 2]} instead")
                self.tokens.append(Char(char))
                self.index += 3
            else:
                self.parse_symbol()
        if len(self.tokens) == 0 or not isinstance(self.tokens[-1], NewLine):
            self.tokens.append(NewLine())
        self.tokens.append(Eof())
        return self.tokens
    
    def parse_label(self) -> None:
        beginning_index = self.index + 1
        while self.index < len(self.program) and self.program[self.index] not in " \t\n":
            self.index += 1
        self.tokens.append(Label(self.program[beginning_index:self.index]))
    
    def parse_int(self) -> None:
        beginning_index = self.index
        self.index += 1
        if self.index < len(self.program) and self.program[self.index] in "box":  # binary, octal, hex
            self.index += 1
        while self.index < len(self.program) and self.program[self.index] in "-1234567890":
            self.index += 1
        self.tokens.append(Int(int(self.program[beginning_index:self.index], 0)))
    
    def parse_symbol(self) -> None:
        beginning_index = self.index
        while self.index < len(self.program) and self.program[self.index] not in " \t\n":
            self.index += 1
        self.tokens.append(Symbol(self.program[beginning_index:self.index]))
