*-----------------------------------------------------------
* Title      :  sideways test
* Written by :  Gabor Major
* Date       :  13/01/2023
* Description:  project test
*-----------------------------------------------------------

* TODO
* 
* decrement notes times slow
* 
* Warnings
* if in the piano sheet there is a held note with lines then it won't play the full thing
* this is an issue of the transcriber and not the assembly code
* when reading in the sound files the program won't find any B or E sharps, the warnings
* can be ignored, these don't exist
* will get a similar error with sprites
* 
* Error
* Players can play the other's notes if they are on the same line
* 
* Drawing
* select menu
* pause menu
* game over screen
* practice win screen
* 
* song_playing_type needs to change whether another song is put in
* speed up rendering by not rerendering the whole screen
* 

; set constants
SCREEN_WIDTH            EQU     1920
SCREEN_HEIGHT           EQU     1080

TOP_BORDER_PADDING      EQU     80
RIGHT_BORDER_PADDING    EQU     20
BOTTOM_BORDER_PADDING   EQU     60
LEFT_BORDER_PADDING     EQU     20

LANE_SIZE               EQU     (SCREEN_HEIGHT-TOP_BORDER_PADDING-BOTTOM_BORDER_PADDING)/5
BEAT_LINE_X             EQU     200

NOTE_SIZE               EQU     80

NOTE_OBJECT_SIZE        EQU     48
LANE_ADDRESSES_SIZE     EQU     55

LIFE_BAR_X              EQU     700

NUMBER_OF_SONGS         EQU     2


; program start
START   ORG    $1000
        ; checks if $10000 has been accidentally used
        IF.L TREBLE_FILE_CONTENTS <NE> #$FFFFFFFF  THEN
            ILLEGAL
        ENDI

        ; turn off input echo
        MOVEQ   #12,D0
        CLR.B   D1
        TRAP    #15
        
        ; turn on double buffering
        ; avoids flickering
		MOVEQ   #92,D0
        MOVEQ   #17,D1
		TRAP    #15

        ; sets the screen size
        MOVEQ   #33,D0
        MOVE.L  #SCREEN_WIDTH*$10000+SCREEN_HEIGHT,D1
        TRAP    #15
        ; sets the window to be fullscreen
        MOVEQ   #2,D1
        TRAP    #15

        ; up and down arrow keys
        MOVE.L  #$26280000,player_2_keymaps

        ; sets up notes
        BSR     NOTE_SET_UP

        ; checks if $28000 has been accidentally used
        IF.L SPRITES_LOADING <NE> #$FFFFFFFF  THEN
            ILLEGAL
        ENDI
        BSR     LOAD_IN_SPRITES

        ; set font properties
        MOVEQ   #21,D0
        MOVE.L  #WHITE,D1
        MOVE.L  #$06120000,D2
        TRAP    #15

        MOVE.B  #1,two_player
        CLR.B   player_1_action_colour
        BRA     MAIN_MENU_LOOP


; loads in all notes into DirectX memory
NOTE_SET_UP
        LEA     NOTES_BASIC_PATH,A1
        LEA     NOTES_NAMES,A2
        FOR D1 = #0 TO #101  DO
            FOR D2 = #0 TO #2   DO
                MOVE.L  A1,A3
                ADD.W   #6,A3
                ADD.W   D2,A3
                MOVE.B  (A2),(A3)
                ADD.W   #1,A2
            ENDF
            MOVEQ   #74,D0
            TRAP    #15
        ENDF
        RTS


LOAD_IN_SPRITES
        BSR     LOAD_IN_PLAYER_SPRITES
        BSR     LOAD_IN_PUNCHING_SPRITES
        BSR     LOAD_IN_FILLED_NOTES_SPRITES
        BSR     LOAD_IN_UNFILLED_NOTES_SPRITES
        RTS


LOAD_IN_PLAYER_SPRITES
        ; load player 1
        MOVE.L  next_free_slot_address,player_1_start_sprite
        LEA     PLAYER_SPRITES_BASIC_PATH,A1
        ; put in a
        MOVE.B  #97,15(A1)

        FOR D5 = #0 TO #7   DO
            LEA     PLAYER_SPRITES_BASIC_PATH,A1

            MOVE.B  D5,D6
            ; modulus 8
            AND.B   #7,D6
            ADD.B   #48,D6
            MOVE.B  D6,17(A1)

            BSR     LOAD_IMAGE_INTO_SPRITES_LOADING
            BSR     QOI_DECODE
        ENDF

        ; load player 2
        MOVE.L  next_free_slot_address,player_2_start_sprite
        LEA     PLAYER_SPRITES_BASIC_PATH,A1
        ; put in b
        MOVE.B  #98,15(A1)

        FOR D5 = #0 TO #7   DO
            LEA     PLAYER_SPRITES_BASIC_PATH,A1

            MOVE.B  D5,D6
            ; modulus 8
            AND.B   #7,D6
            ADD.B   #48,D6
            MOVE.B  D6,17(A1)

            BSR     LOAD_IMAGE_INTO_SPRITES_LOADING
            BSR     QOI_DECODE
        ENDF
        RTS


LOAD_IN_PUNCHING_SPRITES
        ; load punching 1
        MOVE.L  next_free_slot_address,punching_1_start_sprite
        LEA     PUNCHING_SPRITES_BASIC_PATH,A1
        ; put in a
        MOVE.B  #97,17(A1)

        FOR D5 = #0 TO #39   DO
            LEA     PUNCHING_SPRITES_BASIC_PATH,A1

            MOVE.L  D5,D6
            ; divide by 8
            LSR.B   #3,D6
            ADD.B   #48,D6
            MOVE.B  D6,18(A1)

            MOVE.B  D5,D6
            ; modulus 8
            AND.B   #7,D6
            ADD.B   #48,D6
            MOVE.B  D6,19(A1)

            BSR     LOAD_IMAGE_INTO_SPRITES_LOADING
            BSR     QOI_DECODE
        ENDF

        ; load punching 2
        MOVE.L  next_free_slot_address,punching_2_start_sprite
        LEA     PUNCHING_SPRITES_BASIC_PATH,A1
        ; put in b
        MOVE.B  #98,17(A1)

        FOR D5 = #0 TO #39   DO
            LEA     PUNCHING_SPRITES_BASIC_PATH,A1

            MOVE.B  D5,D6
            ; divide by 8
            LSR.B   #3,D6
            ADD.B   #48,D6
            MOVE.B  D6,18(A1)

            MOVE.B  D5,D6
            ; modulus 8
            AND.B   #7,D6
            ADD.B   #48,D6
            MOVE.B  D6,19(A1)

            BSR     LOAD_IMAGE_INTO_SPRITES_LOADING
            BSR     QOI_DECODE
        ENDF
        RTS


LOAD_IN_FILLED_NOTES_SPRITES
        ; load notes 1
        MOVE.L  next_free_slot_address,filled_notes_1_start_sprite
        ADD.L   #SPRITES_PIXEL_LENGTH*8,next_free_slot_address
        LEA     FILLED_NOTES_BASIC_PATH,A1
        ; put in a
        MOVE.B  #97,21(A1)

        FOR D5 = #8 TO #39   DO
            LEA     FILLED_NOTES_BASIC_PATH,A1

            MOVE.B  D5,D6
            ; divide by 8
            LSR.B   #3,D6
            ADD.B   #48,D6
            MOVE.B  D6,22(A1)

            MOVE.L  D5,D6
            ; modulus 8
            AND.B   #7,D6
            ADD.B   #48,D6
            MOVE.B  D6,23(A1)

            BSR     LOAD_IMAGE_INTO_SPRITES_LOADING
            BSR     QOI_DECODE
        ENDF

        ; load notes 2
        MOVE.L  next_free_slot_address,filled_notes_2_start_sprite
        ADD.L   #SPRITES_PIXEL_LENGTH*8,next_free_slot_address
        LEA     FILLED_NOTES_BASIC_PATH,A1
        ; put in b
        MOVE.B  #98,21(A1)

        FOR D5 = #8 TO #39   DO
            LEA     FILLED_NOTES_BASIC_PATH,A1

            MOVE.B  D5,D6
            ; divide by 8
            LSR.B   #3,D6
            ADD.B   #48,D6
            MOVE.B  D6,22(A1)

            MOVE.B  D5,D6
            ; modulus 8
            AND.B   #7,D6
            ADD.B   #48,D6
            MOVE.B  D6,23(A1)

            BSR     LOAD_IMAGE_INTO_SPRITES_LOADING
            BSR     QOI_DECODE
        ENDF
        RTS


LOAD_IN_UNFILLED_NOTES_SPRITES
        ; load notes 1
        MOVE.L  next_free_slot_address,unfilled_notes_1_start_sprite
        ADD.L   #SPRITES_PIXEL_LENGTH*8,next_free_slot_address
        LEA     UNFILLED_NOTES_BASIC_PATH,A1
        ; put in a
        MOVE.B  #97,23(A1)

        FOR D5 = #8 TO #39   DO
            LEA     UNFILLED_NOTES_BASIC_PATH,A1

            MOVE.B  D5,D6
            ; divide by 8
            LSR.B   #3,D6
            ADD.B   #48,D6
            MOVE.B  D6,24(A1)

            MOVE.L  D5,D6
            ; modulus 8
            AND.B   #7,D6
            ADD.B   #48,D6
            MOVE.B  D6,25(A1)

            BSR     LOAD_IMAGE_INTO_SPRITES_LOADING
            BSR     QOI_DECODE
        ENDF
        ; load notes 2
        MOVE.L  next_free_slot_address,unfilled_notes_2_start_sprite
        ADD.L   #SPRITES_PIXEL_LENGTH*8,next_free_slot_address
        LEA     UNFILLED_NOTES_BASIC_PATH,A1
        ; put in b
        MOVE.B  #98,23(A1)

        FOR D5 = #8 TO #39   DO
            LEA     UNFILLED_NOTES_BASIC_PATH,A1

            MOVE.B  D5,D6
            ; divide by 8
            LSR.B   #3,D6
            ADD.B   #48,D6
            MOVE.B  D6,24(A1)

            MOVE.B  D5,D6
            ; modulus 8
            AND.B   #7,D6
            ADD.B   #48,D6
            MOVE.B  D6,25(A1)

            BSR     LOAD_IMAGE_INTO_SPRITES_LOADING
            BSR     QOI_DECODE
        ENDF
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
        MOVEQ   #14,D4

        MOVE.L  #SPRITES_LOADING,A0
        MOVE.L  next_free_slot_address,A1

        ADD.L   #SPRITES_PIXEL_LENGTH,next_free_slot_address

        FOR.L D6 = #0 TO #SPRITES_PIXEL_LENGTH-4 BY #4    DO
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
                        ADDQ.L  #1,D4
                        MOVE.B  (A0,D4),current_pixel_g
                        ADDQ.L  #1,D4
                        MOVE.B  (A0,D4),current_pixel_b
                        ADDQ.L  #1,D4
                    ELSE
                        ; QOI_OP_RGBA
                        IF.B D1 <EQ> #255   THEN
                            MOVE.B  (A0,D4),current_pixel_r
                            ADDQ.L  #1,D4
                            MOVE.B  (A0,D4),current_pixel_g
                            ADDQ.L  #1,D4
                            MOVE.B  (A0,D4),current_pixel_b
                            ADDQ.L  #1,D4
                            MOVE.B  (A0,D4),current_pixel_a
                            ADDQ.L  #1,D4
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


MAIN_MENU_LOOP
        BSR     HANDLE_MENU_SELECT

        IF.B player_1_action_colour <EQ> #1 THEN
            CLR.B   player_1_action_colour
            CLR.B   player_1_action_colour
            BRA     SELECT_SONG_MENU_LOOP
        ELSE
            IF.B player_1_action_colour <EQ> #2 THEN
                CLR.B   player_1_action_colour
                MOVE.B  #1,song_playing_type
                BRA     GAME_START
            ELSE
                IF.B player_1_action_colour <EQ> #3 THEN
                    CLR.B   player_1_action_colour
                    BRA     EXIT_PROGRAM
                ELSE
                    IF.B player_1_action_colour <EQ> #4 THEN
                        CLR.B   player_1_action_colour
                        ADDQ.B  #1,menu_screen_game_type
                        IF.B menu_screen_game_type <HI> #2  THEN
                            CLR.B   menu_screen_game_type
                        ENDI
                    ENDI
                ENDI
            ENDI
        ENDI
        CLR.B   player_1_action_colour

        BSR     HANDLE_DIFFICULTY_INPUT
        BSR     DRAW_MAIN_MENU
        BSR     REPAINT_SCREEN

        ; delay
        MOVEQ   #23,D0
        MOVEQ   #10,D1
        TRAP    #15
        BRA     MAIN_MENU_LOOP


