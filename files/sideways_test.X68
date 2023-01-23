*-----------------------------------------------------------
* Title      :  sideways test
* Written by :  Gabor Major
* Date       :  13/01/2023
* Description:  project test
*-----------------------------------------------------------

* TODO
* Notes
* implement base track
* implement txt file reading
* 
* Gameplay
* change psudo random path index to change after long not change
* 
* Graphics
* check if the centre of lanes is calculated correctly
* change beat line to be only infront of player
* change only player beat line and player model colours
* action colour chages too quickly, needs to be animated
* render letters on notes
* GRAPHICAL TESTING
* 
* OPTIMISE USING THE COUNTER
* 
* ISSUES
* at the big slap the note times array is incorrect
* some notes flicker
* 
* Menu
* tutorial menu
* load in song name
* load in song difficulty
* make it so there is a delay before ending the game and returns to menu
* 
* Varibles
* song difficulty
* song temp
* notes speed
* song file name

; set constants
SCREEN_WIDTH            EQU     1280
SCREEN_HEIGHT           EQU     720

BORDER_SIZE             EQU     20
LANE_SIZE               EQU     (SCREEN_HEIGHT-BORDER_SIZE-BORDER_SIZE)/5
BEAT_LINE_X             EQU     200

PLAYER_SIZE             EQU     20
NOTE_SIZE               EQU     40

NOTE_OBJECT_SIZE        EQU     48


; program start
START   ORG    $1000

        ; turn off input echo
        MOVE.L  #12,D0
        ; 0 in D1
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

        ; sets the song difficulty
        MOVE.B  #1,song_difficulty

        JMP     LOOP


; loads in all notes into DirectX memory
NOTE_SET_UP
        LEA     BASIC_PATH,A1
        LEA     NOTES_NAMES_0,A2
        FOR D1 = #0 TO #101  DO
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
            IF.L #20 <LE> D1    THEN
                BSR     RESET_PLAYER_1_ACTION
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
                    ; moves the notes by 8
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
                IF.W (A1) <LT> #BEAT_LINE_X THEN
                    ; check collision with player line
                    IF.B player_1_lane_number <EQ> D5   THEN
                        MOVE.W  -(A1),D1
                        BSR     GET_COLOUR_FROM_INDEX
                        ; note has been hit correctly
                        IF.L player_1_action_colour <EQ> D1 THEN
                            MOVE.B  #1,last_note_success
                            ; sets the position to the left to make the note disappear when checking collision
                            CLR.W   (A1)
                            BSR     RESET_PLAYER_1_ACTION
                        ELSE
                            IF.L player_1_action_colour <NE> #WHITE THEN
                                ADD.W   #2,A1
                                CLR.W   (A1)
                                SUB.W   #2,A1
                            ENDI
                        ENDI
                        ADD.W   #2,A1
                    ENDI
                    ; check collision with the beat line, ie too late
                    IF.W (A1) <LT> #BEAT_LINE_X-NOTE_SIZE-NOTE_SIZE THEN
                        ; check if it was an invisible or hit note
                        IF.W -(A1) <EQ> #0  THEN
                            IF.B last_note_success <EQ> #1  THEN
                                BSR     PLAY_MUSIC_ON_HIT
                            ENDI
                        ELSE
                            CLR.B   last_note_success
                        ENDI
                        MOVE.W  #$FFFF,(A1)
                        BSR     LANE_LEFT_SHIFT
                    ENDI
                ENDI
            ENDI
            ADD.W   #34,A0
        ENDF
        RTS


; must not use D5, A0, A1
; A1 contains the address to the start of the note object, ie it's colour
PLAY_MUSIC_ON_HIT
        ADD.W   #8,A1
        ; A1 now contains the address to actual note data

        CLR.L 	D3
        CLR.L 	D4
        LEA     notes_times_array,A2
        FOR D6 = #0 TO #NOTE_OBJECT_SIZE-9 DO
            ; D3 contains the number of beats to play the note for
            MOVE.B  (A1,D6),D3
            IF #0 <NE> D3   THEN
                ADD.B   #1,D6
                MOVE.B  (A1,D6),D4
                LEA     NOTES_NAMES_0,A3

                ; if not 0
                IF #48 <NE> D4  THEN
                    ; if 8
                    IF #56 <EQ> D4  THEN
                        MOVE.B  #101,D1
                        ADD.B   #2,D6
                    ELSE
                        SUB.B   #49,D4
                        MULU    #14,D4
                        ADD.B   #3,D4

                        ADD.B   #1,D6
                        MOVE.B  (A1,D6),D1
                        SUB.B   #97,D1
                        ADD.B   #1,D6
                        IF.B (A1,D6) <EQ> #115  THEN
                            ADD.B   #7,D1
                        ENDI
                        ADD.B   D4,D1
                    ENDI
                ELSE
                    ADD.B   #1,D6
                    MOVE.B  (A1,D6),D1
                    SUB.B   #97,D1
                    ADD.B   #1,D6
                    IF.B (A1,D6) <EQ> #115  THEN
                        ADD.B   #2,D1
                    ENDI
                ENDI
                ; D1 now contains the index number of the note both for DirectX and rest times
                
                ; stops a note playing if it is
                IF.B (A2,D1) <NE> #$FF   THEN
                    MOVE.L  #77,D0
                    MOVE.L  #2,D2
                    TRAP    #15
                ENDI

                ; puts in the rest time
                SUB.B   #64,D3
                MOVE.B  D3,(A2,D1)

                ; D1 needed here
                MOVE.B  #75,D0
                TRAP    #15
            ELSE
                SUB.W   #8,A1
                RTS
            ENDI
        ENDF
        SUB.W   #8,A1
        RTS


