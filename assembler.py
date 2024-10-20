import re
import sys


# Constants
MAX_REGISTER = 2**4
MAX_IMMEDIATE = 255
MIN_IMMEDIATE = -128
MAX_OFFSET = 7
MIN_OFFSET = -8
MAX_ADDRESS = 2**10

COMMENT = re.compile(r"[/;#].*")


# Structures
class AssemblyError(Exception):
    """Custom exception for assembly errors."""

    def __init__(
        self, message: str, line: str = None, line_num: str = None, file: str = ""
    ):
        msg = f"\033[31mError\033[0m: {message}\n"
        msg += f"\033[34m --> \033[0m{file} \033[34mline\033[0m {line_num}\n"

        if line:
            indent = len(str(line_num))
            msg += f"\033[34m{" " * indent} |\n"
            msg += f"{line_num} |\033[0m {line}\n"
            msg += f"\033[34m{" " * indent} |\033[0m\n"

        super().__init__(msg)


class OperandError(AssemblyError):
    """Exception for operand-related errors."""

    pass


# Logic
def populate_symbols(symbols: list[str], offset=0) -> dict[str, int]:
    return {symbol: index + offset for index, symbol in enumerate(symbols)}


def populate_symbol_table() -> dict[str, int]:
    """Populate the symbol table with opcodes, registers, conditions, and ports."""
    symbols = {}

    # fmt: off
    opcodes = [
        "nop", "hlt", "add", "sub", "nor", "and", "xor", "rsh",
        "ldi", "adi", "jmp", "brh", "cal", "ret", "lod", "str",
    ]
    # fmt: on
    symbols.update(populate_symbols(opcodes))

    registers = [f"r{i}" for i in range(16)]
    symbols.update(populate_symbols(registers))

    conditions = [
        ["eq", "ne", "ge", "lt"],
        ["=", "!=", ">=", "<"],
        ["z", "nz", "c", "nc"],
        ["zero", "notzero", "carry", "notcarry"],
    ]
    for condition in conditions:
        symbols.update(populate_symbols(condition))

    # fmt: off
    ports = [
        "pixel_x", "pixel_y", "draw_pixel", "clear_pixel", "load_pixel",
        "buffer_screen", "clear_screen_buffer", "write_char", "buffer_chars",
        "clear_chars_buffer", "show_number", "clear_number", "signed_mode",
        "unsigned_mode", "rng", "controller_input",
    ]
    # fmt: on
    symbols.update(populate_symbols(ports, offset=240))

    for i, letter in enumerate(" abcdefghijklmnopqrstuvwxyz.!?"):
        symbols[f'"{letter}"'] = i
        symbols[f"'{letter}'"] = i

    return symbols


def is_definition(word: str) -> bool:
    return word == "define"


def is_label(word: str) -> bool:
    return word[0] == "."


def resolve(
    symbols: dict[str, int], word, line_num=None, line=None, file: str = None
) -> int:
    try:
        if word[0] in "-0123456789":
            return int(word, 0)

        if symbols.get(word) is None:
            raise AssemblyError(
                f"Could not resolve symbol '{word}'",
                line_num=line_num,
                line=line,
                file=file,
            )

        return symbols[word]

    except Exception as e:
        raise AssemblyError(
            f"Error resolving '{word}': {str(e)}",
            line_num=line_num,
            line=line,
            file=file,
        )


def resolve_pseudo_instructions(words):
    """Convert pseudo-instructions to real instructions."""
    pseudo_map = {
        "cmp": lambda w: ["sub", w[1], w[2], "r0"],
        "mov": lambda w: ["add", w[1], "r0", w[2]],
        "lsh": lambda w: ["add", w[1], w[1], w[2]],
        "inc": lambda w: ["adi", w[1], "1"],
        "dec": lambda w: ["adi", w[1], "-1"],
        "not": lambda w: ["nor", w[1], "r0", w[2]],
        "neg": lambda w: ["sub", "r0", w[1], w[2]],
    }
    return pseudo_map.get(words[0], lambda w: w)(words)