HANDLE_MENU_SELECT
        LEA     player_1_action_pressed,A1
        LEA     player_1_action_colour,A2
        LEA     player_1_charge_amount,A3
        LEA     player_1_punching_index,A4
        MOVE.L  player_1_colour_keymaps,D1
        BSR     HANDLE_COLOUR_CHANGE

        ; resets the punching index
        CLR.B   player_1_punching_index
        RTS


HANDLE_DIFFICULTY_INPUT
        ; check for keys
        MOVE.W  #19,D0
        ; 1 2 3
        MOVE.L  #$31323300,D1
        TRAP    #15

        ; checks 1
        BTST.L  #24,D1
        IF  <NE>    then
            MOVE.B  #0,main_menu_difficulty
        ENDI
        ; checks 2
        BTST.L  #16,D1
        IF  <NE>    then
            MOVE.B  #1,main_menu_difficulty
        ENDI
        ; checks 3
        BTST.L  #8,D1
        IF  <NE>    then
            MOVE.B  #2,main_menu_difficulty
        ENDI
        RTS


SELECT_SONG_MENU_LOOP

        BSR     DRAW_SELECT_SONG_MENU
        BSR     REPAINT_SCREEN

        ; delay
        MOVEQ   #23,D0
        MOVEQ   #1,D1
        TRAP    #15
        BRA     SELECT_SONG_MENU_LOOP


GAME_START
		; store time in variables
        MOVE.W  #8,D0
        TRAP    #15
        MOVE.L  D1,last_frame_time
        MOVE.L  D1,last_treble_path_change_time
        MOVE.L  D1,last_bass_path_change_time
        MOVE.L  D1,last_object_time
        MOVE.L  D1,last_note_spawn_time
        MOVE.L  D1,last_notes_hit_index_change_time
        ; stores the time as starting seed
        MOVE.L  D1,random_value

        ; sets up the game type
        IF.B menu_screen_game_type <EQ> #0 THEN
            CLR.B   two_player
            CLR.B   coop_mode
        ELSE
            IF.B menu_screen_game_type <EQ> #1 THEN
                MOVE.B  #1,two_player
                MOVE.B  #1,coop_mode
            ELSE
                IF.B menu_screen_game_type <EQ> #2 THEN
                    MOVE.B  #1,two_player
                    CLR.B   coop_mode
                ENDI
            ENDI
        ENDI

        ; sets lane for the note paths
        MOVE.B  #2,treble_note_path_index
        MOVE.B  #2,bass_note_path_index
        MOVE.B  two_player,D1
        SUB.B   D1,treble_note_path_index
        ADD.B   D1,bass_note_path_index

        ; sets the players' positions
        MOVE.W  #50,player_1_position
        MOVE.W  #50,player_2_position
        MOVE.B  treble_note_path_index,player_1_lane_number
        MOVE.B  bass_note_path_index,player_2_lane_number

        LEA     player_1_position,A0
        LEA     player_1_lane_number,A1
        BSR     CHANGE_PLAYER_Y_POSITION
        LEA     player_2_position,A0
        LEA     player_2_lane_number,A1
        BSR     CHANGE_PLAYER_Y_POSITION

        ; practice
        IF.B song_playing_type <EQ> #0  THEN
            LEA     song_name,A2
            BSR     LOAD_IN_SONG
        ELSE
            BSR     LOAD_IN_RANDOM_NEW_SONG
        ENDI

        ; calculates game difficulty
        MOVEQ   #20,D0
        MOVE.B  main_menu_difficulty,D1
        IF.B two_player <EQ> #0 THEN
            LSL.B   #3,D1
        ELSE
            LSL.B   #2,D1
        ENDI
        SUB.B   D1,D0
        IF.B D0 <EQ> #4 THEN
            MOVE.B  #6,song_difficulty
        ELSE
            MOVE.B  D0,song_difficulty
        ENDI

        ; sets the game speed
        MOVEQ   #20,D0
        SUB.B   song_difficulty,D0
        LSR.B   #2,D0
        ADD.B   #8,D0
        MOVE.W  D0,notes_speed
        MOVE.W  D0,previous_notes_speed
        CLR.W   notes_speed_indexer

        MOVE.W  #384,D0
        CLR.W   D1
        MOVE.B  song_difficulty,D1
        DIVU    D1,D0
        IF.B two_player <EQ> #0 THEN
            LSL.W   #1,D0
        ENDI
        MOVE.W  D0,notes_speed_indexer_rollover

        ; sets starting variables
        CLR.B   player_1_moving
        CLR.B   player_1_action_pressed
        CLR.B   player_1_action_colour
        CLR.B   player_1_charge_amount
        MOVE.W  #200,player_1_life_amount
        CLR.B   player_1_punching_index

        CLR.B   player_2_moving
        CLR.B   player_2_action_pressed
        CLR.B   player_2_action_colour
        CLR.B   player_2_charge_amount
        MOVE.W  #200,player_2_life_amount
        CLR.B   player_2_punching_index

        CLR.B   render_skip_amount

        ; reset values in arrays
        LEA     lanes_colours,A0
        FOR D5 = #0 TO #5   DO
            MOVE.L  #WHITE,(A0)+
        ENDF

        LEA     lanes_notes_hit_animations,A0
        FOR D5 = #0 TO #4   DO
            CLR.L   (A0)+
        ENDF

        LEA     lane_notes_addresses,A0
        FOR D5 = #0 TO #4   DO
            CLR.W   -2(A0)
            MOVE.L  A0,A1
            DBLOOP D6 = #LANE_ADDRESSES_SIZE-1
                    MOVE.W  #$FFFF,(A1)+
            UNLESS.W (A1) <NE> #$FFFF
            ADD.W   #(LANE_ADDRESSES_SIZE*2)+2,A0
        ENDF

        LEA     note_objects,A0
        FOR.L D5 = #0 TO #(NOTE_OBJECT_SIZE*LANE_ADDRESSES_SIZE*2)-1 BY #NOTE_OBJECT_SIZE   DO
            MOVE.W  #$FFFF,(A0,D5)
        ENDF

        CLR.L   score
        CLR.W   player_1_longest_streak
        CLR.W   player_2_longest_streak
        CLR.W   treble_total_notes
        CLR.W   bass_total_notes
        CLR.W   player_1_notes_hit_count
        CLR.W   player_2_notes_hit_count

        BRA     LOAD_SCREEN_LOOP


; loads in two song files
; loads the treble file into $10000
; and the bass file into $20000
LOAD_IN_SONG
        ; sets the index to the start
        MOVE.L  #TREBLE_FILE_CONTENTS,treble_song_file_index
        MOVE.L  #BASS_FILE_CONTENTS,bass_song_file_index
        MOVE.B  #128,treble_quater_beat_count
        MOVE.B  #128,bass_quater_beat_count
        MOVE.B  #1,treble_last_note_success
        MOVE.B  #1,bass_last_note_success

        MOVEQ   #51,D0
        LEA     song_name,A1
        TRAP    #15

        MOVEQ   #53,D0
        MOVE.L  #TREBLE_FILE_CONTENTS,A1
        MOVE.L  #$FFFFF,D2
        TRAP    #15
        MOVE.W  D2,treble_song_file_size
        ; tells the program that this is the last byte
        ADD.L   #1,D2
        MOVE.B  #$FF,(A1,D2)

        MOVEQ   #51,D0
        LEA     song_name,A1
        CLR.L   D3
        MOVE.B  song_name_last_index,D3
        MOVE.B  #66,(A1,D3)
        TRAP    #15

        MOVEQ   #53,D0
        MOVE.L  #BASS_FILE_CONTENTS,A1
        MOVE.L  #$FFFFF,D2
        TRAP    #15
        ADD.L   #1,D2
        MOVE.B  #$FF,(A1,D2)

        MOVEQ   #50,D0
        TRAP    #15

        LEA     song_name,A1
        MOVE.B  #0,(A1,D3)
        RTS


LOAD_IN_RANDOM_NEW_SONG
        BSR     CHECK_AVAILABLE_SONGS
        BSR     GET_RANDOM_SONG_INDEX
        BSR     LOAD_SONG_FILE_NAME
        BSR     LOAD_IN_SONG
        RTS


CHECK_AVAILABLE_SONGS
        LEA     available_songs_array,A0
        IF.B number_of_available_songs <EQ> #0  THEN
            FOR D5 = #0 TO #NUMBER_OF_SONGS-1   DO
                MOVE.B  D5,(A0,D5)
            ENDF
            MOVE.B  #NUMBER_OF_SONGS,number_of_available_songs
        ENDI
        RTS

; A0 contains the available songs array address
; Returns song index in D0
GET_RANDOM_SONG_INDEX
        CLR.W   D3
        MOVE.B  number_of_available_songs,D3
        BSR     GET_RANDOM_VALUE
        SUB.B   #1,number_of_available_songs
        MOVE.B  (A0,D2.W),D0

        FOR.W D5 = D2 TO #NUMBER_OF_SONGS-1 DO
            MOVE.B  1(A0,D5),(A0,D5)
        ENDF
        RTS


LOAD_SONG_FILE_NAME
        LEA     ALL_SONG_FILE_NAMES,A0
        CLR.L   D5
        WHILE.B D0 <NE> #0  DO
            IF.B (A0,D5) <EQ> #0    THEN
                ADDQ.L  #1,D5
                ADD.L   D5,A0
                SUBQ.B  #1,D0
            ENDI
            ADDQ.L  #1,D5
        ENDW

        LEA     song_name,A1
        ADDQ    #6,A1
        CLR.L   D5
        WHILE.B (A0,D5) <NE> #0    DO
            MOVE.B  (A0,D5),(A1,D5)
            ADDQ.B  #1,D5
        ENDW
        MOVE.B  #84,(A1,D5)
        CLR.B   1(A1,D5)
        ADD.B   #6,D5
        MOVE.B  D5,song_name_last_index
        RTS


LOAD_SCREEN_LOOP
        BSR     HANDLE_MENU_SELECT

        MOVEQ   #19,D0
        ; shift
        MOVE.L  #$10000000,D1
        TRAP    #15
        BTST.L  #24,D1
        IF  <NE>    THEN
            IF.W loading_screen_charge <LO> #300    THEN
                ADD.W   #20,loading_screen_charge
            ENDI
        ELSE
            CLR.W   loading_screen_charge
        ENDI

        IF.B player_1_action_colour <EQ> #2 AND.W loading_screen_charge <EQ> #300   THEN
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_object_time
            CLR.B   player_1_action_colour
            BRA     GAME_LOOP
        ENDI
        CLR.B   player_1_action_colour

        BSR     DRAW_LOAD_SCREEN
        BSR     REPAINT_SCREEN
        
        ; delay
        MOVEQ   #23,D0
        MOVEQ   #10,D1
        TRAP    #15
        BRA     LOAD_SCREEN_LOOP


FRAME_DELAY
        ; gets the time
        MOVE.W  #8,D0
        TRAP    #15
        ; subtracts the two times
        SUB.L   last_frame_time,D1
        ; n number of centiseconds have passed
        CMP.L   #1,D1
        IF  <LS>    THEN
            MOVEQ   #23,D0
            MOVEQ   #1,D1
            TRAP    #15
        ENDI
        ;BLO     FRAME_DELAY
        ; save time
        MOVE.W  #8,D0
        TRAP    #15
        MOVE.L  D1,last_frame_time
        RTS


