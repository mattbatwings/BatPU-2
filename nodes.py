from __future__ import annotations

from abc import ABC
from dataclasses import dataclass
from typing import List

import tokens
from tokens import Symbol, Int, Char


class NodeVisitor[*Args](ABC):
    def visit_program(self, program: Program, *args: *Args):
        for item in program.items:
            self.visit_item(item, *args)
    
    def visit_item(self, item: Item, *args: *Args):
        if isinstance(item, Macro):
            return self.visit_macro(item, *args)
        elif isinstance(item, MacroItem):
            return self.visit_macro_item(item, *args)
        elif isinstance(item, Define):
            return self.visit_define(item, *args)
        else:
            raise TypeError(f"Unsupported item type: {item}")
    
    def visit_define(self, define: Define, *args: *Args):
        return self.visit_immediate(define.value, *args)
    
    def visit_macro(self, macro: Macro, *args: *Args):
        for item in macro.body:
            return self.visit_macro_item(item, *args)
    
    def visit_macro_item(self, item: MacroItem, *args: *Args):
        if isinstance(item, Label):
            return self.visit_label(item, *args)
        elif isinstance(item, Instruction):
            return self.visit_instruction(item, *args)
        else:
            raise TypeError(f"Unsupported macro item type: {item}")
    
    def visit_label(self, label: Label, *args: *Args):
        pass
    
    def visit_instruction(self, instruction: Instruction, *args: *Args):
        for arg in instruction.args:
            self.visit_arg(arg, *args)
    
    def visit_arg(self, arg: Arg, *args: *Args):
        if isinstance(arg, VarArg):
            return self.visit_var_arg(arg, *args)
        elif isinstance(arg, Immediate):
            return self.visit_immediate(arg, *args)
        elif isinstance(arg, Register):
            return self.visit_register(arg, *args)
        else:
            raise TypeError(f"Unsupported arg type: {arg}")
    
    def visit_var_arg(self, var_arg: VarArg, *args: *Args): pass
    def visit_immediate(self, immediate: Immediate, *args: *Args): pass
    def visit_register(self, register: Register, *args: *Args): pass


class Node(ABC):
    pass


@dataclass
class Program(Node):
    items: List[Item]


class Item(Node, ABC):
    pass


@dataclass
class Define(Item):
    name: Symbol
    value: Immediate


@dataclass
class Macro(Item):
    name: Symbol
    args: List[Symbol]
    body: List[MacroItem]


class MacroItem(Item, ABC):
    pass


@dataclass
class Label(MacroItem):
    label: tokens.Label


@dataclass
class Instruction(MacroItem):
    mnemonic: Symbol
    args: List[Arg]


class Arg(Node, ABC):
    pass


@dataclass
class VarArg(Arg):
    name: Symbol


@dataclass
class Immediate(Arg):
    value: Int | Char | tokens.Label


@dataclass
class Register(Arg):
    register: Symbol
