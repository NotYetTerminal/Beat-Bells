*-----------------------------------------------------------
* Title      :  sideways test
* Written by :  Gabor Major
* Date       :  13/01/2023
* Description:  project test
*-----------------------------------------------------------

* TODO
* 
* Gameplay
* change psudo random path index to change after long not change
* 
* Graphics
* check if the centre of lanes is calculated correctly
* change only player beat line and player model colours
* GRAPHICAL TESTING
* 
* OPTIMISE USING THE COUNTER
* rendering is wasteful it uses a for loop instead of stopping
* 
* Music
* make it so the invisible notes are played when they are center over beat line
* 
* Warnings
* if in the piano sheet there is a held note with lines then it won't play the full thing
* this is an issue of the transcriber and not the assembly code
* when reading in the sound files the program won't find any B or E sharps, the warnings
* can be ignored these don't exist
* 
* Menu
* tutorial menu
* load in song name
* load in song difficulty
* make it so there is a delay before ending the game and returns to menu
* 
* Variables
* song difficulty
* song file name
* one or two player

; set constants
SCREEN_WIDTH            EQU     1280
SCREEN_HEIGHT           EQU     720

BORDER_SIZE             EQU     20
LANE_SIZE               EQU     (SCREEN_HEIGHT-BORDER_SIZE-BORDER_SIZE)/5
BEAT_LINE_X             EQU     200

PLAYER_SIZE             EQU     20
NOTE_SIZE               EQU     40

NOTE_OBJECT_SIZE        EQU     48
LANE_ADDRESSES_SIZE     EQU     55


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
        MOVE.L  D1,player_1_last_beat_change_time
        MOVE.L  D1,player_2_last_beat_change_time
        ; stores the time as starting seed
        MOVE.L  D1,random_value

        ; sets the screen size
        MOVE.L  #33,D0
        MOVE.L  #SCREEN_WIDTH*$10000+SCREEN_HEIGHT,D1
        TRAP    #15

        ; sets lane for the note paths
        MOVE.B  two_player,D1
        SUB.B   D1,treble_note_path_index
        ADD.B   D1,bass_note_path_index

        ; sets the players' positions
        MOVE.W  #50,player_1_position
        MOVE.W  #100,player_2_position
        MOVE.B  treble_note_path_index,player_1_lane_number
        MOVE.B  bass_note_path_index,player_2_lane_number

        LEA     player_1_position,A0
        LEA     player_1_lane_number,A1
        BSR     CHANGE_PLAYER_Y_POSITION
        LEA     player_2_position,A0
        LEA     player_2_lane_number,A1
        BSR     CHANGE_PLAYER_Y_POSITION

        ; sets up the player keymaps
        LEA     player_1_colour_keymaps,A0
        ; space
        MOVE.B  #$20,3(A0)

        ; up and down arrow keys
        MOVE.L  #$26280000,player_2_keymaps
        ; keypad 1, 5, 3 and 0
        ;MOVE.L  #$230C222D,player_2_colour_keymaps
        MOVE.L  #$51525654,player_2_colour_keymaps

        ; sets the index to the start
        MOVE.L  #TREBLE_FILE_CONTENTS,treble_song_file_index
        MOVE.L  #BASS_FILE_CONTENTS,bass_song_file_index

        ; sets up notes and music
        ; checks if $10000 has been accidentally used
        IF.L TREBLE_FILE_CONTENTS <NE> #$FFFFFFFF  THEN
            ILLEGAL
        ENDI
        BSR     NOTE_SET_UP
        BSR     LOAD_IN_SONG

        ; checks if $28000 has been accidentally used
        IF.L SPRITES_LOADING <NE> #$FFFFFFFF  THEN
            ILLEGAL
        ENDI
        BSR     LOAD_IN_SPRITES

        ; sets the song difficulty
        MOVE.B  #8,song_difficulty

        JMP     LOOP


; loads in all notes into DirectX memory
NOTE_SET_UP
        LEA     NOTES_BASIC_PATH,A1
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


; loads in a two song files
; loads the treble file into $10000
; and the bass file into $20000
LOAD_IN_SONG
        MOVE.B  #51,D0
        LEA     song_name,A1
        ADD     #10,A1
        MOVE.B  #84,(A1)
        SUB     #10,A1
        TRAP    #15

        MOVE.B  #53,D0
        LEA     TREBLE_FILE_CONTENTS,A1
        MOVE.L  #$FFFFF,D2
        TRAP    #15

        MOVE.B  #51,D0
        LEA     song_name,A1
        ADD     #10,A1
        MOVE.B  #66,(A1)
        SUB     #10,A1
        TRAP    #15

        MOVE.B  #53,D0
        LEA     BASS_FILE_CONTENTS,A1
        MOVE.L  #$FFFFF,D2
        TRAP    #15

        MOVE.B  #50,D0
        TRAP    #15

        RTS


LOAD_IN_SPRITES
        BSR     LOAD_IN_PLAYER_SPRITES
        ;BSR     LOAD_IN_NOTES_SPRITES
        RTS


