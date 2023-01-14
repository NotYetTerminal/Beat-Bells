*-----------------------------------------------------------
* Title      : Tester
* Written by : Gabor Major
* Date       : 2022.10.13
* Description: Moving square around using wasd
*-----------------------------------------------------------

; $100 is used as temp variable storage

PLAYER_SIZE     EQU     10  ; stores player size
MARKER_SIZE     EQU     5   ; stores marker size
OBJECTS_SIZE    EQU     10  ; stores the objects size
NUMBER_OF_OBJECTS   EQU 32  ; stores the number of max objects
NUMBER_OF_BOXES EQU     8   ; stores the number of x and y boxes
SHIELD_SIZE     EQU     20  stores the shield around the player size

START   ORG    $1000
        
        ; turn off input echo
        MOVE.W  #12,D0
        MOVE.W  #0,D1
        TRAP    #15
        
        ; turn on double buffering
        ; avoids flickering
		MOVE.L		#92,D0
        MOVE.L		#17,D1
		TRAP		#15

        ; store time in variableS
        MOVE.W  #8,D0
        TRAP    #15
        MOVE.L  D1,last_frame_time
        MOVE.L  D1,last_movement_time
        MOVE.L  D1,last_goal_change_time
        MOVE.L  D1,last_object_time
        MOVE.L  D1,last_note_spawn_time
        ; stores the time as starting seed
        MOVE.L  D1,random_value

        ; saves the screen size
        CLR.L   D1
        MOVE.W  #33,D0
        TRAP    #15
        LEA     screen_dimensions,A0
        MOVE.W  D1,screen_dimensions+2
        SWAP    D1
        MOVE.W  D1,screen_dimensions

        ; sets player position to center
        MOVE.W  D1,D2
        MOVE.W  #2,D3
        BSR     DIVIDE_NUMBER
        MOVE.W  D2,player_1_position
        
        SWAP    D1
        MOVE.W  D1,D2
        BSR     DIVIDE_NUMBER
        MOVE.W  D2,player_1_position+2

        ; saves the grid marker positions
        ; depending on screen size
        BSR     CALCULATE_GRID

        MOVE.L  #'file',song_file_name
        MOVE.L  #'.bin',song_file_name+4
        MOVE.W  #'ar',song_file_name+8
        MOVE.B  #'y',song_file_name+10
        MOVE.B  #0,song_file_name+11
        ; loads in the music from the file
        BSR     LOAD_DATA
        
        ; initialises a goal point
        ; FIX THIS LATER SO THAT THE NOTES DON'T SPAWN EARLY
        BSR     GET_NEW_GOAL_POINT


        JMP     LOOP


CALCULATE_GRID
        ; stores x,y space sizes
        MOVE.W  screen_dimensions,D2
        MOVE.W  #NUMBER_OF_BOXES+3,D3
        BSR     DIVIDE_NUMBER
        MOVE.W  D2,$100

        CLR.L   D2
        MOVE.W  #MARKER_SIZE,D2
        MOVE.W  #2,D3
        BSR     DIVIDE_NUMBER
        
        ; loops over x and y
        FOR D5 = #2 TO #NUMBER_OF_BOXES+1  DO
            MOVE.W  D5,D3
            MULU    $100,D3
            SUB.W   D2,D3             ; take HALF marker size
            LEA     grid_x_positions,A0
            ADD.L   D5,A0
            ADD.L   D5,A0
            SUB.L   #4,A0
            MOVE.W  D3,(A0)
        ENDF
        
        MOVE.W  screen_dimensions+2,D2
        MOVE.W  #NUMBER_OF_BOXES+3,D3
        BSR     DIVIDE_NUMBER
        MOVE.W  D2,$100

        CLR.L   D2
        MOVE.W  #MARKER_SIZE,D2
        MOVE.W  #2,D3
        BSR     DIVIDE_NUMBER
        
        FOR D5 = #2 TO #NUMBER_OF_BOXES+1  DO
            MOVE.W  D5,D3
            MULU    $100,D3
            SUB.W   D2,D3
            LEA     grid_y_positions,A0
            ADD.L   D5,A0
            ADD.L   D5,A0
            SUB.L   #4,A0
            MOVE.W  D3,(A0)
        ENDF

        RTS


