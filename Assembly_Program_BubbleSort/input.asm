        .ORIG x3000

        ; ---- setup: load base and N (via pointer) ----
        LD    R0, DATA_PTR      ; R0 = x4000 (array base)
        LD    R7, LEN_PTR       ; R7 = &N (x3FFE literal)
        LDR   R1, R7, #0        ; R1 = N
        ADD   R1, R1, #-1       ; i = N-1

OUTER:  BRn   DONE              ; if i < 0 : finished
        AND   R2, R2, #0        ; j = 0

INNER:  ADD   R5, R2, #1        ; R5 = j+1   (keep this live until after SWAP)

        ; ---- load A=a[j], B=a[j+1] using computed addresses (LDR offset is imm6) ----
        ADD   R7, R0, R2        ; R7 = base + j
        LDR   R3, R7, #0        ; R3 = A = a[j]
        ADD   R7, R0, R5        ; R7 = base + (j+1)
        LDR   R4, R7, #0        ; R4 = B = a[j+1]

        ; ---- signed compare A vs B ----
        ; If signs differ: (A>=0 & B<0) => SWAP; (A<0 & B>=0) => NOSWAP
        ; Else (same sign): test A-B via NZP of D.
        ADD   R6, R3, #0        ; set NZP from A
        BRn   A_NEG

A_NONNEG:
        ADD   R6, R4, #0        ; set NZP from B
        BRn   SWAP              ; A>=0 & B<0  => A>B
        BRnzp    SAME_SIGN         ; both nonnegative

A_NEG:
        ADD   R6, R4, #0        ; set NZP from B
        BRzp  NOSWAP            ; A<0 & B>=0  => A<B
        ; fallthrough: both negative

SAME_SIGN:
        ; D = A - B (NZP of D tells signed relation)
        NOT   R6, R4
        ADD   R6, R6, #1
        ADD   R6, R3, R6
        BRp   SWAP              ; A>B (signed)
        BRnzp    NOSWAP

        ; ---- no swap path ----
NOSWAP: ADD   R2, R2, #1        ; j++

        ; while (j <= i-1) -> loop back to INNER
        ADD   R5, R1, #0        ; R5 = i
        ADD   R5, R5, #-1       ; R5 = i-1
        NOT   R6, R2            ; R6 = ~j
        ADD   R6, R6, #1        ; R6 = -j
        ADD   R5, R5, R6        ; (i-1) - j
        BRzp  INNER             ; if >=0 keep looping

        ; inner done: i--
        ADD   R1, R1, #-1
        BRnzp OUTER             ; repeat outer pass

        ; ---- swap path ----
SWAP:   ADD   R7, R0, R5        ; R7 = base + (j+1)
        STR   R3, R7, #0        ; a[j+1] = A
        ADD   R7, R0, R2        ; R7 = base + j
        STR   R4, R7, #0        ; a[j]   = B
        BRnzp NOSWAP            ; continue inner at j++

        ; ---- done: set DONE=1 and spin ----
DONE:   LD    R7, DONE_PTR      ; R7 = x3FFF literal
        AND   R6, R6, #0
        ADD   R6, R6, #1        ; R6 = 1
        STR   R6, R7, #0        ; DONE = 1

; ---- PC-relative literals (must be within ±256 words of their LDs) ----
LEN_PTR  .FILL x3FFE
DONE_PTR .FILL x3FFF
DATA_PTR .FILL x4000

        .END