; check if this would be better without as many moves
LOAD_IN_PLAYER_SPRITES
        FOR D5 = #0 TO #7   DO
            ; load player 1
            LEA     PLAYER_SPRITES_BASIC_PATH,A1
            ; put in a
            MOVE.B  #97,15(A1)

            MOVE.L  D5,D6
            ; divide by 8
            LSR.B   #3,D6
            IF.B D6 <EQ> #3 THEN
                ADD.B   #51,D6
            ELSE
                ADD.B   #48,D6
            ENDI
            MOVE.B  D6,16(A1)

            MOVE.L  D5,D6
            ; modulus 8
            AND.B   #7,D6
            ADD.B   #48,D6
            MOVE.B  D6,17(A1)

            BSR     LOAD_IMAGE_INTO_SPRITES_LOADING
            BSR     QOI_DECODE
        ENDF
        * FOR D5 = #0 TO #31   DO
        *     ; load player 2
        *     LEA     PLAYER_SPRITES_BASIC_PATH,A1
        *     ; put in b
        *     MOVE.B  #98,15(A1)

        *     MOVE.B  D5,D6
        *     ; divide by 8
        *     LSR.B   #3,D6
        *     ADD.B   #51,D6
        *     MOVE.B  D6,16(A1)

        *     MOVE.B  D5,D6
        *     ; modulus 8
        *     AND.B   #7,D6
        *     ADD.B   #48,D6
        *     MOVE.B  D6,17(A1)

        *     BSR     LOAD_IMAGE_INTO_SPRITES_LOADING
        *     BSR     QOI_DECODE
        * ENDF
        RTS


; A1 must contain the file name, null terminated string
LOAD_IMAGE_INTO_SPRITES_LOADING
        MOVEQ   #51,D0
        TRAP    #15

        MOVEQ   #53,D0
        MOVE.L  #SPRITES_LOADING,A1
        MOVE.L  #$FFFFF,D2
        TRAP    #15

        SUB.L   #8,D2
        MOVE.L  D2,qoi_import_file_size
        
        MOVEQ   #50,D0
        TRAP    #15
        RTS


QOI_DECODE
        BSR     ZERO_PIXELS_ARRAY
        MOVE.L  #$000000FF,current_pixel_r

        ; could change index run into a Data registry or Address registry
        CLR.B   index_run
        ; starting file index
        ; skips start stuff
        ; D4 could be an Address registry
        MOVE.L  #14,D4

        MOVE.L  #SPRITES_LOADING,A0
        MOVE.L  next_free_slot_address,A1

        ADD.L   #SPRITES_PIXEL_LENGTH,next_free_slot_address

        FOR.L D6 = #0 TO #SPRITES_PIXEL_LENGTH BY #4    DO
            IF.B index_run <HI> #0  THEN
                SUB.B   #1,index_run
            ELSE
                IF.L D4 <LO> qoi_import_file_size  THEN
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
                                ; removes first 2 bits
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
                                    SUBQ    #8,D3
                                    ADD.B   D1,D3
                                    ADD.B   D3,current_pixel_r

                                    ADD.B   D1,current_pixel_g

                                    AND.B   #$0F,D2
                                    SUBQ    #8,D2
                                    ADD.B   D1,D2
                                    ADD.B   D2,current_pixel_b
                                ELSE
                                    ; QOI_OP_DIFF
                                    IF.B D1 <HS> #64    THEN
                                        CLR.L   D2
                                        MOVE.B  D1,D2
                                        LSR.L   #4,D2
                                        AND.B   #$03,D2
                                        SUBQ    #2,D2
                                        ADD.B   D2,current_pixel_r
                                        
                                        MOVE.B  D1,D2
                                        LSR.L   #2,D2
                                        AND.B   #$03,D2
                                        SUBQ    #2,D2
                                        ADD.B   D2,current_pixel_g
                                        
                                        MOVE.B  D1,D2
                                        AND.B   #$03,D2
                                        SUBQ    #2,D2
                                        ADD.B   D2,current_pixel_b
                                    ELSE
                                        ; QOI_OP_INDEX
                                        LEA     previous_seen_pixels,A2
                                        LSL.L   #2,D1
                                        MOVE.L  (A2,D1),current_pixel_r
                                    ENDI
                                ENDI
                            ENDI
                        ENDI
                    ENDI
                    BSR     QOI_PUT_IN_PIXEL
                ELSE
                    MOVE.L  #$000000FF,current_pixel_r
                ENDI
            ENDI
            
            IF.B current_pixel_a <EQ> #0    THEN
                MOVE.L  #0,(A1,D6.L)
            ELSE
                MOVE.B  #0,(A1,D6.L)
                MOVE.B  current_pixel_b,1(A1,D6.L)
                MOVE.B  current_pixel_g,2(A1,D6.L)
                MOVE.B  current_pixel_r,3(A1,D6.L)
            ENDI
        ENDF
        RTS


ZERO_PIXELS_ARRAY
        MOVEQ   #51,D0
        LEA     EMPTY_SEEN_PIXELS_FILE,A1
        TRAP    #15

        MOVEQ   #53,D0
        LEA     previous_seen_pixels,A1
        MOVE.L  #$FFFFF,D2
        TRAP    #15
        
        MOVEQ   #50,D0
        TRAP    #15
        RTS


