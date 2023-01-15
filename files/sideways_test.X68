*-----------------------------------------------------------
* Title      :  sideways test
* Written by :  Gabor Major
* Date       :  13/01/2023
* Description:  project test
*-----------------------------------------------------------

* TODO
* Notes
* drawing notes should be looped over lane objects
* notes need to play automatically when invisible NOT TESTED YET
* 
* Controls
* add delay to repeted actions, but not when action is correct
* 
* Gameplay
* implement difficulty for see through notes
* change the timing of notes spawning
* make it so that only on every full or half beat the notes are spawned
* change psudo random path index to change after long not change
* make it so there is a delay before ending the game
* 
* Graphics
* check if the centre of lanes is calculated correctly
* change beat line to be only infront of player
* change only player beat line and player model colours
* GRAPHICAL TESTING
* 
* 
* ISSUES
* weird ghost notes, that play when they shouldn't
* sometimes some notes don't render
* song file index goes above what is required

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
        MOVE.L  D1,last_path_change_time
        MOVE.L  D1,last_object_time
        MOVE.L  D1,last_note_spawn_time
        MOVE.L  D1,last_beat_change_time
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
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_object_time,D1
        IF.L #2 <LE> D1    THEN
            BSR     MOVE_OBJECTS
            BSR     CHECK_COLLISIONS
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_object_time
        ENDI

        ; input + change position
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_movement_time,D1
        IF.L #8 <LE> D1    THEN
            BSR     HANDLE_INPUT
            BSR     CHECK_COLLISIONS
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_movement_time
        ENDI

        ; collision check
*        BSR     CHECK_OBJECT_COLLISIONS

        ; new path index
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_path_change_time,D1
        IF.L #200 <LE> D1    THEN
            BSR     CHANGE_PATH_INDEX
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_path_change_time
        ENDI

        ; checks for cooldown time
        IF.L last_beat_change_time <NE> #0  THEN
            MOVE.W  #8,D0
            TRAP    #15
            SUB.L   last_beat_change_time,D1
            IF.L #100 <LE> D1    THEN
                MOVE.L  #WHITE,player_1_action_colour
                MOVE.L  #0,last_beat_change_time
            ENDI
        ENDI

        ; spawn new notes
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_note_spawn_time,D1
        IF.L #10 <LE> D1    THEN
            BSR     SPAWN_NEW_NOTE
            BSR     DECREMENT_NOTES_TIMES
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
        BLO     FRAME_DELAY
        ; save time
        MOVE.W  #8,D0
        TRAP    #15
        MOVE.L  D1,last_frame_time

        RTS


MOVE_OBJECTS
        LEA     lane_0_object_addresses,A0
        ; loops through the five lanes
        FOR D5 = #0 TO #4   DO
            MOVE.L  A0,A1
            ; loops until encounters an empty position
            IF.W (A1) <NE> #$FFFF   THEN
                DBLOOP D6 = #15
                    MOVE.W  (A1),A2
                    ADD.W   #2,A2
                    SUB.W   #8,(A2)
                    ADD.W   #2,A1
                UNLESS.W (A1) <NE> #$FFFF
            ENDI
            ADD.W   #34,A0
        ENDF
        RTS


CHECK_COLLISIONS
        LEA     lane_0_object_addresses,A0
        ; loops through the five lanes
        FOR D5 = #0 TO #4   DO
            IF.W (A0) <NE> #$FFFF   THEN
                MOVE.W  (A0),A1
                ADD.W   #2,A1
                ; check if the note is close to beat line
                IF.W (A1) <LT> #BEAT_LINE_X-NOTE_OBJECT_SIZE    THEN
                    ; check collision with player line
                    IF.B player_1_lane_number <EQ> D5   THEN
                        MOVE.W  -(A1),D1
                        MOVE.W  #0,D1
                        IF.W D1 <EQ> #0 THEN
                            BSR     PLAY_MUSIC_ON_HIT
                        ELSE
                            BSR     GET_COLOUR_FROM_INDEX
                            IF.L player_1_action_colour <EQ> D1 THEN
                                BSR     PLAY_MUSIC_ON_HIT
                            ENDI
                        ENDI
                        ADD.W   #2,A1
                    ENDI
                    ; check collision with the beat line, ie too late
                    IF.W (A1) <LT> #BEAT_LINE_X-NOTE_OBJECT_SIZE-NOTE_OBJECT_SIZE   THEN
                        SUB.W   #2,A1
                        MOVE.W  #$FFFF,(A1)
                        BSR     LANE_LEFT_SHIFT
                    ENDI
                ENDI
            ENDI
            ADD.W   #34,A0
        ENDF
        RTS


