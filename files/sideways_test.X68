*-----------------------------------------------------------
* Title      :  sideways test
* Written by :  Gabor Major
* Date       :  13/01/2023
* Description:  project test
*-----------------------------------------------------------

* TODO
* Notes
* drawing notes should be looped over lane objects
* notes need to be moved to the left
* notes need to be deleted when gone past the beat line, MUST CHANGE THE COLOUR TO #$FFFF
* notes need to be played when hit at beat line
* notes need to play automatically when invisible
* 
* Controls
* accept input for colours
* add delay to repeted actions, but not when action is correct
* 
* Gameplay
* implement difficulty for see through notes
* 
* Graphics
* check if the centre of lanes is calculated correctly

; set constants
SCREEN_WIDTH        EQU     1280
SCREEN_HEIGHT       EQU     720

BORDER_SIZE         EQU     20
LANE_SIZE           EQU     (SCREEN_HEIGHT-BORDER_SIZE-BORDER_SIZE)/5
BEAT_LINE_X         EQU     200

PLAYER_SIZE         EQU     20
NOTE_SIZE           EQU     40

NOTE_OBJECT_SIZE    EQU     14


; program start
START   ORG    $1000

        ; turn off input echo
        MOVE.L  #12,D0
        CLR     D1
        TRAP    #15
        
        ; turn on double buffering
        ; avoids flickering
		MOVE.L  #92,D0
        MOVE.B  #17,D1
		TRAP    #15
		
		; store time in variables
        MOVE.W  #8,D0
        TRAP    #15
        MOVE.L  D1,last_frame_time
        MOVE.L  D1,last_movement_time
        ;MOVE.L  D1,last_goal_change_time
        ;MOVE.L  D1,last_object_time
        MOVE.L  D1,last_note_spawn_time
        ; stores the time as starting seed
        MOVE.L  D1,random_value

        ; sets the screen size
        MOVE.L  #33,D0
        MOVE.L  #SCREEN_WIDTH*$10000+SCREEN_HEIGHT,D1
        TRAP    #15

        ; sets the players up/down movement to nothing
        MOVE.B  #0,player_1_moving
        ; sets the player's position
        MOVE.W  #100,player_1_position
        MOVE.B  #2,player_1_lane_number
        BSR     CHANGE_PLAYER_1_POSITION

        ; sets a random starting lane for the note path
        MOVE.W  #5,D3
        BSR     GET_RANDOM_VALUE
        MOVE.B  D2,note_path_index

        ; sets the index to the start
        MOVE.L  #FILE_CONTENTS,song_file_index
        
        ; sets up notes and music
        ; checks if $10000 has been accidentally used
        IF.L FILE_CONTENTS <NE> #$FFFFFFFF  THEN
            ILLEGAL
        ENDI
        BSR     NOTE_SET_UP
        LEA     file_name,A1
        BSR     LOAD_IN_SONG

        JMP     LOOP


NOTE_SET_UP
        ; loads in note rest times
        LEA     rest_times_array,A1
        MOVE.B  #2,(A1)+
        MOVE.B  #3,(A1)+
        MOVE.B  #5,(A1)+
        MOVE.B  #7,(A1)+
        MOVE.B  #9,(A1)+
        MOVE.B  #13,(A1)+
        MOVE.B  #17,(A1)

        ; loads in all notes into DirectX memory
        ; some note files do not exist and will cause warnings
        LEA     BASIC_PATH,A1
        LEA     ALL_NOTES_NAMES,A2
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


; loads in a song binary file
; file name address needs to be in A1
; loads the file into $10000
LOAD_IN_SONG
        MOVE.B  #51,D0
        TRAP    #15

        MOVE.B  #53,D0
        LEA     FILE_CONTENTS,A1
        MOVE.L  #$FFFFF,D2
        TRAP    #15

        MOVE.B  #50,D0
        TRAP    #15

        BSR     SAVE_FILE_SIZE
        RTS


