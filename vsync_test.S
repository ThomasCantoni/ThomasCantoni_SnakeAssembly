;   this program fills the CRT page with random byte values and then inverts them once every second
;   when the vsync interrupt fires


.org $8000

bruh:
    .db $17

start:
    LDX #$FF    ; number to clear stack
    TXS         ; transfer x to stack
    LDA #05     ;
    STA $05    
    LDA #0
    STA $00
    LDY #0
    LDA #0      
    LDX #0
    LDA	r_seed		; get seed
    STA $0701
    LDX #0
    STX $010F
    LDA bruh
    JSR LoadRandomScreen
    LDA #0
    ;STA $0210

    



clear_zero_page_loop:
    STA $06,X
    INX
    BNE clear_zero_page_loop

prepare_Vsync:
    LDX #0
    LDA VsyncCounter,X
    
    STA $0069
    LDA #00

game_loop:
   
JMP game_loop






; VsyncCounter is in $0069
nmi:
    DEC $0069
    BEQ reset_vsync
    RTI

reset_vsync:
    LDX #0
    LDA VsyncCounter,X
    STA $0069
    LDA $0203 ; load the current pixel
    EOR #$FF ; invert it
    STA $0203 ; store it again
    LDX #0
    JSR InvertScreenColor
    RTI


random_test:

    rand_8:
        LDA $0701 ;this is the seed location
        AND	#$B8		; mask non feedback bits
                        ; for maximal length run with 8 bits we need
                        ; taps at b7, b5, b4 and b3
        LDX	#$05		; bit count (shift top 5 bits)
        LDY	#$00		; clear feedback count

    F_loop:
        ASL	A		    ; shift bit into carry
        BCC	bit_clr		; branch if bit = 0

        INY			    ; increment feedback count (b0 is XOR all the
                        ; shifted bits from A)

    bit_clr:
        DEX			    ; decrement count
        BNE	F_loop		; loop if not all done

    no_clr:
        TYA			    ; copy feedback count
        LSR	A		    ; bit 0 into Cb
        LDA	$0701		; get seed back
        ROL	A		    ; rotate carry into byte
        STA	$0701		; save number as next seed
        RTS			    ; done


r_seed:
    .db	$1		; prng seed byte (must not be zero)

VsyncCounter:
    .db $3C

LoadRandomScreen:

    JSR random_test 
    LDX $010F
    STA $0200,X
    INX
    STX $010F
    BNE LoadRandomScreen
    RTS

InvertScreenColor:

    LDA $0200,X; load the current pixel
    EOR #$FF ; invert it
    STA $0200,X ; store it again
    INX
    BNE InvertScreenColor
    RTS

.goto $FFFA
.dw nmi
.dw start
.dw start