LOAD_DATA
        ; open the file
        MOVE.B  #51,D0
        LEA     song_file_name,A1
        TRAP    #15

        ; load the file contents into memory
        MOVE.B  #53,D0
        LEA     SONG_FILE_CONTENTS,A1
        MOVE.L  #64,D2
        TRAP    #15

        ; close all files
        MOVE.B  #50,D0
        TRAP    #15

        RTS

LOOP
        ; frame delay, so that framerate is consistent
        BSR     FRAME_DELAY
        

        ; moves the enemies and notes
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_object_time,D1
        IF.L #20 <LE> D1    THEN
            BSR     MOVE_OBJECTS
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_object_time
        ENDI

        
        ; input + change position
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_movement_time,D1
        IF.L #4 <LE> D1    THEN
            BSR     HANDLE_INPUT
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_movement_time
        ENDI

        ; collision check
        BSR     CHECK_OBJECT_COLLISIONS

        ; new goal point
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_goal_change_time,D1
        IF.L #500 <LE> D1    THEN
            BSR     GET_NEW_GOAL_POINT
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_goal_change_time
        ENDI

        ; spawn new objects
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_note_spawn_time,D1
        IF.L #50 <LE> D1    THEN
            BSR     SPAWN_NEW_OBJECT
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_note_spawn_time
        ENDI

        ; render screen
        BSR     RENDER_SCREEN
                

        JMP     LOOP


FRAME_DELAY
        MOVE.W  #8,D0       ; gets the time
        TRAP    #15

        SUB.L   last_frame_time,D1  ; subtracts the two times
        CMP.L   #2,D1               ; n number of centiseconds have passed
        BLO     frame_delay

        MOVE.W  #8,D0               ; save time
        TRAP    #15
        MOVE.L  D1,last_frame_time

        RTS


HANDLE_INPUT
        MOVE.W  #19,D0
        MOVE.L  player_1_colour_keymaps,D1
        TRAP    #15
        
        IF.L #0 <NE> D1 THEN
            ; CHANGE COLOURS
            BTST.L  #24,D1
            IF  <NE>    THEN
                MOVE.L  #RED,player_1_shield_colour
            ENDI
            BTST.L  #16,D1
            IF  <NE>    THEN
                MOVE.L  #LIME,player_1_shield_colour
            ENDI
            BTST.L  #8,D1
            IF  <NE>    THEN
                MOVE.L  #YELLOW,player_1_shield_colour
            ENDI
            BTST.L  #0,D1
            IF  <NE>    THEN
                MOVE.L  #BLUE,player_1_shield_colour
            ENDI
        ELSE
            MOVE.W  #19,D0
            MOVE.L  player_1_colour_keymaps+4,D1
            TRAP    #15
            IF.L #0 <NE> D1 THEN
                ; CHANGE COLOURS ELECTRIC BOOGALOO
                BTST.L  #24,D1
                IF  <NE>    THEN
                    MOVE.L  #FUCHSIA,player_1_shield_colour
                ENDI
                BTST.L  #16,D1
                IF  <NE>    THEN
                    MOVE.L  #AQUA,player_1_shield_colour
                ENDI
                BTST.L  #8,D1
                IF  <NE>    THEN
                    MOVE.L  #WHITE,player_1_shield_colour
                ENDI
            ENDI
        ENDI
        

        BSR     HANDLE_MOVEMENT
        
        RTS