GAME_LOOP
        ; frame delay, so that framerate is consistent
        BSR     FRAME_DELAY

        ; spawn new notes
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_note_spawn_time,D1
        IF.L #10 <LE> D1    THEN
            BSR     SPAWN_NEW_NOTE
            BSR     DECREMENT_NOTES_TIMES

            ; increments and does modulus 8
            ADDQ.B  #1,sprite_gif_index
            AND.B   #7,sprite_gif_index
            
            IF.B player_1_punching_index <NE> #0 AND.B player_1_punching_index <NE> #8  THEN
                ADDQ.B  #1,player_1_punching_index
                IF.B player_1_punching_index <EQ> #8    THEN
                    CLR.B   player_1_action_colour
                    CLR.B   player_1_charge_amount
                ENDI
            ENDI

            IF.B two_player <EQ> #1 THEN
                IF.B player_2_punching_index <NE> #0 AND.B player_2_punching_index <NE> #8  THEN
                    ADDQ.B  #1,player_2_punching_index
                    IF.B player_2_punching_index <EQ> #8    THEN
                        CLR.B   player_2_action_colour
                        CLR.B   player_2_charge_amount
                    ENDI
                ENDI
            ENDI

            ADD.L   #1,score

            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_note_spawn_time
        ENDI

        ; moves the enemies and notes
        ; input + change position
        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_object_time,D1
        IF.L #2 <LE> D1    THEN
            BSR     MOVE_NOTES
            BSR     HANDLE_INPUT
            BSR     CHECK_BOTH_PLAYER_COLLISIONS

            ADD.W   #1,player_1_life_amount
            IF.W player_1_life_amount <GT> #400 THEN
                MOVE.W  #400,player_1_life_amount
            ENDI

            IF.B two_player <EQ> #1 THEN
                ADD.W   #1,player_2_life_amount
                IF.W player_2_life_amount <GT> #400 THEN
                    MOVE.W  #400,player_2_life_amount
                ENDI
            ENDI

            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_object_time
        ENDI

        ; render screen
        ; render skip is used to keep the game running consistently and skip frames
        ; when there are many objects on the screen
        IF.B render_skip_amount <EQ> #0 THEN
            MOVEQ   #8,D0
            TRAP    #15
            MOVE.L  D1,previous_render_time
            BSR     RENDER_SCREEN
            MOVEQ   #8,D0
            TRAP    #15
            SUB.L   previous_render_time,D1
            LSR.B   #1,D1
            IF.B D1 <NE> #0 THEN
                MOVE.B  #1,render_skip_amount
            ENDI

            BSR     CHECK_LIFE_AMOUNTS
        ELSE
            SUBQ.B  #1,render_skip_amount
        ENDI

        BRA     GAME_LOOP


CHECK_LIFE_AMOUNTS
        IF.B two_player <EQ> #1 THEN
            IF.B coop_mode <EQ> #0  THEN
                IF.W player_1_life_amount <LT> #1   THEN
                    MOVE.B  #2,game_over_status
                    CLR.B   player_1_action_colour
                    BRA     GAME_OVER_LOOP
                ENDI
                IF.W player_2_life_amount <LT> #1   THEN
                    MOVE.B  #1,game_over_status
                    CLR.B   player_1_action_colour
                    BRA     GAME_OVER_LOOP
                ENDI
            ELSE
                MOVE.W  player_1_life_amount,D0
                ADD.W   player_2_life_amount,D0
                IF.W D0 <LT> #1 THEN
                    CLR.B   game_over_status
                    CLR.B   player_1_action_colour
                    BRA     GAME_OVER_LOOP
                ENDI
            ENDI
        ELSE
            IF.W player_1_life_amount <LT> #1   THEN
                CLR.B   game_over_status
                CLR.B   player_1_action_colour
                BRA     GAME_OVER_LOOP
            ENDI
        ENDI
        RTS


GAME_OVER_LOOP
        BSR HANDLE_MENU_SELECT

        IF.B player_1_action_colour <EQ> #1 THEN
            MOVE.B  #1,two_player
            CLR.B   player_1_action_colour
            BRA     MAIN_MENU_LOOP
        ELSE
            IF.B player_1_action_colour <EQ> #2 THEN
                CLR.B   player_1_action_colour
                BRA     GAME_START
            ENDI
        ENDI
        CLR.B   player_1_action_colour

        BSR     DRAW_GAME_OVER
        BSR     REPAINT_SCREEN

        ; delay
        MOVEQ   #23,D0
        MOVEQ   #1,D1
        TRAP    #15
        BRA     GAME_OVER_LOOP


; D1 must contain the time calculated from last object time
MOVE_NOTES
        MOVE.L  D1,D2
        LSR.L   #2,D2
        SUB.L   D2,D1
        MULU    notes_speed,D1

        LEA     lane_notes_addresses,A0
        ; loops through the five lanes
        FOR D5 = #0 TO #4   DO
            MOVE.L  A0,A1
            ; loops until encounters an empty position
            IF.W (A1) <NE> #$FFFF   THEN
                DBLOOP D6 = #LANE_ADDRESSES_SIZE-1
                    MOVE.W  (A1),A2
                    ADD.W   #2,A2
                    ; moves the notes
                    SUB.W   D1,(A2)
                    ADD.W   #2,A1
                UNLESS.W (A1) <NE> #$FFFF
            ENDI
            ADD.W   #(LANE_ADDRESSES_SIZE*2)+2,A0
        ENDF
        RTS


CHECK_BOTH_PLAYER_COLLISIONS
        LEA     player_1_lane_number,A4
        LEA     player_1_action_colour,A5
        LEA     player_1_charge_amount,A6
        BSR     CHECK_COLLISIONS

        LEA     player_1_position,A0
        LEA     player_1_lane_number,A1
        BSR     CHANGE_PLAYER_Y_POSITION

        IF.B two_player <EQ> #1 THEN
            LEA     player_2_lane_number,A4
            LEA     player_2_action_colour,A5
            LEA     player_2_charge_amount,A6
            BSR     CHECK_COLLISIONS

            LEA     player_2_position,A0
            LEA     player_2_lane_number,A1
            BSR     CHANGE_PLAYER_Y_POSITION
        ENDI
        RTS

; A4 must contain the player lane number
; A5 must contain the player action colour
; A6 must contain the player charge amount
CHECK_COLLISIONS
        LEA     lane_notes_addresses,A0
        ; loops through the five lanes
        FOR D5 = #0 TO #4   DO
            IF.W (A0) <NE> #$FFFF   THEN
                MOVE.W  (A0),A1
                ADD.W   #2,A1
                ; check if the note is close to beat line
                IF.W (A1) <LS> #BEAT_LINE_X THEN
                    ; check if the note is invisible
                    IF.W -(A1) <EQ> #0  THEN
                        ADD.W   #2,A1
                        IF.W (A1) <LS> #BEAT_LINE_X-(NOTE_SIZE/2) THEN
                            CLR.W   (A1)
                        ENDI
                    ELSE
                        ADD.W   #2,A1
                        ; check collision with player line
                        IF.B (A4) <EQ> D5   THEN
                            MOVE.W  -(A1),D1
                            ; checks for shift/control note beat
                            BCLR.L  #4,D1
                            IF  <NE>    THEN
                                IF.B (A6) <EQ> #80  THEN
                                    BSR     NOTE_HIT_DETECTION
                                ELSE
                                    ADD.W   #2,A1
                                ENDI
                            ELSE
                                IF.B (A6) <EQ> #0   THEN
                                    BSR     NOTE_HIT_DETECTION
                                ELSE
                                    ADD.W   #2,A1
                                ENDI
                            ENDI
                        ENDI
                    ENDI

                    ; check collision with the beat line, ie too late
                    IF.W (A1) <LS> #BEAT_LINE_X-NOTE_SIZE THEN
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
                                CLR.B   player_1_charge_amount
                                CLR.W   player_1_longest_streak
                                ;SUB.W   #199,player_1_life_amount
                            ELSE
                                CLR.B   bass_last_note_success
                                CLR.B   player_2_charge_amount
                                CLR.W   player_2_longest_streak
                                ;SUB.W   #199,player_2_life_amount
                            ENDI
                            MOVE.W  previous_notes_speed,D0
                            IF.W notes_speed <HI> D0    THEN
                                SUB.W   #1,notes_speed
                            ENDI
                            LEA     lanes_colours,A3
                            MOVE.L  D5,D7
                            LSL.L   #2,D7
                            ADD.L   D7,A3
                            MOVE.L  #WHITE,(A3)+
                            MOVE.L  #WHITE,(A3)
                        ENDI
                        MOVE.W  #$FFFF,(A1)
                        BSR     LANE_LEFT_SHIFT
                    ENDI
                ENDI
            ENDI
            ADD.W   #(LANE_ADDRESSES_SIZE*2)+2,A0
        ENDF
        RTS


; note has been hit correctly
NOTE_HIT_DETECTION
        IF.B (A5) <EQ> D1 THEN
            ; sets the position to the left to make the note disappear when checking collision
            IF.B 6(A1) <EQ> #0  THEN
                CLR.L   D7
                MOVE.B  player_1_lane_number,D7
                IF.B (A4) <EQ> D7   THEN
                    MOVE.B  #1,treble_last_note_success
                    ; puts in the notes hits animation state
                    LEA     lanes_notes_hit_animations,A2
                    LEA     lanes_colours,A3
                    LSL.L   #2,D7
                    ADD.L   D7,A2
                    ADD.L   D7,A3
                    IF.W D1 <EQ> #1 THEN
                        MOVE.L  #BLUE,(A2)
                        MOVE.L  #BLUE,(A3)+
                        MOVE.L  #BLUE,(A3)
                    ELSE
                        IF.W D1 <EQ> #2 THEN
                            MOVE.L  #RED,(A2)
                            MOVE.L  #RED,(A3)+
                            MOVE.L  #RED,(A3)
                        ELSE
                            IF.W D1 <EQ> #3 THEN
                                MOVE.L  #YELLOW,(A2)
                                MOVE.L  #YELLOW,(A3)+
                                MOVE.L  #YELLOW,(A3)
                            ELSE
                                MOVE.L  #PURPLE2,(A2)
                                MOVE.L  #PURPLE2,(A3)+
                                MOVE.L  #PURPLE2,(A3)
                                MOVE.B  7(A1),player_1_lane_number
                            ENDI
                        ENDI
                    ENDI
                    MOVE.B  #7,(A2)
                    CLR.W   (A1)+
                    CLR.W   (A1)
                    CLR.B   (A6)
                    ADDQ.W  #1,notes_speed_indexer
                    ADDQ.W  #1,player_1_longest_streak
                    ADDQ.W  #1,player_1_notes_hit_count
                ELSE
                    ADD.W   #2,A1
                ENDI
            ELSE
                IF.B 6(A1) <EQ> #1  THEN
                    CLR.L   D7
                    MOVE.B  player_2_lane_number,D7
                    IF.B (A4) <EQ> D7   THEN
                        MOVE.B  #1,bass_last_note_success
                        ; puts in the notes hits animation state
                        LEA     lanes_notes_hit_animations,A2
                        LEA     lanes_colours,A3
                        LSL.L   #2,D7
                        ADD.L   D7,A2
                        ADD.L   D7,A3
                        IF.W D1 <EQ> #1 THEN
                            MOVE.L  #AQUA,(A2)
                            MOVE.L  #AQUA,(A3)+
                            MOVE.L  #AQUA,(A3)
                        ELSE
                            IF.W D1 <EQ> #2 THEN
                                MOVE.L  #ORANGE,(A2)
                                MOVE.L  #ORANGE,(A3)+
                                MOVE.L  #ORANGE,(A3)
                            ELSE
                                IF.W D1 <EQ> #3 THEN
                                    MOVE.L  #LIME,(A2)
                                    MOVE.L  #LIME,(A3)+
                                    MOVE.L  #LIME,(A3)
                                ELSE
                                    MOVE.L  #PURPLE2,(A2)
                                    MOVE.L  #PURPLE2,(A3)+
                                    MOVE.L  #PURPLE2,(A3)
                                    MOVE.B  7(A1),player_2_lane_number
                                ENDI
                            ENDI
                        ENDI
                        MOVE.B  #7,(A2)
                        CLR.W   (A1)+
                        CLR.W   (A1)
                        CLR.B   (A6)
                        ADDQ.W  #1,notes_speed_indexer
                        ADDQ.W  #1,player_2_longest_streak
                        ADDQ.W  #1,player_2_notes_hit_count
                    ELSE
                        ADD.W   #2,A1
                    ENDI
                ELSE
                    ADD.W   #2,A1
                ENDI
            ENDI
        ELSE
            ADD.W   #2,A1
        ENDI
        MOVE.W  notes_speed_indexer_rollover,D0
        IF.W notes_speed_indexer <HS> D0    THEN
            SUB.W   D0,notes_speed_indexer
            ADDQ.W  #1,notes_speed
        ENDI
        RTS


; must not use D5, A0, A1, A4, A5, A6
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
                LEA     NOTES_NAMES,A3

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
                    MOVEQ   #77,D0
                    MOVEQ   #2,D2
                    TRAP    #15
                ENDI

                ; puts in the rest time
                SUB.B   #60,D3
                MOVE.B  D3,(A2,D1)

                ; D1 needed here
                MOVEQ   #75,D0
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
        SUB.W   #2,-(A2)
        MOVEQ   #2,D7
        FOR.W D6 = #0 TO (A2) BY #2 DO
            MOVE.W  (A0,D7),(A0,D6)
            ADD.B   #2,D7
        ENDF
        MOVE.W  #$FFFF,(A0,D6)
        RTS


