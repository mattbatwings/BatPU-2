from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Type, List, Optional

import tokens
from tokens import Int, Char
from nodes import NodeVisitor, Register, Program, Macro, Label, Instruction, Arg, Immediate, VarArg, Define


@dataclass
class NativeInstruction:
    mnemonic: str
    opcode: int
    args: List[InstructionArg]


@dataclass
class InstructionArg:
    size: int
    type_: Type[Arg] | None
    default: Optional["type_"] = None


NATIVE_INSTRUCTIONS = [
    NativeInstruction("NOP", 0, [InstructionArg(12, None)]),
    NativeInstruction("HLT", 1, [InstructionArg(12, None)]),
    NativeInstruction("ADD", 2, [InstructionArg(4, Register), InstructionArg(4, Register), InstructionArg(4, Register)]),
    NativeInstruction("SUB", 3, [InstructionArg(4, Register), InstructionArg(4, Register), InstructionArg(4, Register)]),
    NativeInstruction("NOR", 4, [InstructionArg(4, Register), InstructionArg(4, Register), InstructionArg(4, Register)]),
    NativeInstruction("AND", 5, [InstructionArg(4, Register), InstructionArg(4, Register), InstructionArg(4, Register)]),
    NativeInstruction("XOR", 6, [InstructionArg(4, Register), InstructionArg(4, Register), InstructionArg(4, Register)]),
    NativeInstruction("RSH", 7, [InstructionArg(4, Register), InstructionArg(4, None), InstructionArg(4, Register)]),
    NativeInstruction("LDI", 8, [InstructionArg(4, Register), InstructionArg(8, Immediate)]),
    NativeInstruction("ADI", 9, [InstructionArg(4, Register), InstructionArg(8, Immediate)]),
    NativeInstruction("JMP", 10, [InstructionArg(2, None), InstructionArg(10, Immediate)]),
    NativeInstruction("BRH", 11, [InstructionArg(2, Immediate), InstructionArg(10, Immediate)]),
    NativeInstruction("CAL", 12, [InstructionArg(2, None), InstructionArg(10, Immediate)]),
    NativeInstruction("RET", 13, [InstructionArg(12, None)]),
    NativeInstruction("LOD", 14, [InstructionArg(4, Register), InstructionArg(4, Register), InstructionArg(4, Immediate, Immediate(Int(0)))]),
    NativeInstruction("STR", 15, [InstructionArg(4, Register), InstructionArg(4, Register), InstructionArg(4, Immediate, Immediate(Int(0)))]),
]


class Assembler(NodeVisitor[Dict[str, Arg]]):
    def __init__(self):
        self.macros: Dict[str, Macro] = {}
        self.macro_uuid = 0
    
    def visit_program(self, program: Program, cur_macro: Dict[str, Arg] | None = None) -> str:
        object_code = "\n".join(self.visit_item(item, cur_macro) for item in program.items)
        return "\n".join(line.strip() for line in object_code.split("\n") if line.strip())
    
    def visit_define(self, define: Define, cur_macro: Dict[str, Arg] | None = None) -> str:
        return ""
    
    def visit_macro(self, macro: Macro, cur_macro: Dict[str, Arg] | None = None) -> str:
        if macro.name.name.upper() in self.macros:
            exit(f"Duplicate macro '{macro.name.name}'")
        self.macros[macro.name.name.upper()] = macro
        return ""
    
    def visit_label(self, label: Label, cur_macro: Dict[str, Arg] | None = None) -> str:
        return "." + label.label.name if cur_macro is None else f".__MACRO_{self.macro_uuid}_{label.label.name}"
    
    def visit_instruction(self, instruction: Instruction, cur_macro: Dict[str, Arg] | None = None) -> str:
        for native in NATIVE_INSTRUCTIONS:
            if instruction.mnemonic.name.upper() == native.mnemonic:
                native_instruction_count_min = len([None for arg in native.args if arg.type_ is not None and arg.default is None])
                native_instruction_count_max = len([None for arg in native.args if arg.type_ is not None])
                if not (native_instruction_count_min <= len(instruction.args) <= native_instruction_count_max):
                    expected_args = f"between {native_instruction_count_min} and {native_instruction_count_max}" \
                        if native_instruction_count_min != native_instruction_count_max else \
                        str(native_instruction_count_min)
                    exit(f"Invalid number of arguments for {native.mnemonic}: Expected {expected_args} but got {len(instruction.args)}")
                args = ""
                args_iter = iter(instruction.args)
                for native_arg in native.args:
                    if native_arg.type_ is None:
                        args += "0" * native_arg.size
                        continue
                    try:
                        arg = next(args_iter)
                    except StopIteration:
                        arg = native_arg.default
                    if isinstance(arg, VarArg) and cur_macro is not None:
                        arg = self.visit_var_arg(arg, cur_macro)
                    if not isinstance(arg, native_arg.type_):
                        exit(f"Invalid argument: Expected a '{native_arg.type_.__name__}', got '{arg}' instead")
                    arg_bin: str = self.visit_arg(arg, cur_macro)
                    if not (isinstance(arg, Immediate) and isinstance(arg.value, tokens.Label)):
                        arg_bin = arg_bin[-native_arg.size:].zfill(native_arg.size)
                    else:
                        arg_bin += f"({native_arg.size}) "
                    args += arg_bin
                return bin(native.opcode)[2:].zfill(4) + args.strip()
        
        self.macro_uuid += 1
        macro = self.macros[instruction.mnemonic.name.upper()]
        new_macro: Dict[str, Arg] = {}
        if len(instruction.args) != len(macro.args):
            exit(f"Invalid number of arguments for {macro.name}: Expected {len(macro.args)} but got {len(instruction.args)}")
        for macro_arg, instruction_arg in zip(macro.args, instruction.args):
            if isinstance(instruction, VarArg) and cur_macro is not None:
                instruction_arg = self.visit_var_arg(instruction_arg, cur_macro)
            new_macro[macro_arg.name] = instruction_arg
        return "\n".join(self.visit_macro_item(macro_item, new_macro) for macro_item in macro.body)
    
    def visit_var_arg(self, var_arg: VarArg, cur_macro: Dict[str, Arg] | None = None) -> Arg:
        return cur_macro[var_arg.name.name[1:-1]]  # Excluding the '%'s
    
    def visit_immediate(self, immediate: Immediate, cur_macro: Dict[str, Arg] | None = None) -> str:
        if isinstance(immediate.value, tokens.Label):
            return " ." + immediate.value.name if cur_macro is None else f" .__MACRO_{self.macro_uuid}_{immediate.value.name}"
        elif isinstance(immediate.value, Char):
            return bin(ord(immediate.value.value))[2:]
        value: int = immediate.value.value
        if value < 0:
            return "1" * 256 + "".join("0" if value == "1" else "1" for value in bin(-value - 1)[2:])
        return bin(immediate.value.value)[2:]
    
    def visit_register(self, register: Register, cur_macro: Dict[str, Arg] | None = None) -> str:
        return bin(int(register.register.name[1:]))[2:]
