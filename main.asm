; Monitor Firmware is placed in the beginning of the program address space (from 0000h to 1FFFh)
; so the actual user's program must be placed at the address 8000h.
; The program below actually starts at the address 8500h because lower memory region
; is also used by the interrupt vectors.

    ASSERT16 MACRO exp_hi, exp_lo, reg_hi, reg_lo
        inc     assert_cnt
        mov     R7, assert_cnt
        mov     A, reg_lo
        cjne    A, #exp_lo, ASSERT_FAIL
        mov     A, reg_hi
        cjne    A, #exp_hi, ASSERT_FAIL
    ENDM

    ORG 8000h
    jmp main
    ORG 8500h

    ; address of XC953XL GPIO0..7 available on JP1.2-9 
    GPIO_ext    EQU 0D000h
    ; to set GPIO0: write 01h, GPIO1: 02h, GPIO2: 04h and so on

    ; variables to use in montgomery multiplication
    a_lo        EQU 20h
    a_hi        EQU 21h
    b_lo        EQU 22h
    b_hi        EQU 23h
    m_lo        EQU 24h
    m_hi        EQU 25h
    result_0    EQU 26h
    result_1    EQU 27h
    result_2    EQU 28h
    result_3    EQU 29h

    ; variables to use in mod32_16
    rem_lo      EQU 30h
    rem_hi      EQU 31h
    rem_ext     EQU 32h

    ; variables to use in shiftleft32
    sl_0        EQU 33h
    sl_1        EQU 34h
    sl_2        EQU 35h
    sl_3        EQU 36h

    ; assert counter
    assert_cnt     EQU 37h

    ; result of mod_exp16
    x_lo        EQU 38h
    x_hi        EQU 39h

    ; variables used in Diffie-Hellman protocol
    p_lo        EQU 4bh ; prime number
    p_hi        EQU 4ch
    g_lo        EQU 4dh ; generator
    g_hi        EQU 4eh
    ka_lo       EQU 4fh ; private key A
    ka_hi       EQU 50h
    kb_lo       EQU 51h ; private key B
    kb_hi       EQU 52h
    ca_lo       EQU 53h ; public key A
    ca_hi       EQU 54h
    cb_lo       EQU 55h ; public key B
    cb_hi       EQU 56h
    d_lo        EQU 57h ; secret key
    d_hi        EQU 58h

    ; variable to use in cmp_ge16 subroutine
    cmp_var     EQU 59h

    ; variables to use in mod32_16_div8 subroutine
    q           EQU 60h
    tmp_lo      EQU 61h
    tmp_hi      EQU 62h

main:
    ; initialize ASSERT counter
    mov     assert_cnt, #0

    ; set base initial value
    mov     rem_lo, #04h
    mov     rem_hi, #00h

    ; set modulus
    mov     m_lo, #34h
    mov     m_hi, #12h

    main_loop:
    ; ------------------------
    ; SQUARING
    ; ------------------------
    ; set GPIO1
    mov     DPTR, #GPIO_ext
    mov     A, #02h
	movx    @DPTR, A
    ; 1 squaring
    mov     R1, rem_lo
    mov     R2, rem_hi
    lcall   square16
    ; reset GPIO
    mov     DPTR, #GPIO_ext
    mov     A, #00h
	movx    @DPTR, A

    ; ------------------------
    ; MODULO
    ; ------------------------
    ; set GPIO3
    mov     DPTR, #GPIO_ext
    mov     A, #08h
	movx    @DPTR, A
    ; 1 modulo
    mov     R1, 3 ; a0 (LSB)
    mov     R2, 4 ; a1
    mov     R3, 5 ; a2
    mov     R4, 6 ; a3 (MSB)
    lcall   mod32_16_div8
    ; reset GPIO
    mov     DPTR, #GPIO_ext
    mov     A, #00h
	movx    @DPTR, A

    ; ------------------------
    ; MULTIPLYING
    ; ------------------------
    ; set GPIO2
    mov     DPTR, #GPIO_ext
    mov     A, #04h
	movx    @DPTR, A
    ; 1 multiplying
    mov     a_lo, rem_lo
    mov     a_hi, rem_hi
    mov     b_lo, #02h
    mov     b_hi, #01h
    lcall   mul16
    ; reset GPIO
    mov     DPTR, #GPIO_ext
    mov     A, #00h
	movx    @DPTR, A

    ; ------------------------
    ; MODULO
    ; ------------------------
    ; set GPIO3
    mov     DPTR, #GPIO_ext
    mov     A, #08h
	movx    @DPTR, A
    ; 1 modulo
    mov     R1, result_0
    mov     R2, result_1
    mov     R3, result_2
    mov     R4, result_3
    lcall   mod32_16_div8
    ; reset GPIO
    mov     DPTR, #GPIO_ext
    mov     A, #00h
	movx    @DPTR, A

    jmp main_loop

    jmp     $