; saves the file size
SAVE_FILE_SIZE
        MOVE.L  D2,file_size
        DIVU    #8,D2
        CLR     D1
        MOVE.W  D2,D1
        MOVE.L  D1,second_size
        RTS


LOOP
        ; frame delay, so that framerate is consistent
        BSR     FRAME_DELAY
        

        ; moves the enemies and notes
*        MOVE.W  #8,D0
*        TRAP    #15
*        SUB.L   last_object_time,D1
*        IF.L #20 <LE> D1    THEN
*            BSR     MOVE_OBJECTS
*            MOVE.W  #8,D0
*            TRAP    #15
*            MOVE.L  D1,last_object_time
*        ENDI

        
        ; input + change position
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_movement_time,D1
        IF.L #8 <LE> D1    THEN
            BSR     HANDLE_INPUT
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_movement_time
        ENDI

        ; collision check
*        BSR     CHECK_OBJECT_COLLISIONS

        ; spawn new notes
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_note_spawn_time,D1
        IF.L #50 <LE> D1    THEN
            BSR     SPAWN_NEW_NOTE
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_note_spawn_time
        ENDI

        ; render screen
        BSR     RENDER_SCREEN

        JMP     LOOP


FRAME_DELAY
        ; gets the time
        MOVE.W  #8,D0
        TRAP    #15
        ; subtracts the two times
        SUB.L   last_frame_time,D1
        ; n number of centiseconds have passed
        CMP.L   #2,D1
        BLO     frame_delay
        ; save time
        MOVE.W  #8,D0
        TRAP    #15
        MOVE.L  D1,last_frame_time

        RTS


HANDLE_INPUT
*        MOVE.W  #19,D0
*        MOVE.L  player_1_colour_keymaps,D1
*        TRAP    #15
*
*        IF.L #0 <NE> D1 THEN
*            ; CHANGE COLOURS
*            BTST.L  #24,D1
*            IF  <NE>    THEN
*                MOVE.L  #RED,player_1_shield_colour
*            ENDI
*            BTST.L  #16,D1
*            IF  <NE>    THEN
*                MOVE.L  #LIME,player_1_shield_colour
*            ENDI
*            BTST.L  #8,D1
*            IF  <NE>    THEN
*                MOVE.L  #YELLOW,player_1_shield_colour
*            ENDI
*            BTST.L  #0,D1
*            IF  <NE>    THEN
*                MOVE.L  #BLUE,player_1_shield_colour
*            ENDI
*        ELSE
*            MOVE.W  #19,D0
*            MOVE.L  player_1_colour_keymaps+4,D1
*            TRAP    #15
*
*            IF.L #0 <NE> D1 THEN
*                ; CHANGE COLOURS ELECTRIC BOOGALOO
*                BTST.L  #24,D1
*                IF  <NE>    THEN
*                    MOVE.L  #FUCHSIA,player_1_shield_colour
*                ENDI
*                BTST.L  #16,D1
*                IF  <NE>    THEN
*                    MOVE.L  #AQUA,player_1_shield_colour
*                ENDI
*                BTST.L  #8,D1
*                IF  <NE>    THEN
*                    MOVE.L  #WHITE,player_1_shield_colour
*                ENDI
*            ENDI
*        ENDI

        BSR     HANDLE_MOVEMENT
        RTS