HANDLE_INPUT
        BSR     HANDLE_PAUSE

        LEA     player_1_action_pressed,A1
        LEA     player_1_action_colour,A2
        LEA     player_1_punching_index,A4
        MOVE.L  player_1_colour_keymaps,D1
        BSR     HANDLE_COLOUR_CHANGE

        ; shift
        MOVE.L  #$10000000,D1
        LEA     player_1_charge_amount,A3
        BSR     HANDLE_CHARGE

        LEA     player_1_lane_number,A1
        LEA     player_1_moving,A2
        MOVE.L  player_1_keymaps,D1
        BSR     HANDLE_MOVEMENT

        LEA     player_1_position,A0
        BSR     CHANGE_PLAYER_Y_POSITION

        IF.B two_player <EQ> #1 THEN
            LEA     player_2_action_pressed,A1
            LEA     player_2_action_colour,A2
            LEA     player_2_punching_index,A4
            MOVE.L  player_2_colour_keymaps,D1
            BSR     HANDLE_COLOUR_CHANGE

            ; control
            MOVE.L  #$11000000,D1
            LEA     player_2_charge_amount,A3
            BSR     HANDLE_CHARGE

            LEA     player_2_lane_number,A1
            LEA     player_2_moving,A2
            MOVE.L  player_2_keymaps,D1
            BSR     HANDLE_MOVEMENT

            LEA     player_2_position,A0
            BSR     CHANGE_PLAYER_Y_POSITION
        ENDI
        RTS


HANDLE_PAUSE
        MOVEQ   #19,D0
        MOVE.L  #$1B000000,D1
        TRAP    #15

        ; checks esc
        BTST.L  #24,D1
        IF  <NE>    THEN
            CLR.B   player_1_action_colour
            MOVE.B  #1,pause_menu_active
        ENDI
        RTS


PAUSE_MENU_LOOP
        BSR     HANDLE_MENU_SELECT

        IF.B player_1_action_colour <EQ> #1 THEN
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_object_time
            CLR.B   player_1_action_colour
            BRA     GAME_LOOP
        ELSE
            IF.B player_1_action_colour <EQ> #2 THEN
                MOVE.B  #1,two_player
                CLR.B   player_1_action_colour
                BRA     MAIN_MENU_LOOP
            ENDI
        ENDI
        CLR.B   player_1_action_colour

        BSR     DRAW_PAUSE_MENU
        BSR     REPAINT_AREA
        
        ; delay
        MOVEQ   #23,D0
        MOVEQ   #1,D1
        TRAP    #15
        BRA     PAUSE_MENU_LOOP


; A1 must contain player action pressed
; A2 must contain player action colour
; A4 must conatin the player punching index
; D1 must contain player colour keymaps
HANDLE_COLOUR_CHANGE
        MOVEQ   #19,D0
        TRAP    #15

        IF.L #0 <NE> D1 THEN
            MOVE.L  D1,D2
            ; change colours
            BTST.L  #24,D2
            IF  <NE>    THEN
                BTST.B  #7,(A1)
                IF  <EQ>    THEN
                    MOVE.B  #1,(A2)
                    BSET.B  #7,(A1)
                    MOVE.B  #1,(A4)
                ENDI
            ELSE
                BCLR.B  #7,(A1)
            ENDI
            BTST.L  #16,D2
            IF  <NE>    THEN
                BTST.B  #6,(A1)
                IF  <EQ>    THEN
                    MOVE.B  #2,(A2)
                    BSET.B  #6,(A1)
                    MOVE.B  #1,(A4)
                ENDI
            ELSE
                BCLR.B  #6,(A1)
            ENDI
            BTST.L  #8,D2
            IF  <NE>    THEN
                BTST.B  #5,(A1)
                IF  <EQ>    THEN
                    MOVE.B  #3,(A2)
                    BSET.B  #5,(A1)
                    MOVE.B  #1,(A4)
                ENDI
            ELSE
                BCLR.B  #5,(A1)
            ENDI
            ; check for purple pressed
            BTST.L  #0,D2
            IF  <NE>    THEN
                BTST.B  #4,(A1)
                IF  <EQ>    THEN
                    MOVE.B  #4,(A2)
                    BSET.B  #4,(A1)
                    MOVE.B  #1,(A4)
                ENDI
            ELSE
                BCLR.B  #4,(A1)
            ENDI
        ELSE
            BCLR.B  #7,(A1)
            BCLR.B  #6,(A1)
            BCLR.B  #5,(A1)
            BCLR.B  #4,(A1)
        ENDI
        RTS


; A2 contains the player action colour
; A3 contains the player charge address
; A4 contains the player punching index
; D1 must contain player shift/control keycode
HANDLE_CHARGE
        ; check for shift/control pressed
        MOVEQ   #19,D0
        TRAP    #15
        BTST.L  #24,D1
        IF  <NE>    THEN
            IF.B (A3) <LO> #80  THEN
                MOVEQ   #15,D2
                MOVE.B  song_difficulty,D0
                ADD.B   #10,D0
                LSR.B   #1,D0
                SUB.B   D0,D2
                MOVE.W  notes_speed,D0
                LSR.W   #1,D0
                ADD.B   D0,D2
                ADD.B   D2,(A3)
                IF.B (A3) <HI> #80  THEN
                    MOVE.B  #80,(A3)
                ENDI
            ENDI
            IF.B (A4) <HS> #7   THEN
                CLR.B   (A4)
            ENDI
        ELSE
            CLR.B   (A3)
            IF.B (A4) <EQ> #0   THEN
                MOVE.B  #8,(A4)
                CLR.B   (A2)
            ENDI
        ENDI
        RTS


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
        LSR.W   #1,D2
        ADD.W   #TOP_BORDER_PADDING,D2
        ADD.W   D2,D3
        RTS



SPAWN_NEW_NOTE
        MOVE.L  treble_song_file_index,A0

        ; song has ended
        IF.B (A0) <NE> #$FF THEN
            ; check for carraige return and line feed
            IF.B (A0) <EQ> #13  THEN
                ADDQ.L  #2,treble_song_file_index
                ADDQ.L  #2,A0
            ELSE
                IF.B (A0) <EQ> #10  THEN
                    ADDQ.L  #1,treble_song_file_index
                    ADDQ.L  #1,A0
                ENDI
            ENDI

            LEA	    treble_quater_beat_count,A4
            ; first byte is checked if there are any notes being played
            IF.B #48 <NE> (A0) THEN
                BSR     CREATE_NOTE_OBJECT
                LEA     treble_song_file_index,A1
                LEA     treble_note_path_index,A3
                BSR     LOAD_NOTE_DATA

                IF.W (A2) <NE> #0   THEN
                    ADDQ.W  #1,treble_total_notes
                    ; check if teleporter
                    IF.W (A2) <EQ> #4   THEN
                        BSR     PICK_RANDOM_PATH_INDEX
                        MOVE.B  (A3),7(A2)
                    ENDI
                ENDI
                MOVE.B  #0,6(A2)
                
                IF.W (A2) <NE> #0 AND.W (A2) <NE> #4    THEN
                    ; new path index
                    MOVE.W  #8,D0
                    TRAP    #15
                    MOVE.L  D1,D0
                    SUB.L   last_treble_path_change_time,D1
                    IF.L #0 <LE> D1 THEN
                        MOVE.L  D0,last_treble_path_change_time
                        MOVE.W  #100,D3
                        BSR     GET_RANDOM_VALUE
                        ADD.B   #100,D2
                        CLR.L   D3
                        MOVE.B  D2,D3
                        ADD.L   D3,last_treble_path_change_time
                        BSR     CHANGE_TREBLE_PATH_INDEX
                    ENDI
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
            ELSE
                IF.B (A0) <EQ> #10  THEN
                    ADDQ.L  #1,bass_song_file_index
                    ADDQ.L  #1,A0
                ENDI
            ENDI

            LEA	    bass_quater_beat_count,A4
            IF.B #48 <NE> (A0) THEN
                BSR     CREATE_NOTE_OBJECT
                LEA     bass_song_file_index,A1
                LEA     bass_note_path_index,A3
                BSR     LOAD_NOTE_DATA
                IF.B two_player <EQ> #0 THEN
                    CLR.W   (A2)
                ELSE
                    IF.W (A2) <NE> #0   THEN
                        ADDQ.W  #1,bass_total_notes
                        ; check if teleporter
                        IF.W (A2) <EQ> #4   THEN
                            BSR     PICK_RANDOM_PATH_INDEX
                            MOVE.B  (A3),7(A2)
                        ENDI
                    ENDI
                ENDI
                MOVE.B  two_player,6(A2)

                IF.B two_player <EQ> #1 THEN
                    IF.W (A2) <NE> #0 AND.W (A2) <NE> #4    THEN
                        ; new path index
                        MOVE.W  #8,D0
                        TRAP    #15
                        MOVE.L  D1,D0
                        SUB.L   last_bass_path_change_time,D1
                        IF.L #0 <LE> D1 THEN
                            MOVE.L  D0,last_bass_path_change_time
                            MOVE.W  #100,D3
                            BSR     GET_RANDOM_VALUE
                            ADD.B   #100,D2
                            CLR.L   D3
                            MOVE.B  D2,D3
                            ADD.L   D3,last_bass_path_change_time
                            BSR     CHANGE_BASS_PATH_INDEX
                        ENDI
                    ENDI
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
        FOR D5 = #0 TO #(NOTE_OBJECT_SIZE*LANE_ADDRESSES_SIZE*2)-1 BY #NOTE_OBJECT_SIZE  DO
            IF.W (A2,D5) <EQ> #$FFFF   THEN
                ADD.L   D5,A2
                RTS
            ENDI
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
        MOVEQ   #8,D3
        SUB.L   #8,A0
        WHILE.B (A0,D3) <NE> #44   DO
            MOVE.B  (A0,D3),(A2,D3)
            ADDQ.B   #1,D3
        ENDW
        MOVE.B  #0,(A2,D3)
        SUBQ.B  #7,D3
        ADD.L   D3,(A1)
        SUBQ.B  #1,D3

        ; gets the number of notes playing on the same beat
        LSR.B   #2,D3

        ; assign a colour based on the playing notes
        ; and the difficulty
        MOVE.B  song_difficulty,D0
        IF.B (A4) <LO> D0 THEN
            CLR.W   (A2)
        ELSE
            BSR     PICK_NOTE_COLOUR
            MOVE.B   #1,(A4)
        ENDI

        ; assign x and y position based on the path index
        ADD.W   #2,A2
        MOVE.W  #SCREEN_WIDTH,(A2)
        ADD.W   #2,A2
        CLR.L   D2
        MOVE.B  (A3),D2
        BSR     GET_LANE_Y_POSITION
        MOVE.W  D3,(A2)
        SUB.W   #30,(A2)

        ; adds note object to the end of the lane queue
        CLR.L   D1
        MOVE.B  (A3),D1
        MULU    #(LANE_ADDRESSES_SIZE*2)+2,D1
        LEA     lane_notes_addresses,A0
        ADD     D1,A0
        SUB.W   #4,A2
        BSR     ENQUEUE_OBJECT_TO_LANE
        
        RTS


; needs to have the number of notes in D3
; choose a random frequency to pick as the visible colour
PICK_NOTE_COLOUR
        IF.W D3 <NE> #1 THEN
            BSR     GET_RANDOM_VALUE
            AND.L   #$FFFF0000,D2
            LSL.B   #2,D2
        ELSE
            MOVEQ   #0,D2
        ENDI
        ADD.W   #10,D2
        MOVE.B  (A2,D2),D2
        SUB.B   #96,D2
        ; checks 4 bit
        BCLR.L  #4,D2
        IF  <EQ>    THEN
            IF.B D2 <HI> #3 THEN
                SUB.B   #3,D2
            ENDI
        ELSE
            IF.B D2 <HI> #3 THEN
                SUB.B   #3,D2
            ENDI
            BSET.L  #4,D2
        ENDI
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


; A3 contains the current path index
PICK_RANDOM_PATH_INDEX
        MOVE.W  #3,D3
        BSR     GET_RANDOM_VALUE

        FOR D5 = #0 TO #4   DO
            IF.B D5 <NE> treble_note_path_index AND.B D5 <NE> bass_note_path_index   THEN
                IF.B D2 <EQ> #0 THEN
                    MOVE.B  D5,(A3)
                    RTS
                ELSE
                    SUB.B   #1,D2
                ENDI
            ENDI
        ENDF
        RTS


