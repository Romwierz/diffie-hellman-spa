; Monitor Firmware is placed in the beginning of the program address space (from 0000h to 1FFFh)
; so the actual user's program must be placed at the address 8000h.
; The program below actually starts at the address 8500h because lower memory region
; is also used by the interrupt vectors.

    ASSERT16 MACRO exp_hi, exp_lo, reg_hi, reg_lo
        inc     ass_cnt
        mov     R7, ass_cnt
        mov     A, reg_lo
        cjne    A, #exp_lo, ASSERT_FAIL
        mov     A, reg_hi
        cjne    A, #exp_hi, ASSERT_FAIL
    ENDM

    ; display.LIB code starts from adress 9800h and uses 40h-4ah memory region of RAM
    EXTRN code(init_LCD,LCD_XY,zapisz_string_LCD,dispACC_LCD)

    ORG 8000h
    jmp main
    ORG 8500h

    ; variables to use in montgomery multiplication
    a_lo        EQU 20h
    a_hi        EQU 21h
    b_lo        EQU 22h
    b_hi        EQU 23h
    m_lo        EQU 24h
    m_hi        EQU 25h
    result_lo   EQU 26h
    result_hi   EQU 27h
    result_ext  EQU 28h ; for bits b17 and b16 of the result

    ; variable to use in cmp_ge16 subroutine
    cmp_var     EQU 29h

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
    ass_cnt     EQU 37h

main:
    lcall   init_LCD

    mov     A, R4
    lcall   dispACC_LCD

    ; initialize ASSERT counter
    mov     ass_cnt, #0

    ; test case 1
    ; -----------
    ; a = 0x04D2
    ; m = 0x0015
    ; ā = (1234 * 32) mod 21 = 0x0008
    ; convert_out(ā) = 0x0010 = 0x04D2 mod 0x15
    ; -----------
    mov     R1, #0D2h
    mov     R2, #04h
    mov     m_lo, #15h
    mov     m_hi, #00h
    lcall   montgomery_convert_in16 ; expected: R2:R1 = 0x0008
    ASSERT16 00h, 08h, R2, R1
    lcall   montgomery_convert_out16 ; expected: R2:R1 = 0x0010
    ASSERT16 00h, 10h, R2, R1

    ; test case 2
    ; -----------
    ; a = 0x0007
    ; m = 0x0015
    ; ā = (7 * 32) mod 21 = 0x000E
    ; convert_out(ā) = 0x0007 = 0x0007 mod 0x0015
    ; -----------
    mov     R1, #07h
    mov     R2, #00h
    mov     m_lo, #15h
    mov     m_hi, #00h
    lcall   montgomery_convert_in16 ; expected: R2:R1 = 0x000E
    ASSERT16 00h, 0Eh, R2, R1
    lcall   montgomery_convert_out16 ; expected: R2:R1 = 0x0007
    ASSERT16 00h, 07h, R2, R1

    ; test case 3
    ; -----------
    ; a = 0x0014 = 20
    ; m = 0x0015 = 21
    ; ā = (20 * 32) mod 21 = 0x000A
    ; convert_out(ā) = 0x0014 = 0x0014 mod 0x0015
    ; -----------
    mov     R1, #14h
    mov     R2, #00h
    mov     m_lo, #15h
    mov     m_hi, #00h
    lcall   montgomery_convert_in16 ; expected: R2:R1 = 0x000A
    ASSERT16 00h, 0Ah, R2, R1
    lcall   montgomery_convert_out16 ; expected: R2:R1 = 0x0014
    ASSERT16 00h, 14h, R2, R1

    ; test case 4
    ; -----------
    ; a = 0x1234 = 4660
    ; m = 0x00F7 = 247
    ; R = 2^8 = 256
    ; ā = (4660 * 256) mod 247 = 0x00C5
    ; convert_out(ā) = 0x00D6 = 0x1234 mod 0x00F7
    ; -----------
    mov     R1, #34h
    mov     R2, #12h
    mov     m_lo, #0F7h
    mov     m_hi, #00h
    lcall   montgomery_convert_in16 ; expected: R2:R1 = 0x00C5
    ASSERT16 00h, 0C5h, R2, R1
    lcall   montgomery_convert_out16 ; expected: R2:R1 = 0x00D6
    ASSERT16 00h, 0D6h, R2, R1

    jmp     $