HANDLE_MOVEMENT
        MOVE.W  #19,D0
        MOVE.L  player_1_keymaps,D1  ; check for these keys
        TRAP    #15

        IF.L #0 <EQ> D1 THEN    ; checks if any key is pressed
            RTS
        ENDI
        CLR.L   D6
        CLR.L   D7

        BTST.L  #24,D1      ; checks w
        IF  <NE>    THEN
            ADD.W   #-7,D7
            BTST.L  #8,D1       ; checks if going diagonally and changes distance to 7
            IF  <NE>    THEN
                ADD.W   #2,D7
                BTST.L  #0,D1
                IF  <NE>    THEN
                    ADD.W   #-2,D7
                ENDI

            ELSE
                BTST.L  #0,D1
                IF  <NE>    THEN
                    ADD.W   #2,D7
                ENDI
            ENDI
        ENDI
        BTST.L  #16,D1      ; checks s
        IF  <NE>    THEN
            ADD.W   #7,D7
            BTST.L  #8,D1
            IF  <NE>    THEN
                ADD.W   #-2,D7
                BTST.L  #0,D1
                IF  <NE>    THEN
                    ADD.W   #2,D7
                ENDI

            ELSE
                BTST.L  #0,D1
                IF  <NE>    THEN
                    ADD.W   #-2,D7
                ENDI
            ENDI
        ENDI
        BTST.L  #8,D1       ; checks a
        IF  <NE>    THEN
            ADD.W   #-7,D6
            BTST.L  #24,D1
            IF  <NE>    THEN
                ADD.W   #2,D6
                BTST.L  #16,D1
                IF  <NE>    THEN
                    ADD.W   #-2,D6
                ENDI

            ELSE
                BTST.L  #16,D1
                IF  <NE>    THEN
                    ADD.W   #2,D6
                ENDI
            ENDI

        ENDI
        BTST.L  #0,D1       ; checks d
        IF  <NE>    THEN
            ADD.W   #7,D6
            BTST.L  #24,D1
            IF  <NE>    THEN
                ADD.W   #-2,D6
                BTST.L  #16,D1
                IF  <NE>    THEN
                    ADD.W   #2,D6
                ENDI

            ELSE
                BTST.L  #16,D1
                IF  <NE>    THEN
                    ADD.W   #-2,D6
                ENDI
            ENDI
        ENDI

        MOVE.W  #19,D0
        MOVE.L  #$10,D1     ; checks for shift pressed
        TRAP    #15

        BTST.L  #0,D1
        IF  <NE>    THEN
            ADD.W   D6,D6 ; adds the number to itself, i.e. multiply x2
            ADD.W   D7,D7
        ENDI

        LEA     player_1_position,A1   ; refernce player variable
        ADD.W   D6,(A1)+    ; add offset to position
        ADD.W   D7,(A1)
        SUB.W   #2,A1
        
        BSR     CHECK_OUT_OF_BOUNDS

        RTS