; must not use D5, A0, A1
PLAY_MUSIC_ON_HIT
        ; sets the position to the left to make the note disappear when checking collision
        ADD.W   #2,A1
        CLR     (A1)
        ADD.W   #4,A1

        CLR 	D3
        FOR D6 = #0 TO #7   DO
            IF.B (A1,D6) <NE> #0    THEN
                MOVE.B  #1,D3
            ENDI
        ENDF

        IF.B D3 <NE> #0 THEN
            CLR     D3
        ENDI
        
        CLR 	D3
        LEA     notes_times_array,A2
        FOR D6 = #0 TO #7   DO
            MOVE.B  (A1,D6),D3
            IF.L #0 <NE> D3 THEN
                CLR     D2
                ; splits the four bits of d2 byte into d1
                BCLR.L  #7,D3
                IF  <NE>    THEN
                    ADD.B   #8,D2
                ENDI
                BCLR.L  #6,D3
                IF  <NE>    THEN
                    ADD.B   #4,D2
                ENDI
                BCLR.L  #5,D3
                IF  <NE>    THEN
                    ADD.B   #2,D2
                ENDI
                BCLR.L  #4,D3
                IF  <NE>    THEN
                    ADD.B   #1,D2
                ENDI
                ; checks if note is played
                IF #0 <NE> D2   THEN
                    MOVE.B  D6,D1
                    LSL.B   #1,D1
                    ; checks for sharp
                    BTST.L  #3,D2
                    IF  <NE>    THEN
                        ADD.B   #16,D1
                        SUB.B   #8,D2
                        BSR     REST_TIME_FROM_INDEX
                        ; puts in rest time
                        ADD.L   #16,A2
                        BSR     STOP_NOTE_PLAYING
                        MOVE.B  (A3),(A2)
                        SUB.L   #16,A2
                    ELSE
                        BSR     REST_TIME_FROM_INDEX
                        BSR     STOP_NOTE_PLAYING
                        MOVE.B  (A3),(A2)
                    ENDI
                    ; D1 needed here
                    MOVE.B  #75,D0
                    TRAP    #15
                ENDI
                IF #0 <NE> D3   THEN
                    MOVE.B  D3,D2
                    MOVE.B  D6,D1
                    LSL.B   #1,D1
                    ADD.B   #1,D1
                    ; checks for sharp
                    BTST.L  #3,D2
                    ADD.L   #1,A2
                    IF  <NE>    THEN
                        ADD.B   #16,D1
                        SUB.B   #8,D2
                        BSR     REST_TIME_FROM_INDEX
                        ; puts in rest time
                        ADD.L   #16,A2
                        BSR     STOP_NOTE_PLAYING
                        MOVE.B  (A3),(A2)
                        SUB.L   #16,A2
                    ELSE
                        BSR     REST_TIME_FROM_INDEX
                        BSR     STOP_NOTE_PLAYING
                        MOVE.B  (A3),(A2)
                    ENDI
                    SUB.L   #1,A2
                    ; D1 needed here
                    MOVE.B  #75,D0
                    TRAP    #15
                ENDI
            ENDI
            ADD.L   #2,A2
        ENDF
        SUB.W   #6,A1

        RTS