CHANGE_TREBLE_PATH_INDEX
        LEA     treble_note_path_index,A2
        IF.B two_player <EQ> #0 THEN
            IF.B (A2) <EQ> #0   THEN
                ADD.B   #1,(A2)
            ELSE
                IF.B (A2) <EQ> #4   THEN
                    SUB.B   #1,(A2)
                ELSE
                    BSR     UP_DOWN_RANDOM
                ENDI
            ENDI
        ELSE
            IF.B (A2) <EQ> #0   THEN
                IF.B bass_note_path_index <NE> #1   THEN
                    ADD.B   #1,(A2)
                ENDI
            ELSE
                IF.B (A2) <EQ> #4   THEN
                    IF.B bass_note_path_index <NE> #3   THEN
                        SUB.B   #1,(A2)
                    ENDI
                ELSE
                    MOVE.B  (A2),D0
                    SUB.B   bass_note_path_index,D0
                    IF.B D0 <EQ> #1 THEN
                        ADD.B   #1,(A2)
                    ELSE
                        IF.B D0 <EQ> #$FF THEN
                            SUB.B   #1,(A2)
                        ELSE
                            BSR     UP_DOWN_RANDOM
                        ENDI
                    ENDI
                ENDI
            ENDI
        ENDI
        RTS


CHANGE_BASS_PATH_INDEX
        LEA     bass_note_path_index,A2
        IF.B (A2) <EQ> #0   THEN
            IF.B treble_note_path_index <NE> #1 THEN
                ADD.B   #1,(A2)
            ENDI
        ELSE
            IF.B (A2) <EQ> #4   THEN
                IF.B treble_note_path_index <NE> #3 THEN
                    SUB.B   #1,(A2)
                ENDI
            ELSE
                MOVE.B  (A2),D0
                SUB.B   treble_note_path_index,D0
                IF.B D0 <EQ> #1 THEN
                    ADD.B   #1,(A2)
                ELSE
                    IF.B D0 <EQ> #$FF THEN
                        SUB.B   #1,(A2)
                    ELSE
                        BSR     UP_DOWN_RANDOM
                    ENDI
                ENDI
            ENDI
        ENDI
        RTS


; this uses the note path index in A2
UP_DOWN_RANDOM
        BSR     RANDOM_2
        IF  <NE>    THEN
            ADD.B   #1,(A2)
        ELSE
            SUB.B   #1,(A2)
        ENDI
        RTS


; loops over music time array
; decrements times for each note
DECREMENT_NOTES_TIMES
        CLR.B   D0
        LEA notes_times_array,A1
        FOR D5 = #0 TO #101  DO
            IF.B (A1,D5) <NE> #$FF  THEN
                SUB.B   #1,(A1,D5)
                MOVEQ   #1,D0
                IF.B (A1,D5) <EQ> #0    THEN
                    ; stops a note playing
                    MOVE.B  D5,D1
                    MOVEQ   #2,D2
                    MOVEQ   #77,D0
                    TRAP    #15
                    MOVE.B  #$FF,(A1,D5)
                ENDI
            ENDI
        ENDF
        IF.B D0 <EQ> #0 THEN
            MOVE.L  treble_song_file_index,A0
            MOVE.L  bass_song_file_index,A1
            IF.B (A0) <EQ> #$FF AND.B (A1) <EQ> #$FF    THEN
                BSR     CHECK_LANES_EMPTY
                IF.B D0 <EQ> #1 THEN
                    ; load in new song or show victory screen with percentage hit
                    IF.B song_playing_type <EQ> #0  THEN
                        CLR.B   player_1_action_colour
                        BSR     GAME_WON_MENU_LOOP
                    ELSE
                        BSR     LOAD_IN_RANDOM_NEW_SONG
                        ADD.W   #2,previous_notes_speed
                        MOVE.W  previous_notes_speed,notes_speed
                    ENDI
                ENDI
            ENDI
        ENDI
        RTS


CHECK_LANES_EMPTY
        LEA     lane_notes_addresses,A0
        ; loops through the five lanes
        FOR D5 = #0 TO #4   DO
            ; loops until encounters an empty position
            IF.W (A0) <NE> #$FFFF   THEN
                RTS
            ENDI
            ADD.W   #(LANE_ADDRESSES_SIZE*2)+2,A0
        ENDF
        MOVEQ   #1,D0
        RTS


GAME_WON_MENU_LOOP
        BSR HANDLE_MENU_SELECT

        IF.B player_1_action_colour <EQ> #1 THEN
            MOVE.B  #1,two_player
            CLR.B   player_1_action_colour
            BRA     MAIN_MENU_LOOP
        ELSE
            IF.B player_1_action_colour <EQ> #2 THEN
                CLR.B   player_1_action_colour
                BRA     GAME_START
            ENDI
        ENDI
        CLR.B   player_1_action_colour

        BSR     DRAW_GAME_WON_MENU
        BSR     REPAINT_SCREEN
        
        ; delay
        MOVEQ   #23,D0
        MOVEQ   #1,D1
        TRAP    #15
        BRA     GAME_WON_MENU_LOOP


RENDER_SCREEN
        BSR     DRAW_PLAYERS
        BSR     DRAW_NOTES
        BSR     DRAW_FOREGROUND
        BSR     DRAW_CHARGE_METERS
        BSR     DRAW_NOTES_HITS_ANIMATIONS
        BSR     DRAW_INFO_HUD

        IF.B pause_menu_active <EQ> #1  THEN
            CLR.B   pause_menu_active
            ; repaints screen
            MOVEQ   #94,D0
            TRAP    #15
            BRA     PAUSE_MENU_LOOP
        ELSE
            BSR     REPAINT_SCREEN
        ENDI
        RTS


DRAW_PLAYERS
        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #MULTIPLIER_SIZE,D1
        TRAP    #15

        CLR.L   D0
        LEA     player_1_position,A1
        CLR.L   D1
        IF.B player_1_punching_index <EQ> #8    THEN
            MOVE.L  player_1_start_sprite,A0
            MOVE.B  player_1_action_colour,D0
            MOVE.B  sprite_gif_index,D1
            BSR     DRAW_PLAYER
        ELSE
            MOVE.L  punching_1_start_sprite,A0
            IF.B player_1_punching_index <NE> #0    THEN
                MOVE.B  player_1_action_colour,D0
                MOVE.B  player_1_punching_index,D1
            ENDI
            ADD.W   #6,(A1)
            BSR     DRAW_PLAYER
            SUB.W   #6,(A1)
        ENDI

        IF.B two_player <EQ> #1 THEN
            CLR.L   D0
            LEA     player_2_position,A1
            CLR.L   D1
            IF.B player_2_punching_index <EQ> #8    THEN
                MOVE.L  player_2_start_sprite,A0
                MOVE.B  player_2_action_colour,D0
                MOVE.B  sprite_gif_index,D1
                BSR     DRAW_PLAYER
            ELSE
                MOVE.L  punching_2_start_sprite,A0
                IF.B player_2_punching_index <NE> #0    THEN
                    MOVE.B  player_2_action_colour,D0
                    MOVE.B  player_2_punching_index,D1
                ENDI
                ADD.W   #6,(A1)
                BSR     DRAW_PLAYER
                SUB.W   #6,(A1)
            ENDI
        ENDI
        RTS


; A0 must contain the start of the sprite
; A1 must contain the player 1 position
; D0 must contain the player action colour
; D1 must contain the sprite gif index
DRAW_PLAYER
        ; multiply by $2000
        LSL.L   #8,D0
        LSL.L   #5,D0
        ADD.L   D0,A0
        ; multiply by $400
        LSL.L   #8,D1
        LSL.L   #2,D1
        ADD.L   D1,A0

        CLR.L   D3
        CLR.L   D2
        MOVE.W  2(A1),D2
        MOVE.L  D2,D4
        ; 16x16
        FOR D5 = #0 TO #$F  DO
            MOVE.W  (A1),D3
            FOR D6 = #0 TO #$F  DO
                ; set pen colour
                MOVEQ   #80,D0
                MOVE.L  (A0)+,D1
                TRAP    #15

                ; draw rectangle
                MOVEQ   #90,D0
                MOVE.W  D3,D1
                TRAP    #15

                ADDQ    #6,D3
            ENDF
            ADDQ    #6,D2
            ADDQ    #6,D4
        ENDF
        RTS


DRAW_NOTES
        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #MULTIPLIER_SIZE,D1
        TRAP    #15

        LEA     lane_notes_addresses,A3
        ; loops through the five lanes
        FOR A4 = #0 TO #4   DO
            MOVE.L  A3,A2
            ; loops until encounters an empty position
            IF.W (A2) <NE> #$FFFF   THEN
                DBLOOP D7 = #LANE_ADDRESSES_SIZE-1
                    MOVE.W  (A2)+,A1
                    IF.W (A1) <NE> #0   THEN
                        CLR.L   D0
                        MOVE.W  (A1)+,D0
                        BCLR.L  #4,D0
                        ; check if filled or unfilled
                        IF  <EQ>    THEN
                            ; check if treble or bass
                            IF.B 4(A1) <EQ> #0  THEN
                                MOVE.L  filled_notes_1_start_sprite,A0
                            ELSE
                                MOVE.L  filled_notes_2_start_sprite,A0
                            ENDI
                        ELSE
                            ; check if treble or bass
                            IF.B 4(A1) <EQ> #0  THEN
                                MOVE.L  unfilled_notes_1_start_sprite,A0
                            ELSE
                                MOVE.L  unfilled_notes_2_start_sprite,A0
                            ENDI
                        ENDI
                        BSR     DRAW_NOTE
                    ENDI
                UNLESS.W (A2) <NE> #$FFFF
            ENDI
            ADD.W   #(LANE_ADDRESSES_SIZE*2)+2,A3
        ENDF
        RTS


; A0 must contain the start of the sprite
; D0 must contain the note colour
; A1 must contain the note position
DRAW_NOTE
        ; multiply by $2000
        LSL.L   #8,D0
        LSL.L   #5,D0
        ADD.L   D0,A0
        ; multiply by $400
        CLR.L   D1
        MOVE.B  sprite_gif_index,D1
        LSL.L   #8,D1
        LSL.L   #2,D1
        ADD.L   D1,A0

        CLR.L   D3
        CLR.L   D2
        MOVE.W  2(A1),D2
        MOVE.L  D2,D4
        ; 12x12
        FOR D5 = #0 TO #$B  DO
            MOVE.W  (A1),D3
            FOR D6 = #0 TO #$B  DO
                ; set pen colour
                MOVEQ   #80,D0
                MOVE.L  (A0)+,D1
                TRAP    #15

                ; draw rectangle
                MOVEQ   #90,D0
                MOVE.W  D3,D1
                TRAP    #15

                ADDQ    #6,D3
            ENDF
            ADDQ    #6,D2
            ADDQ    #6,D4
        ENDF
        RTS


DRAW_FOREGROUND
        BSR     DRAW_LANE_LINES
        BSR     DRAW_BEAT_LINE
        RTS


DRAW_LANE_LINES
        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #3,D1
        TRAP    #15
        
        ; sets pen colour to grey
        MOVEQ   #80,D0
        MOVE.L  #$00444444,D1
        TRAP    #15

        MOVE.W  #LEFT_BORDER_PADDING+1,D1
        MOVE.W  #SCREEN_WIDTH-RIGHT_BORDER_PADDING-1,D3
        FOR D5 = #0 TO #5   DO
            MOVE.W  #LANE_SIZE,D2
            MULU    D5,D2
            ADD.W   #TOP_BORDER_PADDING,D2
            MOVE.W  D2,D4
            BSR     DRAW_LINE
        ENDF

        ; draw the filled in area
        MOVE.W  #LEFT_BORDER_PADDING+1,D1
        SUB.W   D1,D3

        MOVE.W  treble_song_file_size,D5
        MOVE.L  treble_song_file_index,D7
        SUB.L   #TREBLE_FILE_CONTENTS,D7

        MULU    D7,D3
        DIVU    D5,D3

        ADD.W   D1,D3
        MOVE.W  D1,D7

        LEA     lanes_colours,A0
        FOR D5 = #0 TO #5   DO
            ; sets pen colour
            MOVEQ   #80,D0
            MOVE.L  (A0)+,D1
            TRAP    #15

            MOVE.W  #LANE_SIZE,D2
            MULU    D5,D2
            ADD.W   #TOP_BORDER_PADDING,D2
            MOVE.W  D2,D4
            MOVE.W  D7,D1
            BSR     DRAW_LINE
        ENDF

        RTS