QOI_PUT_IN_PIXEL
        CLR.L   D1
        CLR.L   D2
        LEA     previous_seen_pixels,A2

        MOVE.B  current_pixel_r,D1
        ; multiply by 3
        MOVE.B  D1,D2
        LSL.L   #1,D1
        ADD.L   D1,D2

        CLR.L   D1
        MOVE.B  current_pixel_g,D1
        ; multiply by 5
        ADD.L   D1,D2
        LSL.L   #2,D1
        ADD.L   D1,D2

        CLR.L   D1
        MOVE.B  current_pixel_b,D1
        ; multiply by 7
        SUB.L   D1,D2
        LSL.L   #3,D1
        ADD.L   D1,D2

        CLR.L   D1
        MOVE.B  current_pixel_a,D1
        ; multiply by 11
        ADD.L   D1,D2
        ADD.L   D1,D2
        ADD.L   D1,D2
        LSL.L   #3,D1
        ADD.L   D1,D2

        ; modulus 64
        AND.L   #63,D2
        LSL.L   #2,D2

        MOVE.L  current_pixel_r,(A2,D2)
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
            BSR     CHECK_BOTH_PLAYER_COLLISIONS
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
            BSR     CHECK_BOTH_PLAYER_COLLISIONS
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_movement_time
        ENDI

        ; new path index
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_path_change_time,D1
        IF.L #200 <LE> D1    THEN
            LEA     treble_note_path_index,A0
            LEA     bass_note_path_index,A1
            BSR     CHANGE_PATH_INDEX
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_path_change_time
        ENDI

        ; checks for cooldown time
        IF.L player_1_last_beat_change_time <NE> #0  THEN
            MOVE.W  #8,D0
            TRAP    #15
            SUB.L   player_1_last_beat_change_time,D1
            IF.L #30 <LE> D1    THEN
                BSR     RESET_PLAYER_1_ACTION
            ENDI
        ENDI

        IF.L player_2_last_beat_change_time <NE> #0  THEN
            MOVE.W  #8,D0
            TRAP    #15
            SUB.L   player_2_last_beat_change_time,D1
            IF.L #20 <LE> D1    THEN
                BSR     RESET_PLAYER_2_ACTION
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
                ; LANE_ADDRESSES_SIZE
                DBLOOP D6 = #38
                    MOVE.W  (A1),A2
                    ADD.W   #2,A2
                    ; moves the notes by 8
                    SUB.W   #8,(A2)
                    ADD.W   #2,A1
                UNLESS.W (A1) <NE> #$FFFF
            ENDI
            ADD.W   #(LANE_ADDRESSES_SIZE*2)+2,A0
        ENDF
        RTS


CHECK_BOTH_PLAYER_COLLISIONS
        LEA     player_1_lane_number,A4
        LEA     player_1_action_colour,A5
        LEA     player_1_shift_pressed,A6
        BSR     CHECK_COLLISIONS

        IF.B two_player <EQ> #1 THEN
            LEA     player_2_lane_number,A4
            LEA     player_2_action_colour,A5
            LEA     player_2_shift_pressed,A6
            BSR     CHECK_COLLISIONS
        ENDI
        RTS

; A4 must contain the player lane_number
; A5 must contain the player action colour
; A6 must contain the player shift/control pressed
CHECK_COLLISIONS
        LEA     lane_0_object_addresses,A0
        ; loops through the five lanes
        FOR D5 = #0 TO #4   DO
            IF.W (A0) <NE> #$FFFF   THEN
                MOVE.W  (A0),A1
                ADD.W   #2,A1
                ; check if the note is close to beat line
                IF.W (A1) <LT> #BEAT_LINE_X THEN
                    ; check if the note is invisible
                    IF.W -(A1) <EQ> #0  THEN
                        ADD.W   #2,A1
                        CLR.W   (A1)
                    ELSE
                        ADD.W   #2,A1
                        ; check collision with player line
                        IF.B (A4) <EQ> D5   THEN
                            MOVE.W  -(A1),D1
                            BCLR.L  #4,D1
                            IF  <NE>    THEN
                                MOVE.B  #1,D7
                            ELSE
                                CLR.B   D7
                            ENDI
                            BSR     GET_COLOUR_FROM_INDEX
                            ; note has been hit correctly
                            IF.L (A5) <EQ> D1 THEN
                                IF.B D7 <EQ> (A6) THEN
                                    IF.B 6(A1) <EQ> #0  THEN
                                        MOVE.B  #1,treble_last_note_success
                                    ELSE
                                        IF.B 6(A1) <EQ> #1  THEN
                                            MOVE.B  #1,bass_last_note_success
                                        ENDI
                                    ENDI
                                    ; sets the position to the left to make the note disappear when checking collision
                                    CLR.W   (A1)+
                                    CLR.W   (A1)
                                ELSE
                                    ADD.W   #2,A1
                                    CLR.W   (A1)
                                ENDI
                            ELSE
                                ; check if the note colour was hit incorrectly
                                IF.L (A5) <NE> #WHITE THEN
                                    CLR.W   2(A1)
                                ENDI
                                ADD.W   #2,A1
                            ENDI
                        ENDI
                    ENDI
                    

                    ; check collision with the beat line, ie too late
                    IF.W (A1) <LT> #BEAT_LINE_X-NOTE_SIZE-NOTE_SIZE THEN
                        ; check if it was an invisible or hit note
                        IF.W -(A1) <EQ> #0  THEN
                            IF.B 6(A1) <EQ> #0  THEN
                                IF.B treble_last_note_success <EQ> #1  THEN
                                    BSR     PLAY_MUSIC_ON_HIT
                                ENDI
                            ELSE
                                IF.B 6(A1) <EQ> #1 AND.B bass_last_note_success <EQ> #1   THEN
                                    BSR     PLAY_MUSIC_ON_HIT
                                ENDI
                            ENDI
                        ELSE
                            IF.B 6(A1) <EQ> #0  THEN
                                CLR.B   treble_last_note_success
                            ELSE
                                IF.B 6(A1) <EQ> #1  THEN
                                    CLR.B   bass_last_note_success
                                ENDI
                            ENDI
                        ENDI
                        MOVE.W  #$FFFF,(A1)
                        BSR     LANE_LEFT_SHIFT
                    ENDI
                ENDI
            ENDI
            ADD.W   #(LANE_ADDRESSES_SIZE*2)+2,A0
        ENDF
        RTS


