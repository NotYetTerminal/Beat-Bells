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
        MOVE.L  #FILE_CONTENTS,A1
        MOVE.L  #$FFFFF,D2
        TRAP    #15
        
        MOVE.B  #50,D0
        TRAP    #15

        BSR     QOI_DECODE_C
        BSR     RENDER_IMAGE
        BSR     EXIT_PROGRAM


QOI_DECODE_C
        BSR     ZERO_PIXELS_ARRAY
        MOVE.L  #$000000FF,current_pixel_r ; px

        MOVE.L  (PICTURE_X),D1
        MOVE.L  (PICTURE_Y),D2
        MULU    D2,D1
        MOVE.L  D1,D2
        SWAP    D2
        MULU    #4,D1
        MULU    #4,D2
        SWAP    D2
        ADD.L   D2,D1
        SUB.L   #1,D1
        MOVE.L  D1,pixel_length ; px_len

        CLR.B   index_run       ; run
        MOVE.L  #14,D4 ; P

        MOVE.L  #FILE_CONTENTS,A0   ; bytes
        MOVE.L  #OUTPUT_IMAGE_DATA,A1 ; pixels

        ; px_pos
        FOR.L D5 = #0 TO pixel_length BY #4 DO
            IF.B index_run <HI> #0  THEN
                SUB.B   #1,index_run
            ELSE
                CLR.L   D1
                MOVE.B  (A0,D4),D1
                ADD.L   #1,D4
                ; QOI_OP_RGB
                IF.B D1 <EQ> #254   THEN
                    MOVE.B  (A0,D4),current_pixel_r
                    ADD.L   #1,D4
                    MOVE.B  (A0,D4),current_pixel_g
                    ADD.L   #1,D4
                    MOVE.B  (A0,D4),current_pixel_b
                    ADD.L   #1,D4
                ELSE
                    ; QOI_OP_RGBA
                    IF.B D1 <EQ> #255   THEN
                        MOVE.B  (A0,D4),current_pixel_r
                        ADD.L   #1,D4
                        MOVE.B  (A0,D4),current_pixel_g
                        ADD.L   #1,D4
                        MOVE.B  (A0,D4),current_pixel_b
                        ADD.L   #1,D4
                        MOVE.B  (A0,D4),current_pixel_a
                        ADD.L   #1,D4
                    ELSE
                        ; QOI_OP_RUN
                        IF.B D1 <HS> #192   THEN
                            AND.B   #$3F,D1
                            MOVE.B  D1,index_run
                        ELSE
                            ; QOI_OP_LUMA
                            IF.B D1 <HS> #128   THEN
                                CLR.L   D2
                                MOVE.B  (A0,D4),D2
                                ADD.L   #1,D4
                                MOVE.L  D2,D3

                                AND.B   #$3F,D1
                                SUB.B   #32,D1

                                LSR.L   #4,D3
                                AND.B   #$0F,D3
                                SUB.B   #8,D3
                                ADD.B   D1,D3
                                ADD.B   D3,current_pixel_r

                                ADD.B   D1,current_pixel_g

                                AND.B   #$0F,D2
                                SUB.B   #8,D2
                                ADD.B   D1,D2
                                ADD.B   D2,current_pixel_b
                            ELSE
                                ; QOI_OP_DIFF
                                IF.B D1 <HS> #64    THEN
                                    CLR.L   D2
                                    MOVE.B  D1,D2
                                    LSR.L   #4,D2
                                    AND.B   #$03,D2
                                    SUB.B   #2,D2
                                    ADD.B   D2,current_pixel_r
                                    
                                    MOVE.B  D1,D2
                                    LSR.L   #2,D2
                                    AND.B   #$03,D2
                                    SUB.B   #2,D2
                                    ADD.B   D2,current_pixel_g
                                    
                                    MOVE.B  D1,D2
                                    AND.B   #$03,D2
                                    SUB.B   #2,D2
                                    ADD.B   D2,current_pixel_b
                                ELSE
                                    ; QOI_OP_INDEX
                                    LEA     previous_seen_pixels,A2
                                    MULU    #4,D1
                                    ADD.L   D1,A2
                                    MOVE.L  (A2),current_pixel_r
                                ENDI
                            ENDI
                        ENDI
                    ENDI
                ENDI
                BSR     QOI_PUT_IN_PIXEL_C
            ENDI

            IF.B current_pixel_a <EQ> #0    THEN
                MOVE.L  #0,(A1,D5.L)
            ELSE
                MOVE.B  #0,(A1,D5.L)
                MOVE.B  current_pixel_b,1(A1,D5.L)
                MOVE.B  current_pixel_g,2(A1,D5.L)
                MOVE.B  current_pixel_r,3(A1,D5.L)
            ENDI
        ENDF
        RTS