def validate_operand_count(opcode, words, pc, line=None, file: str = None):
    """Validate the number of operands for the opcode."""
    operand_map = {
        ("nop", "hlt", "ret"): 1,
        ("jmp", "cal"): 2,
        ("rsh", "ldi", "adi", "brh"): 3,
        ("add", "sub", "nor", "and", "xor", "lod", "str"): 4,
    }
    for opcodes, count in operand_map.items():
        if opcode in opcodes and len(words) != count:
            raise OperandError(
                f"Incorrect number of operands for '{opcode}' (expected {count}, got {len(words)})",
                line_num=pc,
                line=line,
                file=file,
            )


def build_machine_code(opcode, words, machine_code, pc, line=None, file: str = None):
    """Build the machine code for a specific instruction."""
    if opcode in ["add", "sub", "nor", "and", "xor", "rsh", "ldi", "adi", "lod", "str"]:
        if words[1] >= MAX_REGISTER:
            raise OperandError(
                f"Invalid reg A for '{opcode}'", line_num=pc, line=line, file=file
            )
        machine_code |= words[1] << 8

    if opcode in ["add", "sub", "nor", "and", "xor", "lod", "str"]:
        if words[2] >= MAX_REGISTER:
            raise OperandError(
                f"Invalid reg B for '{opcode}'", line_num=pc, line=line, file=file
            )
        machine_code |= words[2] << 4

    if opcode in ["add", "sub", "nor", "and", "xor", "rsh"]:
        if words[-1] >= MAX_REGISTER:
            raise OperandError(
                f"Invalid reg C for '{opcode}'", line_num=pc, line=line, file=file
            )
        machine_code |= words[-1]

    if opcode in ["ldi", "adi"]:
        if not MIN_IMMEDIATE <= words[2] <= MAX_IMMEDIATE:
            raise OperandError(
                f"Invalid immediate value '{words[2]}'",
                line_num=pc,
                line=line,
                file=file,
            )
        machine_code |= words[2] & (2**8 - 1)

    if opcode in ["jmp", "brh", "cal"]:
        if words[-1] >= MAX_ADDRESS:
            raise OperandError(
                f"Invalid address '{words[-1]}'", line_num=pc, line=line, file=file
            )
        machine_code |= words[-1]

    if opcode in ["lod", "str"]:
        if not MIN_OFFSET <= words[3] <= MAX_OFFSET:
            raise OperandError(
                f"Invalid offset '{words[3]}'", line_num=pc, line=line, file=file
            )
        machine_code |= words[3] & (2**4 - 1)

    if opcode == "brh":
        if words[1] >= 2**2:
            raise OperandError(
                f"Invalid condition for '{opcode}'", line_num=pc, line=line, file=file
            )
        machine_code |= words[1] << 10

    return machine_code


def compile(path: str, output: str):
    asm_file = open(path, "r")

    # Remove comments
    lines = (re.sub(COMMENT, "", line).strip() for line in asm_file)
    # Remove black lines
    lines = [line for line in lines if line.strip()]

    # Populate symbol table with helper function
    symbols = populate_symbol_table()

    # First pass: collect definitions and labels
    pc = 0
    instructions = []

    for line_num, line in enumerate(lines):
        words = [word.lower() for word in line.split()]

        if is_definition(words[0]):
            symbols[words[1]] = int(words[2])
        elif is_label(words[0]):
            symbols[words[0]] = pc
            if len(words) > 1:
                pc += 1
                instructions.append((line_num, words[1:]))
        else:
            pc += 1
            instructions.append((line_num, words))

    # Generate machine code
    with open(output, "w") as output_file:
        for pc, (line_num, words) in enumerate(instructions):
            # Resolve pseudo-instructions
            words = resolve_pseudo_instructions(words)

            # lod/str optional offset
            if words[0] in ["lod", "str"] and len(words) == 3:
                words.append("0")

            # Space special case
            if words[-1] in ['"', "'"] and words[-2] in ['"', "'"]:
                words = words[:-1]
                words[-1] = "' '"

            # Begin translation
            opcode = words[0]
            machine_code = symbols[opcode] << 12
            line = lines[line_num - 1]
            words = [resolve(symbols, word, line_num, line, path) for word in words]

            # Number of operands check
            validate_operand_count(opcode, words, pc, line, path)

            # Build the machine code for the instruction
            machine_code = build_machine_code(
                opcode, words, machine_code, pc, line, path
            )

            as_string = bin(machine_code)[2:].zfill(16)
            output_file.write(f"{as_string}\n")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        exit("Not enough arguments.")

    compile(sys.argv[1], sys.argv[2] if len(sys.argv) >= 3 else "output.mc")
