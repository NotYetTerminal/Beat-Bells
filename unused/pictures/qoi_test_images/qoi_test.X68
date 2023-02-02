*-----------------------------------------------------------
* Title      :  qoi test
* Written by :  Gabor Major
* Date       :  01/02/2023
* Description:  qoi test
*-----------------------------------------------------------

START   ORG    $1000

        ; loads in a file
        MOVE.B  #51,D0
        LEA     file_name,A1
        TRAP    #15

        MOVE.B  #53,D0
        LEA     FILE_CONTENTS,A1
        MOVE.L  #$FFFFF,D2
        TRAP    #15

        SUB     #1,D2
        MOVE.L  D2,file_size
        
        MOVE.B  #50,D0
        TRAP    #15

        BSR     INITIALISE_PIXELS_ARRAY
        BSR     QOI_DECODE


INITIALISE_PIXELS_ARRAY
        LEA     previous_seen_pixels,A0
        FOR D5 = 0 TO #63   DO
            MOVE.L  #0,(A0)
            ADD     #4,A0
        ENDF
        RTS


QOI_DECODE
        ;BSR     QOI_PUT_IN_PIXEL
        MOVE.L  #FILE_CONTENTS,A0
        ADD     #14,A0
        MOVE.L  #OUTPUT_IMAGE_DATA,A1
        FOR.L D5 = #0 TO file_size  DO
            MOVE.L  current_pixel,previous_pixel
            ;         read    write
            ;MOVE.B  (A0,D5),(A1,D5)

            ; Byte[0]
            CLR.L   D2
            MOVE.B  (A0,D5),D2

            IF D5 <EQ> #$1529   THEN
                ILLEGAL
            ENDI

            ; QOI_OP_INDEX
            IF.B D2 <LO> #64    THEN
                MOVE    #1,D7
                LEA     previous_seen_pixels,A2
                MULU    #4,D2
                ADD     D2,A2
                MOVE.L  (A2),current_pixel
                MOVE.L  current_pixel,(A1)
                ADD     #4,A1
            ELSE
                ; QOI_OP_DIFF
                IF.B D2 <LO> #128   THEN
                    LEA     current_pixel,A2
                    ; check red
                    BTST    #5,D2
                    IF  <NE>    THEN
                        BTST    #4,D2
                        IF  <NE>    THEN
                            ADD.B   #1,(A2)
                        ENDI
                    ELSE
                        BTST    #4,D2
                        IF  <NE>    THEN
                            SUB.B   #1,(A2)
                        ELSE
                            SUB.B   #2,(A2)
                        ENDI
                    ENDI
                    ADD     #1,A2
                    ; check green
                    BTST    #3,D2
                    IF  <NE>    THEN
                        BTST    #2,D2
                        IF  <NE>    THEN
                            ADD.B   #1,(A2)
                        ENDI
                    ELSE
                        BTST    #2,D2
                        IF  <NE>    THEN
                            SUB.B   #1,(A2)
                        ELSE
                            SUB.B   #2,(A2)
                        ENDI
                    ENDI
                    ADD     #1,A2
                    ; check blue
                    BTST    #1,D2
                    IF  <NE>    THEN
                        BTST    #0,D2
                        IF  <NE>    THEN
                            ADD.B   #1,(A2)
                        ENDI
                    ELSE
                        BTST    #0,D2
                        IF  <NE>    THEN
                            SUB.B   #1,(A2)
                        ELSE
                            SUB.B   #2,(A2)
                        ENDI
                    ENDI
                    MOVE.L  current_pixel,(A1)
                    BSR     QOI_PUT_IN_PIXEL
                    ADD     #4,A1
                ELSE
                    ; QOI_OP_LUMA
                    IF.B D2 <LO> #192   THEN
                        LEA     current_pixel,A2
                        ; 128 + 32
                        SUB.B   #160,D2
                        MOVE.B  D2,(A2)
                        ADD     #1,A2
                        
                        ADD     #1,D5
                        CLR.L   D3
                        MOVE.B  (A0,D5),D3
                        MOVE.L  D3,D4

                        LSR.B   #4,D3
                        ADD     D2,D3
                        SUB     #8,D3
                        MOVE.B  D3,(A2)
                        ADD     #1,A2

                        LSL.B   #4,D4
                        LSR.B   #4,D4
                        ADD     D2,D4
                        SUB     #8,D4
                        MOVE.B  D4,(A2)

                        MOVE.L  current_pixel,(A1)
                        BSR     QOI_PUT_IN_PIXEL
                        ADD     #4,A1
                    ELSE
                        ; QOI_OP_RGB
                        IF.B D2 <EQ> #254   THEN
                            LEA     current_pixel,A2

                            ADD     #1,D5
                            MOVE.B  (A0,D5),(A2)+
                            ADD     #1,D5
                            MOVE.B  (A0,D5),(A2)+
                            ADD     #1,D5
                            MOVE.B  (A0,D5),(A2)

                            MOVE.L  current_pixel,(A1)
                            BSR     QOI_PUT_IN_PIXEL
                            ADD     #4,A1
                        ELSE
                            ; QOI_OP_RGBA
                            IF.B D2 <EQ> #255   THEN
                                LEA     current_pixel,A2

                                ADD     #1,D5
                                MOVE.B  (A0,D5),(A2)+
                                ADD     #1,D5
                                MOVE.B  (A0,D5),(A2)+
                                ADD     #1,D5
                                MOVE.B  (A0,D5),(A2)+
                                ADD     #1,D5
                                MOVE.B  (A0,D5),(A2)

                                MOVE.L  current_pixel,(A1)
                                BSR     QOI_PUT_IN_PIXEL
                                ADD     #4,A1
                            ELSE
                                ; QOI_OP_RUN
                                SUB.B   #192,D2
                                FOR D6 = #0 TO D2   DO
                                    MOVE.L  current_pixel,(A1)
                                    ADD     #4,A1
                                ENDF
                            ENDI
                        ENDI
                    ENDI
                ENDI
            ENDI
        ENDF

        BSR     EXIT_PROGRAM


; uses D0, D7, A3
QOI_PUT_IN_PIXEL
        CLR.L   D7
        LEA     current_pixel,A3
        ; red
        MOVE.B  (A3),D0
        MULU    #3,D0
        ADD.L   D0,D7
        ADD     #1,A3
        ; green
        MOVE.B  (A3),D0
        MULU    #5,D0
        ADD.L   D0,D7
        ADD     #1,A3
        ; blue
        MOVE.B  (A3),D0
        MULU    #7,D0
        ADD.L   D0,D7
        ADD     #1,A3
        ; alpha
        MOVE.B  (A3),D0
        MULU    #11,D0
        ADD.L   D0,D7
        ADD     #1,A3

        DIVU    #64,D7

        LEA     previous_seen_pixels,A3
        MULU    #4,D7
        ADD.W   D7,A3
        MOVE.L  current_pixel,(A3)
        RTS


EXIT_PROGRAM
        MOVE.W  #9,D0
        TRAP    #15


current_pixel           DC.L    $000000FF      ; stores the current pixel
previous_pixel          DC.L    $000000FF      ; stores the last seen pixel
previous_seen_pixels    DS.L    64             ; stores a 64 length array of previous pixels




file_name   DC.B    'qoi_logo.qoi',0
file_size   DS.L    1

FILE_CONTENTS   EQU     $10000
OUTPUT_IMAGE_DATA   EQU $20000



    END    START



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