HANDLE_MOVEMENT
        MOVE.W  #19,D0
        ;MOVE.L  player_1_keymaps,D1  ; check for these keys
        MOVE.L  #'WS',D1
        TRAP    #15

        ; checks if any key is pressed
        IF.L #0 <EQ> D1 THEN
            CLR.B   player_1_moving
            RTS
        ENDI

        ; checks w
        BTST.L  #8,D1
        IF  <NE>    THEN
            BTST.B  #0,player_1_moving
            IF  <EQ>    THEN
                IF.B player_1_lane_number <NE> #0 THEN
                    SUB.B   #1,player_1_lane_number
                    BSET.B  #0,player_1_moving
                ENDI
            ENDI
        ELSE
            BCLR.B  #0,player_1_moving
        ENDI
        ; checks s
        BTST.L  #0,D1
        IF  <NE>    THEN
            BTST.B  #1,player_1_moving
            IF  <EQ>    THEN
                IF.B player_1_lane_number <NE> #4 THEN
                    ADD.B   #1,player_1_lane_number
                    BSET.B  #1,player_1_moving
                ENDI
            ENDI
        ELSE
            BCLR.B  #1,player_1_moving
        ENDI

        BSR     CHANGE_PLAYER_1_POSITION
        RTS


CHANGE_PLAYER_1_POSITION
        CLR     D2
        MOVE.B  player_1_lane_number,D2
        BSR     GET_LANE_Y_POSITION
        MOVE.W  D3,player_1_position+2
        RTS


; needs to have lane index in D2.L
; returns the y position of the middle of the lane in D3.W
GET_LANE_Y_POSITION
        MOVE.L  #LANE_SIZE,D3
        MULU    D2,D3
        MOVE.L  #LANE_SIZE,D2
        ADD.W   #BORDER_SIZE,D2
        DIVU    #2,D2
        ADD.W   D2,D3
        RTS


SPAWN_NEW_NOTE
        MOVE.L  song_file_index,A0
        ; two longs are checked if there are any notes being played
        IF.L #0 <NE> (A0) THEN
            ADD.W   #4,A0
            BSR     CREATE_NOTE_OBJECT
            IF A2 <EQ> #$0  THEN
                RTS
            ENDI
            BSR     LOAD_NOTE_DATA
        ELSE
            ADD.W   #4,A0
            IF.L #0 <NE> (A0)   THEN
                BSR     CREATE_NOTE_OBJECT
                IF A2 <EQ> #$0  THEN
                    RTS
                ENDI
                BSR     LOAD_NOTE_DATA
            ENDI
        ENDI
        ADD.L   #8,song_file_index
        RTS


; returns new object address in A2
; 0 in A2 means that the array is full
CREATE_NOTE_OBJECT
        LEA     note_objects,A2
        FOR D5 = #0 TO #15  DO
            IF.W (A2) <EQ> #$FFFF   THEN
                RTS
            ENDI
            ADD.W   #NOTE_OBJECT_SIZE,A2
        ENDF
        MOVE.L  #0,A2
        RTS


LOAD_NOTE_DATA
        ; load the music data into the note object
        SUB.W   #4,A0
        ADD.W   #6,A2
        MOVE.L  (A0),(A2)
        ADD.W   #4,A0
        ADD.W   #4,A2
        MOVE.L  (A0),(A2)

        ; assign a colour based on the playing notes
        ; and the difficulty
        CLR     D3
        ADD.W   #3,A2
        FOR D5 = #0 TO #7  DO
            IF.B (A2) <NE> #0   THEN
                ADD.B   #1,D3
            ENDI
            SUB.W   #1,A2
        ENDF
        ADD.W   #1,A2

        BSR     PICK_NOTE_COLOUR

        ; assign x and y position based on the path index
        ADD.W   #2,A2
        MOVE.W  #SCREEN_WIDTH/2,(A2)
        ADD.W   #2,A2
        CLR     D2
        MOVE.B  note_path_index,D2
        BSR     GET_LANE_Y_POSITION
        MOVE.W  D3,(A2)
        SUB.W   #NOTE_SIZE/2,(A2)

        ; adds note object to the end of the lane queue
        BSR     GET_LANE_ADDRESS_FROM_INDEX
        SUB.W   #4,A2
        BSR     ENQUEUE_OBJECT_TO_LANE
        RTS
            