ASSERT_FAIL:
    sjmp    ASSERT_FAIL

;-----------------------------------------
; add 16-bit values
; A + B = C
; in:   R1:R0 = a_hi:a_lo
;       R3:R2 = b_hi:b_lo
; out:  R5:R4 = c_hi:c_lo + Carry flag
;-----------------------------------------
add16:
    ; add low bytes and store in R4
    mov     A, R0
    add     A, R2
    mov     R4, A

    ; add high bytes with carry and store in R5
    mov     A, R1
    addc    A, R3
    mov     R5, A

    ret

;-----------------------------------------
; subtract 16-bit values
; A - B = C
; in:   R1:R0 = a_hi:a_lo
;       R3:R2 = b_hi:b_lo
; out:  R5:R4 = c_hi:c_lo + Carry (borrow) flag
;-----------------------------------------
sub16:
    clr     C
    mov     A, R0
    subb    A, R2
    mov     R4, A

    mov     A, R1
    subb    A, R3
    mov     R5, A

    ret

;-----------------------------------------
; Multiply 16-bit values.
;
; A * B = P (32-bit)
;
; In:   a_hi:a_lo
;       b_hi:b_lo
;
; Out:  result_3:result_2:result_1:result_0
;-----------------------------------------
mul16:
    ; result = 0
    mov     result_0, #0
    mov     result_1, #0
    mov     result_2, #0
    mov     result_3, #0

    clr     C ; clear Carry

    ; a_lo * b_lo
    mov     A, a_lo
    mov     B, b_lo
    mul     AB ; A=lo, B=hi
    mov     result_0, A
    mov     result_1, B

    ; a_lo * b_hi
    mov     A, a_lo
    mov     B, b_hi
    mul     AB
    add     A, result_1
    mov     result_1, A
    mov     A, result_2
    addc    A, B
    mov     result_2, A
    jnc     mul_no_carry1
    inc     result_3
    mul_no_carry1:

    ; a_hi * b_lo
    mov     A, a_hi
    mov     B, b_lo
    mul     AB
    add     A, result_1
    mov     result_1, A
    mov     A, result_2
    addc    A, B
    mov     result_2, A
    jnc     mul_no_carry2
    inc     result_3
    mul_no_carry2:

    ; a_hi * b_hi
    mov A, a_hi
    mov B, b_hi
    mul AB
    add A, result_2
    mov result_2, A
    mov A, result_3
    addc A, B
    mov result_3, A

    ret

;-----------------------------------------
; Square 16-bit value.
; 
; A^2 = P (32-bit)
;
; In:   R2:R1
;
; Out:  R6:R5:R4:R3
;-----------------------------------------
square16:
   ; clear result
    mov     R3, #0
    mov     R4, #0
    mov     R5, #0
    mov     R6, #0

    ;--------------------------
    ; lo * lo
    ;--------------------------
    mov     A, R1
    mov     B, R1
    mul     AB
    mov     R3, A
    mov     R4, B

    ;--------------------------
    ; hi * hi
    ;--------------------------
    mov     A, R2
    mov     B, R2
    mul     AB
    mov     R5, A
    mov     R6, B

    ;--------------------------
    ; lo * hi  (store in R7:R0)
    ;--------------------------
    mov     A, R1
    mov     B, R2
    mul     AB
    mov     R0, A ; tmp_lo
    mov     R7, B ; tmp_hi

    ;--------------------------
    ; add first copy
    ;--------------------------
    clr     C
    mov     A, R4
    add     A, R0
    mov     R4, A

    mov     A, R5
    addc    A, R7
    mov     R5, A

    mov     A, R6
    addc    A, #0
    mov     R6, A

    ;--------------------------
    ; add second copy
    ;--------------------------
    clr     C
    mov     A, R4
    add     A, R0
    mov     R4, A

    mov     A, R5
    addc    A, R7
    mov     R5, A

    mov     A, R6
    addc    A, #0
    mov     R6, A

    ret

