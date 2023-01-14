*-----------------------------------------------------------
* Title      :  music reader test
* Written by :  Gabor Major
* Date       :  12/01/2023
* Description:  test for project
*-----------------------------------------------------------

START   ORG     $1000

    ; checks if $10000 has been accidentally used
    IF.L FILE_CONTENTS <NE> #$FFFFFFFF  THEN
        DIVU    #0,D0
    ENDI

    ; sets up time
    MOVE.W  #8,D0
    TRAP    #15
    MOVE.L  D1,last_frame_time

    ; loads in a song binary file
    MOVE.B  #51,D0
    LEA     file_name,A1
    TRAP    #15

    MOVE.B  #53,D0
    LEA     FILE_CONTENTS,A1
    MOVE.L  #$FFFFF,D2
    TRAP    #15
    
    MOVE.B  #50,D0
    TRAP    #15
    
    ; saves the file size
    MOVE.L  D2,file_size
    DIVU    #8,D2
    MOVE.L  #0,D1
    MOVE.W  D2,D1
    MOVE.L  D1,second_size

    ; loads in note rest times
    LEA     rest_times_array,A1
    MOVE.B  #2,(A1)
    ADD.L   #1,A1
    MOVE.B  #3,(A1)
    ADD.L   #1,A1
    MOVE.B  #5,(A1)
    ADD.L   #1,A1
    MOVE.B  #7,(A1)
    ADD.L   #1,A1
    MOVE.B  #9,(A1)
    ADD.L   #1,A1
    MOVE.B  #13,(A1)
    ADD.L   #1,A1
    MOVE.B  #17,(A1)
    
    BSR     LOAD_IN_ALL_NOTES
    BSR     PLAY_IN_MUSIC
    SIMHALT

; loads in all notes into DirectX memory
; some note files do not exist and will cause warnings
LOAD_IN_ALL_NOTES
    LEA     BASIC_PATH,A1
    LEA     A10,A2
    FOR D1 = #0 TO #30  DO
        FOR D2 = #0 TO #2   DO
            MOVE.L  A1,A3
            ADD.W   #6,A3
            ADD.W   D2,A3
            MOVE.B  (A2),(A3)
            ADD.W   #1,A2
        ENDF
        MOVE.B  #74,D0
        TRAP    #15
    ENDF

    RTS