; choose a random frequency to pick as the visible colour
PICK_NOTE_COLOUR
        IF D3 <NE> #1   THEN
            BSR     GET_RANDOM_VALUE
        ELSE
            MOVE.W  #1,D2
        ENDI
        MOVE.L  #1,D3
        FOR D5 = #0 TO #7   DO
            IF.B (A2,D5) <NE> #0    THEN
                SUB.B   #1,D2
                IF.W D2 <EQ> #0 THEN
                    IF.B (A2,D5) <GT> #15   THEN
                        ; checks if the right side has any bits
                        BTST.B  #0,(A2,D5)
                        IF  <NE>    THEN
                            BSR     CHOOSE_RANDOM_AND_PICK
                            RTS
                        ENDI
                        BTST.B  #1,(A2,D5)
                        IF  <NE>    THEN
                            BSR     CHOOSE_RANDOM_AND_PICK
                            RTS
                        ENDI
                        BTST.B  #2,(A2,D5)
                        IF  <NE>    THEN
                            BSR     CHOOSE_RANDOM_AND_PICK
                            RTS
                        ENDI
                        ; only left side has bits
                        BSR     ASSIGN_COLOUR_INDEX
                    ELSE
                        ; second half of byte
                        ADD.B   #1,D3
                        BSR     ASSIGN_COLOUR_INDEX
                        RTS
                    ENDI
                ENDI
            ENDI
            ADD.B   #2,D3
        ENDF
        RTS


CHOOSE_RANDOM_AND_PICK
        ; get time
        MOVE.B  #8,D0
        TRAP    #15
        BTST    #0,D1
        IF  <NE>    THEN
            ADD.B   #1,D3
        ENDI
        BSR     ASSIGN_COLOUR_INDEX
        RTS


ASSIGN_COLOUR_INDEX
        SUB.W   #6,A2
        ; modulo 7
        IF D3 <GE> #7   THEN
            SUB.B   #7,D3
            IF D3 <GE> #7   THEN
                SUB.B   #7,D3
            ENDI
        ENDI
        MOVE.W  D3,(A2)
        RTS


; returns the lane address in A0
GET_LANE_ADDRESS_FROM_INDEX
        IF.B note_path_index <EQ> #0    THEN
            LEA     lane_0_object_addresses,A0
        ELSE
            IF.B note_path_index <EQ> #1    THEN
                LEA     lane_1_object_addresses,A0
            ELSE
                IF.B note_path_index <EQ> #2    THEN
                    LEA     lane_2_object_addresses,A0
                ELSE
                    IF.B note_path_index <EQ> #3    THEN
                        LEA     lane_3_object_addresses,A0
                    ELSE
                        LEA     lane_4_object_addresses,A0
                    ENDI
                ENDI
            ENDI
        ENDI
        RTS


; uses A1
; lane address needs to be in A0
; object address needs to be in A2
ENQUEUE_OBJECT_TO_LANE
        MOVE.L  A0,A1
        SUB.W   #2,A1
        ADD.W   (A1),A0
        MOVE.W  A2,(A0)
        ADD.W   #2,(A1)
        RTS

* SPAWN_NEW_NOTE_OLD
*         BSR     CREATE_NOTE_OBJECT
*         IF A2 <EQ> #$0  THEN
*             RTS
*         ENDI
*         MOVE.L  song_file_index,A0
*         LEA     notes_times_array,A1
*         CLR     D3
*         FOR D5 = #0 TO #7   DO
*             MOVE.B  (A0),D3
*             IF.L #0 <NE> D3 THEN
*                 CLR     D2
*                 ; splits the upper four bits of D3.B into D2.B
*                 BTST.L  #7,D3
*                 IF  <NE>    THEN
*                     ADD.B   #8,D2
*                     SUB.B   #128,D3
*                 ENDI
*                 BTST.L  #6,D3
*                 IF  <NE>    THEN
*                     ADD.B   #4,D2
*                     SUB.B   #64,D3
*                 ENDI
*                 BTST.L  #5,D3
*                 IF  <NE>    THEN
*                     ADD.B   #2,D2
*                     SUB.B   #32,D3
*                 ENDI
*                 BTST.L  #4,D3
*                 IF  <NE>    THEN
*                     ADD.B   #1,D2
*                     SUB.B   #16,D3
*                 ENDI
*                 ; checks if note is played
*                 IF #0 <NE> D2   THEN
*                     MOVE.B  D5,D1
*                     ADD.B   D5,D1
                