; must not use D5, A0, A1
; A1 contains the address to the start of the note object, ie it's colour
; uses D0, D1, D2, D3, D4, D6, A2, A3
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
                        IF.B (A1,D6) <NE> #103  THEN
                            IF.B (A1,D6) <GE> #100  THEN
                                SUB.B   #3,D1
                                IF.B (A1,D6) <GE> #113  THEN
                                    SUB.B   #10,D1
                                    IF.B (A1,D6) <GE> #116  THEN
                                        SUB.B   #3,D1
                                    ENDI
                                ENDI
                            ENDI
                        ENDI
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
                SUB.B   #60,D3
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
            IF.W D6 <EQ> (A2)   THEN
                MOVE.W  #$FFFF,(A0,D6)
                ADD.B   #2,D7
            ENDI
            MOVE.W  (A0,D7),(A0,D6)
            ADD.B   #2,D7
        ENDF
        RTS


HANDLE_INPUT
        LEA     player_1_last_beat_change_time,A0
        LEA     player_1_action_pressed,A1
        LEA     player_1_action_colour,A2
        LEA     player_1_shift_pressed,A3
        MOVE.L  player_1_colour_keymaps,D1
        ; shift
        MOVE.L  #$10000000,D3
        BSR     HANDLE_COLOUR_CHANGE

        LEA     player_1_position,A0
        LEA     player_1_lane_number,A1
        LEA     player_1_moving,A2
        MOVE.L  player_1_keymaps,D1
        BSR     HANDLE_MOVEMENT

        IF.B two_player <EQ> #1 THEN
            LEA     player_2_last_beat_change_time,A0
            LEA     player_2_action_pressed,A1
            LEA     player_2_action_colour,A2
            LEA     player_2_shift_pressed,A3
            MOVE.L  player_2_colour_keymaps,D1
            ; control
            MOVE.L  #$11000000,D3
            BSR     HANDLE_COLOUR_CHANGE

            IF.L #BLUE <EQ> (A2)    THEN
                MOVE.L  #AQUA,(A2)
            ELSE
                IF.L #RED <EQ> (A2) THEN
                    MOVE.L  #ORANGE,(A2)
                ELSE
                    IF.L #YELLOW <EQ> (A2)  THEN
                        MOVE.L  #LIME,(A2)
                    ENDI
                ENDI
            ENDI

            LEA     player_2_position,A0
            LEA     player_2_lane_number,A1
            LEA     player_2_moving,A2
            MOVE.L  player_2_keymaps,D1
            BSR     HANDLE_MOVEMENT
        ENDI
        RTS


; A0 must contain player last beat change time
; A1 must contain player action pressed
; A2 must contain player action colour
; A3 must contain player shift/control pressed
; D1 must contain player colour keymaps
; D3 must contain player shift/control keycode
HANDLE_COLOUR_CHANGE
        MOVE.B  #19,D0
        TRAP    #15

        IF.L #0 <NE> D1 THEN
            MOVE.L  D1,D2
            MOVE.L  (A0),D1
            ; change colours
            BTST.L  #24,D2
            IF  <NE>    THEN
                BTST.B  #7,(A1)
                IF  <EQ>    THEN
                    MOVE.L  #BLUE,(A2)
                    BSET.B  #7,(A1)
                    MOVE.W  #8,D0
                    TRAP    #15
                ENDI
            ELSE
                BCLR.B  #7,(A1)
            ENDI
            BTST.L  #16,D2
            IF  <NE>    THEN
                BTST.B  #6,(A1)
                IF  <EQ>    THEN
                    MOVE.L  #RED,(A2)
                    BSET.B  #6,(A1)
                    MOVE.W  #8,D0
                    TRAP    #15
                ENDI
            ELSE
                BCLR.B  #6,(A1)
            ENDI
            BTST.L  #8,D2
            IF  <NE>    THEN
                BTST.B  #5,(A1)
                IF  <EQ>    THEN
                    MOVE.L  #YELLOW,(A2)
                    BSET.B  #5,(A1)
                    MOVE.W  #8,D0
                    TRAP    #15
                ENDI
            ELSE
                BCLR.B  #5,(A1)
            ENDI
            ; check for purple pressed
            BTST.L  #0,D2
            IF  <NE>    THEN
                BTST.B  #4,(A1)
                IF  <EQ>    THEN
                    MOVE.L  #PURPLE2,(A2)
                    BSET.B  #4,(A1)
                    MOVE.W  #8,D0
                    TRAP    #15
                ENDI
            ELSE
                BCLR.B  #4,(A1)
            ENDI
            MOVE.L  D1,(A0)

            ; check for shift/control pressed
            MOVE.L  D3,D1
            MOVE.W  #19,D0
            TRAP    #15
            BTST.L  #24,D1
            IF  <NE>    THEN
                IF.B (A3) <EQ> #0 THEN
                    MOVE.W  #8,D0
                    TRAP    #15
                    MOVE.L  D1,(A0)
                ENDI
                MOVE.B  #1,(A3)
            ELSE
                MOVE.B  #0,(A3)
            ENDI
        ELSE
            BCLR.B  #7,(A1)
            BCLR.B  #6,(A1)
            BCLR.B  #5,(A1)
            BCLR.B  #4,(A1)

            MOVE.B  #1,(A3)
        ENDI
        RTS


