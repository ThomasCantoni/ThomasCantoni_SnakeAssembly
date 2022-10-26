.org $8000

.define Player_X $06
.define Player_Y $07
.define PlayerPosition $08
.define HeadPosition $09
.define TailPosition $0A
.define PositionQueueIndex $0B

.define Points $10
.define FruitColor $11
.define NextPosition $12
.define FruitPosition $13
.define NMI_PeriodMOVE $0C
.define NMI_PeriodCLEAR $0D

.define CanMoveBool $0E

NMI_MOVE_VALUE:
    .db	$10		; prng seed byte (must not be zero)
NMI_CLEAR_VALUE:
    .db	$1		; prng seed byte (must not be zero)
start:
    LDX #$FF    ; number of clear stack
    TXS         ; transfer x to stack
    LDA #05     ;
    STA $05    
    
    LDA NMI_MOVE_VALUE
    STA NMI_PeriodMOVE  
    LDA NMI_CLEAR_VALUE
    STA NMI_PeriodCLEAR 
    JSR clear_crt
    LDX #0
    LDA #0
    JSR clear_zero_page_loop
    LDA #27
    STA FruitColor  
    LDA r_seed
    
    STA $0701
    JSR LoadFruit
    JSR draw_elements
    
    LDX #0 ; starting x point of the dot
    STX $06
    LDX #0 ; starting y point of the dot
    STX $07
    
    LDX #1   ; increase y = go up
    STX $00
    LDX #2   ; decrease y = go down
    STX $01
    LDX #4   ; decrease x = go left
    STX $02
    LDX #8   ; increase x = go right
    STX $03

    LDA #05     ;
    STA $05 
    
    
    JMP game_loop

clear_zero_page_loop:
    STA $06,X
    INX
    BNE clear_zero_page_loop
    RTS
NMI:
    ; ;CHECK_NMI_CLEAR:
    ;     ;DEC NMI_PeriodCLEAR
    ;     ;BNE CHECK_NMI_MOVE

    ;     NMI_Clear_Expired:
    ;         JSR clear_crt
    ;         JSR draw_elements
    ;         LDA NMI_CLEAR_VALUE
    ;         STA NMI_PeriodCLEAR
    ;         ;JMP end_NMI


    CHECK_NMI_MOVE:
        DEC NMI_PeriodMOVE
        BNE end_NMI

        NMI_Move_Expired:
            LDA #1
            STA CanMoveBool
            LDA NMI_MOVE_VALUE
            STA NMI_PeriodMOVE


        
    end_NMI:
        RTI
clear_crt:
    LDX #0
    LDA #0
    loop_clear:
        STA $0200,X
        INX
        BNE loop_clear
    ; STA $06,X
    ; INX
    ; BNE clear_crt
    RTS

draw_elements:
    LDX FruitPosition
    LDA FruitColor
    STA $0200,X
    RTS
LoadFruit:
    JSR random_test
    STA FruitPosition
    TAX 
    LDA FruitColor
    STA $0200,X
    RTS

game_loop:
      
    LDA CanMoveBool
    CMP #1
    BNE game_loop
    LDA $4000
    CMP $00
    BEQ move_up
    LDA $4000
    CMP $01
    BEQ move_down
    LDA $4000
    CMP $02
    BEQ move_left
    LDA $4000
    CMP $03
    BEQ move_right
    JMP game_loop


move_up:
    ;JSR removePreviousCell
    JSR RecordPositionInQueue
    SEC
    LDA Player_Y
    SBC #1
    STA Player_Y
    JSR clear_leftmost_halfbyte
    CLC
    JMP OnMove

move_down:
    ;JSR removePreviousCell
    JSR RecordPositionInQueue
    CLC
    LDA Player_Y
    ADC #1
    SEC
    JSR clear_leftmost_halfbyte
    STA Player_Y
    CLC
    JMP OnMove

move_left:
    ;JSR removePreviousCell
    JSR RecordPositionInQueue
    SEC
    LDA Player_X
    SBC #1
    JSR clear_leftmost_halfbyte
    STA Player_X
    CLC
    JMP OnMove

move_right:
    ;JSR removePreviousCell
    JSR RecordPositionInQueue
    CLC
    LDA Player_X
    ADC #1
    JSR clear_leftmost_halfbyte
    STA Player_X
    JMP OnMove

OnMove:
    JSR calculate_position
        STA NextPosition
        JSR CheckFruit
    
        
        JMP colorPosition
colorPosition:
    JSR clear_crt     
    JSR draw_elements
    LDA #0
    STA CanMoveBool
    ;JSR clear_crt
    ;JSR draw_elements
    LDA $05 ;color of player
    LDX PlayerPosition
    STA $0200,X
   
    LDX Points
    ;DEX
    CPX #0
    BEQ end_ColorPosition
    

    LDX Points
    STX $0400 ;temporary variable
    LDX PositionQueueIndex
    DEX
    LoopColor:
        LDA $05 ;color of player
        LDY $0300,X
        STA $0200,Y
        DEX
        LDA $0400
        SBC #1
        STA $0400
        BNE LoopColor
        
    end_ColorPosition:
        JMP game_loop

calculate_position:
    CLC     ;otherwise cell is not cleared properly
    
    LDX PlayerPosition
   
    LDA #0  
    ADC Player_Y
    ASL A
    ASL A
    ASL A
    ASL A
    ADC Player_X
    STA PlayerPosition    ; momentarily store Accumulator's value in a new address to move it to X
    ;LDX PlayerPosition     ; i read A's value and move it to x
    RTS

clear_leftmost_halfbyte:        
        ; I DO THIS TO PREVENT INACCURATE MOVEMENT AND SQUARE MOVING DOWN/UP ON HORIZONTAL OVERFLOW
        ; when i move, i am adding numbers to either $06 or $07 , when i reach 16 it counts up a digit so the square goes up or down
        ; in order to prevent this i just clear the most significative nibble with shifting all bits left then back to the right
    ASL A
    ASL A
    ASL A
    ASL A
    LSR A
    LSR A
    LSR A
    LSR A
    RTS

;removePreviousCell:
    ; JSR calculate_position
    ; LDA #0
    ; STA $0200,X
    ; JMP endRPC

    ; LDX #0
    ; CLC
    ; LDA PlayerPosition
    ; loopRegion: ; store position
    ; ADC #1
    ; STA $0300,X
    ; INX
    ; CPX Points
    ; BEQ loopRegion
    
    
    ; endRPC:
    ; RTS


CheckFruit:
    
    LDX PlayerPosition
    LDA $0200,X
    CMP FruitColor
    BEQ OnFruitPickUp
    RTS

OnFruitPickUp:
    INC Points

    LDY FruitPosition
    LDA $05
    STA $0200,Y
    LDX Points
    LDA FruitPosition
    STA $0300,X
    JSR LoadFruit
    RTS

RecordPositionInQueue:
    
    LDX PositionQueueIndex
    ;CPX Points
    ;BEQ ResetIndex
    
    ;RPIQ_loop_Start:
    
        LDA PlayerPosition
        STA $0300,X
        INX
        STX PositionQueueIndex
        
        BEQ ResetIndex
        JMP END_Record
    ResetIndex:
        LDX #0 
        STX PositionQueueIndex

    END_Record:
        RTS
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
    .db	$3		; prng seed byte (must not be zero)
.goto $FFFA
.dw NMI
.dw start
.dw start