; shifts the lane in A0 one to the left, deleting the object at index 0
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
                BTST.B  #7,player_1_action_pressed
                IF  <EQ>    THEN
                    MOVE.L  #RED,player_1_action_colour
                    BSET.B  #7,player_1_action_pressed
                ENDI
            ENDI
            BTST.L  #16,D1
            IF  <NE>    THEN
                BTST.B  #6,player_1_action_pressed
                IF  <EQ>    THEN
                    MOVE.L  #ORANGE,player_1_action_colour
                    BSET.B  #6,player_1_action_pressed
                ENDI
            ENDI
            BTST.L  #8,D1
            IF  <NE>    THEN
                BTST.B  #5,player_1_action_pressed
                IF  <EQ>    THEN
                    MOVE.L  #YELLOW,player_1_action_colour
                    BSET.B  #5,player_1_action_pressed
                ENDI
            ENDI
            BTST.L  #0,D1
            IF  <NE>    THEN
                BTST.B  #4,player_1_action_pressed
                IF  <EQ>    THEN
                    MOVE.L  #LIME,player_1_action_colour
                    BSET.B  #4,player_1_action_pressed
                ENDI
            ENDI
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_beat_change_time
        ELSE
            ; clears the actions pressed
            BCLR.B  #7,player_1_action_pressed
            BCLR.B  #6,player_1_action_pressed
            BCLR.B  #5,player_1_action_pressed
            BCLR.B  #4,player_1_action_pressed

            MOVE.W  #19,D0
            MOVE.L  player_1_colour_keymaps+4,D1
            TRAP    #15

            IF.L #0 <NE> D1 THEN
                ; change colours electric boogaloo
                BTST.L  #24,D1
                IF  <NE>    THEN
                    BTST.B  #3,player_1_action_pressed
                    IF  <EQ>    THEN
                        MOVE.L  #AQUA,player_1_action_colour
                        BSET.B  #3,player_1_action_pressed
                    ENDI
                ENDI
                BTST.L  #16,D1
                IF  <NE>    THEN
                    BTST.B  #2,player_1_action_pressed
                    IF  <EQ>    THEN
                        MOVE.L  #BLUE,player_1_action_colour
                        BSET.B  #2,player_1_action_pressed
                    ENDI
                ENDI
                BTST.L  #8,D1
                IF  <NE>    THEN
                    BTST.B  #1,player_1_action_pressed
                    IF  <EQ>    THEN
                        MOVE.L  #PURPLE2,player_1_action_colour
                        BSET.B  #1,player_1_action_pressed
                    ENDI
                ENDI
                MOVE.W  #8,D0
                TRAP    #15
                MOVE.L  D1,last_beat_change_time
            ELSE
                ; clears the actions pressed
                BCLR.B  #3,player_1_action_pressed
                BCLR.B  #2,player_1_action_pressed
                BCLR.B  #1,player_1_action_pressed
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
        CLR.L   D2
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


RESET_PLAYER_1_ACTION
        MOVE.L  #WHITE,player_1_action_colour
        MOVE.L  #0,last_beat_change_time
        RTS


SPAWN_NEW_NOTE
        MOVE.L  song_file_index,A0

        ; song has ended
        IF.B (A0) <EQ> #$FF THEN
            BSR     EXIT_PROGRAM
        ENDI

        ; check for carraige return and line feed
        IF.B (A0) <EQ> #13  THEN
            ADD.L   #2,song_file_index
            ADD.L   #2,A0
        ENDI

        ; first byte is checked if there are any notes being played
        IF.B #48 <NE> (A0) THEN
            BSR     CREATE_NOTE_OBJECT
            IF A2 <EQ> #$0  THEN
                RTS
            ENDI
            BSR     LOAD_NOTE_DATA
        ELSE
            ADD.L   #2,song_file_index
        ENDI

        ADD.B   #1,quater_beat_count
        MOVE.B  song_difficulty,D0
        IF.B quater_beat_count <EQ> D0 THEN
            CLR.B   quater_beat_count
        ENDI
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
        ;ILLEGAL
        RTS