;-----------------------------------------
; Calculate modulo M (16-bit value) of a 32-bit value A.
; A mod M = Remainder
; In:   R4:R3:R2:R1 = a_3:a_2:a_1:a_0
;       m_hi:m_lo
; Out:  rem_hi:rem_lo
;-----------------------------------------
mod32_16:
    push    0

    ; initialize remainder with 0
    mov     rem_lo, #0
    mov     rem_hi, #0
    mov     rem_ext, #0

    mov     R7, #32 ; iterate over every bit of dividend

    mod_loop:
    ; remainder <<= 1
    ; -----------------------
    mov     sl_0, rem_lo
    mov     sl_1, rem_hi
    lcall   shiftleft32
    mov     rem_lo, sl_0
    mov     rem_hi, sl_1
    mov     rem_ext, sl_2

    ; remainder_lo |= get_bit(dividend, bit)
    ; -----------------------
    mov     A, R7
    dec     A
    lcall   get_bit32 ; bit value is stored in A
    orl     A, rem_lo
    mov     rem_lo, A

    ; if remainder >= M then remainder -= M
    ; -----------------------
    mov     A, rem_ext
    anl     A, #01h
    jnz     sub_m

    push 0
    push 1
    push 2
    push 3

    mov     R0, rem_lo
    mov     R1, rem_hi
    mov     R2, m_lo
    mov     R3, m_hi
    lcall   cmp16_ge

    pop 3
    pop 2
    pop 1
    pop 0

    jz      skip_sub_m

    sub_m:
    push 0
    push 1
    push 2
    push 3
    push 4
    push 5

    mov     R0, rem_lo
    mov     R1, rem_hi
    mov     R2, m_lo
    mov     R3, m_hi
    lcall   sub16 ; final result in in R5:R4
    mov     rem_lo, R4
    mov     rem_hi, R5
    mov     rem_ext, #0

    pop 5
    pop 4
    pop 3
    pop 2
    pop 1
    pop 0

    skip_sub_m:
    djnz    R7, mod_loop

    pop     0
    ret

;-----------------------------------------
; Fast modulo: 32-bit A mod 16-bit M
; using 8-bit hardware DIV
;
; In:   R4:R3:R2:R1 = a3:a2:a1:a0
;       m_hi:m_lo
; Out:  rem_hi:rem_lo
;-----------------------------------------
mod32_16_div8:

    mov     rem_lo, #0
    mov     rem_hi, #0

    mov     R6, #4 ; 4 bytes
    mov     R0, #4 ; pointer to MSB (R4)

    mod_div8_loop:
    ; r <<= 8, r |= next byte
    mov     rem_hi, rem_lo
    mov     rem_lo, @R0
    dec     R0

    ; --- approximate division ---
    mov     A, rem_hi
    mov     B, m_hi
    jz      mod_skip_div    ; safety (should not happen)

    div     AB              ; A = q, B = rem
    mov     q, A

    ; --- tmp = q * M ---
    mov     A, q
    mov     B, m_lo
    mul     AB
    mov     tmp_lo, A
    mov     tmp_hi, B

    mov     A, q
    mov     B, m_hi
    mul     AB
    add     A, tmp_hi
    mov     tmp_hi, A

    ; --- r -= tmp ---
    clr     C
    mov     A, rem_lo
    subb    A, tmp_lo
    mov     rem_lo, A

    mov     A, rem_hi
    subb    A, tmp_hi
    mov     rem_hi, A

    ; --- correction if negative ---
    jnc     mod_ok

    ; r += M
    mov     A, rem_lo
    add     A, m_lo
    mov     rem_lo, A

    mov     A, rem_hi
    addc    A, m_hi
    mov     rem_hi, A

    mod_ok:
    mod_skip_div:
    djnz    R6, mod_div8_loop

    ret

;-----------------------------------------
; Shift left 32-bit value.
; In:   sl_3:sl_2:sl_1:sl_0
; Out:  sl_3:sl_2sl_1:sl_0 = sl_3:sl_2sl_1:sl_0 << 1
;-----------------------------------------
shiftleft32:
    clr C ; clear carry flag so it is not rotated into the bit0 of lsb
    mov A, sl_0
    rlc A
    mov sl_0, A

    mov A, sl_1
    rlc A
    mov sl_1, A

    mov A, sl_2
    rlc A
    mov sl_2, A

    mov A, sl_3
    rlc A
    mov sl_3, A

    ret

