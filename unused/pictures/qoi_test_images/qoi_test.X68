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

        SUB     #23,D2
        MOVE.L  D2,file_size
        
        MOVE.B  #50,D0
        TRAP    #15

        BSR     QOI_DECODE_C
        BSR     RENDER_IMAGE
        BSR     EXIT_PROGRAM



* QOI_DECODE
*         MOVE.L  #FILE_CONTENTS,A0
*         ADD     #14,A0
*         MOVE.L  #OUTPUT_IMAGE_DATA,A1
*         FOR.L D5 = #0 TO file_size  DO
*             ;         read    write
*             ;MOVE.B  (A0,D5),(A1,D5)

*             ; Byte[0]
*             CLR.L   D2
*             MOVE.B  (A0,D5),D2

*             ; QOI_OP_INDEX
*             IF.B D2 <LO> #64    THEN
*                 LEA     previous_seen_pixels,A2
*                 MULU    #4,D2
*                 ADD     D2,A2
*                 MOVE.L  (A2),current_pixel
*                 MOVE.L  current_pixel,(A1)
*                 ADD     #4,A1
*             ELSE
*                 LEA     current_pixel,A2
*                 ; QOI_OP_DIFF
*                 IF.B D2 <LO> #128   THEN
*                     ; check red
*                     BTST    #5,D2
*                     IF  <NE>    THEN
*                         BTST    #4,D2
*                         IF  <NE>    THEN
*                             ADD.B   #1,(A2)
*                         ENDI
*                     ELSE
*                         BTST    #4,D2
*                         IF  <NE>    THEN
*                             SUB.B   #1,(A2)
*                         ELSE
*                             SUB.B   #2,(A2)
*                         ENDI
*                     ENDI
*                     ADD     #1,A2
*                     ; check green
*                     BTST    #3,D2
*                     IF  <NE>    THEN
*                         BTST    #2,D2
*                         IF  <NE>    THEN
*                             ADD.B   #1,(A2)
*                         ENDI
*                     ELSE
*                         BTST    #2,D2
*                         IF  <NE>    THEN
*                             SUB.B   #1,(A2)
*                         ELSE
*                             SUB.B   #2,(A2)
*                         ENDI
*                     ENDI
*                     ADD     #1,A2
*                     ; check blue
*                     BTST    #1,D2
*                     IF  <NE>    THEN
*                         BTST    #0,D2
*                         IF  <NE>    THEN
*                             ADD.B   #1,(A2)
*                         ENDI
*                     ELSE
*                         BTST    #0,D2
*                         IF  <NE>    THEN
*                             SUB.B   #1,(A2)
*                         ELSE
*                             SUB.B   #2,(A2)
*                         ENDI
*                     ENDI
*                 ELSE
*                     ; QOI_OP_LUMA
*                     IF.B D2 <LO> #192   THEN
*                         ; 128 + 32
*                         SUB.B   #160,D2
*                         MOVE.B  D2,(A2)
*                         ADD     #1,A2
                        
*                         ADD     #1,D5
*                         CLR.L   D3
*                         MOVE.B  (A0,D5),D3
*                         MOVE.L  D3,D4

*                         LSR.B   #4,D3
*                         ADD     D2,D3
*                         SUB     #8,D3
*                         MOVE.B  D3,(A2)
*                         ADD     #1,A2

*                         LSL.B   #4,D4
*                         LSR.B   #4,D4
*                         ADD     D2,D4
*                         SUB     #8,D4
*                         MOVE.B  D4,(A2)
*                     ELSE
*                         ; QOI_OP_RGB
*                         IF.B D2 <EQ> #254 OR.B D2 <EQ> #255 THEN
*                             ADD     #1,D5
*                             MOVE.B  (A0,D5),(A2)+
*                             ADD     #1,D5
*                             MOVE.B  (A0,D5),(A2)+
*                             ADD     #1,D5
*                             MOVE.B  (A0,D5),(A2)+
*                             ; QOI_OP_RGBA
*                             IF.B D2 <EQ> #255   THEN
*                                 ADD     #1,D5
*                                 ;write memory to file and compare
*                                 MOVE.B  (A0,D5),(A2)
*                             ENDI
*                         ELSE
*                             ; QOI_OP_RUN
*                             ; 192 + 1
*                             SUB.B   #193,D2
*                             FOR D6 = #0 TO D2   DO
*                                 BSR     REVERSE_COLOUR_AND_SAVE
*                                 ADD     #4,A1
*                             ENDF
*                         ENDI
*                     ENDI
*                 ENDI
*                 BSR     REVERSE_COLOUR_AND_SAVE
*                 BSR     QOI_PUT_IN_PIXEL
*                 ADD     #4,A1
*             ENDI
*         ENDF