; A0 must conatin player position
; A1 must contain player lane number
; A2 must contain player moving
; D1 must contain player keymaps
HANDLE_MOVEMENT
        ; check for keys
        MOVE.W  #19,D0
        TRAP    #15

        ; checks if any key is pressed
        IF.L #0 <EQ> D1 THEN
            CLR.B   (A2)
            RTS
        ENDI

        ; checks W
        BTST.L  #24,D1
        IF  <NE>    THEN
            BTST.B  #0,(A2)
            IF  <EQ>    THEN
                IF.B (A1) <NE> #0   THEN
                    SUB.B   #1,(A1)
                    BSET.B  #0,(A2)
                ENDI
            ENDI
        ELSE
            BCLR.B  #0,(A2)
        ENDI
        ; checks S
        BTST.L  #16,D1
        IF  <NE>    THEN
            BTST.B  #1,(A2)
            IF  <EQ>    THEN
                IF.B (A1) <NE> #4   THEN
                    ADD.B   #1,(A1)
                    BSET.B  #1,(A2)
                ENDI
            ENDI
        ELSE
            BCLR.B  #1,(A2)
        ENDI

        BSR     CHANGE_PLAYER_Y_POSITION
        RTS


; changes the player's Y position depending on the lane index
; player position needs to be in A0
; player lane number needs to be in A1
CHANGE_PLAYER_Y_POSITION
        CLR.L   D2
        MOVE.B  (A1),D2
        BSR     GET_LANE_Y_POSITION
        SUB.W   #40,D3
        MOVE.W  D3,2(A0)
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
; treble path node index needs to be in A0
; bass path node index needs to be in A1
; uses A2
CHANGE_PATH_INDEX
        ; if at the top or bottom only call random 2 as it can't go outside the map
        IF.B (A0) <EQ> #0    THEN
            IF.B (A1) <NE> #1   THEN
                MOVE    A0,A2
                BSR     DOUBLE_RANDOM_ADD
            ENDI
        ELSE
            IF.B (A0) <EQ> #4   THEN
                IF.B (A1) <NE> #3   THEN
                    MOVE    A0,A2
                    BSR     DOUBLE_RANDOM_SUB
                ENDI
            ELSE
                CLR.L   D1
                MOVE.B  (A0),D1
                ADD     #1,D1
                IF.B D1 <EQ> (A1)   THEN
                    MOVE    A0,A2
                    BSR     DOUBLE_RANDOM_SUB
                ELSE
                    CLR.L   D1
                    MOVE.B  (A0),D1
                    SUB     #1,D1
                    IF.B D1 <EQ> (A1)   THEN
                        MOVE    A0,A2
                        BSR     DOUBLE_RANDOM_ADD
                    ELSE
                        MOVE    A0,A2
                        BSR     TRIPLE_RANDOM
                    ENDI
                ENDI
            ENDI
        ENDI
        IF.B (A1) <EQ> #0    THEN
            IF.B (A0) <NE> #1   THEN
                MOVE    A1,A2
                BSR     DOUBLE_RANDOM_ADD
            ENDI
        ELSE
            IF.B (A1) <EQ> #4   THEN
                IF.B (A0) <NE> #3   THEN
                    MOVE    A1,A2
                    BSR     DOUBLE_RANDOM_SUB
                ENDI
            ELSE
                CLR.L   D1
                MOVE.B  (A1),D1
                ADD     #1,D1
                IF.B D1 <EQ> (A0)   THEN
                    MOVE    A1,A2
                    BSR     DOUBLE_RANDOM_SUB
                ELSE
                    CLR.L   D1
                    MOVE.B  (A1),D1
                    SUB     #1,D1
                    IF.B D1 <EQ> (A0)   THEN
                        MOVE    A1,A2
                        BSR     DOUBLE_RANDOM_ADD
                    ELSE
                        MOVE    A1,A2
                        BSR     TRIPLE_RANDOM
                    ENDI
                ENDI
            ENDI
        ENDI
        RTS

; these all use the note path index in A2
TRIPLE_RANDOM
        MOVE.W  #3,D3
        BSR     GET_RANDOM_VALUE
        ADD.B   D2,(A2)
        SUB.B   #1,(A2)
        RTS

DOUBLE_RANDOM_ADD
        BSR     RANDOM_2
        IF  <NE>    THEN
            ADD.B   #1,(A2)
        ENDI
        RTS

DOUBLE_RANDOM_SUB
        BSR     RANDOM_2
        IF  <NE>    THEN
            SUB.B   #1,(A2)
        ENDI
        RTS
        RTS


RESET_PLAYER_1_ACTION
        MOVE.L  #WHITE,player_1_action_colour
        MOVE.L  #0,player_1_last_beat_change_time
        RTS


RESET_PLAYER_2_ACTION
        MOVE.L  #WHITE,player_2_action_colour
        MOVE.L  #0,player_2_last_beat_change_time
        RTS