;-----------------------------------------
; shift right 16-bit value
; in:   R1:R0 = a_hi:a_lo
; out:  R1:R0 = (a_hi:a_lo) >> 1
;-----------------------------------------
; important note:
; if needed, carry flag must be explicitly cleared before shifting operation
;-----------------------------------------
shiftright16:
    mov     A, R1
    rrc     A
    mov     R1, A

    mov     A, R0
    rrc     A
    mov     R0, A

    ret

;-----------------------------------------
; shift right x times
; in:   A
;       R0 = x
; out:  A = A >> x
;-----------------------------------------
shiftright_x_times:
    push    0

    xch     A, R0
    jz      shiftright_0_times
    xch     A, R0

    shift_loop:
    clr     C
    rrc     A
    djnz    R0, shift_loop

    xch     A, R0
    shiftright_0_times:
    xch     A, R0

    pop 0

    ret

;-----------------------------------------
; Convert a 16-bit value into Montgomery's space.
; A * R mod M, where R = 2^k and k - n_bits of M
; In:   R4:R3:R2:R1 = 0:0:a_hi:a_lo
;       m_hi:m_lo
; Out:  R2:R1 = _(a_hi:a_lo)
;-----------------------------------------
montgomery_convert_in16:
    ; get bit count of modulus into R7
    push    1
    push    2
    mov     R1, m_lo
    mov     R2, m_hi
    lcall   get_bit_cnt16
    pop     2
    pop     1
    mov     R7, A

    mov     R3, #0
    mov     R4, #0

    shift_loop_mont:
    mov     sl_0, R1
    mov     sl_1, R2
    mov     sl_2, R3
    mov     sl_3, R4
    lcall   shiftleft32
    mov     R1, sl_0
    mov     R2, sl_1
    mov     R3, sl_2
    mov     R4, sl_3

    djnz    R7, shift_loop_mont

    lcall   mod32_16
    mov     R1, rem_lo
    mov     R2, rem_hi

    ret

;-----------------------------------------
; Convert a 16-bit value out of Montgomery's space.
; In:   R2:R1 = _(a_hi:a_lo)
;       m_hi:m_lo
; Out:  R2:R1 = a_hi:a_lo
;-----------------------------------------
; Note:
; Montgomery conversion preserves values modulo M.
; convert_out(convert_in(a)) returns (a mod M),
; not the original integer if a >= M.
;-----------------------------------------
montgomery_convert_out16:
    mov     a_lo, R1
    mov     a_hi, R2
    mov     b_lo, #01h
    mov     b_hi, #00h
    lcall   montgomery_pro16
    mov     R1, result_0
    mov     R2, result_1

    ret

