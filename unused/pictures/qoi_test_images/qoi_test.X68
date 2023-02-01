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

        BSR     QOI_DECODE


QOI_DECODE
        MOVE.L  #FILE_CONTENTS,A0
        MOVE.L  #OUTPUT_IMAGE_DATA,A1
        FOR.L D5 = #0 TO file_size  DO
            ;         read    write
            ;MOVE.B  (A0,D5),(A1,D5)

            ; start byte
            MOVE.B  (A0,D5),D2

            ; QOI_OP_INDEX
            IF.B D2 <LT> #64    THEN
                LEA     previous_seen_pixels,A2
                MULU    #4,D2
                ADD     D2,A2
                MOVE.L  (A2),(A1,D5)
            ELSE
                ; QOI_OP_DIFF
                IF.B D2 <LT> #128   THEN

                ELSE
                    ; QOI_OP_LUMA
                    IF.B D2 <LT> #192   THEN

                    ELSE
                        ; QOI_OP_RGB
                        IF.B D2 <EQ> #254   THEN

                        ELSE
                            ; QOI_OP_RGBA
                            IF.B D2 <EQ> #255   THEN

                            ELSE
                                ; QOI_OP_RUN

                            ENDI
                        ENDI
                    ENDI
                ENDI
            ENDI



            BSR     QOI_PUT_IN_PIXEL
        ENDF
        ADD.L   file_size,A1
        MOVE.B  #20,(A1)







        BSR     EXIT_PROGRAM


; uses D0, D7, A0
QOI_PUT_IN_PIXEL
        CLR.L   D7
        LEA     current_pixel,A0
        ; red
        MOVE.B  (A0),D0
        MULU    #3,D0
        ADD.L   D0,D7
        ADD     #1,A0
        ; green
        MOVE.B  (A0),D0
        MULU    #5,D0
        ADD.L   D0,D7
        ADD     #1,A0
        ; blue
        MOVE.B  (A0),D0
        MULU    #7,D0
        ADD.L   D0,D7
        ADD     #1,A0
        ; alpha
        MOVE.B  (A0),D0
        MULU    #11,D0
        ADD.L   D0,D7
        ADD     #1,A0

        DIVU    #64,D7

        LEA     previous_seen_pixels,A0
        MULU    #4,D7
        ADD.W   D7,A0
        MOVE.L  current_pixel,(A0)
        RTS


EXIT_PROGRAM
        MOVE.W  #9,D0
        TRAP    #15


current_pixel           DC.L    $000000FF      ; stores the current pixel
previous_pixel          DC.L    $000000FF      ; stores the last seen pixel
previous_seen_pixels    DS.L    64              ; stores a 64 length array of previous pixels




file_name   DC.B    'qoi_logo.qoi',0
file_size   DS.L    1

FILE_CONTENTS   EQU     $10000
OUTPUT_IMAGE_DATA   EQU $20000



    END    START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