*                 ENDI
*                IF #0 <NE> D3   THEN
*                    MOVE.B  D5,D1
*                    ADD.B   D5,D1
*                    ADD.B   #1,D1
*                    BTST.L  #3,D3
*                    ADD.L   #1,A1
*                    IF  <NE>    THEN
*                        ADD.B   #16,D1
*                        SUB.B   #8,D3
*                        ; choose which rest time to put in
*                        LEA     rest_times_array,A2
*                        ADD.L   D3,A2
*                        SUB.L   #1,A2
*                        ; puts in rest time
*                        ADD.L   #16,A1
*                        ; stops a note playing if it is
*                        IF.B (A1) <NE> #$FF   THEN
*                            MOVE.L  #2,D2
*                            MOVE.L  #77,D0
*                            TRAP    #15
*                        ENDI
*                        MOVE.B  (A2),(A1)
*                        SUB.L   #16,A1
*                    ELSE
*                        ; choose which rest time to put in
*                        LEA     rest_times_array,A2
*                        ADD.L   D3,A2
*                        SUB.L   #1,A2
*                        ; stops a note playing if it is
*                        IF.B (A1) <NE> #$FF   THEN
*                            MOVE.L  #2,D2
*                            MOVE.L  #77,D0
*                            TRAP    #15
*                        ENDI
*                        MOVE.B  (A2),(A1)
*                    ENDI
*                    SUB.L   #1,A1
*                    MOVE.B  #75,D0
*                    TRAP    #15
*                ENDI
        *     ENDI
        *     ADD.W   #1,A0
        *     ADD.L   #2,A1
        * ENDF
        * ADD.L   #8,song_file_index
        * RTS


PLAY_MUSIC_ON_HIT

        RTS

