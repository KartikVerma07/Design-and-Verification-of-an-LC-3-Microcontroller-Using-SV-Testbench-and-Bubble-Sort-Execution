#!/usr/bin/env python3
# Very small LC-3 assembler (only ops your design supports)
# Supports: BR*/ADD/AND/NOT/LD/LEA/LDR/STR and .ORIG/.END/.FILL/.BLKW/.STRINGZ
# Usage: python assembler.py input.asm -o output.hex

import sys, re

REG = {f"R{i}": i for i in range(8)}
OPC = {"BR":0b0000, "ADD":0b0001, "LD":0b0010, "AND":0b0101,
       "LDR":0b0110, "STR":0b0111, "NOT":0b1001, "LEA":0b1110}

def is_branch(op): return op.startswith("BR")

def num(tok):
    t = tok.replace('_','')
    if t[0] in '#xXbB':
        if t[0] in 'xX': return int(t[1:],16)
        if t[0] in 'bB': return int(t[1:],2)
        return int(t[1:],10)
    # plain decimal allowed
    return int(t,10)

def sfit(v,bits):
    lo = -(1<<(bits-1)); hi = (1<<(bits-1))-1
    if v<lo or v>hi: raise SystemExit(f"imm out of range for {bits}-bit: {v}")
    return v & ((1<<bits)-1)

def reg(tok):
    tok = tok.upper()
    if tok not in REG: raise SystemExit(f"bad register {tok}")
    return REG[tok]

def tokenize_line(s):
    s = s.split(';',1)[0].strip()
    if not s: return None
    toks = [t for t in re.split(r'[,\s]+', s) if t]
    label = None
    # label with ':' or LC-3 style first token not an opcode/directive
    if toks[0].endswith(':'):
        label = toks[0][:-1]; toks = toks[1:]
    elif toks[0][0] != '.' and toks[0].upper() not in OPC and not is_branch(toks[0].upper()):
        label = toks[0]; toks = toks[1:]
    op = toks[0].upper() if toks else None
    args = toks[1:] if len(toks)>1 else []
    return (label, op, args, s)

def pass1(lines):
    pc = None; sym = {}; rec = []
    for lnno, raw in enumerate(lines,1):
        tok = tokenize_line(raw)
        if not tok: continue
        label, op, args, text = tok
        if op == ".ORIG":
            if pc is not None: raise SystemExit(".ORIG redefined")
            pc = num(args[0]); rec.append([lnno, pc, label, op, args, text]); continue
        if pc is None: raise SystemExit("code before .ORIG")
        if label:
            if label in sym: raise SystemExit(f"label {label} redefined")
            sym[label] = pc
        rec.append([lnno, pc, label, op, args, text])
        if op == ".END": break
        if op == ".FILL": pc += 1
        elif op == ".BLKW": pc += num(args[0])
        elif op == ".STRINGZ":
            s = args[0]; pc += (len(s[1:-1]) + 1)
        elif op and op.startswith('.'):
            raise SystemExit(f"unknown directive {op}")
        else:
            pc += 1
    if pc is None: raise SystemExit("missing .ORIG")
    return rec, sym

def enc_BR(op, args, cur, sym):
    cond = op[2:]  # N/Z/P subset or ""
    n = 1 if ('N' in cond or cond=='') else 0
    z = 1 if ('Z' in cond or cond=='') else 0
    p = 1 if ('P' in cond or cond=='') else 0
    tgt = args[0]
    off = (sym[tgt] - (cur+1)) if tgt in sym else num(tgt)
    off9 = sfit(off,9)
    return (OPC["BR"]<<12) | (n<<11)|(z<<10)|(p<<9) | off9

def enc_ADD(args):
    dr, sr1, x = args
    d = reg(dr); s1 = reg(sr1)
    if x.upper().startswith('R'):
        s2 = reg(x)
        return (OPC["ADD"]<<12)|(d<<9)|(s1<<6)|(0<<5)|s2
    imm5 = sfit(num(x),5)
    return (OPC["ADD"]<<12)|(d<<9)|(s1<<6)|(1<<5)|imm5

def enc_AND(args):
    dr, sr1, x = args
    d = reg(dr); s1 = reg(sr1)
    if x.upper().startswith('R'):
        s2 = reg(x)
        return (OPC["AND"]<<12)|(d<<9)|(s1<<6)|(0<<5)|s2
    imm5 = sfit(num(x),5)
    return (OPC["AND"]<<12)|(d<<9)|(s1<<6)|(1<<5)|imm5

def enc_NOT(args):
    dr, sr = args
    return (OPC["NOT"]<<12)|(reg(dr)<<9)|(reg(sr)<<6)|0b111111

def enc_LD_like(op, args, cur, sym):
    dr, tgt = args
    off = (sym[tgt] - (cur+1)) if tgt in sym else num(tgt)
    off9 = sfit(off,9)
    return (OPC[op]<<12)|(reg(dr)<<9)|off9

def enc_LDR(args):
    dr, base, off = args
    off6 = sfit(num(off),6)
    return (OPC["LDR"]<<12)|(reg(dr)<<9)|(reg(base)<<6)|off6

def enc_STR(args):
    sr, base, off = args
    off6 = sfit(num(off),6)
    return (OPC["STR"]<<12)|(reg(sr)<<9)|(reg(base)<<6)|off6

def pass2(rec, sym):
    words = []
    for lnno, pc, label, op, args, text in rec:
        if op in (".ORIG",): continue
        if op == ".END": break
        if op == ".FILL":
            words.append(num(args[0]) & 0xFFFF); continue
        if op == ".BLKW":
            words.extend([0]*num(args[0])); continue
        if op == ".STRINGZ":
            s = args[0]; s = s[1:-1]  # remove quotes
            for ch in s: words.append(ord(ch)&0xFF)
            words.append(0); continue

        if is_branch(op):
            w = enc_BR(op, args, pc, sym)
        elif op == "ADD":
            w = enc_ADD(args)
        elif op == "AND":
            w = enc_AND(args)
        elif op == "NOT":
            w = enc_NOT(args)
        elif op == "LD":
            w = enc_LD_like("LD", args, pc, sym)
        elif op == "LEA":
            w = enc_LD_like("LEA", args, pc, sym)
        elif op == "LDR":
            w = enc_LDR(args)
        elif op == "STR":
            w = enc_STR(args)
        else:
            raise SystemExit(f"unsupported opcode {op}")
        words.append(w & 0xFFFF)
    return words

def main():
    if len(sys.argv)<2: print("Usage: assembler.py input.asm -o out.hex"); sys.exit(2)
    inp, out = None, None
    i=1
    while i<len(sys.argv):
        if sys.argv[i]=="-o" and i+1<len(sys.argv):
            out = sys.argv[i+1]; i+=2; continue
        if inp is None: inp = sys.argv[i]; i+=1; continue
        print(f"Unknown arg {sys.argv[i]}"); sys.exit(2)
    if not out: out = re.sub(r'\.a(sm)?$', '', inp) + ".hex"

    src = open(inp,'r',encoding='utf-8').read()
    rec, sym = pass1(src.splitlines())
    words = pass2(rec, sym)
    with open(out,'w',encoding='utf-8') as f:
        for w in words: f.write(f"{w:04X}\n")
    print(f"OK: {len(words)} words -> {out}")

if __name__ == "__main__":
    main()