; ---------------------------------------------------------
; Calculate the Montgomery product of the M-residues of two numbers.
;
; _U = _A * _B * R⁻¹ (mod M)
;
; In:   a_hi:a_lo }
;       b_hi:b_lo } RAM addresses
;       m_hi:m_lo }
; Out:  result_1:result_0 = _U
;-----------------------------------------
; Important notes:
;
; 1) The result is also an M-residue and thus must be converted out
; of Montgomery space to obtain the natural value.
;
; 2) During Montgomery multiplication the intermediate "result"
; may exceed 16 bits due to additions:
;   result += B and result += M.
;
; result_2 stores carry-out bits beyond bit15 (bits 16-17),
; preserving full intermediate precision.
;
; Before each right shift of result_1:result_0, result_2 is also shifted and because of the fact,
; that LSB bit is shifted into Carry, a correct logical (n+1)-bit shift is ensured.
;
; Without result_2, MSBs would be lost and the algorithm
; would produce incorrect results.
; ---------------------------------------------------------
montgomery_pro16:
    push    0
    push    1
    push    2
    push    3
    push    4
    push    5
    push    7

    ; initialize result with 0
    mov     result_0, #0
    mov     result_1, #0
    mov     result_2, #0

    ; get bit count of modulus into R7
    push    1
    push    2
    mov     R1, m_lo
    mov     R2, m_hi
    lcall   get_bit_cnt16
    pop     2
    pop     1
    mov     R7, A

    mont_loop:

    ; if (A & 1) result += B
    ; -----------------------
    mov     A, a_lo
    anl     A, #01h
    jz      skip_add_b
    ; result += B
    mov     R0, result_0
    mov     R1, result_1
    mov     R2, b_lo
    mov     R3, b_hi
    lcall   add16
    mov     result_0, R4
    mov     result_1, R5
    jnc     no_carry1
    inc     result_2
    no_carry1:

    skip_add_b:

    ; if (result & 1) result += M
    ; ----------------------------
    mov     A, result_0
    anl     A, #01h
    jz      skip_add_m

    ;result += M
    mov     R0, result_0
    mov     R1, result_1
    mov     R2, m_lo
    mov     R3, m_hi
    lcall   add16
    mov     result_0, R4
    mov     result_1, R5
    jnc     no_carry2
    inc     result_2
    no_carry2:

    skip_add_m:

    ; result >>= 1
    ; -------------
    mov     R0, result_0
    mov     R1, result_1
    ; shift bit17 into bit16 and bit16 into result_1
    clr     C
    mov     A, result_2
    rrc     A
    mov     result_2, A
    lcall   shiftright16
    mov     result_0, R0
    mov     result_1, R1

    ; A >>= 1
    ; --------
    clr     C
    mov     R0, a_lo
    mov     R1, a_hi
    lcall   shiftright16
    mov     a_lo, R0
    mov     a_hi, R1

    clr     C ; clear Carry after each iteration
    djnz    R7, mont_loop

    ; if result >= M then result -= M
    ; -------------------------------
    mov     R0, result_0
    mov     R1, result_1
    mov     R2, m_lo
    mov     R3, m_hi
    lcall   cmp16_ge
    jz      montgomery_pro16_done

    lcall   sub16 ; final result in in R5:R4
    mov     result_0, R4
    mov     result_1, R5

    montgomery_pro16_done:
    pop     7
    pop     5
    pop     4
    pop     3
    pop     2
    pop     1
    pop     0
    ret

; ---------------------------------------------------------
; Calculate the product of two 16-bit numbers modulo M using Montgomery reduction algorithm.
;
; U = A * B (mod M)
;
; In:   R2:R1 = a_hi:a_lo
;       R4:R3 = b_hi:b_lo
;       m_hi:m_lo
; Out:  R6:R5 = u_hi:u_lo
;-----------------------------------------
; Important note:
; The Montgomery reduction algorithm requires that R and M be relatively prime,
; i.e., gcd(R, M) = gcd(2^k, M) = 1. This requirement is satisfied if n is odd.
;-----------------------------------------
montgomery_mul16:
    ; convert A into Montgomery representation -> R2:R1 = _A
    push    3
    push    4
    lcall   montgomery_convert_in16
    pop     4
    pop     3

    ; convert B into Montgomery representation -> R4:R3 = _B
    push    1
    push    2
    mov     A, R3
    mov     R1, A
    mov     A, R4
    mov     R2, A
    push    3
    push    4
    lcall   montgomery_convert_in16
    pop     4
    pop     3
    mov     A, R1
    mov     R3, A
    mov     A, R2
    mov     R4, A
    pop     2
    pop     1

    ; _U = MonPro(_A,_B)
    mov     a_lo, R1
    mov     a_hi, R2
    mov     b_lo, R3
    mov     b_hi, R4
    lcall   montgomery_pro16

    ; _U -> U
    ; convert _U out of Montgomery representation -> R6:R5 = U
    push    1
    push    2
    mov     R1, result_0
    mov     R2, result_1
    lcall   montgomery_convert_out16
    mov     A, R1
    mov     R5, A
    mov     A, R2
    mov     R6, A
    pop     2
    pop     1

    ret