; plays music that is loaded in
PLAY_IN_MUSIC
*    LEA     FILE_CONTENTS,A0
*    MOVE.L  #0,D3
*    FOR D5 = #0 TO #SECOND_SIZE-1 DO
*        LEA notes_times_array,A1
*        FOR D6 = #0 TO #7   DO
*            MOVE.B  (A0),D3
*            MOVE.L  #0,D2
*            IF.L #0 <NE> D3 THEN
*                ; splits the four bits of d2 byte into d1
*                BTST.L  #7,D3
*                IF  <NE>    THEN
*                    ADD.B   #8,D2
*                    SUB.B   #128,D3
*                ENDI
*                BTST.L  #6,D3
*                IF  <NE>    THEN
*                    ADD.B   #4,D2
*                    SUB.B   #64,D3
*                ENDI
*                BTST.L  #5,D3
*                IF  <NE>    THEN
*                    ADD.B   #2,D2
*                    SUB.B   #32,D3
*                ENDI
*                BTST.L  #4,D3
*                IF  <NE>    THEN
*                    ADD.B   #1,D2
*                    SUB.B   #16,D3
*                ENDI
*                ; checks if note is played
*                IF #0 <NE> D2   THEN
*                    MOVE.B  D6,D1
*                    ADD.B   D6,D1
*                    BTST.L  #3,D2
*                    ; check if the note is a sharp
*                    IF  <NE>    THEN
*                        ADD.B   #16,D1
*                        SUB.B   #8,D2
*                        ; choose which rest time to put in
*                        LEA     rest_times_array,A2
*                        ADD.L   D2,A2
*                        SUB.L   #1,A2
*                        ; puts in rest time
*                        ADD.L   #16,A1
*                        ; stops a note playing if it is
*                        IF.B (A1) <NE> #$FF   THEN
*                            MOVE.L  #2,D2
*                            MOVE.L  #77,D0
*                            TRAP    #15
*                        ENDI
*                        MOVE.B  (A2),(A1)
*                        SUB.L   #16,A1
*                    ELSE
*                        ; choose which rest time to put in
*                        LEA     rest_times_array,A2
*                        ADD.L   D2,A2
*                        SUB.L   #1,A2
*                        ; stops a note playing if it is
*                        IF.B (A1) <NE> #$FF   THEN
*                            MOVE.L  #2,D2
*                            MOVE.L  #77,D0
*                            TRAP    #15
*                        ENDI
*                        MOVE.B  (A2),(A1)
*                    ENDI
*                    MOVE.B  #75,D0
*                    TRAP    #15
*                ENDI
*                IF #0 <NE> D3   THEN
*                    MOVE.B  D6,D1
*                    ADD.B   D6,D1
*                    ADD.B   #1,D1
*                    BTST.L  #3,D3
*                    ADD.L   #1,A1
*                    IF  <NE>    THEN
*                        ADD.B   #16,D1
*                        SUB.B   #8,D3
*                        ; choose which rest time to put in
*                        LEA     rest_times_array,A2
*                        ADD.L   D3,A2
*                        SUB.L   #1,A2
*                        ; puts in rest time
*                        ADD.L   #16,A1
*                        ; stops a note playing if it is
*                        IF.B (A1) <NE> #$FF   THEN
*                            MOVE.L  #2,D2
*                            MOVE.L  #77,D0
*                            TRAP    #15
*                        ENDI
*                        MOVE.B  (A2),(A1)
*                        SUB.L   #16,A1
*                    ELSE
*                        ; choose which rest time to put in
*                        LEA     rest_times_array,A2
*                        ADD.L   D3,A2
*                        SUB.L   #1,A2
*                        ; stops a note playing if it is
*                        IF.B (A1) <NE> #$FF   THEN
*                            MOVE.L  #2,D2
*                            MOVE.L  #77,D0
*                            TRAP    #15
*                        ENDI
*                        MOVE.B  (A2),(A1)
*                    ENDI
*                    SUB.L   #1,A1
*                    MOVE.B  #75,D0
*                    TRAP    #15
*                ENDI
*            ENDI
*            ADD.W   #1,A0
*            ADD.L   #2,A1
*        ENDF
*        ; loops over music time array
*        ; decrements times for each note
*        LEA notes_times_array,A1
*        FOR D6 = #0 TO #30  DO
*            ADD.L   D6,A1
*            IF.B    (A1) <NE> #$FF  THEN
*                SUB.B   #1,(A1)
*                IF.B    (A1) <EQ> #0    THEN
*                    ; stops a note playing
*                    MOVE.B  D6,D1
*                    MOVE.L  #2,D2
*                    MOVE.L  #77,D0
*                    TRAP    #15
*                    MOVE.B  #$FF,(A1)
*                ENDI
*            ENDI
*            SUB.L   D6,A1
*        ENDF
*        BSR FRAME_DELAY
*    ENDF

    RTS


RENDER_SCREEN
        BSR     DRAW_BACKGROUND
        BSR     DRAW_NOTES
        BSR     DRAW_PLAYER_1

        ; repaints screen
        MOVE.B  #94,D0
		TRAP    #15
		; clears buffer
		MOVE.B  #11,D0
		MOVE.W  #$FF00,D1
		TRAP    #15

        RTS


DRAW_BACKGROUND
        ; sets pen and fill colour to white
        MOVE.B  #80,D0
        MOVE.L  #$00FFFFFF,D1
        TRAP    #15
        MOVE.W  #81,D0
        TRAP    #15
        
        BSR     DRAW_LANE_LINES
        BSR     DRAW_BEAT_LINE
        RTS


