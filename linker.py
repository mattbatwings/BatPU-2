from typing import Dict


def link(object_file_contents: str) -> bytes:
    pc = 0
    labels: Dict[str, int] = {}
    for line in object_file_contents.split("\n"):
        line = line.strip()
        if not line:
            continue
        if line[0] == ".":
            if line in labels:
                exit(f"Duplicate label 'line'")
            labels[line] = pc
        else:
            pc += 1
    
    byte_code = b""
    for line in object_file_contents.split("\n"):
        line = line.strip()
        if not line:
            continue
        if line[0] == ".":
            continue
        words = line.split(" ")
        new_words = "0b"
        for word in words:
            if word[0] == ".":
                length = int(word.split("(")[-1][:-1])
                word = word.rsplit("(", 1)[0]
                new_words += bin(labels[word])[2:].zfill(length)
            else:
                new_words += word
        byte_code += bytes.fromhex(hex(int(new_words, 2))[2:])
    return byte_code.strip()