; D2.L holds the index
; returns value at (A3)
; choose which rest time to put in
REST_TIME_FROM_INDEX
        LEA     rest_times_array,A3
        ADD.L   D2,A3
        SUB.L   #1,A3
        RTS

; stops a note playing if it is
STOP_NOTE_PLAYING
        IF.B (A2) <NE> #$FF   THEN
            MOVE.L  #2,D2
            MOVE.L  #77,D0
            TRAP    #15
        ENDI
        RTS

; shifts the lane in A0 one to the left, deleting the ojetct at index 0
LANE_LEFT_SHIFT
        MOVE.W  A0,A2
        SUB.W   #2,A2
        SUB.W   #2,(A2)
        MOVE.L  #2,D7
        FOR.W D6 = #0 TO (A2) BY #2 DO
            MOVE.W  (A0,D7),(A0,D6)
            ADD.B   #2,D7
        ENDF
        RTS


HANDLE_INPUT
        IF last_beat_change_time <EQ> #0    THEN
            BSR     HANDLE_COLOUR_CHANGE
        ENDI
        BSR     HANDLE_MOVEMENT
        RTS


HANDLE_COLOUR_CHANGE
        MOVE.W  #19,D0
        MOVE.L  player_1_colour_keymaps,D1
        TRAP    #15

        IF.L #0 <NE> D1 THEN
            ; change colours
            BTST.L  #24,D1
            IF  <NE>    THEN
                MOVE.L  #RED,player_1_action_colour
            ENDI
            BTST.L  #16,D1
            IF  <NE>    THEN
                MOVE.L  #ORANGE,player_1_action_colour
            ENDI
            BTST.L  #8,D1
            IF  <NE>    THEN
                MOVE.L  #YELLOW,player_1_action_colour
            ENDI
            BTST.L  #0,D1
            IF  <NE>    THEN
                MOVE.L  #LIME,player_1_action_colour
            ENDI
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_beat_change_time
        ELSE
            MOVE.W  #19,D0
            MOVE.L  player_1_colour_keymaps+4,D1
            TRAP    #15

            IF.L #0 <NE> D1 THEN
                ; change colours electric boogaloo
                BTST.L  #24,D1
                IF  <NE>    THEN
                    MOVE.L  #AQUA,player_1_action_colour
                ENDI
                BTST.L  #16,D1
                IF  <NE>    THEN
                    MOVE.L  #BLUE,player_1_action_colour
                ENDI
                BTST.L  #8,D1
                IF  <NE>    THEN
                    MOVE.L  #PURPLE2,player_1_action_colour
                ENDI
                MOVE.W  #8,D0
                TRAP    #15
                MOVE.L  D1,last_beat_change_time
            ENDI
        ENDI
        RTS

HANDLE_MOVEMENT
        MOVE.W  #19,D0
        ; check for these keys
        MOVE.L  player_1_keymaps,D1
        TRAP    #15

        ; checks if any key is pressed
        IF.L #0 <EQ> D1 THEN
            CLR.B   player_1_moving
            RTS
        ENDI

        ; checks W
        BTST.L  #24,D1
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
        ; checks S
        BTST.L  #16,D1
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


; changes the path node index
CHANGE_PATH_INDEX
        ; if at the top or bottom only call random 2 as it can't go outside the map
        IF.B note_path_index <EQ> #0    THEN
            BSR     RANDOM_2
            IF  <NE>    THEN
                ADD.B   #1,note_path_index
            ENDI
        ELSE
            IF.B note_path_index <EQ> #4    THEN
                BSR     RANDOM_2
                IF  <NE>    THEN
                    SUB.B   #1,note_path_index
                ENDI
            ELSE
                MOVE.W  #3,D3
                BSR     GET_RANDOM_VALUE
                ADD.B   D2,note_path_index
                SUB.B   #1,note_path_index
            ENDI
        ENDI
        RTS