DRAW_LANE_LINES
        ; sets pen width
        MOVE.B  #93,D0
        MOVE.B  #3,D1
        TRAP    #15
        
        MOVE.W  #BORDER_SIZE+1,D1
        MOVE.W  #SCREEN_WIDTH-BORDER_SIZE-1,D3
        FOR D5 = #0 TO #5   DO
            MOVE.W  #LANE_SIZE,D2
            MULU    D5,D2
            ADD.W   #BORDER_SIZE,D2
            MOVE.W  D2,D4
            BSR     DRAW_LINE
        ENDF
        RTS


DRAW_BEAT_LINE
        ; sets pen width
        MOVE.B  #93,D0
        MOVE.B  #5,D1
        TRAP    #15

        MOVE.W  #BEAT_LINE_X,D1
        MOVE.W  #BORDER_SIZE+1,D2
        MOVE.W  #BEAT_LINE_X,D3
        MOVE.W  #SCREEN_HEIGHT-BORDER_SIZE-1,D4
        BSR     DRAW_LINE
        RTS


; line from D1.W,D2.W TO D3.W,D4.W
DRAW_LINE
        MOVE.B  #84,D0
        TRAP    #15
        RTS


DRAW_NOTES
        ; sets pen width
        MOVE.B  #93,D0
        MOVE.B  #3,D1
        TRAP    #15

        LEA     note_objects,A0
        FOR D5 = #0 TO #15  DO
            ; sets pen and fill colour to white
            MOVE.W  (A0),D1
            IF.B D1 <NE> #0 THEN
                IF.B D1 <NE> #$FF   THEN
                    MOVE.B  #80,D0
                    BSR     GET_COLOUR_FROM_INDEX
                    TRAP    #15
                    MOVE.W  #81,D0
                    TRAP    #15
                    ADD.W   #2,A0

                    MOVE.W  #NOTE_SIZE,D3
                    MOVE.W  #NOTE_SIZE,D4
                    BSR     DRAW_SQUARE
                    SUB.W   #4,A0
                ENDI
            ENDI
            ADD.W   #NOTE_OBJECT_SIZE,A0
        ENDF
        
        RTS


; colour index needs to be in D1.B
; returns the colour into D1.L
GET_COLOUR_FROM_INDEX
        IF.B D1 <EQ> #1 THEN
            MOVE.L  #BLUE,D1
        ELSE
            IF.B D1 <EQ> #2 THEN
                MOVE.L  #PURPLE2,D1
            ELSE
                IF.B D1 <EQ> #3 THEN
                    MOVE.L  #RED,D1
                ELSE
                    IF.B D1 <EQ> #4 THEN
                        MOVE.L  #ORANGE,D1
                    ELSE
                        IF.B D1 <EQ> #5 THEN
                            MOVE.L  #YELLOW,D1
                        ELSE
                            IF.B D1 <EQ> #6 THEN
                                MOVE.L  #LIME,D1
                            ELSE
                                IF.B D1 <EQ> #7 THEN
                                    MOVE.L  #AQUA,D1
                                ENDI
                            ENDI
                        ENDI
                    ENDI
                ENDI
            ENDI
        ENDI
        
        RTS



DRAW_PLAYER_1
        ; sets pen width
        MOVE.B  #93,D0
        MOVE.B  #3,D1
        TRAP    #15

        ; sets pen and fill colour to white
        MOVE.B  #80,D0
        MOVE.L  #$00FFFFFF,D1
        TRAP    #15
        MOVE.W  #81,D0
        TRAP    #15

        LEA     player_1_position,A0
        MOVE.W  #PLAYER_SIZE,D3
        MOVE.W  #PLAYER_SIZE,D4
        BSR     DRAW_SQUARE
        
        ; draws the square bounding box
        SUB.W   #40,D1
        SUB.W   #40,D2
        ADD.W   #40,D3
        ADD.W   #40,D4

        MOVE.W  #90,D0
        TRAP    #15
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