SPAWN_NEW_NOTE
        ;invisibleS WRONG AGAIN
        MOVE.L  treble_song_file_index,A0

        ; song has ended
        IF.B (A0) <EQ> #$FF THEN
            MOVE.L  bass_song_file_index,A0
            IF.B (A0) <EQ> #$FF THEN
                BSR     EXIT_PROGRAM
            ENDI
        ELSE
            ; check for carraige return and line feed
            IF.B (A0) <EQ> #13  THEN
                ADD.L   #2,treble_song_file_index
                ADD.L   #2,A0
            ENDI

            LEA	    treble_quater_beat_count,A4
            ; first byte is checked if there are any notes being played
            IF.B #48 <NE> (A0) THEN
                BSR     CREATE_NOTE_OBJECT
                LEA     treble_song_file_index,A1
                LEA     treble_note_path_index,A3
                BSR     LOAD_NOTE_DATA
                MOVE.B  #0,6(A2)

                CLR.L   D0
                MOVE.B  song_difficulty,D0
                IF.B (A4) <GE> D0 THEN
                    MOVE.B   #1,(A4)
                ENDI
            ELSE
                ADD.L   #2,treble_song_file_index
            ENDI
            ADD.B   #1,(A4)
        ENDI

        ; checks the bass file as well
        MOVE.L  bass_song_file_index,A0
        IF.B (A0) <NE> #$FF THEN
            IF.B (A0) <EQ> #13  THEN
                ADD.L   #2,bass_song_file_index
                ADD.L   #2,A0
            ENDI

            LEA	    bass_quater_beat_count,A4
            IF.B #48 <NE> (A0) THEN
                BSR     CREATE_NOTE_OBJECT
                LEA     bass_song_file_index,A1
                LEA     bass_note_path_index,A3
                BSR     LOAD_NOTE_DATA
                IF.B two_player <EQ> #0     THEN
                    CLR.W   (A2)
                ENDI
                MOVE.B  two_player,6(A2)

                CLR.L   D0
                MOVE.B  song_difficulty,D0
                IF.B (A4) <GE> D0 THEN
                    MOVE.B   #1,(A4)
                ENDI
            ELSE
                ADD.L   #2,bass_song_file_index
            ENDI
            ADD.B   #1,(A4)
        ENDI

        RTS


; returns new object address in A2
; 0 in A2 means that the array is full
CREATE_NOTE_OBJECT
        LEA     note_objects,A2
        FOR D5 = #0 TO #LANE_ADDRESSES_SIZE-1  DO
            IF.W (A2) <EQ> #$FFFF   THEN
                RTS
            ENDI
            ADD.W   #NOTE_OBJECT_SIZE,A2
        ENDF
        ILLEGAL
        RTS


; A0 contains the address to the current song data beat note
; A1 contains the address to the song file indexes
; A2 contains the address to the start of music note object
; A3 contains the address to the note path index
; A4 contains the address to the whatever quarter beat count
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
        ADD.L   D3,(A1)
        ADD.L   #1,(A1)

        ; gets the number of notes playing on the same beat
        DIVU    #4,D3

        ; assign a colour based on the playing notes
        ; and the difficulty
        CLR.L   D0
        MOVE.B  song_difficulty,D0
        IF.B (A4) <LT> D0 THEN
            CLR.W   (A2)
        ELSE
            BSR     PICK_NOTE_COLOUR
        ENDI

        ; assign x and y position based on the path index
        ADD.W   #2,A2
        MOVE.W  #SCREEN_WIDTH,(A2)
        ADD.W   #2,A2
        CLR.L   D2
        MOVE.B  (A3),D2
        BSR     GET_LANE_Y_POSITION
        MOVE.W  D3,(A2)
        SUB.W   #NOTE_SIZE/2,(A2)

        ; adds note object to the end of the lane queue
        CLR.L   D1
        MOVE.B  (A3),D1
        MULU    #(LANE_ADDRESSES_SIZE*2)+2,D1
        LEA     lane_0_object_addresses,A0
        ADD     D1,A0
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


; A4 contains the address to the whatever quarter beat count
CHECK_QUARTER_BEAT_COUNT
        CLR.L   D0
        MOVE.B  song_difficulty,D0
        IF.B (A4) <GE> D0 THEN
            MOVE.B   #1,(A4)
        ELSE
            ADD.B   #1,(A4)
        ENDI
        RTS