SPAWN_NEW_NOTE
        MOVE.L  song_file_index,A0
        ; song has ended
        IF.L (A0) <EQ> #$FFFFFFFF   THEN
            BSR     EXIT_PROGRAM
        ENDI
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
        ILLEGAL
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
        MOVE.W  #SCREEN_WIDTH,(A2)
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
        CLR     D3
        FOR D5 = #0 TO #7   DO
            IF.B (A2,D5) <NE> #0    THEN
                SUB.B   #1,D2
                IF.W D2 <EQ> #0 THEN
                    MOVE.B  (A2,D5),D7
                    IF D7 <GT> #15  THEN
                        ; checks if the right side has any bits
                        BTST    #0,D7
                        IF  <NE>    THEN
                            BSR     CHOOSE_RANDOM_AND_PICK
                            RTS
                        ENDI
                        BTST    #1,D7
                        IF  <NE>    THEN
                            BSR     CHOOSE_RANDOM_AND_PICK
                            RTS
                        ENDI
                        BTST    #2,D7
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
        BSR     RANDOM_2
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
        ADD.W   #1,D3
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


; loops over music time array
; decrements times for each note
DECREMENT_NOTES_TIMES
        LEA notes_times_array,A1
        FOR D5 = #0 TO #30  DO
            IF.B (A1,D5) <NE> #$FF  THEN
                SUB.B   #1,(A1,D5)
                IF.B (A1,D5) <EQ> #0    THEN
                    ; stops a note playing
                    MOVE.B  D5,D1
                    MOVE.L  #2,D2
                    MOVE.L  #77,D0
                    TRAP    #15
                    MOVE.B  #$FF,(A1,D5)
                ENDI
            ENDI
        ENDF
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
        ;MOVE.L  #$00FFFFFF,D1
        MOVE.L  player_1_action_colour,D1
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
            IF.W D1 <NE> #0 THEN
                IF.W D1 <NE> #$FFFF THEN
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


; colour index needs to be in D1.W
; returns the colour into D1.L
GET_COLOUR_FROM_INDEX
        IF.W D1 <EQ> #1 THEN
            MOVE.L  #BLUE,D1
        ELSE
            IF.W D1 <EQ> #2 THEN
                MOVE.L  #PURPLE2,D1
            ELSE
                IF.W D1 <EQ> #3 THEN
                    MOVE.L  #RED,D1
                ELSE
                    IF.W D1 <EQ> #4 THEN
                        MOVE.L  #ORANGE,D1
                    ELSE
                        IF.W D1 <EQ> #5 THEN
                            MOVE.L  #YELLOW,D1
                        ELSE
                            IF.W D1 <EQ> #6 THEN
                                MOVE.L  #LIME,D1
                            ELSE
                                IF.W D1 <EQ> #7 THEN
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


; uses D0, D1
; uses BTST to get result, sets the Z flag
RANDOM_2
        ; get time
        MOVE.B  #8,D0
        TRAP    #15
        BTST    #0,D1
        RTS


EXIT_PROGRAM
        MOVE.W  #9,D0
        TRAP    #15


; variables
random_value            DS.L    1       ; stores a random variable

last_frame_time         DS.L    1       ; stores the time at last frame
last_movement_time      DS.L    1       ; stores the time when last accepted input
last_path_change_time   DS.L    1       ; stores the time when path index last changed
last_object_time        DS.L    1       ; stores the time when the notes where moved
last_note_spawn_time    DS.L    1       ; stores the time when note was last spawned
last_beat_change_time   DS.L    1       ; stores the time when beat was last checked and put back into white

player_1_position       DS.W    2       ; stores the top right player position x,y
player_1_lane_number    DS.B    1       ; stores the lane number
player_1_moving         DS.B    1       ; stores whther the player is moving up or down
player_1_keymaps        DC.L    'WS'    ; stores the movement keys of player
player_1_action_colour  DC.L    WHITE   ; stores the player action colour
player_1_colour_keymaps DC.L    'YHUJIKL' ; stores the keymaps for the player changing colours

; stores the number of objects in the arrays
lane_0_object_count     DC.W    0
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