*         RTS


QOI_DECODE_C
        BSR     ZERO_PIXELS_ARRAY
        MOVE.L  #$000000FF,current_pixel_r ; px

        MOVE.L  (PICTURE_X),D1
        MOVE.L  (PICTURE_Y),D2
        MULU    D2,D1
        SUB.B   #1,D1
        MOVE.L  D1,pixel_length ; px_len

        SUB.L   #8,file_size    ; CHUNKS LEN
        CLR.B   index_run       ; run
        MOVE.L  #14,file_pixel_index ; P

        MOVE.L  #FILE_CONTENTS,A0   ; bytes
        MOVE.L  #OUTPUT_IMAGE_DATA,A1 ; pixels

        ; px_pos
        FOR.L D5 = #0 TO pixel_length BY #4 DO
            IF.B index_run <NE> #0  THEN
                SUB.B   #1,index_run
            ELSE
                MOVE.L  file_size,D2
                IF.L file_pixel_index <LO> D2   THEN
                    CLR.L   D1
                    MOVE.B  file_pixel_index(A0),D1
                    ADD.L   #2,file_pixel_index
                    ; QOI_OP_RGB
                    IF.B D1 <EQ> #254   THEN
                        MOVE.B  file_pixel_index(A0),current_pixel_r
                        ADD.L   #2,file_pixel_index
                        MOVE.B  file_pixel_index(A0),current_pixel_g
                        ADD.L   #2,file_pixel_index
                        MOVE.B  file_pixel_index(A0),current_pixel_b
                        ADD.L   #2,file_pixel_index
                    ELSE
                        ; QOI_OP_RGBA
                        IF.B D1 <EQ> #255   THEN
                            MOVE.B  file_pixel_index(A0),current_pixel_r
                            ADD.L   #2,file_pixel_index
                            MOVE.B  file_pixel_index(A0),current_pixel_g
                            ADD.L   #2,file_pixel_index
                            MOVE.B  file_pixel_index(A0),current_pixel_b
                            ADD.L   #2,file_pixel_index
                            MOVE.B  file_pixel_index(A0),current_pixel_a
                            ADD.L   #2,file_pixel_index
                        ELSE
                            ; QOI_OP_RUN
                            IF.B D1 <HS> #192   THEN
                                AND.B   #$3F,D1
                                MOVE.B  D1,index_run
                            ELSE
                                ; QOI_OP_LUMA
                                IF.B D1 <HS> #128   THEN
                                    CLR.L   D2
                                    MOVE.B  D1,D2
                                    LSL.B   #4,D2
                                    AND.B   #$03,D2
                                    SUB.B   #2,D2
                                    MOVE.B  D2,current_pixel_r
                                    
                                    MOVE.B  D1,D2
                                    LSL.B   #2,D2
                                    AND.B   #$03,D2
                                    SUB.B   #2,D2
                                    MOVE.B  D2,current_pixel_g
                                    
                                    MOVE.B  D1,D2
                                    AND.B   #$03,D2
                                    SUB.B   #2,D2
                                    MOVE.B  D2,current_pixel_b
                                ELSE
                                    ; QOI_OP_DIFF
                                    IF.B D1 <HS> #64    THEN
                                        CLR.L   D2
                                        MOVE.B  file_pixel_index(A0),D2
                                        MOVE.L  D2,D3
                                        ADD.L   #2,file_pixel_index

                                        AND.B   #$3F,D1
                                        SUB.B   #32,D1

                                        LSL.B   #4,D3
                                        AND.B   #$0F,D3
                                        SUB.B   #8,D3
                                        ADD.B   D1,D3
                                        MOVE.B  D3,current_pixel_r

                                        MOVE.B  D1,current_pixel_g

                                        AND.B   #$0F,D2
                                        SUB.B   #8,D2
                                        ADD.B   D1,D2
                                        MOVE.B  D2,current_pixel_b
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
                    BSR     QOI_PUT_IN_PIXEL
                ENDI
            ENDI

            ; pixels[px_pos + 0]
            MOVE.B  current_pixel_a,(A1,D5)
            MOVE.B  current_pixel_b,1(A1,D5)
            MOVE.B  current_pixel_g,2(A1,D5)
            MOVE.B  current_pixel_r,3(A1,D5)
        ENDF
        RTS