; A0 contains the address to the current song data beat note
; A2 contains the address to the start of music note object
LOAD_NOTE_DATA
        ; load the music data into the note object
        MOVE.L  #8,D3
        SUB.L   #8,A0
        WHILE.B (A0,D3) <NE> #44   DO
            MOVE.B  (A0,D3),(A2,D3)
            ADD.W   #1,D3
        ENDW
        MOVE.B  #0,(A2,D3)
        SUB.L   #8,D3
        ADD.L   D3,song_file_index
        ADD.L   #1,song_file_index

        ; gets the number of notes playing on the same beat
        DIVU    #4,D3

        ; assign a colour based on the playing notes
        ; and the difficulty
        IF.B quater_beat_count <NE> #0  THEN
            CLR.W   (A2)
        ELSE
            BSR     PICK_NOTE_COLOUR
        ENDI

        ; assign x and y position based on the path index
        ADD.W   #2,A2
        MOVE.W  #SCREEN_WIDTH,(A2)
        ADD.W   #2,A2
        CLR.L   D2
        MOVE.B  note_path_index,D2
        BSR     GET_LANE_Y_POSITION
        MOVE.W  D3,(A2)
        SUB.W   #NOTE_SIZE/2,(A2)

        ; adds note object to the end of the lane queue
        BSR     GET_LANE_ADDRESS_FROM_INDEX
        SUB.W   #4,A2
        BSR     ENQUEUE_OBJECT_TO_LANE
        RTS


; needs to have the number of notes in D3
; choose a random frequency to pick as the visible colour
PICK_NOTE_COLOUR
        IF D3 <NE> #1   THEN
            BSR     GET_RANDOM_VALUE
        ELSE
            MOVE.W  #0,D2
        ENDI
        MULU    #4,D2
        ADD.W   #10,D2
        MOVE.B  (A2,D2),D2
        SUB.B   #96,D2
        MOVE.W  D2,(A2)
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

        LEA     lane_0_object_addresses,A1
        ; loops through the five lanes
        FOR D5 = #0 TO #4   DO
            MOVE.L  A1,A2
            ; loops until encounters an empty position
            IF.W (A2) <NE> #$FFFF   THEN
                DBLOOP D6 = #15
                    MOVE.W  (A2),A0
                    IF.W (A0) <NE> #0 AND.W (A0) <NE> #$FFFF    THEN
                        MOVE.B  #80,D0
                        MOVE.W  (A0),D1
                        BSR     GET_COLOUR_FROM_INDEX
                        TRAP    #15
                        MOVE.W  #81,D0
                        TRAP    #15
                        ADD.W   #2,A0

                        MOVE.W  #NOTE_SIZE,D3
                        MOVE.W  #NOTE_SIZE,D4
                        BSR     DRAW_SQUARE
                    ENDI
                    ADD.W   #2,A2
                UNLESS.W (A2) <NE> #$FFFF
            ENDI
            ADD.W   #34,A1
        ENDF
        RTS


; colour index needs to be in D1.W
; returns the colour into D1.L
GET_COLOUR_FROM_INDEX
        IF.W D1 <EQ> #0 THEN
            CLR.L   D1
        ELSE
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
player_1_moving         DC.B    0       ; stores whether the player is moving up or down
player_1_action_pressed DC.B    0       ; stores whether any action buttons are pressed
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
;   W   useless
;   L*10   music notes data, same as in the file
note_path_index         DS.B    1       ; stores the lane index of the note path
song_file_index         DS.L    1       ; stores the byte index that the song is at

notes_times_array       DS.B    102     ; contains the times for each note that needs to be hold

file_size               DS.L    1       ; stores the size of the song file in bytes
file_name               DC.B    'songs/Troupe Master Grimm T.txt',0
; THE PROGRAM MUST NOT USE THE FOLLOWING MEMORY ADDRESS
; THERE IS A CHECK AT THE START OF THE PROGRAM TO STOP THIS FROM HAPPENEING
; IT IS ILLEGAL AND RAISES AN ERROR
FILE_CONTENTS           EQU     $10000

; notes names
BASIC_PATH              DC.B    'notes/aaa.wav',0
NOTES_NAMES_0           DC.B    '0an0bn0as'
NOTES_NAMES_1           DC.B    '1an1bn1cn1dn1en1fn1gn1as1bs1cs1ds1es1fs1gs'
NOTES_NAMES_2           DC.B    '2an2bn2cn2dn2en2fn2gn2as2bs2cs2ds2es2fs2gs'
NOTES_NAMES_3           DC.B    '3an3bn3cn3dn3en3fn3gn3as3bs3cs3ds3es3fs3gs'
NOTES_NAMES_4           DC.B    '4an4bn4cn4dn4en4fn4gn4as4bs4cs4ds4es4fs4gs'
NOTES_NAMES_5           DC.B    '5an5bn5cn5dn5en5fn5gn5as5bs5cs5ds5es5fs5gs'
NOTES_NAMES_6           DC.B    '6an6bn6cn6dn6en6fn6gn6as6bs6cs6ds6es6fs6gs'
NOTES_NAMES_7           DC.B    '7an7bn7cn7dn7en7fn7gn7as7bs7cs7ds7es7fs7gs'
NOTES_NAMES_8           DC.B    '8cn'


song_difficulty         DS.B    1       ; stores the difficulty of the song playing, 16 - easy, 8 - medium, 4 - hard, 2 - expert, 1 - all the notes
quater_beat_count       DC.B    0       ; stores the count of quater beats played
last_note_success       DC.B    0       ; stores whether the last hit note was correct


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