; loops over music time array
; decrements times for each note
DECREMENT_NOTES_TIMES
        LEA notes_times_array,A1
        FOR D5 = #0 TO #101  DO
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
        IF.B two_player <EQ> #1 THEN
            BSR     DRAW_PLAYER_2
        ENDI

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
        ;MOVE.L  player_1_action_colour,D1
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
                ; LANE_ADDRESSES_SIZE
                DBLOOP D6 = #38
                    MOVE.W  (A2),A0
                    IF.W (A0) <NE> #0 AND.W (A0) <NE> #$FFFF    THEN
                        MOVE.B  #80,D0
                        MOVE.W  (A0),D1
                        BCLR.L  #4,D1
                        IF  <EQ>    THEN
                            BSR     GET_COLOUR_FROM_INDEX
                            TRAP    #15
                            MOVE.W  #81,D0
                            TRAP    #15
                            ADD.W   #2,A0

                            MOVE.W  #NOTE_SIZE,D3
                            MOVE.W  #NOTE_SIZE,D4
                            BSR     DRAW_SQUARE
                        ELSE
                            BSR     GET_COLOUR_FROM_INDEX
                            TRAP    #15
                            MOVE.W  #81,D0
                            TRAP    #15
                            ADD.W   #2,A0

                            MOVE.W  #NOTE_SIZE,D3
                            MOVE.W  #NOTE_SIZE,D4
                            BSR     DRAW_UNFILLED_SQUARE
                        ENDI
                    ENDI
                    ADD.W   #2,A2
                UNLESS.W (A2) <NE> #$FFFF
            ENDI
            ADD.W   #(LANE_ADDRESSES_SIZE*2)+2,A1
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
                    MOVE.L  #RED,D1
                ELSE
                    IF.W D1 <EQ> #3 THEN
                        MOVE.L  #YELLOW,D1
                    ELSE
                        IF.W D1 <EQ> #4 THEN
                            MOVE.L  #AQUA,D1
                        ELSE
                            IF.W D1 <EQ> #5 THEN
                                MOVE.L  #ORANGE,D1
                            ELSE
                                IF.W D1 <EQ> #6 THEN
                                    MOVE.L  #LIME,D1
                                ELSE
                                    IF.W D1 <EQ> #7 THEN
                                        MOVE.L  #PURPLE2,D1
                                    ELSE
                                        MOVE.L  #WHITE,D1
                                    ENDI
                                ENDI
                            ENDI
                        ENDI
                    ENDI
                ENDI
            ENDI
        ENDI
        
        RTS


; A0 must contain the start of the sprite
DRAW_PLAYER_1
        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #MULTIPLIER_SIZE,D1
        TRAP    #15

        MOVE.L  #$2A000,A0
        LEA     player_1_position,A1

        ; 32x32
        CLR.L   D3
        CLR.L   D2
        MOVE.W  2(A1),D2
        MOVE.L  D2,D4
        FOR.L D5 = #0 TO #$1F   DO
            MOVE.W  (A1),D3
            FOR.L D6 = #0 TO #$1F   DO
                ; set pen colour
                MOVEQ   #80,D0
                MOVE.L  (A0)+,D1
                TRAP    #15

                ; draw rectangle
                MOVEQ   #87,D0
                MOVE.W  D3,D1
                ;MOVE.L  D6,D1
                ;MOVE.L  D5,D2
                ; multiplies by 3, does x4, -1
                ;LSL.W   #1,D1
                ;LSL.W   #1,D2
                * SUB.W   D6,D1
                * SUB.W   D5,D2
                ;ADD.W   (A1),D1
                ;ADD.W   2(A1),D2

                ;MOVE.W  D1,D3
                ;MOVE.W  D2,D4
                TRAP    #15
                
                ADDQ    #2,D3
            ENDF
            ADDQ    #2,D2
            ADDQ    #2,D4
        ENDF
        RTS


DRAW_PLAYER_2
        ; sets pen width
        MOVE.B  #93,D0
        MOVE.B  #3,D1
        TRAP    #15

        ; sets pen and fill colour to white
        MOVE.B  #80,D0
        MOVE.L  player_2_action_colour,D1
        TRAP    #15
        MOVE.W  #81,D0
        TRAP    #15

        LEA     player_2_position,A0
        MOVE.W  #PLAYER_SIZE,D3
        MOVE.W  #PLAYER_SIZE,D4
        BSR     DRAW_UNFILLED_SQUARE
        
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

; draws an unfilled square at A0 plus size in D3,D4
DRAW_UNFILLED_SQUARE
        ; set bounds of square to draw
        MOVE.W  (A0)+,D1
        MOVE.W  (A0),D2
        ADD.W   D1,D3
        ADD.W   D2,D4

        MOVE.W  #90,D0
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
player_1_last_beat_change_time  DS.L    1       ; stores the time when beat was last checked and put back into white
player_2_last_beat_change_time  DS.L    1       ; stores the time when beat was last checked and put back into white

player_1_position       DS.W    2       ; stores the top right player position x,y
player_1_lane_number    DS.B    1       ; stores the lane number
player_1_moving         DC.B    0       ; stores whether the player is moving up or down
player_1_action_pressed DC.B    0       ; stores whether any action buttons are pressed
player_1_keymaps        DC.L    'WS'    ; stores the movement keys of player
player_1_action_colour  DC.L    WHITE   ; stores the player action colour
player_1_colour_keymaps DC.L    'HUKA'  ; stores the keymaps for the player changing colours
player_1_shift_pressed  DC.B    0       ; stores whether the shift is pressed down

player_2_position       DS.W    2       ; stores the top right player position x,y
player_2_lane_number    DS.B    3       ; stores the lane number
player_2_moving         DC.B    0       ; stores whether the player is moving up or down
player_2_action_pressed DC.B    0       ; stores whether any action buttons are pressed
player_2_keymaps        DC.L    'AA'    ; stores the movement keys of player
player_2_action_colour  DC.L    WHITE   ; stores the player action colour
player_2_colour_keymaps DC.L    'AAAA' ; stores the keymaps for the player changing colours
player_2_shift_pressed  DC.B    0       ; stores whether the control is pressed down

; stores the number of objects in the arrays
lane_0_object_count     DC.W    0
; stores the addresses of objects in the rows
; these are queues
lane_0_object_addresses DS.W    LANE_ADDRESSES_SIZE
lane_1_object_count     DC.W    0
lane_1_object_addresses DS.W    LANE_ADDRESSES_SIZE
lane_2_object_count     DC.W    0
lane_2_object_addresses DS.W    LANE_ADDRESSES_SIZE
lane_3_object_count     DC.W    0
lane_3_object_addresses DS.W    LANE_ADDRESSES_SIZE
lane_4_object_count     DC.W    0
lane_4_object_addresses DS.W    LANE_ADDRESSES_SIZE

