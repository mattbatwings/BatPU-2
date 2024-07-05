from math import log2, log
from math import inf as INFINITY

# MAJOR, MINOR, PATCH, PRE-RELEASE IDENTIFIER, BUILD (https://semver.org)
VERSION = ['4','0','1','BETA','']
# display like "MAJOR.MINOR.PATCH[-PRE-RELEASE IDENT][+BUILD]", [] = omitted if empty
VER_FMT = "{0}.{1}.{2}[-{3}][+{4}]"
# Size prefixes
SIZE_PREFIX_DEFS = {
                    'k':1, # kibi-
                    'm':2, # mebi-
                    'g':3, # gibi- # weird flex but ok
                    't':4, # tebi- # why the fuck do you need this much memory??
                    'p':5, # pebi- # because I can-
                    'e':6, # exbi- # and nobody can stop me!!
                    'z':7, # zebi-
                    'y':8. # yobi-
                   }
# Full names for prefixes
SIZE_PREFIX_FULL = {
                    'k':'kibi-',
                    'm':'Mebi-',
                    'g':'Gibi-',
                    't':'Tebi-',
                    'p':'Pebi-',
                    'e':'Exbi-',
                    'z':'Zebi-',
                    'y':'Yobi-', # yo? that's deprecated!
                   }

# Display error message
def fatal_error(origin, message):
    exit(f"{origin}: fatal error: {message}")
# how do I explain this
def find_nz(string:str, delimiter:str, start:int=0):
    output=str.find(string, delimiter, start)
    if(output==-1):
        return output+len(string)+1
    else:
        return output
# str.find() but with multi-delimiter support
def strfind(string, delimiters, start=0):
    output=[]
    idx=start
    try:
        while(string[idx] not in delimiters):
            idx += 1
    except IndexError:
        return -1
    return idx
# strfind() but it skips over characters with a backslash behind them
def strfind_escape(string, delimiters, start=0):
    output=[]
    idx=start
    try:
        while(string[idx] not in delimiters):
            if(string[idx] == '\\'):
                idx += 1
            idx += 1
    except IndexError:
        return -1
    return idx
# inverted ffind()
def inverted_strfind(string, delimiters, start=0):
    output=[]
    idx=start
    try:
        while(string[idx] in delimiters):
            idx += 1
    except IndexError:
        return -1
    return idx
# str.split() but with multi-delimiter support
def split_string(string:str, delimiters:str):
    idx=0
    output=[]
    while(idx<len(string)):
        idx=inverted_strfind(string, delimiters, idx)
        if(idx==-1):
            break
        idx_end=strfind(string, delimiters, idx)
        if(idx_end==-1):
            output.append(string[idx:])
            break
        output.append(string[idx:idx_end])
        idx=idx_end
    return output

# Version renderer
def render_version(version, version_format):
    to_print = ""
    idx=0
    while(idx<len(version_format)):
        if(version_format[idx]=='['):
            idx_end=find_nz(version_format, ']',idx)
            substr=version_format[idx:idx_end]
            keep=True
            idx2=0
            while(idx2<(idx_end-idx)):
                idx2=substr.find('{',idx2)+1
                if(idx2==0):
                    break
                idx2_end=find_nz(substr, '}',idx2)
                if(version[int(substr[idx2:idx2_end])]==''):
                    keep=False
                    break
                idx2=idx2_end
            if(keep):
                to_print+=version_format[idx+1:idx_end]
            idx=idx_end+1
        else:
            idx_end=find_nz(version_format, '[',idx)
            to_print+=version_format[idx:idx_end]
            idx=idx_end
    
    return (to_print.format(*version), to_print.format('MAJOR','MINOR','PATCH','PRE-RELEASE','BUILD'))
# Special print
def type_print(x):
    if(type(x) == str):
        return f"\'{x}\'"
#    elif(type(x) == list):
#        return '[\n' + dump_array(x) + ']'
#    elif(type(x) == dict):
#        return '{\n' + dump_dict(x) + '}'
    else:
        return f"{x}"
# Dump dictionary
def dump_dict(dictionary):
    output = "{\n"
    for key in dictionary:
        element = dictionary[key]
        output += f"  {type_print(key)} = {type_print(element)}\n"
    output += "}\n"
    return output
# Dump array
def dump_array(array):
    output = "[\n"
    for element in array:
        output += f"  {type_print(element)}\n"
    output += "]\n"
    return output
# Deep copy
def deep_copy(array):
    array_copy = []
    for x in array:
        if(type(x) == list):
            array_copy.append(deep_copy(x))
        else:
            array_copy.append(x)
    return array_copy
# Garbfield
def word_dissect(word, size, word_length):
    mask = (1 << word_length) - 1
    return [((word >> x) & mask) for x in range((size - 1) * word_length, -1, -word_length)]
# Find the maximum value in an array, after applying a key function to the elements
def find_max(array, key=lambda x:x):
    max_val = key(array[0])
    for element in array[1:]:
        max_val = max(max_val, key(element))
    return max_val