DRAW_BEAT_LINE
        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #5,D1
        TRAP    #15

        ; sets pen to white
        MOVEQ   #80,D0
        MOVE.L  #WHITE,D1
        TRAP    #15

        MOVE.W  #BEAT_LINE_X,D1
        MOVE.W  #21,D2
        MOVE.W  #BEAT_LINE_X,D3
        MOVE.W  #SCREEN_HEIGHT-19,D4
        BSR     DRAW_LINE
        RTS


; line from D1.W,D2.W TO D3.W,D4.W
DRAW_LINE
        MOVEQ   #84,D0
        TRAP    #15
        RTS


DRAW_CHARGE_METERS
        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #1,D1
        TRAP    #15

        LEA     player_1_position,A0
        MOVE.B  player_1_charge_amount,D5
        BSR     DRAW_METER

        LEA     player_2_position,A0
        MOVE.B  player_2_charge_amount,D5
        BSR     DRAW_METER
        RTS

; A0 contains the address to the player position
; D5 contains the player charge amount
DRAW_METER
        IF.B D5 <NE> #0 THEN
            ; sets pen colour to white
            MOVEQ   #80,D0
            MOVE.L  #WHITE,D1
            TRAP    #15
            MOVE.W  #81,D0
            TRAP    #15

            ; draw charge meter border
            MOVE.W  #20,D1
            MOVE.W  2(A0),D2
            MOVE.W  D1,D3
            ADD.W   #10,D3
            MOVE.W  D2,D4
            ADD.W   #80,D4

            MOVE.W  #90,D0
            TRAP    #15
            MOVE.W  D1,D7

            ; draw charge meter inside
            IF.B D5 <NE> #80    THEN
                ; sets pen and fill colour to grey
                MOVEQ   #80,D0
                MOVE.L  #$00444444,D1
                TRAP    #15
                MOVE.W  #81,D0
                TRAP    #15
            ENDI
            MOVE.W  D7,D1
            ADD.W   #1,D1
            SUB.W   #1,D3

            MOVE.W  D4,D2
            CLR.L   D7
            MOVE.B  D5,D7
            SUB.W   D7,D2
            IF.B D5 <EQ> #80    THEN
                ADD.W   #1,D2
            ENDI
            SUB.W   #1,D4
            
            MOVE.W  #87,D0
            TRAP    #15
        ENDI
        RTS


DRAW_NOTES_HITS_ANIMATIONS
        LEA     lanes_notes_hit_animations,A1

        MOVE.W  #8,D0
        TRAP    #15
        SUB.L   last_notes_hit_index_change_time,D1
        MOVE.L  D1,D5
        
        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #5,D1
        TRAP    #15

        CLR.L   D2
        FOR A0 = #0 TO #4   DO
            IF.B (A1) <NE> #0   THEN
                ; sets pen colour
                MOVEQ   #80,D0
                MOVE.L  (A1),D1
                AND.L   #WHITE,D1
                TRAP    #15

                MOVE.W  A0,D2
                BSR     GET_LANE_Y_POSITION
                MOVE.W  D3,D7

                IF.B (A1) <LO> #4   THEN
                    BSR     LOWER_SHORT_DRAW
                ELSE
                    IF.B (A1) <HI> #4   THEN
                        BSR     UPPER_SHORT_DRAW
                    ELSE
                        BSR     LONG_DRAW
                    ENDI
                ENDI
                IF.L #8 <LE> D5 THEN
                    SUBQ.B  #1,(A1)
                ENDI
            ENDI
            ADD.L   #4,A1
        ENDF

        IF.L #8 <LE> D5 THEN
            MOVE.W  #8,D0
            TRAP    #15
            MOVE.L  D1,last_notes_hit_index_change_time
        ENDI
        RTS


LOWER_SHORT_DRAW
        CLR.L   D6
        MOVE.B  (A1),D6
        LSL.L   #3,D6

        MOVE.W  #BEAT_LINE_X,D1
        MOVE.W  D7,D2
        SUB.W   #32,D1
        SUB.W   #32,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4
        ADD.W   D6,D3
        ADD.W   D6,D4
        BSR     DRAW_LINE

        MOVE.W  #BEAT_LINE_X,D1
        MOVE.W  D7,D2
        ADD.W   #32,D1
        SUB.W   #32,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4
        SUB.W   D6,D3
        ADD.W   D6,D4
        BSR     DRAW_LINE

        MOVE.W  #BEAT_LINE_X,D1
        MOVE.W  D7,D2
        SUB.W   #32,D1
        ADD.W   #32,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4
        ADD.W   D6,D3
        SUB.W   D6,D4
        BSR     DRAW_LINE

        MOVE.W  #BEAT_LINE_X,D1
        MOVE.W  D7,D2
        ADD.W   #32,D1
        ADD.W   #32,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4
        SUB.W   D6,D3
        SUB.W   D6,D4
        BSR     DRAW_LINE
        RTS


UPPER_SHORT_DRAW
        MOVEQ   #8,D6
        SUB.B  (A1),D6
        LSL.L   #3,D6

        MOVE.W  #BEAT_LINE_X,D1
        MOVE.W  D7,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4

        SUB.W   D6,D1
        SUB.W   D6,D2
        ADD.W   D6,D3
        ADD.W   D6,D4
        BSR     DRAW_LINE
        
        MOVE.W  D3,D7
        MOVE.W  D1,D3
        MOVE.W  D7,D1
        BSR     DRAW_LINE
        RTS


LONG_DRAW
        MOVE.W  #BEAT_LINE_X,D1
        MOVE.W  D7,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4

        SUB.W   #32,D1
        SUB.W   #32,D2
        ADD.W   #32,D3
        ADD.W   #32,D4
        BSR     DRAW_LINE

        MOVE.W  D3,D7
        MOVE.W  D1,D3
        MOVE.W  D7,D1
        BSR     DRAW_LINE
        RTS


DRAW_INFO_HUD
        ; set font colour
        MOVEQ   #21,D0
        MOVE.L  #WHITE,D1
        MOVE.L  #$06120000,D2
        TRAP    #15

        BSR     DRAW_LIFE_BARS

        ; sets pen fill to black
        MOVE.W  #81,D0
        CLR.L   D1
        TRAP    #15

        BSR     DRAW_SCORE_AND_LIFE_TEXT
        BSR     DRAW_SONG_NAME
        BSR     DRAW_STREAKS

        BSR     DRAW_CONTROL_BUTTONS
        RTS


DRAW_SCORE_AND_LIFE_TEXT
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$1801,D1
        TRAP    #15

        ; show text
        MOVEQ   #14,D0
        LEA     score_text,A1
        TRAP    #15

        ; show number
        MOVEQ   #3,D0
        MOVE.L  score,D1
        TRAP    #15

        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$3001,D1
        TRAP    #15

        ; show text
        MOVEQ   #14,D0
        LEA     life_text,A1
        TRAP    #15
        RTS


DRAW_LIFE_BARS
        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #1,D1
        TRAP    #15

        ; sets pen colour
        MOVEQ   #80,D0
        MOVE.L  #WHITE,D1
        TRAP    #15

        ; draw border
        MOVE.W  #90,D0
        MOVE.W  #LIFE_BAR_X,D1
        MOVE.W  #30,D2
        MOVE.W  #LIFE_BAR_X+402,D3
        MOVE.W  #55,D4
        TRAP    #15

        ADDQ.W  #1,D2
        SUBQ.W  #1,D4

        IF.B two_player <EQ> #0 THEN
            ; sets pen and fill colour to red
            MOVEQ   #80,D0
            MOVE.L  #RED,D1
            TRAP    #15
            MOVE.W  #81,D0
            TRAP    #15

            MOVE.W  #87,D0
            MOVE.W  #LIFE_BAR_X+1,D1
            MOVE.W  #LIFE_BAR_X+1,D3

            IF.W player_1_life_amount <GT> #0   THEN
                ADD.W   player_1_life_amount,D3
            ENDI
            TRAP    #15
        ELSE
            IF.B coop_mode <EQ> #0  THEN
                ; sets pen and fill colour to red
                MOVEQ   #80,D0
                MOVE.L  #RED,D1
                TRAP    #15
                MOVE.W  #81,D0
                TRAP    #15

                MOVE.W  #87,D0
                MOVE.W  #LIFE_BAR_X+1,D1
                MOVE.W  #LIFE_BAR_X+1,D3
                SUB.W   #12,D4

                IF.W player_1_life_amount <GT> #0   THEN
                    ADD.W   player_1_life_amount,D3
                ENDI
                TRAP    #15

                ; sets pen and fill colour to lime
                MOVEQ   #80,D0
                MOVE.L  #LIME,D1
                TRAP    #15
                MOVE.W  #81,D0
                TRAP    #15

                MOVE.W  #87,D0
                MOVE.W  #LIFE_BAR_X+1,D1
                MOVE.W  #LIFE_BAR_X+1,D3
                ADD.W   #12,D2
                ADD.W   #12,D4

                IF.W player_2_life_amount <GT> #0   THEN
                    ADD.W   player_2_life_amount,D3
                ENDI
                TRAP    #15
            ELSE
                MOVE.W  player_1_life_amount,D7
                ADD.W   player_2_life_amount,D7

                IF.W D7 <GT> #0   THEN
                    LSR.W   #1,D7
                ELSE
                    CLR.W   D7
                ENDI

                DIVU    #25,D7
                MOVE.B  D7,D6
                SWAP    D7
                SUBQ.B  #1,D6
                
                MOVE.W  #LIFE_BAR_X+1,D3

                FOR.B D5 = #0 TO D6 DO
                    BTST    #0,D5
                    IF  <NE>    THEN
                        MOVE.L  #LIME,D1
                    ELSE
                        MOVE.L  #RED,D1
                    ENDI
                    ; sets pen and fill colour
                    MOVEQ   #80,D0
                    TRAP    #15
                    MOVE.W  #81,D0
                    TRAP    #15
                    
                    MOVE.W  #87,D0
                    MOVE.W  D3,D1
                    ADD.W   #25,D3
                    TRAP    #15
                ENDF

                IF.W D7 <NE> #0 THEN
                    ; does one last draw for partial square
                    BTST    #0,D6
                    IF  <NE>    THEN
                        MOVE.L  #RED,D1
                    ELSE
                        MOVE.L  #LIME,D1
                    ENDI
                    ; sets pen and fill colour
                    MOVEQ   #80,D0
                    TRAP    #15
                    MOVE.W  #81,D0
                    TRAP    #15
                    
                    MOVE.W  #87,D0
                    MOVE.W  D3,D1
                    ADD.W   D7,D3
                    TRAP    #15
                ENDI
            ENDI
        ENDI
        RTS


DRAW_SONG_NAME
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$3025,D1
        TRAP    #15

        ; show text
        MOVEQ   #14,D0
        LEA     song_name_text,A1
        TRAP    #15

        ; set font
        MOVEQ   #21,D0
        MOVE.L  #WHITE,D1
        MOVE.L  #$06120002,D2
        TRAP    #15

        ; show song name
        MOVEQ   #14,D0
        LEA     song_name,A1
        ADD.L   #6,A1
        TRAP    #15
        RTS


DRAW_STREAKS
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$6801,D1
        TRAP    #15

        ; set font colour
        MOVEQ   #21,D0
        MOVE.L  #WHITE,D1
        MOVE.L  #$06120000,D2
        TRAP    #15

        ; show text
        MOVEQ   #14,D0
        LEA     streak_text,A1
        TRAP    #15
        
        ; set font colour
        MOVEQ   #21,D0
        MOVE.L  #RED,D1
        MOVE.L  #$06120002,D2
        TRAP    #15

        ; show x
        MOVEQ   #14,D0
        ADD.L   #8,A1
        TRAP    #15

        ; show number
        MOVEQ   #3,D0
        CLR.L   D1
        MOVE.W  player_1_longest_streak,D1
        TRAP    #15

        IF.B two_player <EQ> #1 THEN
            ; set font colour
            MOVEQ   #21,D0
            MOVE.L  #LIME,D1
            MOVE.L  #$06120002,D2
            TRAP    #15

            ; show x
            MOVEQ   #14,D0
            TRAP    #15

            ; show number
            MOVEQ   #3,D0
            CLR.L   D1
            MOVE.W  player_2_longest_streak,D1
            TRAP    #15
        ENDI
        RTS


DRAW_MAIN_MENU
        IF.B sprite_gif_index <NE> #0 AND.B sprite_gif_index <NE> #4    THEN
            BRA     CHANGE_COLOUR
        ENDI
        MOVEQ   #7,D3
        BSR     GET_RANDOM_VALUE