ZERO_PIXELS_ARRAY
        LEA     previous_seen_pixels,A0
        FOR D5 = #0 TO #255 BY #4   DO
            MOVE.L  #$000000FF,(A0,D5)
        ENDF
        RTS


QOI_PUT_IN_PIXEL_C
        CLR.L   D1
        CLR.L   D2
        LEA     previous_seen_pixels,A2

        MOVE.B  current_pixel_r,D1
        MULU    #3,D1
        ADD.L   D1,D2

        CLR.L   D1
        MOVE.B  current_pixel_g,D1
        MULU    #5,D1
        ADD.L   D1,D2

        CLR.L   D1
        MOVE.B  current_pixel_b,D1
        MULU    #7,D1
        ADD.L   D1,D2

        CLR.L   D1
        MOVE.B  current_pixel_a,D1
        MULU    #11,D1
        ADD.L   D1,D2

        DIVU    #64,D2
        SWAP    D2
        MULU    #4,D2
        ADD.L   D2,A2

        MOVE.L  current_pixel_r,(A2)
        RTS


RENDER_IMAGE
        MOVE.L  #OUTPUT_IMAGE_DATA,A0
        FOR.L D5 = #1 TO (PICTURE_Y)  DO
            FOR.L D6 = #1 TO (PICTURE_X)  DO
                ; set pen colour
                MOVE.B  #80,D0
                MOVE.L  (A0),D1
                TRAP    #15
                MOVE.B  #81,D0
                TRAP    #15

                ;set pixel colour
                MOVE.B  #87,D0
                MOVE.W  D6,D1
                MOVE.W  D5,D2
                MULU    #MULTIPLIER_SIZE,D1
                MULU    #MULTIPLIER_SIZE,D2
                MOVE.W  D1,D3
                MOVE.W  D2,D4
                ADD.W   #MULTIPLIER_SIZE,D3
                ADD.W   #MULTIPLIER_SIZE,D4
                TRAP    #15
                
                ADD.W   #4,A0
            ENDF
        ENDF

        RTS


; draws a square at A0 plus size in D3,D4
DRAW_SQUARE
        ; set bounds of square to draw
        MOVE.W  (A0)+,D1
        MOVE.W  (A0),D2
        ADD.W   D1,D3
        ADD.W   D2,D4

        MOVE.W  #87,D0
        TRAP    #15
        RTS


EXIT_PROGRAM
        MOVE.W  #9,D0
        TRAP    #15


; stores the current pixel
current_pixel_r         DC.B    $00
current_pixel_g         DC.B    $00
current_pixel_b         DC.B    $00
current_pixel_a         DC.B    $FF
previous_seen_pixels    DS.L    64             ; stores a 64 length array of previous pixels

PICTURE_X           EQU     $10004      ; stores the x length of picture
PICTURE_Y           EQU     $10008      ; stores the y length of picture

pixel_length        DS.L    1           ; stores the number of bytes taken up by pixels
index_run           DS.B    1           ; stores the number of runs for index
file_pixel_index    DS.L    1           ; stores the file index position

file_name   DC.B    'qoi_logo.qoi',0
out_name    DC.B    'qoi_out',0


MULTIPLIER_SIZE     EQU 1

FILE_CONTENTS   EQU     $10000
OUTPUT_IMAGE_DATA   EQU $20000


    END    START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
