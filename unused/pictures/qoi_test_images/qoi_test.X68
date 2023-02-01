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
    
    MOVE.B  #50,D0
    TRAP    #15


    SIMHALT

file_name   DC.B    'qoi_logo.qoi',0

FILE_CONTENTS   EQU     $10000


    END    START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