CHECK_INDEX_AGAIN
        IF.B D2 <EQ> #0 THEN
            MOVE.L  #WHITE,D1
        ELSE
            IF.B D2 <EQ> #1 THEN
                MOVE.L  #BLUE,D1
            ELSE
                IF.B D2 <EQ> #2 THEN
                    MOVE.L  #RED,D1
                ELSE
                    IF.B D2 <EQ> #3 THEN
                        MOVE.L  #YELLOW,D1
                    ELSE
                        IF.B D2 <EQ> #4 THEN
                            MOVE.L  #PURPLE2,D1
                        ELSE
                            IF.B D2 <EQ> #5 THEN
                                MOVE.L  #AQUA,D1
                            ELSE
                                IF.B D2 <EQ> #6 THEN
                                    MOVE.L  #ORANGE,D1
                                ELSE
                                    MOVE.L  #LIME,D1
                                ENDI
                            ENDI
                        ENDI
                    ENDI
                ENDI
            ENDI
        ENDI
        IF.L D1 <EQ> main_menu_title_colour THEN
            ADD.B   #1,D2
            BRA     CHECK_INDEX_AGAIN
        ELSE
            MOVE.L  D1,main_menu_title_colour
        ENDI
CHANGE_COLOUR
        ; set font
        MOVEQ   #21,D0
        MOVE.L  main_menu_title_colour,D1
        MOVE.L  #$06400003,D2
        TRAP    #15

        ; draw text
        MOVEQ   #95,D0
        MOVE.W  #730,D1
        MOVE.W  #100,D2
        LEA     main_menu_title_text,A1
        TRAP    #15

        ; draw aqua bell
        MOVE.L  filled_notes_2_start_sprite,A0
        LEA     main_menu_bell_positions,A1
        MOVE.L  #$02700078,(A1)
        MOVEQ   #1,D0
        BSR     DRAW_NOTE
        
        ; draw orange bell
        MOVE.L  filled_notes_2_start_sprite,A0
        ADD.L   #$2600000,(A1)
        MOVEQ   #2,D0
        BSR     DRAW_NOTE


        ; set font
        MOVEQ   #21,D0
        MOVE.L  #WHITE,D1
        MOVE.L  #$06180000,D2
        TRAP    #15

        ; set font
        MOVEQ   #21,D0
        MOVE.L  #$06180000,D2
        IF.B main_menu_difficulty <EQ> #0  THEN
            MOVE.L  #LIME,D1
        ELSE
            MOVE.L  #WHITE,D1
        ENDI
        TRAP    #15
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$2A08,D1
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        LEA     main_menu_difficulty_text,A1
        TRAP    #15

        ; set font
        MOVEQ   #21,D0
        MOVE.L  #$06180000,D2
        IF.B main_menu_difficulty <EQ> #1  THEN
            MOVE.L  #ORANGE,D1
        ELSE
            MOVE.L  #WHITE,D1
        ENDI
        TRAP    #15
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$3006,D1
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        ADD.L   #5,A1
        TRAP    #15

        ; set font
        MOVEQ   #21,D0
        MOVE.L  #$06180000,D2
        IF.B main_menu_difficulty <EQ> #2  THEN
            MOVE.L  #RED,D1
        ELSE
            MOVE.L  #WHITE,D1
        ENDI
        TRAP    #15
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$3808,D1
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        ADD.L   #7,A1
        TRAP    #15


        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #1,D1
        TRAP    #15
        ; draw cross icon
        MOVEQ   #86,D0
        MOVE.W  #910,D1
        MOVE.W  #310,D2
        TRAP    #15

        MOVE.W  D1,D3
        ; set pen colour
        MOVEQ   #80,D0
        IF.B main_menu_difficulty <EQ> #1   THEN
            MOVE.L  #ORANGE,D1
        ELSE
            MOVE.L  #WHITE,D1
        ENDI
        TRAP    #15
        MOVEQ   #85,D0
        MOVE.W  D3,D1
        SUB.W   cross_long_length,D2
        TRAP    #15

        ADD.W   cross_short_length,D1
        TRAP    #15

        ADD.W   cross_long_length,D2
        TRAP    #15

        MOVE.W  D1,D3
        ; set pen colour
        MOVEQ   #80,D0
        IF.B main_menu_difficulty <EQ> #2   THEN
            MOVE.L  #RED,D1
        ELSE
            MOVE.L  #WHITE,D1
        ENDI
        TRAP    #15
        MOVEQ   #85,D0
        MOVE.W  D3,D1
        ADD.W   cross_long_length,D1
        TRAP    #15

        ADD.W   cross_short_length,D2
        TRAP    #15

        SUB.W   cross_long_length,D1
        TRAP    #15

        MOVE.W  D1,D3
        ; set pen colour
        MOVEQ   #80,D0
        MOVE.L  #WHITE,D1
        TRAP    #15
        MOVEQ   #85,D0
        MOVE.W  D3,D1
        ADD.W   cross_long_length,D2
        TRAP    #15

        SUB.W   cross_short_length,D1
        TRAP    #15

        SUB.W   cross_long_length,D2
        TRAP    #15

        MOVE.W  D1,D3
        ; set pen colour
        MOVEQ   #80,D0
        IF.B main_menu_difficulty <EQ> #0   THEN
            MOVE.L  #LIME,D1
        ELSE
            MOVE.L  #WHITE,D1
        ENDI
        TRAP    #15
        MOVEQ   #85,D0
        MOVE.W  D3,D1
        SUB.W   cross_long_length,D1
        TRAP    #15

        SUB.W   cross_short_length,D2
        TRAP    #15

        ADD.W   cross_long_length,D1
        TRAP    #15


        ; set font
        MOVEQ   #21,D0
        MOVE.L  #$06180000,D2
        IF.B menu_screen_game_type <EQ> #0  THEN
            MOVE.L  #RED,D1
        ELSE
            MOVE.L  #WHITE,D1
        ENDI
        TRAP    #15
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$300C,D1
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        LEA     main_menu_player_type_text,A1
        TRAP    #15

        ; set font
        MOVEQ   #21,D0
        MOVE.L  #$06180000,D2
        IF.B menu_screen_game_type <NE> #0  THEN
            MOVE.L  #LIME,D1
        ELSE
            MOVE.L  #WHITE,D1
        ENDI
        TRAP    #15
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$300D,D1
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        ADD.L   #10,A1
        TRAP    #15

        ; set font
        MOVEQ   #21,D0
        MOVE.L  #$06180000,D2
        IF.B menu_screen_game_type <EQ> #1  THEN
            MOVE.L  #ORANGE,D1
        ELSE
            MOVE.L  #WHITE,D1
        ENDI
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        ADD.L   #10,A1
        TRAP    #15

        ; set font
        MOVEQ   #21,D0
        MOVE.L  #$06180000,D2
        IF.B menu_screen_game_type <EQ> #2  THEN
            MOVE.L  #AQUA,D1
        ELSE
            MOVE.L  #WHITE,D1
        ENDI
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        ADD.L   #6,A1
        TRAP    #15

        
        ; set font
        MOVEQ   #21,D0
        MOVE.L  #WHITE,D1
        MOVE.L  #$06180000,D2
        TRAP    #15

        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$3010,D1
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        LEA     main_menu_select_text,A1
        TRAP    #15
        
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$3014,D1
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        ADD.L   #14,A1
        TRAP    #15
        
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$3018,D1
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        ADD.L   #12,A1
        TRAP    #15

        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #MULTIPLIER_SIZE,D1
        TRAP    #15

        ; draw purple2 bell
        MOVE.L  filled_notes_1_start_sprite,A0
        LEA     main_menu_bell_positions,A1
        MOVE.L  #$030001C0,(A1)
        MOVEQ   #4,D0
        BSR     DRAW_NOTE

        ; draw blue bell
        MOVE.L  filled_notes_1_start_sprite,A0
        ADD.L   #$90,(A1)
        MOVEQ   #1,D0
        BSR     DRAW_NOTE

        ; draw red bell
        MOVE.L  filled_notes_1_start_sprite,A0
        ADD.L   #$90,(A1)
        MOVEQ   #2,D0
        BSR     DRAW_NOTE

        ; draw yellow bell
        MOVE.L  filled_notes_1_start_sprite,A0
        ADD.L   #$90,(A1)
        MOVEQ   #3,D0
        BSR     DRAW_NOTE

        ADDQ.B  #1,sprite_gif_index
        AND.B   #7,sprite_gif_index

        BSR     DRAW_CONTROL_BUTTONS
        RTS


DRAW_SELECT_SONG_MENU
        BSR     DRAW_CONTROL_BUTTONS
        RTS


DRAW_LOAD_SCREEN
        ; set font
        MOVEQ   #21,D0
        MOVE.L  #WHITE,D1
        MOVE.L  #$06180000,D2
        TRAP    #15

        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$220E,D1
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        LEA     loading_screen_text,A1
        TRAP    #15
        ; sets the cursor position
        MOVEQ   #11,D0
        MOVE.L  #$2510,D1
        TRAP    #15
        ; show text
        MOVEQ   #14,D0
        ADD.L   #39,A1
        TRAP    #15


        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #MULTIPLIER_SIZE,D1
        TRAP    #15

        ; draw red bell
        MOVE.L  unfilled_notes_1_start_sprite,A0
        LEA     main_menu_bell_positions,A1
        MOVE.L  #$040002E0,(A1)
        MOVEQ   #2,D0
        BSR     DRAW_NOTE

        IF.W loading_screen_charge <NE> #0  THEN
            ; sets pen colour
            MOVEQ   #80,D0
            IF.W loading_screen_charge <EQ> #300    THEN
                MOVE.L  #WHITE,D1
            ELSE
                MOVE.L  #$00444444,D1
            ENDI
            TRAP    #15
            MOVE.W  #81,D0
            TRAP    #15

            ; draw rectangle
            MOVEQ   #87,D0
            MOVE.W  #700,D1
            MOVE.W  #$2F0,D2
            MOVE.W  D1,D3
            MOVE.W  D2,D4
            ADD.W   loading_screen_charge,D3
            ADD.W   #30,D4
            TRAP    #15
        ENDI

        ADDQ.B  #1,sprite_gif_index
        AND.B   #7,sprite_gif_index

        BSR     DRAW_CONTROL_BUTTONS
        RTS


DRAW_GAME_OVER


        RTS


DRAW_PAUSE_MENU


        RTS


DRAW_GAME_WON_MENU


        RTS


DRAW_CONTROL_BUTTONS
        ; sets pen width
        MOVEQ   #93,D0
        MOVEQ   #MULTIPLIER_SIZE,D1
        TRAP    #15

        ; sets pen colour
        MOVEQ   #80,D0
        MOVE.L  #BLUE,D1
        TRAP    #15
        MOVEQ   #81,D0
        TRAP    #15

        ; draw circle
        MOVEQ   #88,D0
        MOVE.W  #1750,D1
        MOVE.W  #15,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4
        ADD.W   #10,D3
        ADD.W   #10,D4
        TRAP    #15

        ; sets pen colour
        MOVEQ   #80,D0
        MOVE.L  #RED,D1
        TRAP    #15
        MOVEQ   #81,D0
        TRAP    #15

        ; draw circle
        MOVEQ   #88,D0
        MOVE.W  #1770,D1
        MOVE.W  #35,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4
        ADD.W   #10,D3
        ADD.W   #10,D4
        TRAP    #15

        ; sets pen colour
        MOVEQ   #80,D0
        MOVE.L  #YELLOW,D1
        TRAP    #15
        MOVEQ   #81,D0
        TRAP    #15

        ; draw circle
        MOVEQ   #88,D0
        MOVE.W  #1750,D1
        MOVE.W  #55,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4
        ADD.W   #10,D3
        ADD.W   #10,D4
        TRAP    #15

        ; sets pen colour
        MOVEQ   #80,D0
        MOVE.L  #PURPLE2,D1
        TRAP    #15
        MOVEQ   #81,D0
        TRAP    #15

        ; draw circle
        MOVEQ   #88,D0
        MOVE.W  #1730,D1
        MOVE.W  #35,D2
        MOVE.W  D1,D3
        MOVE.W  D2,D4
        ADD.W   #10,D3
        ADD.W   #10,D4
        TRAP    #15

        IF.B two_player <EQ> #1 THEN
            ; draw circle
            MOVEQ   #88,D0
            MOVE.W  #1830,D1
            MOVE.W  #35,D2
            MOVE.W  D1,D3
            MOVE.W  D2,D4
            ADD.W   #10,D3
            ADD.W   #10,D4
            TRAP    #15

            ; sets pen colour
            MOVEQ   #80,D0
            MOVE.L  #AQUA,D1
            TRAP    #15
            MOVEQ   #81,D0
            TRAP    #15

            ; draw circle
            MOVEQ   #88,D0
            MOVE.W  #1850,D1
            MOVE.W  #15,D2
            MOVE.W  D1,D3
            MOVE.W  D2,D4
            ADD.W   #10,D3
            ADD.W   #10,D4
            TRAP    #15

            ; sets pen colour
            MOVEQ   #80,D0
            MOVE.L  #ORANGE,D1
            TRAP    #15
            MOVEQ   #81,D0
            TRAP    #15

            ; draw circle
            MOVEQ   #88,D0
            MOVE.W  #1870,D1
            MOVE.W  #35,D2
            MOVE.W  D1,D3
            MOVE.W  D2,D4
            ADD.W   #10,D3
            ADD.W   #10,D4
            TRAP    #15

            ; sets pen colour
            MOVEQ   #80,D0
            MOVE.L  #LIME,D1
            TRAP    #15
            MOVEQ   #81,D0
            TRAP    #15

            ; draw circle
            MOVEQ   #88,D0
            MOVE.W  #1850,D1
            MOVE.W  #55,D2
            MOVE.W  D1,D3
            MOVE.W  D2,D4
            ADD.W   #10,D3
            ADD.W   #10,D4
            TRAP    #15
        ENDI

        ; resets fill colour
        MOVEQ   #81,D0
        MOVE.L  #0,D1
        TRAP    #15
        RTS