ZERO_PIXELS_ARRAY
        LEA     previous_seen_pixels,A0
        FOR D5 = #0 TO #255 BY #4   DO
            CLR.L  (A0,D5)
        ENDF
        RTS


QOI_PUT_IN_PIXEL
        CLR.L   D1
        CLR.L   D2
        LEA     previous_seen_pixels,A2

        MOVE.B  current_pixel_r,D1
        MULU    #3,D1
        ADD.W   D1,D2

        MOVE.B  current_pixel_g,D1
        MULU    #5,D1
        ADD.W   D1,D2

        MOVE.B  current_pixel_b,D1
        MULU    #7,D1
        ADD.W   D1,D2

        MOVE.B  current_pixel_a,D1
        MULU    #11,D1
        ADD.W   D1,D2

        DIVU    #64,D2
        MULU    #4,D2
        ADD.L   D2,A2

        MOVE.L  current_pixel_r,(A2)
        RTS

; takes the rgba colour in current_pixel
; converts it to 0bgr and saves it into A1
* REVERSE_COLOUR_AND_SAVE
*         MOVE.L  current_pixel,D1
*         IF.B D1 <NE> #0 THEN
*             MOVE.B  #0,D7
*         ENDI

*         LSR.L   #8,D1
*         MOVE.B  D1,D3
*         LSR.L   #8,D1

*         LSL.L   #8,D3
*         LSL.L   #8,D3
*         LSL.L   #8,D3
*         ADD.L   D3,D1

*         MOVE.B  D1,D3
*         LSR.L   #8,D1
*         LSL.L   #8,D3
*         ADD.W  D3,D1

*         MOVE.L  D1,(A1)
*         RTS


* ; uses D0, D7, A3
* QOI_PUT_IN_PIXEL
*         CLR.L   D7
*         LEA     current_pixel,A3
*         ; red
*         CLR.L   D0
*         MOVE.B  (A3),D0
*         MULU    #3,D0
*         ADD.L   D0,D7
*         ADD     #1,A3
*         ; green
*         CLR.L   D0
*         MOVE.B  (A3),D0
*         MULU    #5,D0
*         ADD.L   D0,D7
*         ADD     #1,A3
*         ; blue
*         CLR.L   D0
*         MOVE.B  (A3),D0
*         MULU    #7,D0
*         ADD.L   D0,D7
*         ADD     #1,A3
*         ; alpha
*         CLR.L   D0
*         MOVE.B  (A3),D0
*         MULU    #11,D0
*         ADD.L   D0,D7
*         ADD     #1,A3

*         DIVU    #64,D7

*         LEA     previous_seen_pixels,A3
*         MULU    #4,D7
*         ADD.W   D7,A3
*         MOVE.L  current_pixel,(A3)
*         RTS


RENDER_IMAGE
        MOVE.L  OUTPUT_IMAGE_DATA,A0
        FOR.L D5 = #1 TO (PICTURE_X)  DO
            FOR.L D6 = #1 TO (PICTURE_Y)  DO
                ; set pen colour
                MOVE.B  #80,D0
                MOVE.L  (A0),D1
                TRAP    #15

                ;set pixel colour
                MOVE.B  #82,D0
                MOVE.W  D5,D1
                ADD.W   #99,D1
                MOVE.W  D6,D2
                ADD.W   #99,D2
                TRAP    #15

                ADD.W   #4,A0
            ENDF
        ENDF

        RTS



EXIT_PROGRAM
        MOVE.W  #9,D0
        TRAP    #15


; stores the current pixel
current_pixel_r         DC.B    $00
current_pixel_g         DC.B    $00
current_pixel_b         DC.B    $00
current_pixel_a         DC.B    $FF
;current_pixel         DC.B    $FF
previous_seen_pixels    DS.L    64             ; stores a 64 length array of previous pixels

PICTURE_X           EQU     $10004      ; stores the x length of picture
PICTURE_Y           EQU     $10008      ; stores the y length of picture

pixel_length        DS.L    1           ; stores the number of bytes taken up by pixels
index_run           DS.B    1           ; stores the number of runs for index
file_pixel_index    DS.L    1           ; stores the file index position

file_name   DC.B    'qoi_logo.qoi',0
out_name    DC.B    'qoi_out',0
file_size   DS.L    1

FILE_CONTENTS   EQU     $10000
OUTPUT_IMAGE_DATA   EQU $20000



    END    START







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