ASSERT_FAIL:
    sjmp ASSERT_FAIL

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
    lcall   get_bit_cnt16
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
    mov     R1, result_lo
    mov     R2, result_hi

    ret

; ---------------------------------------------------------
; Calculate the Montgomery product of the M-residues of two numbers.
;
; _U = _A * _B * R⁻¹ (mod M)
;
; In:   a_hi:a_lo }
;       b_hi:b_lo } RAM addresses
;       m_hi:m_lo }
; Out:  result_hi:result_lo = _U
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
; result_ext stores carry-out bits beyond bit15 (bits 16-17),
; preserving full intermediate precision.
;
; Before each right shift of result_hi:result_lo, result_ext is also shifted and because of the fact,
; that LSB bit is shifted into Carry, a correct logical (n+1)-bit shift is ensured.
;
; Without result_ext, MSBs would be lost and the algorithm
; would produce incorrect results.
; ---------------------------------------------------------
montgomery_pro16:
    ; initialize result with 0
    mov     result_lo, #0
    mov     result_hi, #0
    mov     result_ext, #0

    ; get bit count of modulus into R7
    lcall   get_bit_cnt16
    mov     R7, A

    mont_loop:

    ; if (A & 1) result += B
    ; -----------------------
    mov     A, a_lo
    anl     A, #01h
    jz      skip_add_b
    ; result += B
    mov     R0, result_lo
    mov     R1, result_hi
    mov     R2, b_lo
    mov     R3, b_hi
    lcall   add16
    mov     result_lo, R4
    mov     result_hi, R5
    jnc     no_carry1
    inc     result_ext
    no_carry1:

    skip_add_b:

    ; if (result & 1) result += M
    ; ----------------------------
    mov     A, result_lo
    anl     A, #01h
    jz      skip_add_m

    ;result += M
    mov     R0, result_lo
    mov     R1, result_hi
    mov     R2, m_lo
    mov     R3, m_hi
    lcall   add16
    mov     result_lo, R4
    mov     result_hi, R5
    jnc     no_carry2
    inc     result_ext
    no_carry2:

    skip_add_m:

    ; result >>= 1
    ; -------------
    mov     R0, result_lo
    mov     R1, result_hi
    ; shift bit17 into bit16 and bit16 into result_hi
    clr     C
    mov     A, result_ext
    rrc     A
    mov     result_ext, A
    lcall   shiftright16
    mov     result_lo, R0
    mov     result_hi, R1

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
    mov     R0, result_lo
    mov     R1, result_hi
    mov     R2, m_lo
    mov     R3, m_hi
    lcall   cmp16_ge
    jz      montgomery_pro16_done

    lcall   sub16 ; final result in in R5:R4
    mov     result_lo, R4
    mov     result_hi, R5

    montgomery_pro16_done:
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
; get_bit_cnt16
; in:   m_lo, m_hi
; out:  A = number of bits (MSB index + 1)
; ---------------------------------------------------------
get_bit_cnt16:
    push 7

    ; set initial bit count value to 0
    mov     R7, #0
    mov     A, m_lo
    orl     A, m_hi
    jz      get_bit_cnt16_done ; return if all bytes are zeros

    ; check if m_hi != 0
    mov     A, m_hi
    jnz     msb_in_hi

    msb_in_lo:
    mov     R7, #9 ; max bit count is 8
    mov     A, m_lo

    find_msb_lo:
    dec     R7
    clr     C
    rlc     A
    jnc     find_msb_lo ; until bit7 == 0

    ljmp    get_bit_cnt16_done

    msb_in_hi:
    mov     R7, #17 ; max bit count is 16
    mov     A, m_hi

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

END