; ---------------------------------------------------------
; Calculate the modular exponentiation of a 16-bit value (where exponent and modulus are also 16-bit values).
;
; X = A^e mod M
;
; In:   R2:R1 = a_hi:a_lo
;       R4:R3 = e_hi:e_lo
;       m_hi:m_lo
; Out:  R6:R5 = x_hi:x_lo
;-----------------------------------------
mod_exp16:
    ; set ext GPIO0 high
    mov     DPTR, #GPIO_ext
    mov     A, #01h
	movx    @DPTR, A

    ; 1) _a = mont_convert_in(a, m)
    ; -----------------------
    push    3
    push    4
    lcall   montgomery_convert_in16
    pop     4
    pop     3

    ; 2) _x = mont_convert_in(1, m)
    ; -----------------------
    push    1
    push    2
    mov     R1, #01h
    mov     R2, #00h
    push    3
    push    4
    lcall   montgomery_convert_in16
    pop     4
    pop     3
    mov     A, R1
    mov     x_lo, A
    mov     A, R2
    mov     x_hi, A
    pop     2
    pop     1

    ; 3) n_bits = get_bits_cnt(e)
    ; -----------------------
    push    1
    push    2
    mov     A, R3
    mov     R1, A
    mov     A, R4
    mov     R2, A
    lcall   get_bit_cnt16
    pop     2
    pop     1
    mov     R7, A
    jz      modexp_exp_zero

    ; 4) square and multiply loop
    ; -----------------------
    mod_exp_loop:
    ; set ext GPIO0-2 high
    mov     DPTR, #GPIO_ext
    mov     A, #07h
	movx    @DPTR, A

    ; _x = mont_pro(_x, _x, m)
    ; -----------------------
    mov     a_lo, x_lo
    mov     a_hi, x_hi
    mov     b_lo, x_lo
    mov     b_hi, x_hi
    lcall   montgomery_pro16
    mov     x_lo, result_0
    mov     x_hi, result_1

    ; set ext GPIO2 low and keep GPIO0-1 high
    mov     DPTR, #GPIO_ext
    mov     A, #03h
	movx    @DPTR, A

    ; check exponent bit
    push    1
    push    2
    mov     A, R3
    mov     R1, A
    mov     A, R4
    mov     R2, A
    mov     A, R7
    dec     A
    lcall   get_bit32
    pop     2
    pop     1
    jz      skip_mul_a

    ; set ext GPIO3 high and keep GPIO0-1 high
    mov     DPTR, #GPIO_ext
    mov     A, #0Bh
	movx    @DPTR, A

    ;_x = mont_pro(_a, _x, m)
    ; -----------------------
    mov     a_lo, R1
    mov     a_hi, R2
    mov     b_lo, result_0
    mov     b_hi, result_1
    lcall   montgomery_pro16
    mov     x_lo, result_0
    mov     x_hi, result_1

    ; set ext GPIO1,3 low and keep GPIO0 high
    mov     DPTR, #GPIO_ext
    mov     A, #01h
	movx    @DPTR, A

    skip_mul_a:
    djnz    R7, mod_exp_loop

    ; 5) x = mont_convert_out(_x, m)
    ; -----------------------
    modexp_exp_zero:
    push    1
    push    2
    mov     R1, x_lo
    mov     R2, x_hi
    lcall   montgomery_convert_out16
    mov     A, R1
    mov     x_lo, A
    mov     A, R2
    mov     x_hi, A
    pop     2
    pop     1

    mov     R5, x_lo
    mov     R6, x_hi

    ; set ext GPIO0-1 low
    mov     DPTR, #GPIO_ext
    mov     A, #0
	movx    @DPTR, A

    ret

; ---------------------------------------------------------
; cmp16_ge
; in:   R1:R0 = a_hi:a_lo
;       R3:R2 = b_hi:b_lo
; out:  A = 1 if a >= b, 0 if a < b
; ---------------------------------------------------------
cmp16_ge:
    push    0
    push    1
    push    2
    push    3

    ; compare high bytes
    mov     A, R1
    mov     cmp_var, R3
    cjne    A, cmp_var, check_hi_diff
    ; compare low bytes
    mov     A, R0
    mov     cmp_var, R2
    cjne    A, cmp_var, check_lo_diff
    ; if both bytes are equal
    mov     A, #1
    ljmp    cmp16_ge_done

    check_hi_diff:
    jc      a_less ; if carry flag is set, second operand is greater
    mov     A, #1
    ljmp    cmp16_ge_done

    check_lo_diff:
    jc      a_less ; if carry flag is set, second operand is greater
    mov     A, #1
    ljmp    cmp16_ge_done

    a_less:
    mov     A, #0

    cmp16_ge_done:
    pop     3
    pop     2
    pop     1
    pop     0

    ret
    
