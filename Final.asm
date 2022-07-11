$NOLIST
$MODLP51
$LIST

CLK           EQU 22118400 ; Microcontroller system crystal frequency in Hz
TIMER0_RATE0  EQU ((2048*2)+100)
TIMER0_RATE1  EQU ((2048*2)-100)
TIMER0_RELOAD0 EQU ((65536-(CLK/TIMER0_RATE0)))
TIMER0_RELOAD1 EQU ((65536-(CLK/TIMER0_RATE1)))
TIMER0_RATE2  EQU ((2048*2)-2700)
TIMER0_RATE3  EQU ((2048*2)-2500)
MUSIC1 EQU ((65536-(CLK/TIMER0_RATE2)))
MUSIC2 EQU ((65536-(CLK/TIMER0_RATE3)))
TIMER0_RATE4  EQU ((2048*2)-2300)
TIMER0_RATE5  EQU ((2048*2)-2200)
MUSIC3 EQU ((65536-(CLK/TIMER0_RATE4)))
MUSIC4 EQU ((65536-(CLK/TIMER0_RATE5)))
TIMER0_RATE6  EQU ((2048*2)-2050)
TIMER0_RATE7  EQU ((2048*2)-1750)
MUSIC5 EQU ((65536-(CLK/TIMER0_RATE6)))
MUSIC6 EQU ((65536-(CLK/TIMER0_RATE7)))
TIMER0_RATE8  EQU ((2048*2)-1400)
MUSIC7 EQU ((65536-(CLK/TIMER0_RATE8)))
RandomSeed	  EQU P0.2
SOUND_OUT	  EQU p2.2

org 0000H
   ljmp MyProgram

org 0x010B
	ljmp Timer0_ISR

cseg
; These 'equ' must match the hardware wiring
LCD_RS equ P3.2
;LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P3.3
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P3.6
LCD_D7 equ P3.7

$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$include(math32.inc);

DSEG at 0x30
Period_A: ds 2
Period_B: ds 2
x:		  ds 4
y:		  ds 4
bcd:	  ds 5
PointsA:  ds 1
PointsB:  ds 1
Seed:     ds 4

BSEG
mf:		  dbit 1
toneflag: dbit 1

CSEG
;                      1234567890123456    <- This helps determine the location of the counter
Initial_Message1:  db 'A:           00 ', 0
Initial_Message2:  db 'B:           00 ', 0
Start_Message:     db '  Game Start !  ', 0
EmptyScreen1:      db '                ', 0
player1wins_mess:  db ' PlayerA Wins   ', 0
player2wins_mess:  db ' PlayerB Wins   ', 0  


winner_message1:   db '               C', 0
winner_message2:   db '              CO', 0
winner_message3:   db '             CON', 0
winner_message4:   db '            CONG', 0
winner_message5:   db '           CONGR', 0
winner_message6:   db '          CONGRA', 0
winner_message7:   db '         CONGRAT', 0
winner_message8:   db '        CONGRATU', 0
winner_message9:   db '       CONGRATUL', 0
winner_message10:  db '      CONGRATULA', 0
winner_message11:  db '     CONGRATULAT', 0
winner_message12:  db '    CONGRATULATI', 0
winner_message13:  db '   CONGRATULATIO', 0
winner_message14:  db '  CONGRATULATION', 0
winner_message15:  db ' CONGRATULATION!', 0
winner_message16:  db 'CONGRATULATION!!', 0
winner_message17:  db 'ONGRATULATION!! ', 0
winner_message18:  db 'NGRATULATION!!  ', 0
winner_message19:  db 'GRATULATION!!   ', 0
winner_message20:  db 'RATULATION!!    ', 0
winner_message21:  db 'ATULATION!!     ', 0
winner_message22:  db 'TULATION!!      ', 0
winner_message23:  db 'ULATION!!       ', 0
winner_message24:  db 'LATION!!        ', 0
winner_message25:  db 'ATION!!         ', 0
winner_message26:  db 'TION!!          ', 0
winner_message27:  db 'ION!!           ', 0
winner_message28:  db 'ON!!            ', 0
winner_message29:  db 'N!!             ', 0
winner_message30:  db '!!              ', 0
winner_message31:  db '!               ', 0
; When using a 22.1184MHz crystal in fast mode
; one cycle takes 1.0/22.1184MHz = 45.21123 ns
; (tuned manually to get as close to 1s as possible)
Wait1s:
    mov R2, #176