SPAWN_NEW_OBJECT
        LEA     notes_directions,A0
        LEA     notes_colours,A1
        LEA     notes_x_positions,A2
        LEA     notes_y_positions,A3
        LEA     grid_x_positions,A4
        LEA     grid_y_positions,A5
        ADD.W   goal_index,A4
        ADD.W   goal_index,A4
        ADD.W   goal_index+2,A5
        ADD.W   goal_index+2,A5
        ; NUMBER_OF_OBJECTS-1
        FOR D5 = #0 TO #1   DO
            IF.B (A0) <EQ> #$FF  THEN
                ; set the colour
                ; NEED COLOUR FROM FILE
                MOVE.W  #7,D3
                BSR     GET_RANDOM_VALUE
                IF.W D2 <EQ> #0 THEN
                    MOVE.L  #RED,(A1)
                ENDI
                IF.W D2 <EQ> #1 THEN
                    MOVE.L  #LIME,(A1)
                ENDI
                IF.W D2 <EQ> #2 THEN
                    MOVE.L  #YELLOW,(A1)
                ENDI
                IF.W D2 <EQ> #3 THEN
                    MOVE.L  #BLUE,(A1)
                ENDI
                IF.W D2 <EQ> #4 THEN
                    MOVE.L  #FUCHSIA,(A1)
                ENDI
                IF.W D2 <EQ> #5 THEN
                    MOVE.L  #AQUA,(A1)
                ENDI
                IF.W D2 <EQ> #6 THEN
                    MOVE.L  #WHITE,(A1)
                ENDI

                ; set the orientation and speed
                ;get speed
                MOVE.W  #2,D3
                BSR     GET_RANDOM_VALUE
                IF.B D2 <EQ> #0 THEN
                    IF.W goal_index <GT> #3 THEN
                        ADD.B   #%10,D2
                    ENDI
                ELSE
                    IF.W goal_index+2 <GT> #3   THEN
                        ADD.B   #%10,D2
                    ENDI
                ENDI
                MOVE.B  D2,(A0)
                
                ; set the positions
                MOVE.W  (A4),(A2)
                MOVE.W  (A5),(A3)
                ; random offset
                MOVE.W  #16,D3
                BSR     GET_RANDOM_VALUE
                IF.B (A0) <EQ> #0   THEN
                    MOVE.W  screen_dimensions,(A2)
                    SUB.W   #13,(A3)
                    ADD.W   D2,(A3)
                ENDI
                IF.B (A0) <EQ> #1   THEN
                    MOVE.W  screen_dimensions+2,(A3)
                    SUB.W   #13,(A2)
                    ADD.W   D2,(A2)
                ENDI
                IF.B (A0) <EQ> #2    THEN
                    MOVE.W  #-OBJECTS_SIZE,(A2)
                    SUB.W   #13,(A3)
                    ADD.W   D2,(A3)
                ENDI
                IF.B (A0) <EQ> #3    THEN
                    MOVE.W  #-OBJECTS_SIZE,(A3)
                    SUB.W   #13,(A2)
                    ADD.W   D2,(A2)
                ENDI

                RTS
            ENDI
            ADD.W   #$1,A0
            ADD.W   #$4,A1
            ADD.W   #$2,A2
            ADD.W   #$2,A3
        ENDF
        
        RTS


MOVE_OBJECTS
        LEA     notes_directions,A0
        LEA     notes_x_positions,A1
        LEA     notes_y_positions,A2
        FOR D5 = #0 TO #NUMBER_OF_OBJECTS-1 DO
            IF.B (A0) <NE> #$FF THEN
                IF.B (A0) <EQ> #0   THEN
                    SUB.W   #5,(A1)
                ENDI
                IF.B (A0) <EQ> #1   THEN
                    SUB.W   #5,(A2)
                ENDI
                IF.B (A0) <EQ> #2   THEN
                    ADD.W   #5,(A1)
                ENDI
                IF.B (A0) <EQ> #3   THEN
                    ADD.W   #5,(A2)
                ENDI
                BSR     OBJECT_OUT_OF_BOUNDS
            ENDI
            ADD.W   #$1,A0
            ADD.W   #$2,A1
            ADD.W   #$2,A2
        ENDF
        
        RTS

; data to be checked in A0, A1, A2
; uses D1
OBJECT_OUT_OF_BOUNDS
        ; check if out of bounds top left
        IF.W (A1) <LT> #-OBJECTS_SIZE   THEN
            MOVE.B  #$FF,(A0)   ; deletes data in A0 in notes_directions unreferencing the other data
            RTS
        ENDI
        IF.W (A2) <LT> #-OBJECTS_SIZE   THEN
            MOVE.B  #$FF,(A0)
            RTS
        ENDI

        ; check out of bounds bottom right
        MOVE.W  screen_dimensions,D1
        IF.W (A1) <GT> D1   THEN
            MOVE.B  #$FF,(A0)
            RTS
        ENDI
        MOVE.W  screen_dimensions+2,D1
        IF.W (A2) <GT> D1  THEN
            MOVE.B  #$FF,(A0)
            RTS
        ENDI

        RTS