; ---------------------------------------------------------
; Get the bit count (MSB index + 1) of a 16-bit value.
; In:   R2:R1 = a_hi:a_lo
; Out:  A
; ---------------------------------------------------------
get_bit_cnt16:
    push 7

    ; set initial bit count value to 0
    mov     R7, #0
    mov     A, R1
    orl     A, R2
    jz      get_bit_cnt16_done ; return if all bytes are zeros

    ; check if R2 != 0
    mov     A, R2
    jnz     msb_in_hi

    msb_in_lo:
    mov     R7, #9 ; max bit count is 8
    mov     A, R1

    find_msb_lo:
    dec     R7
    clr     C
    rlc     A
    jnc     find_msb_lo ; until bit7 == 0

    ljmp    get_bit_cnt16_done

    msb_in_hi:
    mov     R7, #17 ; max bit count is 16
    mov     A, R2

    find_msb_hi:
    dec     R7
    clr     C
    rlc     A
    jnc     find_msb_hi

    get_bit_cnt16_done:
    mov     A, R7
    pop     7
    ret

; ---------------------------------------------------------
; Get the value of the bit on given index of a 32-bit value.
; In:   A = bit index (0..31)
;       R4:R3:R2:R1 = 32-bit value
; Out:  A = 0 or 1
; ---------------------------------------------------------
; Warning:
; It is not checked if index exceeds 31 value.
; ---------------------------------------------------------
get_bit32:
    push    0

    ; if A > 31 return 0
    ; ------------------------
    ; mov     R0, A
    ; anl     A, #0C0h
    ; jz      index_in_range
    ; mov     A, #0
    ; pop     0
    ; ret

    index_in_range:
    ; mov     A, R0
    ; divide the index by 8 to get the byte index (quotient in A)
    ; and relative bit index (remainder in B)
    mov     B, #8
    div     AB

    ; (a[byte_i] >> bit_i) & 1
    ; ------------------------
    add     A, #1 ; byte0 is under R1 so base must be adjusted by adding 1 (in case of reg bank 0)
    mov     R0, A
    mov     A, @R0 ; it is assumed that register bank 0 is used
    mov     R0, B
    lcall   shiftright_x_times

    anl     A, #1

    pop     0

    ret

; ---------------------------------------------------------
;
; TESTS
;
; ---------------------------------------------------------
    ASSERT32 MACRO exp_3, exp_2, exp_1, exp_0, res_3, res_2, res_1, res_0
        inc     assert_cnt
        mov     R7, assert_cnt
        mov     A, res_0
        cjne    A, #exp_0, ASSERT_FAIL_1
        mov     A, res_1
        cjne    A, #exp_1, ASSERT_FAIL_1
        mov     A, res_2
        cjne    A, #exp_2, ASSERT_FAIL_1
        mov     A, res_3
        cjne    A, #exp_3, ASSERT_FAIL_1
    ENDM

test_square16:
    ; ------------
    ; test case 1
    ; ------------
    ; A = 0x0004
    ; expected:
    ; P = 0x00000010 = 16
    ; --------------------------------
    mov     R1, #04h
    mov     R2, #00h
    lcall   square16
    ASSERT32 00h, 00h, 00h, 10h, R6, R5, R4, R3

    ; ------------
    ; test case 2
    ; ------------
    ; A = 0x0005
    ; expected:
    ; P = 0x00000019 = 25
    ; --------------------------------
    mov     R1, #05h
    mov     R2, #00h
    lcall   square16
    ASSERT32 00h, 00h, 00h, 19h, R6, R5, R4, R3

    ; ------------
    ; test case 3
    ; ------------
    ; A = 0x00FF
    ; expected:
    ; P = 0x00FE01 = 65025
    ; --------------------------------
    ; mov     R1, #0FFh
    ; mov     R2, #00h
    ; lcall   square16
    ; ASSERT32 00h, 00h, 0FEh, 01h, R6, R5, R4, R3

    ; ------------
    ; test case 4
    ; ------------
    ; A = 0x1234
    ; expected:
    ; P = 0x014B5A90
    ; --------------------------------
    ; mov     R1, #34h
    ; mov     R2, #12h
    ; lcall   square16
    ; ASSERT32 01h, 4Bh, 5Ah, 90h, R6, R5, R4, R3

ASSERT_FAIL_1:
    sjmp    ASSERT_FAIL_1

END
