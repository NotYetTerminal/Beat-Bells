*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

START   ORG     $1000

    ; sets up time
    MOVE.W  #8,D0
    TRAP    #15
    MOVE.L  D1,last_frame_time

    ; loads in a song binary file
    MOVE.B  #51,D0
    LEA     FILENAME,A1
    TRAP    #15

    MOVE.B  #53,D0
    LEA     FILE_CONTENTS,A1
    MOVE.L  #512,D2
    TRAP    #15
    
    MOVE.B  #50,D0
    TRAP    #15
    
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
    LEA     A10,A1
    FOR D1 = #0 TO #30  DO
        MOVE.B  #74,D0
        TRAP    #15
        ADD.W   #14,A1
    ENDF

    RTS

; plays music that is loaded in
PLAY_IN_MUSIC
    LEA     FILE_CONTENTS,A0
    MOVE.L  #0,D3
    FOR D5 = #0 TO #63  DO
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
                        MOVE.B  (A2),(A1)
                        SUB.L   #16,A1
                    ELSE
                        ; choose which rest time to put in
                        LEA     rest_times_array,A2
                        ADD.L   D2,A2
                        SUB.L   #1,A2
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
                        MOVE.B  (A2),(A1)
                        SUB.L   #16,A1
                    ELSE
                        ; choose which rest time to put in
                        LEA     rest_times_array,A2
                        ADD.L   D3,A2
                        SUB.L   #1,A2
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
                    MOVE.B  #77,D0
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
A10 DC.B    'notes/a10.wav',0
B10 DC.B    'notes/b10.wav',0
C10 DC.B    'notes/c10.wav',0
D10 DC.B    'notes/d10.wav',0
E10 DC.B    'notes/e10.wav',0
F10 DC.B    'notes/f10.wav',0
G10 DC.B    'notes/g10.wav',0

A20 DC.B    'notes/a20.wav',0
B20 DC.B    'notes/b20.wav',0
C20 DC.B    'notes/c20.wav',0
D20 DC.B    'notes/d20.wav',0
E20 DC.B    'notes/e20.wav',0
F20 DC.B    'notes/f20.wav',0
G20 DC.B    'notes/g20.wav',0

A30 DC.B    'notes/a30.wav',0
B30 DC.B    'notes/b30.wav',0

A11 DC.B    'notes/a11.wav',0
B11 DC.B    'notes/b11.wav',0
C11 DC.B    'notes/c11.wav',0
D11 DC.B    'notes/d11.wav',0
E11 DC.B    'notes/e11.wav',0
F11 DC.B    'notes/f11.wav',0
G11 DC.B    'notes/g11.wav',0

A21 DC.B    'notes/a21.wav',0
B21 DC.B    'notes/b21.wav',0
C21 DC.B    'notes/c21.wav',0
D21 DC.B    'notes/d21.wav',0
E21 DC.B    'notes/e21.wav',0
F21 DC.B    'notes/f21.wav',0
G21 DC.B    'notes/g21.wav',0

A31 DC.B    'notes/a31.wav',0

notes_times_array   DS.B    31  ; contains the times for each note that needs to be hold
rest_times_array    DS.B    7   ; contains the number of quater beats needed for each note

FILENAME    DC.B    'songs/number_one.sun',0
FILE_CONTENTS   DS.B    512

    END    START













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