X3: mov R1, #250
X2: mov R0, #166
X1: djnz R0, X1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, X2 ; 22.51519us*250=5.629ms
    djnz R2, X3 ; 5.629ms*176=1.0s (approximately)
    ret

WaitHalfSec:
    mov R2, #89
L13: mov R1, #250
L12: mov R0, #166
L11: djnz R0, L11 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, L12 ; 22.51519us*250=5.629ms
    djnz R2, L13 ; 5.629ms*89=0.5s (approximately)
    ret

;Initializes timer/counter 2 as a 16-bit timer
InitTimer2:
	mov T2CON, #0b_0000_0000 ; Stop timer/counter.  Set as timer (clock input is pin 22.1184MHz).
	; Set the reload value on overflow to zero (just in case is not zero)
	mov RCAP2H, #0
	mov RCAP2L, #0
    ret
    
InitTimer0:
	mov a, TMOD
	anl a, #0xf0 ; 11110000 Clear the bits for timer 0
	orl a, #0x01 ; 00000001 Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH0, #high(TIMER0_RELOAD1)
	mov TL0, #low(TIMER0_RELOAD1)
	; Set autoreload value
	mov RH0, #high(TIMER0_RELOAD1)
	mov RL0, #low(TIMER0_RELOAD1)
	; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  ; Start timer 0
	ret
	
Timer0_ISR:
	cpl SOUND_OUT ; Connect speaker to P2.2!
	reti
	
Random:
; Seed = 214013*seed + 2531011
	mov x+0, Seed+0
	mov x+1, Seed+1
	mov x+2, Seed+2
	mov x+3, Seed+3
	Load_y(214013)
	lcall mul32
	Load_y(2531011)
	lcall add32
	mov Seed+0, x+0
	mov Seed+1, x+1
	mov Seed+2, x+2
	mov Seed+3, x+3
	ret
	
Wait_Random:
	Wait_Milli_Seconds(Seed+0)
	Wait_Milli_Seconds(Seed+1)
	Wait_Milli_Seconds(Seed+2)
	Wait_Milli_Seconds(Seed+3)
	ret

;Converts the hex number in TH2-TL2 to BCD in R2-R1-R0
hex2bcd3:
	clr a
    mov R0, #0  ;Set BCD result to 00000000 
    mov R1, #0
    mov R2, #0
    mov R3, #16 ;Loop counter.

hex2bcd_loop:
    mov a, TL2 ;Shift TH0-TL0 left through carry
    rlc a
    mov TL2, a
    
    mov a, TH2
    rlc a
    mov TH2, a
      
	; Perform bcd + bcd + carry
	; using BCD numbers
	mov a, R0
	addc a, R0
	da a
	mov R0, a
	
	mov a, R1
	addc a, R1
	da a
	mov R1, a
	
	mov a, R2
	addc a, R2
	da a
	mov R2, a
	
	djnz R3, hex2bcd_loop
	ret

; Dumps the 5-digit packed BCD number in R2-R1-R0 into the LCD
DisplayBCD_LCD:
	; 5th digit:
    mov a, R2
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 4th digit:
    mov a, R1
    swap a
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 3rd digit:
    mov a, R1
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 2nd digit:
    mov a, R0
    swap a
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 1st digit:
    mov a, R0
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
    
    ret
    
;------------------------------
display_pointA_sc:
	ljmp display_pointA
;-----------------------------

Check_A:
	mov x+0, Period_A+0
	mov x+1, Period_A+1
	mov x+2, #0
	mov x+3, #0
	
	load_y(4775)
	lcall x_gt_y
	
	jb mf, A_counter ;mf = 1, A is pressed
	jnb mf, display_pointA_sc
	
	
A_counter:
	mov a, PointsA
	jb toneflag, PointsA_check0 ;minus A
	cjne a, #0x04, PointsA_add
	mov a, #0x00
	mov PointsA, a
	sjmp player1wins
	