; uses D2,D3, A1
; data to be checked in A1
CHECK_OUT_OF_BOUNDS
        ; check if out of bounds top left
        IF.W (A1) <LT> #5     THEN
            MOVE.W  #5,(A1)
        ENDI
        ADD.W   #2,A1
        IF.W (A1) <LT> #5    THEN
            MOVE.W  #5,(A1)
        ENDI

        ; check out of bounds bottom right
        MOVE.W  screen_dimensions,D2
        MOVE.W  screen_dimensions+2,D3
        
        SUB.W   #PLAYER_SIZE,D2
        SUB.W   #PLAYER_SIZE,D3

        SUB.W   #5,D2
        SUB.W   #5,D3

        IF.W D2 <LT> -(A1) THEN
            MOVE.W  D2,(A1)
        ENDI
        ADD.W   #2,A1
        IF.W D3 <LT> (A1) THEN
            MOVE.W  D3,(A1)
        ENDI

        RTS

; USES D0 -> D5
; uses A0, A1, A2, A3
CHECK_OBJECT_COLLISIONS
        MOVE.W  player_1_position,D0
        MOVE.W  player_1_position+2,D1
        SUB.W   #5,D0
        SUB.W   #5,D1
        MOVE.W  D0,D2
        MOVE.W  D1,D3
        ADD.W   #SHIELD_SIZE,D2
        ADD.W   #SHIELD_SIZE,D3
        
        LEA     notes_x_positions,A0
        LEA     notes_y_positions,A1
        LEA     notes_colours,A2
        LEA     notes_directions,A3
        FOR D6 = #0 TO #NUMBER_OF_OBJECTS-1 DO
            IF.B (A3) <NE> #$FF THEN
                MOVE.W  (A0),D4
                MOVE.W  D4,D5
                ADD.W   #OBJECTS_SIZE,D5

                IF.W D4 <GE> D0 AND.W D4 <LE> D2    THEN
                    BSR     CHECK_Y
                ELSE
                    IF.W D5 <GE> D0 AND.W D5 <LE> D2    THEN
                        BSR     CHECK_Y
                    ENDI
                ENDI
            ENDI
            
            ADD.W   #$2,A0
            ADD.W   #$2,A1
            ADD.W   #$4,A2
            ADD.W   #$1,A3
        ENDF

        RTS


CHECK_Y
        MOVE.W  (A1),D4
        MOVE.W  D4,D5
        ADD.W   #OBJECTS_SIZE,D5
        IF.W D4 <GE> D1 AND.W D4 <LE> D3    THEN
            MOVE.B  #$FF,(A3)
            IF.L A2 <EQ> player_1_shield_colour THEN
                NOP
            ENDI
        ELSE
            IF.W D5 <GE> D1 AND.W D5 <LE> D3    THEN
                MOVE.B  #$FF,(A3)
                IF.L A2 <EQ> player_1_shield_colour THEN
                    NOP
                ENDI
            ENDI
        ENDI
        
        RTS


RENDER_SCREEN
        BSR     DRAW_BACKGROUND
        BSR     DRAW_OBJECTS
        BSR     DRAW_PLAYER_1
        
        MOVE.L  #94,D0      ; repaints screen
		TRAP    #15
		MOVE.L  #$FF00,D1   ; clears buffer
		MOVE.L  #11,D0
		TRAP    #15

        RTS


