; Monitor Firmware is placed in the beginning of the program address space (from 0000h to 1FFFh)
; so the actual user's program must be placed at the address 8000h.
; The program below actually starts at the address 8500h because lower memory region
; is also used by the interrupt vectors.

    ; display.LIB code starts from adress 9800h and uses 40h-4ah memory region of RAM
    EXTRN code(init_LCD,LCD_XY,zapisz_string_LCD)

    ORG 8000h
    jmp start
    ORG 8500h

    num1_lo   EQU 20h
    num1_hi   EQU 21h
    num2_lo   EQU 22h
    num2_hi   EQU 23h
    result_lo EQU 24h
    result_hi EQU 25h

start:
    lcall init_LCD

    mov A, #00000000b
    lcall LCD_XY
    mov DPTR, #imie
    lcall zapisz_string_LCD

    mov A, #01000000b
    lcall LCD_XY
    mov DPTR, #nazwisko
    lcall zapisz_string_LCD

    mov num1_lo, #0ffh
    mov num1_hi, #0ffh
    mov num2_lo, #02h
    mov num2_hi, #00h
    lcall add16

    jmp $

imie:
    DB 'bajo#'

nazwisko:
    DB 'jajo#'
	
add16:
    mov A, num1_lo
    add A, num2_lo
    mov result_lo, A

    mov A, num1_hi
    addc A, num2_hi
    mov result_hi, A

    ret

END