; uses D0, D1, D2, D3
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
        SWAP    D2
        ; remainder is now in D2.W, i.e. the random number
        RTS


; uses D1, D2, D3
; dividend in D2.L
; divisor in D3.W
; result in D2.L
DIVIDE_NUMBER
        MOVE.W  D3,D1
        SUB.W   #1,D1
        SWAP    D1
        ; mask in D1.L
        MOVE.W  #$FFFF,D1

        ; prevent overflow, FFFF plus n-1 on left side
        AND.L   D1,D2
        ; divide by number of values wanted
        DIVU    D3,D2
        RTS


EXIT_PROGRAM
        MOVE.W  #9,D0
        TRAP    #15


; variables
random_value            DS.L    1       ; stores a random variable

last_frame_time         DS.L    1       ; stores the time at last frame
last_movement_time      DS.L    1       ; stores the time when last accepted input
last_note_spawn_time    DS.L    1       ; stores the time when note was last spawned

player_1_position       DS.W    2       ; stores the top right player position x,y
player_1_lane_number    DS.B    1       ; stores the lane number
player_1_moving         DS.B    1       ; stores whther the player is moving up or down

; stores the number of objects in the arrays
lane_0_object_count     DC.B    0
; stores the addresses of objects in the rows
; these are queues
lane_0_object_addresses DS.W    16
lane_1_object_count     DC.W    0
lane_1_object_addresses DS.W    16
lane_2_object_count     DC.W    0
lane_2_object_addresses DS.W    16
lane_3_object_count     DC.W    0
lane_3_object_addresses DS.W    16
lane_4_object_count     DC.W    0
lane_4_object_addresses DS.W    16


note_objects            DS.W    NOTE_OBJECT_SIZE*8    ; stores the notes objects data
;   note object structure:
;   W   note colour index, 0 means that it is invisible
;   W   x position
;   W   y position
;   L   music notes data, same as in the file
;   L   music notes data
note_path_index         DS.B    1       ; stores the lane index of the note path
song_file_index         DS.L    1       ; stores the byte index that the song is at

notes_times_array       DS.B    31      ; contains the times for each note that needs to be hold
rest_times_array        DS.B    7       ; contains the number of quater beats needed for each note

file_size               DS.L    1      ; stores the size of the song file in bytes
second_size             DS.L    1      ; stores the size of the song file divided by 8 in bytes
file_name               DC.B    'songs/number_one',0
; THE PROGRAM MUST NOT USE THE FOLLOWING MEMORY ADDRESS
; THERE IS A CHECK AT THE START OF THE PROGRAM TO STOP THIS FROM HAPPENEING
; IT IS ILLEGAL AND RAISES AN ERROR
FILE_CONTENTS           EQU     $10000

; notes names
BASIC_PATH              DC.B    'notes/aaa.wav',0
ALL_NOTES_NAMES         DC.B    'a10b10c10d10e10f10g10a20b20c20d20e20f20g20a30b30a11b11c11d11e11f11g11a21b21c21d21e21f21g21a31'


; COLOURS
BLACK           EQU     $00000000
MAROON          EQU     $00000080
GREEN           EQU     $00008000
OLIVE           EQU     $00008080
NAVY            EQU     $00800000
PURPLE          EQU     $00800080
TEAL            EQU     $00808000
GREY            EQU     $00808080
BLUE            EQU     $00FF0000       ; A
PURPLE2         EQU     $00FF0080       ; B
RED             EQU     $000000FF       ; C
ORANGE          EQU     $000080FF       ; D
YELLOW          EQU     $0000FFFF       ; E
LIME            EQU     $0000FF00       ; F
AQUA            EQU     $00FFFF00       ; G
MAGENTA         EQU     $00FF00FF
LITEGREY        EQU     $00C0C0C0
WHITE           EQU     $00FFFFFF


        END    START










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