DRAW_BACKGROUND
        ; sets the pen and fill to blue
        MOVE.L  #BLUE,D1
        MOVE.W  #80,D0
        TRAP    #15
        MOVE.W  #81,D0
        TRAP    #15
        
        MOVE.W  #MARKER_SIZE,D3
        MOVE.W  #MARKER_SIZE,D4

        ; loops over x and y
        FOR D5 = #0 TO #NUMBER_OF_BOXES-1  DO
            FOR D6 = #0 TO #NUMBER_OF_BOXES-1  DO
                LEA     grid_x_positions,A1
                ADD.W   D5,A1
                ADD.W   D5,A1
                MOVE.W  (A1),$100

                LEA     grid_y_positions,A1
                ADD.W   D6,A1
                ADD.W   D6,A1
                MOVE.W  (A1),$102
                
                LEA     $100,A0
                IF.W goal_index <EQ> D5 THEN
                    IF.W goal_index+2 <EQ> D6   THEN
                        MOVE.L  #WHITE,D1   ; change colour to white
                        MOVE.W  #80,D0
                        TRAP    #15
                        MOVE.W  #81,D0
                        TRAP    #15
                        
                        BSR     DRAW_SQUARE
                        
                        MOVE.L  #BLUE,D1   ; change colour back to blue
                        MOVE.W  #80,D0
                        TRAP    #15
                        MOVE.W  #81,D0
                        TRAP    #15
                    ELSE
                        BSR     DRAW_SQUARE
                    ENDI
                ELSE
                    BSR     DRAW_SQUARE
                ENDI
            ENDF
        ENDF

        RTS


DRAW_OBJECTS
        LEA     notes_colours,A0
        LEA     notes_x_positions,A1
        LEA     notes_y_positions,A2
        LEA     notes_directions,A3
        FOR D5 = #0 TO #NUMBER_OF_OBJECTS-1 DO
            IF.B (A3) <NE> #$FF THEN
                ; sets the note colour
                MOVE.W  #80,D0
                MOVE.L  (A0),D1
                TRAP    #15
                MOVE.W  #81,D0
                TRAP    #15

                MOVE.W  (A1),D1
                MOVE.W  (A2),D2
                MOVE.W  D1,D3
                MOVE.W  D2,D4
                ADD.W   #OBJECTS_SIZE,D3
                ADD.W   #OBJECTS_SIZE,D4
                MOVE.W  #91,D0
                TRAP    #15

            ENDI
            ADD.W   #$4,A0
            ADD.W   #$2,A1
            ADD.W   #$2,A2
            ADD.W   #$1,A3
        ENDF
        
        RTS



DRAW_PLAYER_1
        ; sets the pen and fill to red
        MOVE.W  #80,D0
        MOVE.L  #GREY,D1
        TRAP    #15
        MOVE.W  #81,D0
        TRAP    #15
        
        LEA     player_1_position,A0   ; refernce player variable
        MOVE.W  #PLAYER_SIZE,D3
        MOVE.W  #PLAYER_SIZE,D4
        BSR     DRAW_SQUARE
        
        ; sets the pen width to 3
        MOVE.W  #93,D0
        MOVE.W  #3,D1
        TRAP    #15

        ; draw the player shield
        MOVE.W  #80,D0
        MOVE.L  player_1_shield_colour,D1
        TRAP    #15
        
        MOVE.W  player_1_position,D1
        MOVE.W  player_1_position+2,D2
        SUB.W   #5,D1
        SUB.W   #5,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4
        ADD.W   #SHIELD_SIZE,D3
        ADD.W   #SHIELD_SIZE,D4

        MOVE.W  #91,D0
        TRAP    #15
        
        MOVE.W  #93,D0
        MOVE.W  #1,D1
        TRAP    #15

        RTS

; draws a square at A0 plus size in D3,D4
DRAW_SQUARE
        MOVE.W  (A0)+,D1    ; set bounds of square to draw
        MOVE.W  (A0),D2
        ADD.W   D1,D3
        ADD.W   D2,D4

        MOVE.W  #87,D0
        TRAP    #15
        
        SUB.W   D1,D3
        SUB.W   D2,D4

        RTS


GET_NEW_GOAL_POINT
        MOVE.W  #NUMBER_OF_BOXES,D3
        BSR     GET_RANDOM_VALUE
        MOVE.W  D2,goal_index       ; x value

        BSR     GET_RANDOM_VALUE
        MOVE.W  D2,goal_index+2     ; y value

        RTS