player1wins:
	Set_Cursor(1, 1)
	Send_Constant_String(#player1wins_mess)
    Set_Cursor(2, 1)
    Send_Constant_String(#EmptyScreen1)
	ljmp empty_state

PointsA_add:
    mov a, PointsA
    add a, #0x01
    da a
    mov PointsA, a
	clr TR0
    ljmp display_pointA

PointsA_check0:
	mov a, PointsA
	cjne a, #0x00, PointsA_minus
	ljmp display_PointA


PointsA_minus:
	mov a, PointsA
	subb a, #0x01
	da a
	mov PointsA, a
	clr TR0
	ljmp display_pointA

;------------------------------
display_pointB_sc:
	ljmp display_pointB
;-----------------------------
    
Check_B:
	mov x+0, Period_B+0
	mov x+1, Period_B+1
	mov x+2, #0
	mov x+3, #0
	
	load_y(4845)
	lcall x_gt_y
	
	jb mf, B_counter ;mf = 1, A is pressed
	jnb mf, display_pointB_sc
	
B_counter:
	mov a, PointsB
	jb toneflag, PointsB_check0
	cjne a, #0x04, PointsB_add
	mov a, #0x00
	mov PointsB, a
	sjmp player2wins
	
player2wins:
	Set_Cursor(1, 1)
	Send_Constant_String(#player2wins_mess)
    Set_Cursor(2, 1)
    Send_Constant_String(#EmptyScreen1)
	ljmp empty_state

PointsB_add:
    mov a, PointsB
    add a, #0x01
    da a
    mov PointsB, a
    da a
    ljmp display_pointB

PointsB_check0:
	mov a, PointsB
	cjne a, #0x00, PointsB_minus
	ljmp display_PointB

PointsB_minus:
	mov a, PointsB
	subb a, #0x01
	da a
	mov PointsB, a
	clr TR0
	ljmp display_pointB
	
empty_state:
	clr TR0
	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message1)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC1)
	mov RL0, #low(MUSIC1)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message2)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC1)
	mov RL0, #low(MUSIC1)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message3)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC5)
	mov RL0, #low(MUSIC5)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message4)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC5)
	mov RL0, #low(MUSIC5)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message5)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC6)
	mov RL0, #low(MUSIC6)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message6)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC6)
	mov RL0, #low(MUSIC6)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message7)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC5)
	mov RL0, #low(MUSIC5)
	setb TR0
	

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message8)
	lcall WaitHalfSec

	clr TR0
	mov RH0, #high(MUSIC5)
	mov RL0, #low(MUSIC5)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message9)
	lcall WaitHalfSec


	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC4)
	mov RL0, #low(MUSIC4)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message10)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC4)
	mov RL0, #low(MUSIC4)
	setb TR0


	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message11)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC3)
	mov RL0, #low(MUSIC3)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message12)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC3)
	mov RL0, #low(MUSIC3)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message13)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC2)
	mov RL0, #low(MUSIC2)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message14)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC2)
	mov RL0, #low(MUSIC2)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message15)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC1)
	mov RL0, #low(MUSIC1)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message16)
	lcall WaitHalfSec

	clr TR0
	mov RH0, #high(MUSIC1)
	mov RL0, #low(MUSIC1)
	setb TR0


	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message17)
	lcall WaitHalfSec
	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC5)
	mov RL0, #low(MUSIC5)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message18)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC5)
	mov RL0, #low(MUSIC5)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message19)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC4)
	mov RL0, #low(MUSIC4)
	setb TR0


	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message20)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC4)
	mov RL0, #low(MUSIC4)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message21)
	lcall WaitHalfSec


	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC3)
	mov RL0, #low(MUSIC3)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message22)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC3)
	mov RL0, #low(MUSIC3)
	setb TR0


	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message23)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC2)
	mov RL0, #low(MUSIC2)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message24)
	lcall WaitHalfSec

	clr TR0
	mov RH0, #high(MUSIC2)
	mov RL0, #low(MUSIC2)
	setb TR0



	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message25)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC5)
	mov RL0, #low(MUSIC5)
	setb TR0


	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message26)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC5)
	mov RL0, #low(MUSIC5)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message27)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC4)
	mov RL0, #low(MUSIC4)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message28)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC4)
	mov RL0, #low(MUSIC4)
	setb TR0


	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message29)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC3)
	mov RL0, #low(MUSIC3)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message30)
	lcall WaitHalfSec
	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC3)
	mov RL0, #low(MUSIC3)
	setb TR0

	Set_Cursor(2, 1)
    Send_Constant_String(#winner_message31)
	lcall WaitHalfSec

	clr TR0
	Wait_Milli_Seconds(#100)
	mov RH0, #high(MUSIC2)
	mov RL0, #low(MUSIC2)
	setb TR0
	lcall wait1s

	ljmp empty_state

;---------------------------------;
; Hardware initialization         ;
;---------------------------------;
Initialize_All:
    lcall InitTimer2
	lcall InitTimer0
    lcall LCD_4BIT ; Initialize LCD
	mov PointsA, #0x00
	mov PointsB, #0x00
	ret

;---------------------------------;
; Main program loop               ;
;---------------------------------;
MyProgram:
    ; Initialize the hardware:
    mov SP, #7FH
    lcall Initialize_All
    setb EA
    ; Make sure the two input pins are configure for input
    setb P2.0 ; Pin is used as input
    setb P2.1 ; Pin is used as input


	Set_CUrsor(1,1)
	Send_Constant_String(#Start_Message)
    
    lcall WaitHalfSec
	clr TR0
	mov RH0, #high(MUSIC1)
	mov RL0, #low(MUSIC1)
	setb TR0
	
	lcall WaitHalfSec
	clr TR0
	mov RH0, #high(MUSIC2)
	mov RL0, #low(MUSIC2)
	setb TR0
    
    lcall WaitHalfSec
	clr TR0
	mov RH0, #high(MUSIC3)
	mov RL0, #low(MUSIC3)
	setb TR0

	lcall WaitHalfSec
	clr TR0
	mov RH0, #high(MUSIC4)
	mov RL0, #low(MUSIC4)
	setb TR0
    
	lcall WaitHalfSec
	clr TR0
	mov RH0, #high(MUSIC5)
	mov RL0, #low(MUSIC5)
	setb TR0
	
	lcall WaitHalfSec
	clr TR0
	mov RH0, #high(MUSIC6)
	mov RL0, #low(MUSIC6)
	setb TR0

	lcall WaitHalfSec
	clr TR0
	mov RH0, #high(MUSIC7)
	mov RL0, #low(MUSIC7)
	setb TR0

	Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message1)
	Set_Cursor(2, 1)
    Send_Constant_String(#Initial_Message2)

SetupRandom:
	setb TR0
	jnb RandomSeed, $
	mov Seed+0, TH0
	mov Seed+1, #0x01
	mov Seed+2, #0x87
	mov Seed+3, TL0
	clr TR0

Pick_frequency:
	clr mf
	lcall Random
	
	mov x+0, Seed+0
	mov x+1, Seed+1
	mov x+2, Seed+2
	mov x+3, Seed+3
	Load_y(2147483648)
	
	lcall x_lt_y
	
	jb mf, Frequency2 ;mf = 1, goes to frequency 2
	ljmp Frequency1
	
Counter:   

A_plate:
    ; Measure the period applied to pin P2.0
    clr TR2 ; Stop counter 2
    mov TL2, #0
    mov TH2, #0
    jb P2.0, $
    jnb P2.0, $
    setb TR2 ; Start counter 0
    jb P2.0, $
    jnb P2.0, $
    clr TR2 ; Stop counter 2, TH2-TL2 has the period
    ; save the period of P2.0 for later use
    mov Period_A+0, TL2
    mov Period_A+1, TH2
    ljmp check_A
    
B_plate:
    ; Measure the period applied to pin P2.1
    clr mf
	clr TR2 ; Stop counter 2
    mov TL2, #0
    mov TH2, #0
    jb P2.1, $
    jnb P2.1, $
    setb TR2 ; Start counter 0
    jb P2.1, $
    jnb P2.1, $
    clr TR2 ; Stop counter 2, TH2-TL2 has the period
    ; save the period of P2.1 for later use
    mov Period_B+0, TL2
    mov Period_B+1, TH2
    ljmp check_B

Frequency1: ;adding
	;it waits random sec before the next beep
	clr toneflag ;toneflag = 0 (add)
	clr TR0
	lcall Wait_Random
	lcall Wait_Random
	lcall Wait_Random
	
	mov RH0, #high(TIMER0_RELOAD1)
	mov RL0, #low(TIMER0_RELOAD1)
	setb TR0
	
	;it beeps for one second
	lcall WaitHalfSec
	
	ljmp A_plate
	
Frequency2: ;subtracting
	setb toneflag ;toneflag = 1 (sub)
	clr TR0
	lcall Wait_Random
	lcall Wait_Random
	lcall Wait_Random
	
	mov RH0, #high(TIMER0_RELOAD0)
	mov RL0, #low(TIMER0_RELOAD0)
	setb TR0
	
	lcall WaitHalfSec
	
    ljmp A_plate ; After beeping goes to counter to check 

display_pointA:

    Set_Cursor(1, 14)     ; the place in the LCD where we want the BCD counter value
	Display_BCD(PointsA)
	jnb mf, B_plate		  ; if A is not pressed then check B
    ljmp Pick_frequency	  ; if A is pressed goes to the next beep

display_pointB:
	Set_Cursor(2,14)
	Display_BCD(PointsB)
	ljmp Pick_frequency
	
	
     
end