REPAINT_SCREEN
        ; repaints screen
        MOVEQ   #94,D0
		TRAP    #15
		; clears buffer
		MOVEQ   #11,D0
		MOVE.W  #$FF00,D1
		TRAP    #15
        RTS


REPAINT_AREA
        ; repaints screen
        MOVEQ   #94,D0
		TRAP    #15
        ; sets pen colour
        MOVEQ   #80,D0
        CLR.L   D1
        TRAP    #15
        MOVE.W  #81,D0
        TRAP    #15
		; clears area
		MOVEQ   #87,D0
        MOVE.W  #500,D1
        MOVE.W  #300,D2
        MOVE.W  #1420,D3
        MOVE.W  #780,D4
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
        MOVEQ   #8,D0
        TRAP    #15
        BTST    #0,D1
        RTS


EXIT_PROGRAM
        MOVE.W  #9,D0
        TRAP    #15


; variables
random_value                    DS.L    1       ; stores a random variable

last_frame_time                 DS.L    1       ; stores the time at last frame
last_treble_path_change_time    DS.L    1       ; stores the time when the treble path index last changed
last_bass_path_change_time      DS.L    1       ; stores the time when the bass path index last changed
last_object_time                DS.L    1       ; stores the time when the notes where moved
last_note_spawn_time            DS.L    1       ; stores the time when note was last spawned
last_notes_hit_index_change_time    DS.L    1       ; stores when the sprite indexes were last changed

player_1_position       DS.W    2       ; stores the top right player position x,y
player_1_lane_number    DS.B    1       ; stores the lane number
player_1_moving         DC.B    0       ; stores whether the player is moving up or down
player_1_action_pressed DC.B    0       ; stores whether any action buttons are pressed
player_1_keymaps        DC.L    'WS'    ; stores the movement keys of player
player_1_action_colour  DC.B    0       ; stores the player action colour
player_1_colour_keymaps DC.L    'HUK '  ; stores the keymaps for the player changing colours
player_1_charge_amount  DC.B    0       ; stores the charge amount
player_1_life_amount    DC.W    200     ; stores the life amount
player_1_punching_index DC.B    0       ; stores whether player is punching

player_2_position       DS.W    2       ; stores the top right player position x,y
player_2_lane_number    DS.B    3       ; stores the lane number
player_2_moving         DC.B    0       ; stores whether the player is moving up or down
player_2_action_pressed DC.B    0       ; stores whether any action buttons are pressed
player_2_keymaps        DC.L    'RF'    ; stores the movement keys of player
player_2_action_colour  DC.B    0       ; stores the player action colour
player_2_colour_keymaps DC.L    'XCVZ'  ; stores the keymaps for the player changing colours
player_2_charge_amount  DC.B    0       ; stores the charge amount
player_2_life_amount    DC.W    200     ; stores the life amount
player_2_punching_index DC.B    0       ; stores whether player is punching

; stores the number of notes in the arrays
                        DC.W    0
; stores the addresses of notes in the rows
; these are queues
lane_notes_addresses    DS.W    LANE_ADDRESSES_SIZE
                        DC.W    0
                        DS.W    LANE_ADDRESSES_SIZE
                        DC.W    0
                        DS.W    LANE_ADDRESSES_SIZE
                        DC.W    0
                        DS.W    LANE_ADDRESSES_SIZE
                        DC.W    0
                        DS.W    LANE_ADDRESSES_SIZE

note_objects            DS.W    NOTE_OBJECT_SIZE*LANE_ADDRESSES_SIZE*2    ; stores the notes objects data
;   note object structure:
;   W   note colour index, 0 means that it is invisible
;   W   x position
;   W   y position
;   B   stores the player number 0 or 1, treble or bass
;   L*10   music notes data, same as in the file

treble_note_path_index  DC.B    2       ; stores the lane index of the note path
bass_note_path_index    DC.B    2       ; stores the lane index of the note path
treble_song_file_index  DC.L    0       ; stores the byte index that the song is at
bass_song_file_index    DC.L    0       ; stores the byte index that the song is at
treble_song_file_size   DC.W    0       ; stores the total length of the treble song file

notes_times_array       DS.B    102     ; contains the times for each note that needs to be hold

song_name_last_index    DS.B    1
song_name               DC.B    'songs/'
                        DS.B    26

number_of_available_songs       DC.B    0
available_songs_array           DS.B    NUMBER_OF_SONGS
ALL_SONG_FILE_NAMES             DC.B    'Running in the 90s',0,'Running in the 90s',0

; THE PROGRAM MUST NOT USE THE FOLLOWING MEMORY ADDRESS
; THERE IS A CHECK AT THE START OF THE PROGRAM TO STOP THIS FROM HAPPENEING
; IT IS ILLEGAL AND RAISES AN ERROR
TREBLE_FILE_CONTENTS    EQU     $10000
BASS_FILE_CONTENTS      EQU     $20000

; notes names
NOTES_BASIC_PATH        DC.B    'notes/aaa.wav',0
NOTES_NAMES             DC.B    '0an0bn0as'
                        DC.B    '1an1bn1cn1dn1en1fn1gn1as1bs1cs1ds1es1fs1gs'
                        DC.B    '2an2bn2cn2dn2en2fn2gn2as2bs2cs2ds2es2fs2gs'
                        DC.B    '3an3bn3cn3dn3en3fn3gn3as3bs3cs3ds3es3fs3gs'
                        DC.B    '4an4bn4cn4dn4en4fn4gn4as4bs4cs4ds4es4fs4gs'
                        DC.B    '5an5bn5cn5dn5en5fn5gn5as5bs5cs5ds5es5fs5gs'
                        DC.B    '6an6bn6cn6dn6en6fn6gn6as6bs6cs6ds6es6fs6gs'
                        DC.B    '7an7bn7cn7dn7en7fn7gn7as7bs7cs7ds7es7fs7gs'
                        DC.B    '8cn'

; stores the difficulty of the song playing
; one player
; 20 - easy,
; 12 - medium,
; 6 - hard
; two player
; 20 - easy,
; 16 - medium,
; 12 - hard
song_difficulty             DC.B    20      ; stores the notes spawning difficulty
treble_quater_beat_count    DC.B    128     ; stores the count of quarter beats played
bass_quater_beat_count      DC.B    128     ; stores the count of quarter beats played
treble_last_note_success    DC.B    1       ; stores whether the last hit note was correct
bass_last_note_success      DC.B    1       ; stores whether the last hit note was correct

previous_render_time            DS.L    1
render_skip_amount              DC.B    0

lanes_colours                   DCB.L   6,WHITE
lanes_notes_hit_animations      DCB.L   5,$00000000
; stores the status of lane hit animations
; first byte is used as an index
; other three are the coolour BGR

; gui stuff
score                           DC.L    0               ; stores the score
score_text                      DC.B    'Score: ',0
player_1_longest_streak         DC.W    0               ; stores the streak of hitting notes
player_2_longest_streak         DC.W    0               ; stores the streak of hitting notes
streak_text                     DC.B    'Streak:',0,' x',0
treble_total_notes              DC.W    0               ; stores the total amount of visible treble notes spawned
bass_total_notes                DC.W    0               ; stores the total amount of visible bass notes spawned
player_1_notes_hit_count        DC.W    0               ; stores the number of visible notes hit
player_2_notes_hit_count        DC.W    0               ; stores the number of visible notes hit
song_name_text                  DC.B    'Currently playing: ',0
life_text                       DC.B    'Life:',0

select_song_line                DC.B    0               ; stores the select line
main_menu_difficulty            DC.B    0               ; stores the difficulty
menu_screen_game_type           DC.B    0               ; stores whether single player 0 versus 1 or coop 2

two_player                      DC.B    0               ; stores the player count, 0 = one player, 1 = two players
coop_mode                       DC.B    1               ; stores whether two player is coop 1 or versus 0
song_playing_type               DC.B    1               ; stores whether practice 0 or endless 1
game_over_status                DC.B    0               ; stores whether game over 0 or a player won 1 or 2

notes_speed                     DC.W    8               ; stores the speed at which notes move by
previous_notes_speed            DC.W    8               ; stores the previous song's starting speed
notes_speed_indexer             DC.W    0               ; stores an index so the note speed in slowly increased
notes_speed_indexer_rollover    DC.W    32              ; stores the value at which point the indexer adds to the notes speed

main_menu_title_text            DC.B    'BEAT|BELLS',0
main_menu_difficulty_text       DC.B    'Easy',0,'Medium',0,'Hard',0
main_menu_player_type_text      DC.B    '1 Player ',0,'2 Player ',0,'Coop ',0,'Versus',0
main_menu_select_text           DC.B    'Practice Song',0,'Endless Run',0,'Exit',0
main_menu_bell_positions        DC.L    0
main_menu_title_colour          DC.L    0

cross_short_length              DC.W    20
cross_long_length               DC.W    30

loading_screen_text             DC.B    'Charge punches against shielded bells!',0,'Hold shoulder buttons and punch!',0
loading_screen_charge           DC.W    0

pause_menu_active             DC.B    0

; COLOURS
; the treble notes are going to be red, yellow and blue
; the bass notes are going to be aqua, lime, and orange
; teleport is going to be purple2
BLUE            EQU     $00FF0000       ; Treble A, D
RED             EQU     $000000FF       ; Treble B, E
YELLOW          EQU     $0000FFFF       ; Treble C, F
AQUA            EQU     $00FFFF00       ; Bass A, D
ORANGE          EQU     $000080FF       ; Bass B, E
LIME            EQU     $0000FF00       ; Bass C, F
PURPLE2         EQU     $00FF0080       ; Teleport
WHITE           EQU     $00FFFFFF

; QOI decoding
SPRITES_LOADING             EQU     $28000      ; address where the qoi file is loaded
SPRITES_PIXEL_LENGTH        EQU     $400        ; size of sprites is 16x16x4

MULTIPLIER_SIZE             EQU     8           ; the size to multiply the sprites by

PLAYER_SPRITES_BASIC_PATH   DC.B    'player_sprites/a0a.qoi',0
PUNCHING_SPRITES_BASIC_PATH DC.B    'punching_sprites/aaa.qoi',0
FILLED_NOTES_BASIC_PATH     DC.B    'filled_notes_sprites/aaa.qoi',0
UNFILLED_NOTES_BASIC_PATH   DC.B    'unfilled_notes_sprites/aaa.qoi',0
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
next_free_slot_address      DC.L    $2A000              ; stores the address of the next free available memory space for the next decoded sprite

sprite_gif_index            DC.B    0                   ; stores the index of the sprite gifs max 7

player_1_start_sprite           DS.L    1
player_2_start_sprite           DS.L    1
punching_1_start_sprite         DS.L    1
punching_2_start_sprite         DS.L    1
filled_notes_1_start_sprite     DS.L    1
filled_notes_2_start_sprite     DS.L    1
unfilled_notes_1_start_sprite   DS.L    1
unfilled_notes_2_start_sprite   DS.L    1

        END    START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