; gets random number into D2.W
; D3.W needs to have the range of numbers in it
GET_RANDOM_VALUE
        MOVE.L  random_value,D0
        MOVEQ   #$AF-$100,D1
        MOVEQ   #18,D2
NINC0
        ADD.L   D0,D0
        BCC     NINC1
        EOR.B   D1,D0
NINC1
        DBF     D2,NINC0
        MOVE.L  D0,random_value
        MOVE.L  D0,D2

        BSR     DIVIDE_NUMBER
        SWAP    D2                  ; remainder is now in D2.W, i.e. the random number
        RTS

; dividend in D2.L
; divisor in D3.W
; mask in D4.L
; result in D2.L
DIVIDE_NUMBER
        MOVE.W  D3,D4
        SUB.W   #1,D4
        SWAP    D4
        MOVE.W  #$FFFF,D4

        AND.L   D4,D2          ; prevent overflow, FFFF plus n-1 on left side
        DIVU    D3,D2              ; divide by number of values wanted
        RTS


DONE    MOVE.W  #9,D0
        TRAP    #15


last_frame_time         DS.L    1   ; stores the time at last frame
last_movement_time      DS.L    1   ; stores the time when last accepted input
last_goal_change_time   DS.L    1   ; stores the time when goal last changed
last_object_time        DS.L    1   ; stores the time when the notes where moved
last_note_spawn_time    DS.L    1   ; stores the time when note was last spawned
screen_dimensions       DS.W    2   ; stores screen size x,y

player_1_position       DS.W    2       ; stores the top right player position x,y
player_1_keymaps        DC.L    'WSAD'  ; stores the movement keys of player
player_1_shield_colour  DC.L    RED     ; stores the player shield colour that is active
player_1_colour_keymaps DC.L    'HNUJIKL' ; stores the keymaps for the player changing colours

random_value            DS.L    1   ; stores a random variable
goal_index              DS.W    2   ; stores the index values of the goal square

grid_x_positions        DS.W    NUMBER_OF_BOXES ; stores the positions of the markers
grid_y_positions        DS.W    NUMBER_OF_BOXES ; stores the positions of the markers

notes_x_positions       DS.W    NUMBER_OF_OBJECTS  ; stores the notes x positions
notes_y_positions       DS.W    NUMBER_OF_OBJECTS  ; atores the notes y positions
notes_directions        DS.B    NUMBER_OF_OBJECTS  ; stores the notes directions, 0x <-, 1x ^, 2x ->, 3x v
notes_colours           DS.L    NUMBER_OF_OBJECTS  ; stores the notes colours

note_time_to_spawn      DS.W    1   ; stores the time to spawn the next note
song_file_name          DS.B    16  ; stores the name of the song file to be played

; THE PROGRAM MUST NOT USE THIS MEMORY
; data structure is
; 4 bit number represents each line for that quarter beat
; 0 rest, 1 1/4, 2 1/2, 3 1/1, 4 1.5/1, 5 2/1, 6 3/1, 7 4/1
; last bit represents, 0 normal, 1 sharp note
; 4 bits * 16 lines gives 64 bits or 8 bytes ber quarter beat
SONG_FILE_CONTENTS      EQU     $3000   ; stores the data for the song file


; COLOURS
BLACK       EQU     $00000000
MAROON      EQU     $00000080
GREEN       EQU     $00008000
OLIVE       EQU     $00008080
NAVY        EQU     $00800000
PURPLE      EQU     $00800080
TEAL        EQU     $00808000
GREY        EQU     $00808080
RED         EQU     $000000FF
LIME        EQU     $0000FF00
YELLOW      EQU     $0000FFFF
BLUE        EQU     $00FF0000
FUCHSIA     EQU     $00FF00FF
AQUA        EQU     $00FFFF00
LITEGREY    EQU     $00C0C0C0
WHITE       EQU     $00FFFFFF


    END     START





















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