; plays music that is loaded in
PLAY_IN_MUSIC
    LEA     FILE_CONTENTS,A0
    MOVE.L  #0,D3
    FOR D5 = #0 TO #SECOND_SIZE-1 DO
        LEA notes_times_array,A1
        FOR D6 = #0 TO #7   DO
            MOVE.B  (A0),D3
            MOVE.L  #0,D2
            IF.L #0 <NE> D3 THEN
                ; splits the four bits of d2 byte into d1
                BTST.L  #7,D3
                IF  <NE>    THEN
                    ADD.B   #8,D2
                    SUB.B   #128,D3
                ENDI
                BTST.L  #6,D3
                IF  <NE>    THEN
                    ADD.B   #4,D2
                    SUB.B   #64,D3
                ENDI
                BTST.L  #5,D3
                IF  <NE>    THEN
                    ADD.B   #2,D2
                    SUB.B   #32,D3
                ENDI
                BTST.L  #4,D3
                IF  <NE>    THEN
                    ADD.B   #1,D2
                    SUB.B   #16,D3
                ENDI
                ; checks if note is played
                IF #0 <NE> D2   THEN
                    MOVE.B  D6,D1
                    ADD.B   D6,D1
                    BTST.L  #3,D2                    
                    IF  <NE>    THEN
                        ADD.B   #16,D1
                        SUB.B   #8,D2
                        ; choose which rest time to put in
                        LEA     rest_times_array,A2
                        ADD.L   D2,A2
                        SUB.L   #1,A2
                        ; puts in rest time
                        ADD.L   #16,A1
                        ; stops a note playing if it is
                        IF.B (A1) <NE> #$FF   THEN
                            MOVE.L  #2,D2
                            MOVE.L  #77,D0
                            TRAP    #15
                        ENDI
                        MOVE.B  (A2),(A1)
                        SUB.L   #16,A1
                    ELSE
                        ; choose which rest time to put in
                        LEA     rest_times_array,A2
                        ADD.L   D2,A2
                        SUB.L   #1,A2
                        ; stops a note playing if it is
                        IF.B (A1) <NE> #$FF   THEN
                            MOVE.L  #2,D2
                            MOVE.L  #77,D0
                            TRAP    #15
                        ENDI
                        MOVE.B  (A2),(A1)
                    ENDI
                    MOVE.B  #75,D0
                    TRAP    #15
                ENDI
                IF #0 <NE> D3   THEN
                    MOVE.B  D6,D1
                    ADD.B   D6,D1
                    ADD.B   #1,D1
                    BTST.L  #3,D3
                    ADD.L   #1,A1
                    IF  <NE>    THEN
                        ADD.B   #16,D1
                        SUB.B   #8,D3
                        ; choose which rest time to put in
                        LEA     rest_times_array,A2
                        ADD.L   D3,A2
                        SUB.L   #1,A2
                        ; puts in rest time
                        ADD.L   #16,A1
                        ; stops a note playing if it is
                        IF.B (A1) <NE> #$FF   THEN
                            MOVE.L  #2,D2
                            MOVE.L  #77,D0
                            TRAP    #15
                        ENDI
                        MOVE.B  (A2),(A1)
                        SUB.L   #16,A1
                    ELSE
                        ; choose which rest time to put in
                        LEA     rest_times_array,A2
                        ADD.L   D3,A2
                        SUB.L   #1,A2
                        ; stops a note playing if it is
                        IF.B (A1) <NE> #$FF   THEN
                            MOVE.L  #2,D2
                            MOVE.L  #77,D0
                            TRAP    #15
                        ENDI
                        MOVE.B  (A2),(A1)
                    ENDI
                    SUB.L   #1,A1
                    MOVE.B  #75,D0
                    TRAP    #15
                ENDI
            ENDI
            ADD.W   #1,A0
            ADD.L   #2,A1
        ENDF
        ; loops over music time array
        ; decrements times for each note
        LEA notes_times_array,A1
        FOR D6 = #0 TO #30  DO
            ADD.L   D6,A1
            IF.B    (A1) <NE> #$FF  THEN
                SUB.B   #1,(A1)
                IF.B    (A1) <EQ> #0    THEN
                    ; stops a note playing
                    MOVE.B  D6,D1
                    MOVE.L  #2,D2
                    MOVE.L  #77,D0
                    TRAP    #15
                    MOVE.B  #$FF,(A1)
                ENDI
            ENDI
            SUB.L   D6,A1
        ENDF
        BSR FRAME_DELAY
    ENDF

    RTS


FRAME_DELAY
        MOVE.W  #8,D0       ; gets the time
        TRAP    #15

        SUB.L   last_frame_time,D1  ; subtracts the two times
        CMP.L   #10,D1               ; n number of centiseconds have passed
        BLO     frame_delay

        MOVE.W  #8,D0               ; save time
        TRAP    #15
        MOVE.L  D1,last_frame_time

        RTS

last_frame_time         DS.L    1   ; stores the time at last frame

; notes names
BASIC_PATH  DC.B    'notes/aaa.wav',0
A10 DC.B    'a10'
B10 DC.B    'b10'
C10 DC.B    'c10'
D10 DC.B    'd10'
E10 DC.B    'e10'
F10 DC.B    'f10'
G10 DC.B    'g10'

A20 DC.B    'a20'
B20 DC.B    'b20'
C20 DC.B    'c20'
D20 DC.B    'd20'
E20 DC.B    'e20'
F20 DC.B    'f20'
G20 DC.B    'g20'

A30 DC.B    'a30'
B30 DC.B    'b30'

A11 DC.B    'a11'
B11 DC.B    'b11'
C11 DC.B    'c11'
D11 DC.B    'd11'
E11 DC.B    'e11'
F11 DC.B    'f11'
G11 DC.B    'g11'

A21 DC.B    'a21'
B21 DC.B    'b21'
C21 DC.B    'c21'
D21 DC.B    'd21'
E21 DC.B    'e21'
F21 DC.B    'f21'
G21 DC.B    'g21'

A31 DC.B    'a31'

notes_times_array   DS.B    31  ; contains the times for each note that needs to be hold
rest_times_array    DS.B    7   ; contains the number of quater beats needed for each note

file_size   DS.L    1      ; the size of the .sun file in bytes
second_size DS.L    1      ; the size of the .sun file divided by 8 in bytes

file_name       DC.B    'songs/number_one',0
; THE PROGRAM MUST NOT USE THE FOLLOWING MEMORY ADDRESS
FILE_CONTENTS   EQU     $10000

    END    START
















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