note_objects            DS.W    NOTE_OBJECT_SIZE*LANE_ADDRESSES_SIZE*2    ; stores the notes objects data
;   note object structure:
;   W   note colour index, 0 means that it is invisible
;   W   x position
;   W   y position
;   W   useless
;   L*10   music notes data, same as in the file

treble_note_path_index  DC.B    2       ; stores the lane index of the note path
bass_note_path_index    DC.B    2       ; stores the lane index of the note path
treble_song_file_index  DC.L    0       ; stores the byte index that the song is at
bass_song_file_index    DC.L    0       ; stores the byte index that the song is at

two_player              DC.B    1       ; stores the player count, 0 = one player, 1 = two players

notes_times_array       DS.B    102     ; contains the times for each note that needs to be hold

song_name               DC.B    'songs/RIT9T.txt',0
; THE PROGRAM MUST NOT USE THE FOLLOWING MEMORY ADDRESS
; THERE IS A CHECK AT THE START OF THE PROGRAM TO STOP THIS FROM HAPPENEING
; IT IS ILLEGAL AND RAISES AN ERROR
TREBLE_FILE_CONTENTS    EQU     $10000
BASS_FILE_CONTENTS      EQU     $20000

; notes names
NOTES_BASIC_PATH        DC.B    'notes/aaa.wav',0
NOTES_NAMES_0           DC.B    '0an0bn0as'
NOTES_NAMES_1           DC.B    '1an1bn1cn1dn1en1fn1gn1as1bs1cs1ds1es1fs1gs'
NOTES_NAMES_2           DC.B    '2an2bn2cn2dn2en2fn2gn2as2bs2cs2ds2es2fs2gs'
NOTES_NAMES_3           DC.B    '3an3bn3cn3dn3en3fn3gn3as3bs3cs3ds3es3fs3gs'
NOTES_NAMES_4           DC.B    '4an4bn4cn4dn4en4fn4gn4as4bs4cs4ds4es4fs4gs'
NOTES_NAMES_5           DC.B    '5an5bn5cn5dn5en5fn5gn5as5bs5cs5ds5es5fs5gs'
NOTES_NAMES_6           DC.B    '6an6bn6cn6dn6en6fn6gn6as6bs6cs6ds6es6fs6gs'
NOTES_NAMES_7           DC.B    '7an7bn7cn7dn7en7fn7gn7as7bs7cs7ds7es7fs7gs'
NOTES_NAMES_8           DC.B    '8cn'


song_difficulty             DC.B    16      ; stores the difficulty of the song playing, 16 - easy, 8 - medium, 4 - hard, 2 - expert, 1 - all the notes
treble_quater_beat_count    DC.B    32      ; stores the count of quarter beats played
bass_quater_beat_count      DC.B    32      ; stores the count of quarter beats played
treble_last_note_success    DC.B    0       ; stores whether the last hit note was correct
bass_last_note_success      DC.B    0       ; stores whether the last hit note was correct

; COLOURS
; the treble notes are going to be red, yellow and blue
; the bass notes are going to be aqua, lime, and orange
; teleport is goin to be purple2
BLACK           EQU     $00000000
MAROON          EQU     $00000080
GREEN           EQU     $00008000
OLIVE           EQU     $00008080
NAVY            EQU     $00800000
PURPLE          EQU     $00800080
TEAL            EQU     $00808000
GREY            EQU     $00808080
BLUE            EQU     $00FF0000       ; Treble A, D
RED             EQU     $000000FF       ; Treble B, E
YELLOW          EQU     $0000FFFF       ; Treble C, F
AQUA            EQU     $00FFFF00       ; Bass A, D
ORANGE          EQU     $000080FF       ; Bass B, E
LIME            EQU     $0000FF00       ; Bass C, F
PURPLE2         EQU     $00FF0080       ; Teleport
MAGENTA         EQU     $00FF00FF
LITEGREY        EQU     $00C0C0C0
WHITE           EQU     $00FFFFFF


; QOI decoding
SPRITES_LOADING             EQU     $28000      ; address where the qoi file is loaded
SPRITES_HOLDING             EQU     $2A000      ; address where the unpacked rgba data is stored
SPRITES_PIXEL_LENGTH        EQU     $1000       ; size of sprites is 32x32x4
;PICTURE_DIMENSION           EQU     $20         ; dimension of sprites is 32x32

MULTIPLIER_SIZE             EQU     4           ; the size to multiply the sprites by


PLAYER_SPRITES_BASIC_PATH   DC.B    'player_sprites/aaa.qoi',0
EMPTY_SEEN_PIXELS_FILE      DC.B    'files/empty_seen_pixels.bin',0

; stores the current pixel
                            DS.L    0
current_pixel_r             DC.B    $00
current_pixel_g             DC.B    $00
current_pixel_b             DC.B    $00
current_pixel_a             DC.B    $FF
previous_seen_pixels        DCB.L   64,$FF              ; stores a 64 length array of previous pixels

qoi_import_file_size        DS.L    1                   ; stores the size of the imported qoi image
index_run                   DS.B    1                   ; stores the number of runs for index
next_free_slot_address      DC.L    SPRITES_HOLDING     ; stores the address of the next free available memory space for the next decoded sprite


        END    START



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
