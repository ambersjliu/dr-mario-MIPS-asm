################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Amber Liu, 1010152870
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    32
# - Display height in pixels:   32
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################


##############################################################################
# Macros
##############################################################################
.macro PUSH_TO_STACK (%reg)
    # Moves the stack pointer to free space and stores the data in %reg there
    addi $sp, $sp, -4
    sw %reg, 0($sp)
.end_macro

.macro POP_FROM_STACK (%reg)
    # Pops the last thing off the stack, stores it in reg, and moves the stack pointer forward
    lw %reg, 0($sp)
    addi $sp, $sp, 4
.end_macro

.macro PUSH_ALL_SAVED()
  PUSH_TO_STACK($s0)
  PUSH_TO_STACK($s1)
  PUSH_TO_STACK($s2)
  PUSH_TO_STACK($s3)
  PUSH_TO_STACK($s4)
  PUSH_TO_STACK($s5)
  PUSH_TO_STACK($s6)
  PUSH_TO_STACK($s7)
.end_macro

.macro POP_ALL_SAVED()
  POP_FROM_STACK($s7)
  POP_FROM_STACK($s6)
  POP_FROM_STACK($s5)
  POP_FROM_STACK($s4)
  POP_FROM_STACK($s3)
  POP_FROM_STACK($s2)
  POP_FROM_STACK($s1)
  POP_FROM_STACK($s0)
.end_macro

.macro PUSH_ALL_TEMP()
  PUSH_TO_STACK($t0)
  PUSH_TO_STACK($t1)
  PUSH_TO_STACK($t2)
  PUSH_TO_STACK($t3)
  PUSH_TO_STACK($t4)
  PUSH_TO_STACK($t5)
  PUSH_TO_STACK($t6)
  PUSH_TO_STACK($t7)
  PUSH_TO_STACK($t8)
  PUSH_TO_STACK($t9)
.end_macro

.macro POP_ALL_TEMP()
  POP_FROM_STACK($t9)
  POP_FROM_STACK($t8)
  POP_FROM_STACK($t7)
  POP_FROM_STACK($t6)
  POP_FROM_STACK($t5)
  POP_FROM_STACK($t4)
  POP_FROM_STACK($t3)
  POP_FROM_STACK($t2)
  POP_FROM_STACK($t1)
  POP_FROM_STACK($t0)
.end_macro

.macro PLAY_SOUND_WITH_SLEEP(%note, %dur, %instr, %vol)
  PUSH_TO_STACK($a0)
  PUSH_TO_STACK($a1)
  PUSH_TO_STACK($a2)
  PUSH_TO_STACK($a3)
  PUSH_TO_STACK($v0)
  li $v0, 31
  li $a0, %note
  li $a1, %dur
  li $a2, %instr 
  li $a3, %vol
  syscall

  li $v0, 32
  move $a0, $a1  # sleep during note duration so future notes don't overlap
  syscall

  POP_FROM_STACK($v0)
  POP_FROM_STACK($a3)
  POP_FROM_STACK($a2)
  POP_FROM_STACK($a1)
  POP_FROM_STACK($a0)
.end_macro

.macro PLAY_SOUND(%note, %dur, %instr, %vol)
  # For single sound effects
  PUSH_TO_STACK($a0)
  PUSH_TO_STACK($a1)
  PUSH_TO_STACK($a2)
  PUSH_TO_STACK($a3)
  PUSH_TO_STACK($v0)
  li $v0, 31
  li $a0, %note
  li $a1, %dur
  li $a2, %instr 
  li $a3, %vol
  syscall

  POP_FROM_STACK($v0)
  POP_FROM_STACK($a3)
  POP_FROM_STACK($a2)
  POP_FROM_STACK($a1)
  POP_FROM_STACK($a0)
.end_macro

.macro PLAY_GAME_OVER_SOUND()
  # sad trombone
  PLAY_SOUND_WITH_SLEEP(60, 200, 57, 100)
  PLAY_SOUND_WITH_SLEEP(59, 200, 57, 100)
  PLAY_SOUND_WITH_SLEEP(58, 200, 57, 100)
  PLAY_SOUND_WITH_SLEEP(57, 600, 57, 100)

.end_macro

.macro PLAY_GAME_WIN_SOUND()
  # happy trumpet
  PLAY_SOUND_WITH_SLEEP(72, 200, 56, 100)
  PLAY_SOUND_WITH_SLEEP(72, 600, 56, 100)
.end_macro

.macro PLAY_ROTATE_SOUND()
  # steel drum
  PLAY_SOUND(69, 100, 114, 100)
.end_macro

.macro PLAY_CANT_ROTATE_SOUND()
  # incorrect buzzer
  PLAY_SOUND(57, 100, 87, 100)
.end_macro

.macro PLAY_CLEAR_SOUND()
  PLAY_SOUND(74, 100, 10, 100)
.end_macro

.macro PLAY_DROP_SOUND()
  PLAY_SOUND(78, 100, 115, 100)
.end_macro

.macro PLAY_SPEEDUP_SOUND()
  PLAY_SOUND(74, 100, 55, 100)
.end_macro

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# Width of the screen
WIDTH: 
    .word 32
# Height of the screen
HEIGHT:
    .word 32
# Amount required to shift when moving down rows. Must satisfy WIDTH * 4 = 2^WIDTH_SHIFT
WIDTH_SHIFT:
    .word 7

# === Grid constants ===

GRID_WIDTH:
    .word 20

GRID_HEIGHT:
    .word 26

GRID_LOCATION:
    .word 520 # 4 * 32 * 4 bytes  + 2 * 4 bytes to get to the top left corner of the grid

NUM_VIRUSES:
    .word 4 # number of viruses to spawn in the grid

# other colours
GREEN:
  .word 0x25f53a
OUTLINE_GREY:
  .word 0x404040

# Capsule colours =============
RED:
    .word 0xFF2B59
BLUE:
    .word 0x122EFF
YELLOW:
    .word 0xF7CB52
# Virus colours (so they can be differentiated)
VIRUS_RED:
    .word 0xC7061C
VIRUS_BLUE:
    .word 0x0025DE
VIRUS_YELLOW:
    .word 0xFFB300
GREY:
    .word 0x8693B5
    
# Capsule start location 

CAPSULE_START:
    .word 9 # x-coord
    .word 1 # y-coord

# sleep duration
SLEEP_DURATION:
      .word 16

CAPSULE_HALF_LOCATION:
  .word 1 # above
  .word 2 # below
  .word 3 # left 
  .word 4 # right
  .word -1 # deleted

# base number of frames required before gravity movement
GRAVITY_FRAMES:
  .word 30

# music 

MELODY:
  # verse
  .word 62, 69, 74, 77, 74, 69 
  .word 62, 69, 74, 76, 74, 69 
  .word 55, 67, 70, 75, 70, 67
  .word 55, 67, 70, 74, 70, 67
  .word 57, 64, 69, 74, 69, 64
  .word 55, 64, 69, 73, 69, 64

  .word 62, 69, 74, 77, 74, 69 
  .word 62, 69, 74, 76, 74, 69 
  .word 55, 67, 70, 75, 70, 67
  .word 55, 67, 70, 74, 70, 67
  .word 57, 64, 69, 74, 69, 64
  .word 55, 64, 69, 73, 69, 64
  # chorus
  .word 54, 69, 74, 54, 69, 74
  .word 54, 69, 74, 54, 69, 74

  .word 55, 71, 74, 55, 71, 74
  .word 55, 71, 74, 55, 71, 74

  .word 54, 69, 73, 54, 69, 73
  .word 54, 69, 73, 54, 69, 73

  .word 54, 0, 0, 0, 0, 0
  .word 55, 0, 0, 0, 0, 0


NOTE_DURATION:
  .word 208

MELODY_LENGTH:
  .word 120 
  
INSTRUMENT:
  .word 25

VOLUME:
  .word 100



##############################################################################
# Mutable Data
##############################################################################

CURR_CAPSULE_STATE:
  .word 0 # Top half colour
  .word 0 # bottom half colour
  .word 1 # Orientation (1, 2, 3, 4)
  .word 0 # position x
  .word 0 # position y
  # Position refers to the location of the lower left corner of the imaginary 2x2 square the capsule is in

CURR_CAPSULE_OUTLINE:
  .word 0 # orientation (0 vertical, 1 horizontal)
  .word 0 # position x
  .word 0 # position y 
  # position also refers to the anchor

GRID_STATE: # Stores the colour, border, and virus information
    .space 2080 # 20 * 26 * 4 bytes

GRID_CAPSULE_RELATIONSHIPS: # For each capsule, stores a value indicating where to find its other half
    .space 2080 #

GRAVITY_COUNTER:
  .word 0

CAPSULES_DROPPED:
  .word 0

GRAVITY_TIME_DECREASE:
  .word 0 # incremented every 10 capsules to increase the drop speed

VIRUSES_REMAINING:
  .word 0

#music
MELODY_POINTER:
  .word 0

MUSIC_TIMER:
  .word 0
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    jal erase_screen
    jal init_mutable_values
    lw $a0, NUM_VIRUSES
    jal init_grid
    jal init_relationships_grid
    
    # draw the pill bottle
    jal draw_pill_bottle


game_loop:
    jal draw_grid
    # Check if game is over 
    jal check_game_over
    bne $v0, $zero, game_over
    lw $t0, VIRUSES_REMAINING
    beq $t0, $zero, game_win

    jal init_capsule
    jal draw_capsule

    jal update_capsule_outline
    jal draw_capsule_outline

    

    handle_keystroke_loop:

      lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
      lw $t1, 0($t0)                      # Load first word from keyboard
      bne $t1, 1, after_handle_keystroke      # If first word wasn't 1, key wasn't pressed

      lw $t1, 4($t0)                      # $t1 = key pressed (second word from keyboard)
      beq $t1, 0x70, handle_pause # p for pause
      beq $t1, 0x71, game_over  # q for quit
      beq $t1, 0x77, handle_rotate # w for rotate
      beq $t1, 0x61, handle_move_left # a for left
      beq $t1, 0x73, handle_move_down # s for down
      beq $t1, 0x64, handle_move_right # d for right
      # any other key presses we just go to the post-handling part
      j after_handle_keystroke


      handle_pause:
        jal draw_pause 
        jal pause
        jal erase_pause
        jal after_handle_keystroke

      handle_rotate:
        jal erase_capsule
        jal rotate
        jal draw_capsule

        jal erase_capsule_outline
        jal update_capsule_outline
        jal draw_capsule_outline
        j after_handle_keystroke
        
      handle_move_left:
        jal erase_capsule 
        jal move_left 
        jal draw_capsule 

        jal erase_capsule_outline
        jal update_capsule_outline
        jal draw_capsule_outline
        j after_handle_keystroke

      handle_move_down:
        jal erase_capsule 
        jal move_down 
        move $s0, $v0
        jal draw_capsule

        beq $s0, 1, handle_collision


        
        j after_handle_keystroke

      handle_move_right:
        jal erase_capsule 
        jal move_right
        jal draw_capsule 
        
        jal erase_capsule_outline
        jal update_capsule_outline
        jal draw_capsule_outline
        j after_handle_keystroke

      handle_collision:
        PLAY_DROP_SOUND()
        # increment number of capsules dropped
        la $t0, CAPSULES_DROPPED 
        lw $t1, 0($t0)
        addi $t1, $t1, 1
        sw $t1, 0($t0)
        # if 10 were dropped, increment the number of frames to be subtracted from the gravity base amount 
        # and reset the capsule counter
        blt $t1, 10, handle_collision_logic
        PLAY_SPEEDUP_SOUND()
        sw $zero, 0($t0)
        la $t0, GRAVITY_TIME_DECREASE
        lw $t1, 0($t0)
        addi $t1, $t1, 3
        sw $t1, 0($t0)
        

        handle_collision_logic:
        jal add_capsule_to_grid
        jal add_capsule_to_relationships
        # Loop to handle collisions 
        handle_consecutives_loop:
          jal find_and_clear_consecutives
          beq $v0, -1, game_loop
          jal drop_capsules
          j handle_consecutives_loop
          

    after_handle_keystroke:
      jal update_music
      li $v0, 32
      lw $a0, SLEEP_DURATION
      syscall # sleep for SLEEP_DURATION ms

      la $t0, GRAVITY_COUNTER
      lw $t1, 0($t0)
      addi $t1, $t1, 1 # increment 
      lw $t2, GRAVITY_FRAMES # base number of frames 
      lw $t3, GRAVITY_TIME_DECREASE # amount to decrease 
      sub $t2, $t2, $t3 # subtract it 
      
      bge $t1, $t2, handle_gravity
      sw $t1, 0($t0)
      j handle_keystroke_loop

    handle_gravity:
      sw $zero, 0($t0)

      j handle_move_down
          
    # j game_over
    # 5. Go back to Step 1


game_over:
  jal erase_screen
  jal draw_end_screen

  PLAY_GAME_OVER_SOUND()
  j game_over_loop
  

game_win:
  jal erase_screen
  jal draw_win_screen
  PLAY_GAME_WIN_SOUND()

  j game_over_loop

game_over_loop:
  li $v0, 32
  lw $a0, SLEEP_DURATION
  syscall # sleep for SLEEP_DURATION ms

  lw $t0, ADDR_KBRD # $t0 = base address for keyboard
  lw $t1, 0($t0) # $t1 = first word from keyboard
  bne $t1, 1, game_over_loop # If the first key is not 1, no key is pressed
  lw $t1, 4($t0) 
  beq $t1, 0x71, quit # if the key is q, quit
  beq $t1, 0x72, main # if the key is r, reset the game
  j game_over_loop

quit:
  li $v0, 10 # terminate the program gracefully
  syscall

# =========== Functions =============

# Initialization functions =========================================================

init_mutable_values:
  # Resets mutable data values
  PUSH_TO_STACK($ra)
  
  la $t0, GRAVITY_COUNTER
  sw $zero, 0($t0)

  la $t0, CAPSULES_DROPPED
  sw $zero, 0($t0)

  la $t0, GRAVITY_TIME_DECREASE
  sw $zero, 0($t0)

  la $t0, VIRUSES_REMAINING
  sw $zero, 0($t0)

  la $t0, MELODY_POINTER
  sw $zero, 0($t0)

  la $t0, MUSIC_TIMER
  sw $zero, 0($t0)
  
  POP_FROM_STACK($ra)
  jr $ra

init_capsule:
  PUSH_TO_STACK($ra)

  # Intialize capsule colour
  jal set_random_capsule_colour
  
  # Set init capsule position
  la $t0, CURR_CAPSULE_STATE
  la $t2, CAPSULE_START
  # Set x to capsule_start x
  lw $t1, 0($t2)
  sw $t1, 12($t0)
  # Set y to 1
  lw $t1, 4($t2)
  sw $t1, 16($t0)

  # set orientation to 1
  li $t1, 1
  sw $t1, 8($t0)

  POP_FROM_STACK($ra)
  jr $ra

init_grid:
  # $a0 stores number of viruses to spawn in this grid
  # todo:
  # - set all borders to -1 and unoccupied cells to 0
  # - generate all the virus colours
  # - place all the viruses on the grid
  PUSH_TO_STACK($ra)

  la $t0, GRID_STATE  # Load base address of grid
  li $t1, 0  # Row counter
  li $t2, 0  # Column counter
  lw $t3, GRID_WIDTH    # Grid width
  lw $t4, GRID_HEIGHT   # grid height

  sub $t6, $t3, 1 # grid width-1
  sub $t7, $t4, 1 # grid height-1
  # 1. set all borders to -1 and all other cells to 0
  grid_init_loop:
    beq $t1, 0, set_border # top border/row=0
    beq $t2, 0, set_border # left border/column=0
    beq $t2, $t6, set_border # right border/column=19
    beq $t1, $t7, set_border # bottom border/row=25
    # else, not a border, set to empty
    sw $zero, 0($t0)
    j init_next_cell
    
    set_border:
      li $t5, -1
      sw $t5, 0($t0)

    init_next_cell:
      addi $t0, $t0, 4 # move to next cell in grid
      addi $t2, $t2, 1 # col++
      # repeat if col < grid width
      blt $t2, $t3, grid_init_loop

      # else
      li $t2, 0 # reset column counter
      addi $t1, $t1, 1 # row++
      # repeat if row < grid_height
      blt $t1, $t4, grid_init_loop

  # 2. generate and place viruses
  jal init_viruses

  POP_FROM_STACK($ra)
  jr $ra

init_relationships_grid:
  # sets all values to 0
  PUSH_TO_STACK($ra)

  la $t0, GRID_CAPSULE_RELATIONSHIPS  # Load base address of grid
  li $t1, 0  # Row counter
  li $t2, 0  # Column counter
  lw $t3, GRID_WIDTH    # Grid width
  lw $t4, GRID_HEIGHT   # grid height

  sub $t6, $t3, 1 # grid width-1
  sub $t7, $t4, 1 # grid height-1
  relationships_grid_init_loop:
    sw $zero, 0($t0)
    j init_next_cell_rships
    
    init_next_cell_rships:
      addi $t0, $t0, 4 # move to next cell in grid
      addi $t2, $t2, 1 # col++
      # repeat if col < grid width
      blt $t2, $t3, relationships_grid_init_loop

      # else
      li $t2, 0 # reset column counter
      addi $t1, $t1, 1 # row++
      # repeat if row < grid_height
      blt $t1, $t4, relationships_grid_init_loop

  POP_FROM_STACK($ra)
  jr $ra


init_viruses:
  # $a0: number of viruses to spawn and place in grid

  # push return address to stack
  PUSH_TO_STACK($ra)
  PUSH_TO_STACK($s0)

  la $t0, VIRUSES_REMAINING
  sw $a0, 0($t0) # store  number of viruses in memory 

  move $s0, $a0 # put the number of viruses there KEEP IT SAFE
  la $t0, GRID_STATE # Load base address of grid
  li $s1, 0 # loop counter
  lw $t3, GRID_HEIGHT # get grid_height
  # we want to generate viruses in the lower half (so in range [GRID_HEIGHT//2, GRID_HEIGHT])
  sra $t4, $t3, 1 # store GRID_HEIGHT//2 in $t4
  
  init_viruses_loop:
    bge $s1, $s0, end_init_viruses_loop
    # generate random virus colour
    jal generate_random_virus_colour
    move $t8, $v0
    # generate random virus location
    # loop until we find an empty location
    init_virus_location_loop:
      # x: generate a random value in [1, grid_width-1)]

      li $a1, 1
      lw $a2, GRID_WIDTH
      sub $a2, $a2, 1
      jal generate_in_range
      move $t5, $v0 # move x-coord to $t5

      
      # y: generate a random value in [grid_height//2, grid_height-1)
      move $a1, $t4 # lower bound is grid_height//2
      lw $a2, GRID_HEIGHT # upper bound is grid_height
      sub $a2, $a2, 1 # upper bound is grid_height-1
      jal generate_in_range
      move $t6, $v0 # move y-coord to $t6


      # check that the grid location isn't occupied, if it is, loop again and generate another (x,y) coordinate
      move $a0, $t5 # x
      move $a1, $t6 # y
      jal get_cell_address
      lw $t7, 0($v0) # load value at (x,y) in grid 
      beq $t7, $zero, place_virus
      #otherwise we try again
      j init_virus_location_loop
    #after the location loop, set the randomly generated colour at the location inside of the grid
    place_virus:
      sw $t8, 0($v0) # place the colour at the coordinate
      # increment loop var
      addi $s1, $s1, 1
      j init_viruses_loop
  end_init_viruses_loop:
  POP_FROM_STACK($s0)
  POP_FROM_STACK($ra)
  jr $ra



# Movement functions ===================================================================================
move_right:
  # Checks if the capsule can move right
  # If so, increments CURR_CAPSULE_STATE's x value by 1
  PUSH_TO_STACK($ra)
  # first get the orientation
  jal vert_or_horiz

  la $t0, CURR_CAPSULE_STATE
  lw $t1, 12($t0) # x pos
  lw $t2, 16($t0) # y  pos
  beq $v0, $zero, move_right_vert # $v0 is 0 when capsule vertical
  # otherwise it's horizontal, in which case we only need to check 2 to the right of the anchor pixel
  move $a0, $t1 # x in $a0
  move $a1, $t2 # y in $a1
  # to look 2 steps right we increment $a0
  addi $a0, $a0, 2
  jal get_cell_address
  lw $t3, 0($v0) # load the value at the address 2 to the right of anchor pixel
  bne $t3, $zero, end_move_right # if it's not empty, then we don't move right
  j can_move_right

  move_right_vert:
    # need to check that neither the "anchor" pixel or the top pixel collide horizontally
    # 1) anchor pixel
    move $a0, $t1 # x in $a0
    move $a1, $t2 # y in $a1
    # to look 1 step right we increment $a0
    addi $a0, $a0, 1
    jal get_cell_address
    lw $t3, 0($v0) # load the value at the address next to anchor pixel to $t3
    bne $t3, $zero, end_move_right # if it's not empty, then we don't move right

    # 2) top pixel 
    # to look 1 step up we decrement y 
    subi $a1, $a1, 1
    jal get_cell_address
    lw $t3, 0($v0) # load the value at the address next to top pixel to $t3
    bne $t3, $zero, end_move_right # if it's not empty, then we don't move right
    j can_move_right

  can_move_right:
    la $t0, CURR_CAPSULE_STATE
    lw $t1, 12($t0) # x pos
    addi $t1, $t1, 1
    sw $t1, 12($t0) # increment it
  
  end_move_right:
  POP_FROM_STACK($ra)
  jr $ra
  
move_left:
  # Checks if the capsule can move left
  # If so, decrements CURR_CAPSULE_STATE's x value by 1
  PUSH_TO_STACK($ra)
  jal vert_or_horiz

  la $t0, CURR_CAPSULE_STATE
  lw $t1, 12($t0) # x pos
  lw $t2, 16($t0) # y  pos
  beq $v0, $zero, move_left_vert # $v0 is 0 when capsule vertical
  # otherwsie it's horizontal, then we only need to check if the anchor pixel can move left 
  move $a0, $t1 # x in $a0
  move $a1, $t2 # y in $a1
  # decrement x to check left 
  subi $a0, $a0, 1
  jal get_cell_address
  lw $t3, 0($v0) # load the value at the address left of anchor pixel to $t3
  bne $t3, $zero, end_move_left # if it's not empty, return without moving
  j can_move_left

  move_left_vert:
    # we check that both the anchor pixel and top pixel don't collide with something when moving left
    # 1) anchor pixel
    move $a0, $t1 # x in $a0
    move $a1, $t2 # y in $a1
    # to look 1 step left we decrement $a0
    subi $a0, $a0, 1
    jal get_cell_address
    lw $t3, 0($v0) # load the value at the address next to anchor pixel to $t3
    bne $t3, $zero, end_move_left # if it's not empty, then we don't move left

    # 2) top pixel 
    # to look 1 step up we decrement y 
    subi $a1, $a1, 1
    jal get_cell_address
    lw $t3, 0($v0) # load the value at the address next to top pixel to $t3
    bne $t3, $zero, end_move_left # if it's not empty, then we don't move left
    j can_move_left

  can_move_left:
    la $t0, CURR_CAPSULE_STATE
    lw $t1, 12($t0) # x pos
    subi $t1, $t1, 1
    sw $t1, 12($t0) # decrement it
  
  end_move_left:
  POP_FROM_STACK($ra)
  jr $ra

move_down:
  # Checks if the capsule can move down
  # If so, increments CURR_CAPSULE_STATE's y value by 1
  # Returns: $v0 = 0 if the capsule can move down, 1 if not
  PUSH_TO_STACK($ra)

  la $t0, CURR_CAPSULE_STATE
  lw $t1, 12($t0) # x pos
  lw $t2, 16($t0) # y  pos

  # in both cases we have to check under the anchor draw_pixel
  move $a0, $t1 # x in $a0
  move $a1, $t2 # y in $a1
  # to look 1 step down we increment y
  addi $a1, $a1, 1
  jal get_cell_address
  lw $t3, 0($v0) # load the value at the address below the anchor pixel to $t3
  bne $t3, $zero, cant_move_down # if it isn't 0, then we can't move down

  
  # check orientation to determine if we need to check under the right pixel too 
  jal vert_or_horiz
  beq $v0, $zero, can_move_down # $v0 is 0 when capsule is vertical, so we're done

  # since it's not vertical, increment $a0 to look right 
  addi $a0, $a0, 1
  jal get_cell_address
  lw $t3, 0($v0) # load the value at the address below the right pixel to $t3
  bne $t3, $zero, cant_move_down # if its not empty there, can't move down
  j can_move_down

  can_move_down:
    # increment y
    la $t0, CURR_CAPSULE_STATE
    lw $t1, 16($t0) # y pos
    addi $t1, $t1, 1 # increment
    sw $t1, 16($t0)
    
    li $v0, 0 # load 0 to $v0
    j end_move_down
    
  cant_move_down:
    li $v0, 1

  end_move_down:
  POP_FROM_STACK($ra)
  jr $ra

rotate:
  # Checks if the capsule can rotate
  # If so, sets the new orientation of CURR_CAPSULE_STATE
  PUSH_TO_STACK($ra)
  jal vert_or_horiz # get capsule horizontal or vertical
  la $t0, CURR_CAPSULE_STATE
  lw $t1, 12($t0) # x pos
  lw $t2, 16($t0) # y  pos

  beq $v0, $zero, rotate_vert # $v0 is 0 when capsule vertical
  # capsule is currently horizontal, so we need to check that the pixel above the anchor pixel is empty
  move $a0, $t1 # x in $a0
  move $a1, $t2 # y in $a1
  # decrement y  by 1
  subi $a1, $a1, 1
  jal get_cell_address
  lw $t3, 0($v0) # load the value at the address above the anchor pixel to $t3
  bne $t3, $zero, end_rotate_fail # if it's not empty, don't rotate
  j increment_orientation
  

  rotate_vert:
    # capsule is currently vertical, so we need to check that the pixel right of the anchor pixel is empty
    move $a0, $t1 # x in $a0
    move $a1, $t2 # y in $a1
    # increment x by 1
    addi $a0, $a0, 1
    jal get_cell_address
    lw $t3, 0($v0) # load the value at the address besides the anchor pixel to $t3
    bne $t3, $zero, end_rotate_fail # if it's not empty, don't rotate
    j increment_orientation

  increment_orientation:
    la $t0, CURR_CAPSULE_STATE
    lw $t1, 8($t0) # load orientation

    beq $t1, 4, orientation_is_four # if orientation is 4, we should set it to 1
    # otherwise we can just increment it 
    addi $t1, $t1, 1
    sw $t1, 8($t0)
    j end_rotate_success

    orientation_is_four:
      li $t1, 1
      sw $t1, 8($t0)
      j end_rotate_success

  end_rotate_fail:
    PLAY_CANT_ROTATE_SOUND()
    j end_rotate

  end_rotate_success:
    PLAY_ROTATE_SOUND()

  end_rotate:
  POP_FROM_STACK($ra)
  jr $ra

update_capsule_outline:
  # Updates the capsule outline state
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()
  
  la $t0, CURR_CAPSULE_STATE
  lw $s0, 12($t0) # position x
  lw $s1, 16($t0) # position y
  jal vert_or_horiz
  move $s3, $v0 # get orientation -> 0 if vertical, 1 if horizontal 
  get_capsule_outline_loop:
    
    move $a0, $s0 # x
    addi $a1, $s1, 1 # y
    jal get_cell_address
    lw $s5, 0($v0) # value inside
    bne $s5, $zero, end_update_capsule_outline

    beq $s3, 0 get_capsule_outline_next

    # if capsule horizontal
    # check to the right too
    addi $a0, $s0, 1
    jal get_cell_address
    lw $s6, 0($v0)

    # beq $s6, -1, get_capsule_outline_next
    bne $s6, $zero, end_update_capsule_outline

    get_capsule_outline_next:
    addi $s1, $s1, 1 # increment y
    j get_capsule_outline_loop
    
  end_update_capsule_outline:
  la $s2, CURR_CAPSULE_OUTLINE
  jal vert_or_horiz
  sw $v0, 0($s2) # store curr orientation

  sw $s0, 4($s2) # x
  sw $s1, 8($s2) # y
    
  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra

# Gameplay functions

check_game_over:
  # Output: $v0 = 0 if game not over, 1 if game is over.
  PUSH_TO_STACK($ra)
  # get the capsule spawn location 
  la $t0, CAPSULE_START
  lw $a0, 0($t0)
  lw $a1, 4($t0)
  jal get_cell_address # this is the address of the "pivot" draw_pixel
  # if this pixel is occupied, game over
  lw $t1, 0($v0) # get value in $v0
  bne $t1, $zero, game_over_true
  # we also need to check the pixel one step over
  la $t0, CAPSULE_START
  lw $a0, 0($t0)
  addi $a0, $a0, 1
  lw $a1, 4($t0)
  jal get_cell_address # this is the address of the pixel to the right
  lw $t1, 0($v0) # get value in $v0
  bne $t1, $zero, game_over_true
  li $v0, 0 # then the game is not over, set return to 0
  j check_game_over_return
  
  game_over_true:
    li $v0, 1 # game is over, set return to 1
  check_game_over_return:
  POP_FROM_STACK($ra)
  jr $ra

pause:
  # Pauses the game until "p" is pressed again.
  PUSH_TO_STACK($ra)

  pause_loop:
    li $v0, 32
    lw $a0, SLEEP_DURATION
    syscall # sleep for SLEEP_DURATION ms

    lw $t0, ADDR_KBRD # $t0 = base address for keyboard
    lw $t1, 0($t0) # $t1 = first word from keyboard
    bne $t1, 1, pause_loop # If the first key is not 1, no key is pressed
    lw $t1, 4($t0) 
    beq $t1, 0x70, pause_end # if the key is p, return to gameplay
    j pause_loop
  pause_end:
  POP_FROM_STACK($ra)
  jr $ra
  


add_capsule_to_grid:
  # Adds the current capsule to the grid state.
  # modifies: $t0, $t1, $t2, $t3, $t4, $t5
  PUSH_TO_STACK($ra)
  la $t0, CURR_CAPSULE_STATE
  lw $t1, 0($t0)       # Left side color
  lw $t2, 4($t0)       # Right side color
  lw $t3, 8($t0)       # Orientation
  lw $t4, 12($t0)      # X position
  lw $t5, 16($t0)      # Y position
  
  # load anchor pixel since we need to consider it in every case
  move $a0, $t4 # x in $a0
  move $a1, $t5 # y in $a1
  PUSH_TO_STACK($t0)
  PUSH_TO_STACK($t1)
  PUSH_TO_STACK($t2)
  jal get_cell_address # its safe since this doesn't modify $t3
  POP_FROM_STACK($t2)
  POP_FROM_STACK($t1)
  POP_FROM_STACK($t0)

  beq $t3, 1, add_capsule_1 
  beq $t3, 2, add_capsule_2 
  beq $t3, 3, add_capsule_3 
  beq $t3, 4, add_capsule_4 


  add_capsule_1: # Left colour on left (anchor), right colour on right
    sw $t1, 0($v0)
    addi $a0, $a0, 1 # increment x
    
    PUSH_TO_STACK($t0)
    PUSH_TO_STACK($t1)
    PUSH_TO_STACK($t2)
    jal get_cell_address # its safe since this doesn't modify $t3
    POP_FROM_STACK($t2)
    POP_FROM_STACK($t1)
    POP_FROM_STACK($t0)

    sw $t2, 0($v0)
    
    j end_add_capsule

  add_capsule_2: # Right colour on bottom (anchor), left colour on top
    sw $t2, 0($v0) # store right colour 
    subi $a1, $a1, 1 # decrement y

    PUSH_TO_STACK($t0)
    PUSH_TO_STACK($t1)
    PUSH_TO_STACK($t2)
    jal get_cell_address 
    POP_FROM_STACK($t2)
    POP_FROM_STACK($t1)
    POP_FROM_STACK($t0)

    sw $t1, 0($v0) # store left colour at top
    j end_add_capsule 

  add_capsule_3: # Right colour on left (anchor), left colour on right
    sw $t2, 0($v0)
    addi $a0, $a0, 1 # increment x
    
    PUSH_TO_STACK($t0)
    PUSH_TO_STACK($t1)
    PUSH_TO_STACK($t2)
    jal get_cell_address 
    POP_FROM_STACK($t2)
    POP_FROM_STACK($t1)
    POP_FROM_STACK($t0)

    sw $t1, 0($v0) # store left colour on right
    j end_add_capsule

  add_capsule_4: # Left colour on bottom (anchor), right colour on top
    sw $t1, 0($v0)
    subi $a1, $a1, 1 # decrement y

    PUSH_TO_STACK($t0)
    PUSH_TO_STACK($t1)
    PUSH_TO_STACK($t2)
    jal get_cell_address 
    POP_FROM_STACK($t2)
    POP_FROM_STACK($t1)
    POP_FROM_STACK($t0)

    sw $t2, 0($v0) # store left colour at top
    j end_add_capsule

  
  end_add_capsule:
  POP_FROM_STACK($ra)
  jr $ra



add_capsule_to_relationships:
  # Adds the current capsule to the capsule relationships array
  # Stores where to look for the other half of the capsule at the corresponding cell for a capsule half.
  # modifies the temp registers: $t0, $t1, $t2, $t3 and also $v0
  PUSH_TO_STACK($ra)

  PUSH_ALL_SAVED()
  la $t0, CURR_CAPSULE_STATE
  lw $t1, 12($t0) # x pos
  lw $t2, 16($t0) # y  pos

  #todo load all the "capsule location" values to some registers that won't get touched

  la $s0, CAPSULE_HALF_LOCATION
  lw $s1, 0($s0) # above 
  lw $s2, 4($s0) # below 
  lw $s3, 8($s0) # left 
  lw $s4, 12($s0) # right


  # In either case we need the address of the anchor pixel in the relationships grid
  move $a0, $t1 # x coord
  move $a1, $t2 # y coord   
  jal get_cell_address_relationships
  move $t3, $v0 # move it to $t3
  
  jal vert_or_horiz # get capsule horizontal or vertical
  beq $v0, $zero, add_vert_capsule_relationship # $v0 = 0 means vertical capsule 
  # otherwise it's horizontal
  # store "right" in address of anchor pixel 
  sw $s4, 0($t3)
  #increment x coord and store "right" there 
  addi $a0, $a0, 1
  jal get_cell_address_relationships
  sw $s3, 0($v0)
  
  
  j end_add_capsule_to_relationships

  add_vert_capsule_relationship:
    # store "above" in address of anchor pixel 
    sw $s1, 0($t3)
    # decrement y coord and store "below" there 
    subi $a1, $a1, 1 
    jal get_cell_address_relationships
    sw $s2, 0($v0)

  end_add_capsule_to_relationships:
  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra
  
find_and_clear_consecutives:
  # Finds the first column or row of 4 or more cells with the same colour to be cleared
  # Returns: $v0 = 0 if success, -1 if no clears were performed
  PUSH_TO_STACK($ra)


  # Call find_column_clear. if $t0 != -1, then go to clear the cells
  jal find_column_clear
  POP_FROM_STACK($t0) # x value
  POP_FROM_STACK($t1) # y value
  POP_FROM_STACK($t2) # length
  bne $t0, -1, return_find_consecutives_vert
  # Otherwise there were no columns to clear, so call find_row_clear.
  # if $t0 != -1, go clear the cells
  # otherwise return -1 in all 3 return values
  jal find_row_clear
  POP_FROM_STACK($t0) # x value
  POP_FROM_STACK($t1) # y value
  POP_FROM_STACK($t2) # length
  bne $t0, -1, return_find_consecutives_horiz
  j return_find_consecutives_none

  return_find_consecutives_vert:
    li $t3, 0
    j clear_consecutives

  return_find_consecutives_horiz:
    li $t3, 1
    j clear_consecutives

  clear_consecutives:
    PUSH_TO_STACK($t3)
    PUSH_TO_STACK($t2)
    PUSH_TO_STACK($t1)
    PUSH_TO_STACK($t0)
    jal delete_chain
    li $v0, 0
    POP_FROM_STACK($ra)
    jr $ra

  return_find_consecutives_none:
    li $v0, -1
    POP_FROM_STACK($ra)
    jr $ra
  


find_column_clear:
  # Finds the first vertical chain of 4 or more cells with the same colour to be cleared.
  # *"First": going from left to right, scanning each column from top to bottom
  # Returns: 
  # 1st pop: x-coord of cell to start clearing from
  # 2nd pop: y-coord of cell ^^^
  # 3rd pop: length of chain
  # If no chain was found, all 3 return values will be -1
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()

  lw $s0, GRID_HEIGHT 
  lw $s1, GRID_WIDTH

  li $s3, 1 # Row counter
  li $s4, 1 # Column counter

  # we want to skip over side borders, so the row counter can start at 1 and and run for < GRID_WIDTH-1
  subi $s1, $s1, 1
  # but we can use the bottom border to identify chains that go down to the ground

  li $t4, -1 # let $t4 be the y-coord/row that the current chain starts from
  li $t5, 0 # let $t5 be the length of the current chain 
  li $t6, 0 # let $t6 be the current colour
  find_column_clear_loop:
    # get curr cell address
    move $a0, $s4 # Move current column/x to $a0
    move $a1, $s3 # move current row/y to $a1
    jal get_cell_address # Get the address of the current cell in the grid
    lw $s5, 0($v0) # Store cell contents in $s5

    #if we encounter an empty cell or border, break the current chain
    beq $s5, 0, break_chain
    beq $s5, -1, break_chain

    # if there is no current colour, set the current colour and start a new chain
    beq $t6, $zero, break_or_start_new_chain
    
    # else check curr colour matches prev colour
    move $a0, $t6 # move prev colour into $a0 
    move $a1, $s5 # move curr colour into $a1
    PUSH_ALL_TEMP()
    jal is_matching_colour
    POP_ALL_TEMP()
    bnez $v0, break_or_start_new_chain # if they don't match, break the current chain (and return if necessary) OR start new one
    j extend_chain # if they do match, extend the chain      

    break_or_start_new_chain:
      bge $t5, 4, break_chain
      move $t4, $s3 # move curr row to be the y-coord of the current chain start
      move $t6, $s5 # move curr colour 
      li $t5, 1 # reset chain length to 1
      j find_column_clear_next_cell

    extend_chain:
      addi $t5, $t5, 1 # increment chain length
      j find_column_clear_next_cell

    break_chain:
      # if the current chain length wasn't long enough, reset it 
      blt $t5, 4, reset_chain
      # otherwise we can return early
      # save the correct x value 
      move $t3, $s4
      POP_ALL_SAVED()
      POP_FROM_STACK($ra)
      
      PUSH_TO_STACK($t5) # length of chain
      PUSH_TO_STACK($t4) # curr chain starting y 
      PUSH_TO_STACK($t3) # curr chain starting x
      jr $ra

    reset_chain:
      li $t4, -1
      li $t5, 0 
      li $t6, 0 
      j find_column_clear_next_cell

    find_column_clear_next_cell:
      addi $s3, $s3, 1 # Increment row counter
      # repeat if row counter < GRID_HEIGHT 
      blt $s3, $s0, find_column_clear_loop

      # then row counter = GRID_HEIGHT, so we reset it and increment column counter
      li $s3, 1
      addi $s4, $s4, 1 
      # repeat if column_counter < GRID_WIDTH
      blt $s4, $s1, find_column_clear_loop

  # otherwise we didn't find any chains
  POP_ALL_SAVED()
  POP_FROM_STACK($ra)    

  li $t0, -1
  PUSH_TO_STACK($t0)
  PUSH_TO_STACK($t0)
  PUSH_TO_STACK($t0)
  
  jr $ra

find_row_clear:
  # Finds the first vertical chain of 4 or more cells with the same colour to be cleared.
  # *"First": going from left to right, scanning each column from top to bottom
  # Returns: 
  # 1st pop: x-coord of cell to start clearing from
  # 2nd pop: y-coord of cell ^^^
  # 3rd pop: length of chain
  # If no chain was found, all 3 return values will be -1
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()

  lw $s0, GRID_HEIGHT 
  lw $s1, GRID_WIDTH

  li $s3, 1 # Row counter
  li $s4, 1 # Column counter

  # we want to skip over the bottom border, so the column counter can start at 1 and and run for < GRID_HEIGHT-1
  # but we can use the side border to identify chains that go into the sides

  li $t4, -1 # let $t4 be the x-coord/column that the current chain starts from
  li $t5, 0 # let $t5 be the length of the current chain 
  li $t6, 0 # let $t6 be the current colour
  find_row_clear_loop:
    # get curr cell address
    move $a0, $s4 # Move current column/x to $a0
    move $a1, $s3 # move current row/y to $a1
    jal get_cell_address # Get the address of the current cell in the grid
    lw $s5, 0($v0) # Store cell contents in $s5

    #if we encounter an empty cell or border, break the current chain
    beq $s5, 0, break_chain_row
    beq $s5, -1, break_chain_row

    # if there is no current colour, set the current colour and start a new chain
    beq $t6, $zero, start_new_chain_row
    
    # else check curr colour matches prev colour
    move $a0, $t6 # move prev colour into $a0 
    move $a1, $s5 # move curr colour into $a1
    PUSH_ALL_TEMP()
    jal is_matching_colour
    POP_ALL_TEMP()
    bnez $v0, start_new_chain_row # if they don't match, break the current chain
    j extend_chain_row # if they do match, extend the chain

    start_new_chain_row:
      bge $t5,4, break_chain_row
      move $t4, $s4 # move curr col to be the x-coord of the current chain start
      move $t6, $s5 # move curr colour 
      li $t5, 1 # reset chain length to 1
      j find_row_clear_next_cell

    extend_chain_row:
      addi $t5, $t5, 1 # increment chain length
      j find_row_clear_next_cell

    break_chain_row:
      # if the current chain length wasn't long enough, reset it 
      blt $t5, 4, reset_chain_row
      # otherwise we can return early
      # save the correct y value 
      move $t3, $s3
      POP_ALL_SAVED()
      POP_FROM_STACK($ra)
      
      PUSH_TO_STACK($t5) # length of chain
      PUSH_TO_STACK($t3) # curr chain starting y 
      PUSH_TO_STACK($t4) # curr chain starting x
      jr $ra

    reset_chain_row:
      li $t4, -1
      li $t5, 0 
      li $t6, 0 
      j find_row_clear_next_cell

    find_row_clear_next_cell:
      addi $s4, $s4, 1 # Increment column counter
      # repeat if column counter < GRID_WIDTH
      blt $s4, $s1, find_row_clear_loop

      # then column counter = GRID_WIDTH, so we reset it and increment row counter
      li $s4, 1
      addi $s3, $s3, 1 
      # repeat if row counter < GRID_HEIGHT
      blt $s3, $s0, find_row_clear_loop

  # otherwise we didn't find any chains
  POP_ALL_SAVED()
  POP_FROM_STACK($ra)    

  li $t0, -1
  PUSH_TO_STACK($t0)
  PUSH_TO_STACK($t0)
  PUSH_TO_STACK($t0)
  
  jr $ra

delete_chain:
  # Deletes the chain with
  # first pop: x-coord of starting cell
  # second pop: y-coord of starting cell
  # third pop: chain length
  # fourth pop: orientation: 0 for vertical, 1 for horizontal
  
  POP_FROM_STACK($t0) 
  POP_FROM_STACK($t1) 
  POP_FROM_STACK($t2) 
  POP_FROM_STACK($t3) 
  
  PUSH_TO_STACK($ra)

  PUSH_ALL_SAVED()
  move $s0, $t0 # x
  move $s1, $t1 # y
  move $s2, $t2 # chain length
  move $s3, $t3 # orientation

  la $s4, CAPSULE_HALF_LOCATION
  lw $s4, 16($s4) # get "deleted" value

  li $s5, 0 # counter  

  deletion_loop:
    move $a0, $s0
    move $a1, $s1
    # 1) delete it from state grid
    jal get_cell_address
    # todo: check if it was a virus and if so, decrement the number of viruses AND SKIP TO NEXT LOOP
    PUSH_TO_STACK($a0)
    PUSH_TO_STACK($v0)
    
    lw $a0, 0($v0) # get colour
    jal is_virus
    beq $v0, $zero, skip_decrementing_virus
    # todo: decrement virus count...
    la $t7, VIRUSES_REMAINING
    lw $t6, 0($t7)
    subi $t6, $t6, 1
    sw $t6, 0($t7)
    POP_FROM_STACK($v0)
    POP_FROM_STACK($a0)
    sw $zero, 0($v0)
    j delete_incr
    
    
    skip_decrementing_virus:
    POP_FROM_STACK($v0)
    POP_FROM_STACK($a0)
    sw $zero, 0($v0) # set the value there to 0 to delete it from state

    # 2) set the other capsule half's value to -1 (if it exists)
    jal get_cell_address_relationships 
    # store the address in $s6 
    move $s6, $v0
    
    lw $a2, 0($s6) # get location of other capsule half
    beq $a2, $s4, delete_curr_half_rship # skip next steps if the other capsule half was deleted
    
    jal get_other_capsule_half
    move $a0, $v0 # x coord of other half
    move $a1, $v1, # y coord of other half
    jal get_cell_address_relationships # get its address in the relationships grid 
    sw $s4, 0($v0) # set its value to "deleted"/-1

    # 3) delete it from the relationship grid 
    delete_curr_half_rship:
      sw $zero, 0($s6)

    # 4) increment in the correct direction
    delete_incr:
    beq $s3, $zero, delete_curr_vertical_incr
    # otherwise we are moving horizontally 
    addi $s0, $s0, 1
    j deletion_loop_next_cell

    delete_curr_vertical_incr:
      # moving vertically downwards
      addi $s1, $s1, 1

    deletion_loop_next_cell:
      addi $s5, $s5, 1
      beq $s5, $s2, end_delete_chain
      j deletion_loop
      
    
  end_delete_chain:
  PLAY_CLEAR_SOUND()
  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra

drop_capsules:
  # Attempts to drop every capsule in the grid
  # iterate through each grid element
  # if we encounter a capsule, and there's empty space under it, attempt to drop it 
  # check if it's a full capsule or half by checking its value in the relationship grid
  # if -1, simply call drop_half
  # otherwise, call to get the other half's coordinates and push them to the stack, call drop_full capsule
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()
  lw $s0, GRID_HEIGHT   # row counter
  lw $s1, GRID_WIDTH
  subi $s0, $s0, 3 # skip bottom row entirely since no need to drop
  subi $s1, $s1, 1 # we want to skip the right border
  li $s2, 1 # column counter
  
  drop_capsules_loop:
    move $a0, $s2 # move x
    move $a1, $s0 # move y
    
    jal get_cell_address
    lw $t0, 0($v0) # get what's in it
    beq $t0, $zero, drop_capsules_next_cell # skip if it's 0
    beq $t0, -1, drop_capsules_next_cell # skip if it's -1
    # check if it's a virus 
    PUSH_TO_STACK($a0)
    move $a0, $t0 # move colour into $a0
    jal is_virus
    POP_FROM_STACK($a0)
    beq $v0, 1, drop_capsules_next_cell # skip if it's a virus 

    # since it's not a virus, we now check if it's a half or full capsule 
    jal get_cell_address_relationships
    lw $a2, 0($v0) # get whats in it
    beq $a2, -1, handle_half_capsule

    # otherwise it's a full capsule 
    # 1) Split into cases based on value of curr cell relationship value
    beq $a2, 1, handle_full_bottom
    beq $a2, 2, handle_full_top
    beq $a2, 3, handle_full_right
    beq $a2, 4, handle_full_left

    handle_full_bottom:
      jal get_other_capsule_half
      move $a0, $v0 # top half
      move $a1, $v1 
      move $a2, $s2 # bottom half
      move $a3, $s0
      jal drop_full_capsule_vert
      j drop_capsules_next_cell

    handle_full_top:
      jal get_other_capsule_half
      move $a2, $v0 # bottom half
      move $a3, $v1
      jal drop_full_capsule_vert
      j drop_capsules_next_cell

    handle_full_right:
      jal get_other_capsule_half # get left half 
      move $a0, $v0 
      move $a1, $v1 
      move $a2, $s2 # right half
      move $a3, $s0
      
      jal drop_full_capsule_horiz

      j drop_capsules_next_cell

    handle_full_left: 
      jal get_other_capsule_half # get right half 
      move $a2, $v0 
      move $a3, $v1 
      jal drop_full_capsule_horiz
      j drop_capsules_next_cell

    handle_half_capsule:
      jal drop_half_capsule

      j drop_capsules_next_cell

  drop_capsules_next_cell:
    addi $s2, $s2, 1 # increment column counter
    blt $s2, $s1, drop_capsules_loop # loop again if its less than the grid width
    # else
    li $s2, 1 # reset column counter
    subi $s0, $s0, 1 # decr row counter
    bge $s0, 1, drop_capsules_loop # if we're not at the top border

  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra

drop_full_capsule_horiz:
  # Drops a full horizontal capsule until one capsule half collides with something beneath it 
  # given:
  # $a0: x of left half of capsule
  # $a1: y of left half of capsule
  # $a2: x of right half of capsule
  # $a3: y of right half of capsule
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()
  move $s0, $a0 # x for left
  move $s1, $a1 # y for left
  move $s2, $a2 # x for right
  move $s3, $a3 # y for right
  la $s4, CAPSULE_HALF_LOCATION
  lw $s5, 8($s4) # "left" value
  lw $s4, 12($s4) # "right" value

  # get initial colours 
  jal get_cell_address
  lw $s6, 0($v0) # left cell colour 

  move $a0, $s2
  move $a1, $s3 
  jal get_cell_address
  lw $s7, 0($v0) # right cell colour

  drop_full_capsule_horiz_loop:
    # 1) get addresses under both left and right and check if either is nonempty, if so return
    move $a0, $s0 # left cell
    move $a1, $s1
    addi $a1, $a1, 1
    jal get_cell_address
    lw $t0, 0($v0)
    bne $t0, $zero, end_drop_full_capsule_horiz

    move $a0, $s2 # right cell
    move $a1, $s3
    addi $a1, $a1, 1
    jal get_cell_address
    lw $t0, 0($v0)
    bne $t0, $zero, end_drop_full_capsule_horiz

    # 2) get address of initial cells in grid and relationship state and clear them 
    move $a0, $s2 # right cell
    move $a1, $s3
    jal get_cell_address
    sw $zero, 0($v0)

    jal get_cell_address_relationships
    sw $zero, 0($v0)

    move $a0, $s0 # left cell
    move $a1, $s1
    jal get_cell_address
    sw $zero, 0($v0)

    jal get_cell_address_relationships
    sw $zero, 0($v0)

    # 3) get address of cells 1 down and put the new values in them 
    addi $s1, $s1, 1
    addi $s3, $s3, 1
    
    move $a0, $s2 # right cell
    move $a1, $s3
    jal get_cell_address
    sw $s7, 0($v0)

    jal get_cell_address_relationships
    sw $s5, 0($v0) # store "left" there

    move $a0, $s0 # left cell
    move $a1, $s1
    jal get_cell_address
    sw $s6, 0($v0)

    jal get_cell_address_relationships
    sw $s4, 0($v0) # store "right" there

    jal draw_grid
    li $v0, 32
    lw $a0, SLEEP_DURATION
    sll $a0, $a0, 2 # multiply it by 4, idk
    syscall # sleep for SLEEP_DURATION ms
    j drop_full_capsule_horiz_loop

  end_drop_full_capsule_horiz:
  PLAY_DROP_SOUND()

  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra

drop_full_capsule_vert:
  # Drops a full capsule (vertical orientation) until one capsule half collides with something beneath it 
  # given:
  # $a0: x of top half of capsule
  # $a1: y of top half of capsule
  # $a2: x of bottom half of capsule
  # $a3: y of bottom half of capsule
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()
  # load: init x, y for each, top, bottom values, initial colours in left, right,
  move $s0, $a0 # x for top
  move $s1, $a1 # y for top
  move $s2, $a2 # x for bottom
  move $s3, $a3 # y for bottom
  la $s4, CAPSULE_HALF_LOCATION
  lw $s5, 4($s4) # "below" value
  lw $s4, 0($s4) # "above" value

  # get initial colours 
  jal get_cell_address
  lw $s6, 0($v0) # top cell colour 

  move $a0, $s2
  move $a1, $s3 
  jal get_cell_address
  lw $s7, 0($v0) # bottom cell colour
  
  drop_full_capsule_vert_loop:
    # 1) get address of cell below the bottom cell and check if it is empty, if not we exit
    move $a0, $s2
    move $a1, $s3
    addi $a1, $a1, 1
    jal get_cell_address
    lw $t0, 0($v0)
    bne $t0, $zero, end_drop_full_capsule_vert

    # 2) get address of initial cells in grid and relationship state and clear them 
    move $a0, $s2 # bottom cell
    move $a1, $s3
    jal get_cell_address
    sw $zero, 0($v0)

    jal get_cell_address_relationships
    sw $zero, 0($v0)

    move $a0, $s0 # top cell
    move $a1, $s1
    jal get_cell_address
    sw $zero, 0($v0)

    jal get_cell_address_relationships
    sw $zero, 0($v0)

    # 3) get address of cells 1 down and put the new values in them 
    addi $s1, $s1, 1
    addi $s3, $s3, 1
    
    move $a0, $s2 # bottom cell
    move $a1, $s3
    jal get_cell_address
    sw $s7, 0($v0)

    jal get_cell_address_relationships
    sw $s4, 0($v0)

    move $a0, $s0 # top cell
    move $a1, $s1
    jal get_cell_address
    sw $s6, 0($v0)

    jal get_cell_address_relationships
    sw $s5, 0($v0)

    jal draw_grid

    li $v0, 32
    lw $a0, SLEEP_DURATION
    sll $a0, $a0, 2 # multiply it by 4, idk
    syscall # sleep for SLEEP_DURATION ms

    j drop_full_capsule_vert_loop

  end_drop_full_capsule_vert:
  PLAY_DROP_SOUND()

  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra

drop_half_capsule:
  # Drops half a capsule until it collides with something beneath it
  # given: 
  # $a0: x of capsule half to drop
  # $a1: y of capsule half to drop
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()
  la $s3, CAPSULE_HALF_LOCATION
  lw $s3, 16($s3) # get the "deleted" value
  jal get_cell_address
  lw $s4, 0($v0) # get original capsule colour
  # i fucked up i need to formally keep track of everything and not clobber values I WROTE IT WHEN I WAS SICK
  drop_half_capsule_loop:
    jal get_cell_address # get the address of the current cell 
    move $s0, $v0 #save it in $s0 

    jal get_cell_address_relationships # and its relationships grid cell
    move $s1, $v0 # save it in $s1
    
    addi $a1, $a1, 1 # increment y 
    
    jal get_cell_address #  get address of one cell below
    move $s2, $v0 # save it in $s2
    lw $t0, 0($s2) # get the value

    bne $t0, $zero, drop_half_capsule_end # if it's not empty, we're done
    
    # else:
    sw $zero, 0($s0) # clear the old cell 
    sw $zero, 0($s1) # and its value in the relationships grid

    sw $s4, 0($s2) # store the original capsule colour in the new location

    jal get_cell_address_relationships # get the address of the new location in the relationships grid
    sw $s3, 0($v0) # store the "deleted" relationship value there 
    jal draw_grid
    
    PUSH_TO_STACK($a0)
    li $v0, 32
    lw $a0, SLEEP_DURATION
    sll $a0, $a0, 2 # multiply it by 4, idk
    syscall # sleep for SLEEP_DURATION ms
    POP_FROM_STACK($a0)

    j drop_half_capsule_loop
    

  drop_half_capsule_end:
  PLAY_DROP_SOUND()

  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra

# MUSIC and sound effects

update_music:
  # updates the music
  PUSH_TO_STACK($ra)
  PUSH_ALL_TEMP()
  la $t0, MUSIC_TIMER
  lw $t1, 0($t0) # get current time since last note 
  lw $t2, NOTE_DURATION
  lw $t3, SLEEP_DURATION
  add $t1, $t1, $t3 # add the last sleep duration 
  sw $t1, 0($t0) # update the time since last note

  blt $t1, $t2, end_update_music # if it's not time, skip and continue program flow 

  # reset the timer otherwise and play the note 
  sw $zero, 0($t0)

  # 1) load the melody pointer address 
  la $t3, MELODY_POINTER
  lw $t4, 0($t3) # get the value 
  # 2) get the melody area in memory and play it
  la $t5, MELODY
  sll $t6, $t4, 2 # multiply pointer value by 4 due to word size 
  add $t5, $t5, $t6 # get address at pointer 
  lw $a0, 0($t5)
  jal play_note 
  # 3) update pointer
  addi $t4, $t4, 1
  lw $t5, MELODY_LENGTH
  blt $t4, $t5, no_reset # if we reached the end, reset the pointer
  li $t4, 0
  
  no_reset:
    sw $t4, 0($t3) # store new pointer value  
  end_update_music:
  POP_ALL_TEMP()
  POP_FROM_STACK($ra)
  jr $ra

play_note:
  # plays the note in $a0 
  # OK when i wrote this it didn't occur to me that i should make it more flexible
  # so i'm writing a macro instead
  PUSH_TO_STACK($ra)
  beq $a0, 0, end_play_note
  li $v0, 31
  lw $a1, NOTE_DURATION
  lw $a2, INSTRUMENT
  lw $a3, VOLUME
  syscall
  end_play_note:
  POP_FROM_STACK($ra)
  jr $ra

  

# Drawing functions ===============================================================================

draw_capsule:
  # Draw the capsule based on the current state
  PUSH_TO_STACK($ra)
  
  la $t0, CURR_CAPSULE_STATE # Get state
  lw $t1, 0($t0)       # Left side color
  lw $t2, 4($t0)       # Right side color
  lw $t3, 8($t0)       # Orientation
  lw $t4, 12($t0)      # X position
  lw $t5, 16($t0)      # Y position

  la $t6, GRID_LOCATION # Load offset for the grid (we use the same one in every draw_pixel call)
  lw $a3, 0($t6)

  beq $t3, 1, draw_orientation_1
  beq $t3, 2, draw_orientation_2
  beq $t3, 3, draw_orientation_3
  beq $t3, 4, draw_orientation_4

  draw_orientation_1: # Left colour on left, right colour on right
    # Draw left capsule half
    move $a0, $t4  # Load X of left pixel
    move $a1, $t5 # Load Y pixel of left pixel
    move $a2, $t1 # Load colour of left capsule half
    # WARNING!!!!! draw_pixel overwrites $t0, $t2, $t3, $t4
    PUSH_TO_STACK($t2)
    
    jal draw_pixel

    POP_FROM_STACK($t2)

    # Draw right capsule half
    addi $a0, $a0, 1 # increment X to go 1 step right
    move $a2, $t2 # Load colour of right capsule half
    jal draw_pixel
    
    j end_draw_capsule

  draw_orientation_2: # left colour on top, right colour on bottom
    # Draw bottom capsule half
    move $a0, $t4  # Load X of bottom pixel
    move $a1, $t5 # Load Y pixel of bottom pixel
    move $a2, $t2 # Load colour of right capsule half
    jal draw_pixel

    # draw top capsule half
    addi $a1, $a1, -1 # decrement Y to go 1 step up
    move $a2, $t1 # Load colour of left capsule half
    jal draw_pixel
    j end_draw_capsule
  
  draw_orientation_3: # right colour on left, left colour on right
    # Draw left capsule half
    move $a0, $t4  # Load X of left pixel
    move $a1, $t5 # Load Y pixel of left pixel
    move $a2, $t2 # Load colour of right capsule half
    jal draw_pixel

    # Draw right capsule half
    addi $a0, $a0, 1 # increment X to go 1 step right
    move $a2, $t1 # Load colour of left capsule half
    jal draw_pixel
    j end_draw_capsule
  
  draw_orientation_4: # right colour on top, left colour on bottom
    # Draw bottom capsule half
    move $a0, $t4  # Load X of bottom pixel
    move $a1, $t5 # Load Y pixel of bottom pixel
    move $a2, $t1 # Load colour of left capsule half
    PUSH_TO_STACK($t2)
    jal draw_pixel

    # draw top capsule half
    POP_FROM_STACK($t2)
    addi $a1, $a1, -1 # decrement Y to go 1 step up
    move $a2, $t2 # Load colour of right capsule half
    jal draw_pixel
    j end_draw_capsule
    j end_draw_capsule
    
  end_draw_capsule:
    POP_FROM_STACK($ra)
    jr $ra

draw_capsule_outline:
  # Draws the outline of the capsule
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()
  
  la $t0, CURR_CAPSULE_OUTLINE
  lw $s0, 0($t0) # orientation
  lw $s1, 4($t0) # x 
  lw $s2, 8($t0) # y

  lw $a3, GRID_LOCATION
  lw $a2, OUTLINE_GREY
  
  move $a0, $s1
  move $a1, $s2
  jal draw_pixel 

  beq $s0, $zero, draw_capsule_outline_vertical
  beq $s0, 1, draw_capsule_outline_horizontal 

  draw_capsule_outline_vertical: # anchor pixel and draw up 
    subi $a1, $a1, 1 # decrement y
    jal draw_pixel
    j end_draw_capsule_outline
    
  draw_capsule_outline_horizontal:
    addi $a0, $a0, 1 # increment x
    jal draw_pixel

  end_draw_capsule_outline:
  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra

draw_grid:
  # Load the grid height, width, and location
  # Loop for each row -> for each column
  # Call get_address for each cell, get the value
  # Then call draw_pixel
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()
  PUSH_TO_STACK($a0)
  PUSH_TO_STACK($a1)
  PUSH_TO_STACK($a2)
  PUSH_TO_STACK($a3)
  lw $s0, GRID_HEIGHT 
  lw $s1, GRID_WIDTH
  lw $s2, GRID_LOCATION

  li $s3, 1 # Row counter
  li $s4, 1 # Column counter

  # in fact we want to skip over the borders, so the row counter can start at 1 and and run for < GRID_WIDTH-1
  # and the column counter can similarly start at 1 and run for < GRID_HEIGHT-1
  subi $s0, $s0, 1
  subi $s1, $s1, 1
  

  draw_grid_loop:
    move $a0, $s4 # Move current column/x to $a0
    move $a1, $s3 # move current row/y to $a1
    jal get_cell_address # Get the address of the current cell in the grid
    lw $s5, 0($v0) # Store what's in the cell in $s5
    # If $s5 == -1, skip drawing
    beq $s5, -1, draw_next_cell
    # otherwise we draw what's in the cell
    move $a2, $s5 # move colour to $a2
    move $a3, $s2 # move offset to $a3
    jal draw_pixel

    draw_next_cell:
      addi $s4, $s4, 1 # Increment column counter
      # repeat if column counter < GRID_WIDTH
      blt $s4, $s1, draw_grid_loop

      # then column_counter = GRID_WIDTH, so we reset it and increment row counter
      li $s4, 1
      addi $s3, $s3, 1 
      # repeat if row_counter < GRID_HEIGHT
      blt $s3, $s0, draw_grid_loop

  POP_FROM_STACK($a3)
  POP_FROM_STACK($a2)
  POP_FROM_STACK($a1)
  POP_FROM_STACK($a0)
  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra


draw_pill_bottle:
  # Draws the pill bottle.
  
  PUSH_TO_STACK($ra)

  # left bottle neck
  li $a0, 9
  li $a1, 2
  li $a2, 3
  lw $a3, GREY
  jal draw_vertical_line

  li $a0, 2
  li $a1, 4
  li $a2, 8
  jal draw_horizontal_line

  # left bottle side
  li $a0, 2
  li $a1, 4
  li $a2, 25
  jal draw_vertical_line

  # bottle bottom
  li $a0, 2
  li $a1, 29
  li $a2, 20
  jal draw_horizontal_line

  # right bottle neck
  li $a0, 14
  li $a1, 2
  li $a2, 3
  lw $a3, GREY
  jal draw_vertical_line

  li $a0, 14
  li $a1, 4
  li $a2, 8
  jal draw_horizontal_line

  # right bottle side
  li $a0, 21
  li $a1, 4
  li $a2, 25
  jal draw_vertical_line

  POP_FROM_STACK($ra)
  jr $ra

draw_pause:
  # Draws the pause button in the upper right corner.
  PUSH_TO_STACK($ra)
  li $a0, 28
  li $a1, 0
  li $a2, 3
  lw $a3, GREY
  jal draw_vertical_line

  li $a0, 30
  li $a1, 0
  li $a2, 3
  jal draw_vertical_line
  POP_FROM_STACK($ra)
  jr $ra
  

draw_rectangle:
  # $a0 stores x coord of start
  # $a1 stores y coord of start
  # $a2 stores width
  # $a3 stores height
  # from stack, $t0 stores colour
  POP_FROM_STACK($t0)
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()
  move $s0, $a0 # x coord
  move $s1, $a1 # y coord
  move $s2, $a2 # width
  move $s3, $a3 # height 
  move $s4, $t0 # colour

  li $s5, 0 # height counter
  draw_rectangle_loop:
    beq $s5, $s3, end_draw_rectangle
    move $a0, $s0
    add $a1, $s1, $s5 # y + height counter 
    move $a2, $s2 
    move $a3, $s4

    jal draw_horizontal_line
    addi $s5, $s5, 1
    j draw_rectangle_loop

    
  end_draw_rectangle:
  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra
  
draw_horizontal_line:
  # $a0 stores x coord of start
  # $a1 stores y coord of start
  # $a2 stores length of line
  # $a3 stores colour of line
  # draws a horizontal line, left to right
  PUSH_TO_STACK($ra)

  # $t0 stores index of pixel being drawn
  add $t0, $zero, $zero

  # $t2 stores amount to shift when moving down rows
  la $t2, WIDTH_SHIFT
  lw $t2, 0($t2)

  # $t1 stores starting pixel
  lw $t1, ADDR_DSPL
  sll $a0, $a0, 2 # multiply x by 4
  sllv $a1, $a1, $t2 # multiply y by 2^WIDTH_SHIFT
  
  add $t1, $t1, $a0 # add x offset
  add $t1, $t1, $a1 # add y offset

  draw_horizontal_line_loop:
    beq $t0, $a2, end_draw_horizontal_line
    sw $a3, 0($t1)
    addi $t1, $t1, 4 # move pixel right
    addi $t0, $t0, 1 # $t0 ++
    j draw_horizontal_line_loop

  end_draw_horizontal_line:
    POP_FROM_STACK($ra)
    jr $ra

draw_vertical_line:
  # $a0 stores x coord of start
  # $a1 stores y coord of start
  # $a2 stores length of line
  # $a3 stores colour of line
  # draws a vertical line, top-down

  PUSH_TO_STACK($ra)
  # $t0 stores index of pixel being drawn
  add $t0, $zero, $zero

  # $t2 stores amount to shift when moving down rows
  la $t2, WIDTH_SHIFT
  lw $t2, 0($t2) # $t2 stores WIDTH_SHIFT 

  # $t1 stores starting pixel
  lw $t1, ADDR_DSPL
  sll $a0, $a0, 2 # multiply x by 4
  sllv $a1, $a1, $t2 # multiply y by 2^WIDTH_SHIFT
  
  add $t1, $t1, $a0 # add x offset
  add $t1, $t1, $a1 # add y offset

  # store WIDTH in $t2
  la $t2, WIDTH
  lw $t2, 0($t2)
  sll $t2, $t2, 2 # multiply by 4 so we can add this to move between rows

  draw_vertical_line_loop:
    beq $t0, $a2, end_draw_vertical_line
    sw $a3, 0($t1)
    add $t1, $t1, $t2 # increment row we're on 
    addi $t0, $t0, 1 # increment index
    j draw_vertical_line_loop

  end_draw_vertical_line:
    POP_FROM_STACK($ra)
    jr $ra

draw_pixel:
  # Draws a pixel at the specified (x,y) location, after adding the specified offset to the display's base address
  # this makes it easier to draw within the grid
  # $a0: x position
  # $a1: y position
  # $a2: colour
  # $a3: offset to be added to base address
  # we assume this function won't ever be called unless as part of a subroutine, so we can take the values directly from the a registers
  # $t0: final address to draw at 
  # $t2: width shift required to move down rows
  # $t3: x * 4
  # $t4: y * 2^WIDTH_SHIFT
  
  PUSH_TO_STACK($ra)
  
  lw $t0, ADDR_DSPL # Get base address of display
  add $t0, $t0, $a3 # Add offset to base address

  la $t2, WIDTH_SHIFT # get amount required to shift to go down rows
  lw $t2, 0($t2) # store it in $t2
  
  sll $t3, $a0, 2 # multiply x by 4 (each word is 4 bytes) and put it in $t3
  sllv $t4, $a1, $t2 # multiply y by 2^WIDTH_SHIFT and put it in $t4
  
  add $t0, $t0, $t3 # add x offset
  add $t0, $t0, $t4 # add y offset

  sw $a2, 0($t0)          # Store color at the calculated address

  POP_FROM_STACK($ra)
  jr $ra
  


# Erasing functions (???)


erase_screen:
  # fills the entire screen with black
  PUSH_TO_STACK($ra)
  li $a0, 0
  li $a1, 0
  lw $a2, WIDTH 
  lw $a3, HEIGHT
  PUSH_TO_STACK($zero)
  jal draw_rectangle
  POP_FROM_STACK($ra)
  jr $ra


erase_capsule:
  # Erases the capsule from the screen.
  # modifies: $t0, $t1, $a0, $a1, $a2, $a3
  PUSH_TO_STACK($ra)
  la $t0, CURR_CAPSULE_STATE
  lw $t1, 8($t0) # orientation
  lw $a0, 12($t0) # x pos
  lw $a1, 16($t0) # y pos
  li $a2, 0 # load 0/black to $a2
  lw $a3, GRID_LOCATION # offset
  # First colour the "master" pixel black
  jal draw_pixel
  
  # Check the orientation
  jal vert_or_horiz
  beq $v0, $zero, erase_vert_capsule # if $v0 is vertical, skip this
  # then $v0 = 1 so it's horizontal, increment x pos and draw again
  addi $a0, $a0, 1
  j end_erase_capsule

  erase_vert_capsule:
    # decrement y pos and draw again
    subi $a1, $a1, 1

  end_erase_capsule:
  jal draw_pixel
  POP_FROM_STACK($ra)
  jr $ra

erase_capsule_outline:
  # erases the outline of the capsule
  PUSH_TO_STACK($ra)
  PUSH_ALL_SAVED()
  
  la $t0, CURR_CAPSULE_OUTLINE
  lw $s0, 0($t0) # orientation
  lw $s1, 4($t0) # x 
  lw $s2, 8($t0) # y

  lw $a3, GRID_LOCATION
  li $a2, 0
  
  move $a0, $s1
  move $a1, $s2
  jal draw_pixel 

  beq $s0, $zero, draw_capsule_outline_vertical
  beq $s0, 1, draw_capsule_outline_horizontal 

  erase_capsule_outline_vertical: # anchor pixel and draw up 
    subi $a1, $a1, 1 # decrement y
    jal draw_pixel
    j end_draw_capsule_outline
    
  erase_capsule_outline_horizontal:
    addi $a0, $a0, 1 # increment x
    jal draw_pixel

  end_erase_capsule_outline:
  POP_ALL_SAVED()
  POP_FROM_STACK($ra)
  jr $ra

erase_pause:
  # erases the pause button from the upper right corner.
  PUSH_TO_STACK($ra)
  li $a0, 28
  li $a1, 0
  li $a2, 3
  li $a3, 0
  jal draw_vertical_line

  li $a0, 30
  li $a1, 0
  li $a2, 3
  jal draw_vertical_line
  POP_FROM_STACK($ra)
  jr $ra

# Random generating functions

set_random_capsule_colour:
  # Calls generate_random_colour twice and stores the colours in the capsule state 
  # modifies: $t0, $v0
  PUSH_TO_STACK($ra)
  la $t0, CURR_CAPSULE_STATE

  jal generate_random_colour
  sw $v0, 0($t0) # Generate and store top colour
  
  jal generate_random_colour
  sw $v0, 4($t0) # Generate and store bottom colour
  
  POP_FROM_STACK($ra)
  jr $ra

generate_random_colour:
  # output: $v0 = one of RED, BLUE, YELLOW
  # modifies: $v0, $a0, $a1

  li $v0, 42
  li $a0, 0 # Generates random number from 0 to 2 inclusive and stores it in $a0
  li $a1, 3
  syscall

  beq $a0, 0, return_red
  beq $a0, 1, return_yellow
  # otherwise it's 2 so we return BLUE
  lw $v0, BLUE
  j generate_random_colour_return

  return_red:
    lw $v0, RED
    j generate_random_colour_return

  return_yellow:
    lw $v0, YELLOW
    j generate_random_colour_return
  
    
  generate_random_colour_return:
  jr $ra


generate_random_virus_colour:
  # output: v0 = one of VIRUS_RED, VIRUS_BLUE, VIRUS_YELLOW
  # modifies: $v0, $a0, $a1
  li $v0, 42
  li $a0, 0 # Generates random number from 0 to 2 inclusive and stores it in $a0
  li $a1, 3
  syscall

  beq $a0, 0, return_virus_red
  beq $a0, 1, return_virus_yellow
  # otherwise it's 2 so we return BLUE
  lw $v0, VIRUS_BLUE
  j generate_random_colour_return

  return_virus_red:
    lw $v0, VIRUS_RED
    j generate_random_colour_return

  return_virus_yellow:
    lw $v0, VIRUS_YELLOW
    j generate_random_virus_colour_return
  
    
  generate_random_virus_colour_return:
  jr $ra

generate_in_range:
    # Input: $a1 = lower_bound, $a2 = upper_bound
    # Output: $v0 = random number in [lower_bound, upper_bound)
    # modifies: $t0, $v0, $a0, $a1
    PUSH_TO_STACK($ra) # Save return address
    PUSH_TO_STACK($a1) # Save original lower_bound

    sub $t0, $a2, $a1 # $t0 = range_size (upper_bound - lower_bound)
    li $v0, 42 # generate random number to be stored in $a0
    li $a0, 0                
    move $a1, $t0 # Upper limit for random number (range_size)
    syscall # $a0 = random number in [0, range_size - 1]

    POP_FROM_STACK($a1) # Restore original lower_bound
    add $v0, $a0, $a1 # $v0 = random_number + lower_bound
    
    POP_FROM_STACK($ra) 
    jr $ra

# Utils


get_cell_address:
    # given (x,y), return the address of the cell in GRID_STATE
    # Input: $a0 = column/x, $a1 = row/y
    # Output: $v0 = address of cell
    # modifies: $t0, $t1, $t2, $v0
    PUSH_TO_STACK($ra)
    la $t0, GRID_STATE   # base address of grid
    lw $t1, GRID_WIDTH   # Grid width
    # we can use mul since we're not gonna go over 2^32 anyway
    mul $t2, $a1, $t1   # $t2 = row * GRID_WIDTH
    add $t2, $t2, $a0   # $t2 = row * GRID_WIDTH + column
    sll $t2, $t2, 2   # Multiply by 4 (word length)
    add $v0, $t0, $t2   # Base address + offset
    POP_FROM_STACK($ra)
    jr $ra


get_cell_address_relationships:
  # given (x,y), return the address of the cell in GRID_CAPSULE_RELATIONSHIPS array
  # Input: $a0 = column/x, $a1 = row/y
  # Output: $v0 = address of cell
  # modifies: $t0, $t1, $t2, $v0
  PUSH_TO_STACK($ra)
  la $t0, GRID_CAPSULE_RELATIONSHIPS  # base address of capsule relationships array
  lw $t1, GRID_WIDTH   # Grid width
  # we can use mul since we're not gonna go over 2^32 anyway
  mul $t2, $a1, $t1   # $t2 = row * GRID_WIDTH
  add $t2, $t2, $a0   # $t2 = row * GRID_WIDTH + column
  sll $t2, $t2, 2   # Multiply by 4 (word length)
  add $v0, $t0, $t2   # Base address + offset
  POP_FROM_STACK($ra)
  jr $ra

vert_or_horiz:
  # Output: $v0 = 0 if capsule is vertical, 1 if capsule is horizontal
  # since orientation 1 or 3 = horizontal, and 2 or 4 = vertical
  # modifies: $t0, $t1, $t2, $v0
  PUSH_TO_STACK($ra)
  la $t0, CURR_CAPSULE_STATE
  lw $t1, 8($t0) # get the orientation
  li $t2, 2 # load 2 to $t2
  div $t1, $t2
  mfhi $v0
  POP_FROM_STACK($ra)
  jr $ra

is_virus:
  # Given 
  # $a0: value at a cell
  # modifies: $t0, $t1, $t2, $v0
  # Returns: $v0 = 0 if not, 1 if yes
  PUSH_TO_STACK($ra)
  lw $t0, VIRUS_RED
  lw $t1, VIRUS_BLUE
  lw $t2, VIRUS_YELLOW
  li $v0, 0

  beq $t0, $a0, is_virus_true
  beq $t1, $a0, is_virus_true
  beq $t2, $a0, is_virus_true
  j end_is_virus
  
  is_virus_true:
    addi $v0, $v0, 1
  end_is_virus:
  POP_FROM_STACK($ra)
  jr $ra

is_matching_colour:
  # Given
  # $a0: Colour in previous cell
  # $a1: Colour in current cell
  # Returns:
  # $v0 = 0 if the two are considered the same colour, 1 if not
  # *This is necessary because viruses and capsules are slightly different colours, so simply checking equality isn't enough.
  PUSH_TO_STACK($ra)

  # fast track - if they have the same values
  beq $a0, $a1, colours_match
  # Load all color values
  lw $t0, RED
  lw $t1, VIRUS_RED
  lw $t2, BLUE
  lw $t3, VIRUS_BLUE
  lw $t4, YELLOW
  lw $t5, VIRUS_YELLOW

  # WLOG: if $a0 is either of red or virus red, we check if $a1 is also either of red or virus red
  # and if $a1 is, then the colours match

  # Check RED and VIRUS_RED combinations
  beq $a0, $t0, check_reds
  beq $a0, $t1, check_reds

  # Check BLUE and VIRUS_BLUE combinations
  beq $a0, $t2, check_blues
  beq $a0, $t3, check_blues

  # Check YELLOW and VIRUS_YELLOW combinations
  beq $a0, $t4, check_yellows
  beq $a0, $t5, check_yellows

  # i guess $a0 is none of these something is wrong so 💀
  j colours_dont_match

  check_reds:
    beq $a1, $t0, colours_match
    beq $a1, $t1, colours_match
    j colours_dont_match

  check_blues:
    beq $a1, $t2, colours_match
    beq $a1, $t3, colours_match
    j colours_dont_match

  check_yellows:
    beq $a1, $t4, colours_match
    beq $a1, $t5, colours_match
    j colours_dont_match

  colours_match:
    li $v0, 0
    j end_is_matching_colour

  colours_dont_match:
    li $v1, 1
    j end_is_matching_colour

  end_is_matching_colour:
  POP_FROM_STACK($ra)
  jr $ra

get_other_capsule_half:
  # given
  # $a0: x of current capsule half 
  # $a1: y of current capsule half
  # $a2: direction that other capsule half is located in
  # precondition: $a2 != -1
  # returns:
  # $v0: x of other capsule half
  # $v1: y of other capsule half
  # if called improperly, returns -1 for both $v0 and $v1
  PUSH_TO_STACK($ra)
  # possible direction indicators
  la $t0, CAPSULE_HALF_LOCATION
  lw $t1, 0($t0) # above
  lw $t2, 4($t0) # below
  lw $t3, 8($t0) # left 
  lw $t4, 12($t0) # right

  # we need the original x and y coordinates in any case
  move $v0, $a0 
  move $v1, $a1

  beq $a2, $t1, other_capsule_half_above
  beq $a2, $t2, other_capsule_half_below 
  beq $a2, $t3, other_capsule_half_left
  beq $a2, $t4, other_capsule_half_right

  # in any other case, something went wrong, so return both -1
  li $v0, -1 
  li $v1, -1
  j end_get_other_capsule_half

  other_capsule_half_above:
    # decrement y
    subi $v1, $v1, 1
    j end_get_other_capsule_half
  
  other_capsule_half_below:
    # increment y
    addi $v1, $v1, 1
    j end_get_other_capsule_half

  other_capsule_half_left:
    # decrement x
    subi $v0, $v0, 1
    j end_get_other_capsule_half

  other_capsule_half_right:
    # increment x
    addi $v0, $v0, 1
    j end_get_other_capsule_half
    
  end_get_other_capsule_half:
  POP_FROM_STACK($ra)
  jr $ra

# end screens

draw_end_screen:
  # draws the end screen
  PUSH_TO_STACK($ra)
  # G
  li $a0, 3
  li $a1, 9
  li $a2, 4
  lw $a3, RED 
  jal draw_vertical_line

  li $a0, 4
  li $a1, 8
  li $a2, 3
  jal draw_horizontal_line

  li $a0, 4
  li $a1, 13
  li $a2, 3
  jal draw_horizontal_line

  li $a0, 6
  li $a1, 11
  li $a2, 3
  jal draw_vertical_line

  # A 

  li $a0, 9
  li $a1, 8
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 9
  li $a1, 11
  li $a2, 2

  jal draw_horizontal_line

  li $a0, 8
  li $a1, 9
  li $a2, 5 
  jal draw_vertical_line

  li $a0, 11
  li $a1, 9
  li $a2, 5 
  jal draw_vertical_line

  # M
  # left side
  li $a0, 13
  li $a1, 8
  li $a2, 6
  jal draw_vertical_line

  # right side
  li $a0, 17
  li $a1, 8
  li $a2, 6
  jal draw_vertical_line

  # diagonals
  li $a0, 14
  li $a1, 8
  li $a2, 1
  jal draw_vertical_line

  li $a0, 16
  li $a1, 8
  li $a2, 1
  jal draw_vertical_line 

  li $a0, 15
  li $a1, 9
  li $a2, 5
  jal draw_vertical_line


  # E
  li $a0, 19
  li $a1, 8
  li $a2, 6
  jal draw_vertical_line

  li $a0, 20
  li $a1, 8
  li $a2, 3
  jal draw_horizontal_line

  li $a0, 20
  li $a1, 11
  li $a2, 3
  jal draw_horizontal_line

  li $a0, 20
  li $a1, 13
  li $a2, 3
  jal draw_horizontal_line

  # O

  li $a0, 9
  li $a1, 15
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 9
  li $a1, 20
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 8
  li $a1, 16
  li $a2, 4
  jal draw_vertical_line

  li $a0, 11
  li $a1, 16
  li $a2, 4
  jal draw_vertical_line

  # V
  li $a0, 13
  li $a1, 15
  li $a2, 4
  jal draw_vertical_line

  li $a0, 17
  li $a1, 15
  li $a2, 4
  jal draw_vertical_line

  li $a0, 14
  li $a1, 19
  li $a2, 1
  jal draw_vertical_line

  li $a0, 16
  li $a1, 19
  li $a2, 1
  jal draw_vertical_line

  li $a0, 15
  li $a1, 20
  li $a2, 1
  jal draw_vertical_line

  # E
  li $a0, 19
  li $a1, 15
  li $a2, 6
  jal draw_vertical_line

  li $a0, 20
  li $a1, 15
  li $a2, 3
  jal draw_horizontal_line

  li $a0, 20
  li $a1, 18
  li $a2, 3
  jal draw_horizontal_line

  li $a0, 20
  li $a1, 20
  li $a2, 3
  jal draw_horizontal_line

  # R
  li $a0, 24
  li $a1, 15
  li $a2, 6
  jal draw_vertical_line

  li $a0, 25
  li $a1, 15
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 25
  li $a1, 18
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 27
  li $a1, 16
  li $a2, 2
  jal draw_vertical_line

  li $a0, 27
  li $a1, 19
  li $a2, 2
  jal draw_vertical_line

  # "restart" R
  lw $a3, GREEN
  
  li $a0, 3
  li $a1, 23
  li $a2, 6
  jal draw_vertical_line

  li $a0, 4
  li $a1, 23
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 4
  li $a1, 26
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 6
  li $a1, 24
  li $a2, 2
  jal draw_vertical_line

  li $a0, 6
  li $a1, 27
  li $a2, 2
  jal draw_vertical_line

  # quit Q
  lw $a3, BLUE

  li $a0, 25
  li $a1, 23
  li $a2, 3
  jal draw_horizontal_line

  li $a0, 24
  li $a1, 24
  li $a2, 4
  jal draw_vertical_line

  li $a0, 28
  li $a1, 24
  li $a2, 3
  jal draw_vertical_line

  li $a0, 25
  li $a1, 28
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 26
  li $a1, 26
  li $a2, 1
  jal draw_vertical_line

  li $a0, 27
  li $a1, 27
  li $a2, 1
  jal draw_vertical_line

  li $a0, 28
  li $a1, 28
  li $a2, 1
  jal draw_vertical_line

  POP_FROM_STACK($ra)
  jr $ra

draw_win_screen:
  # draws the win screen
  PUSH_TO_STACK($ra)

  lw $a3, YELLOW
  # W 
  li $a0, 5
  li $a1, 8
  li $a2, 6
  jal draw_vertical_line

  li $a0, 8
  li $a1, 8
  li $a2, 6
  jal draw_vertical_line
  
  li $a0, 11
  li $a1, 8
  li $a2, 6
  jal draw_vertical_line

  li $a0, 6
  li $a1, 14
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 9
  li $a1, 14
  li $a2, 2
  jal draw_horizontal_line


  # i 

  li $a0, 15
  li $a1, 10
  li $a2, 1
  jal draw_vertical_line

  li $a0, 15
  li $a1, 12
  li $a2, 3
  jal draw_vertical_line

  # n 

  li $a0, 19
  li $a1, 11
  li $a2, 4
  jal draw_vertical_line

  li $a0, 20
  li $a1, 12
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 22
  li $a1, 12
  li $a2, 3
  jal draw_vertical_line

  # !

  li $a0, 26
  li $a1, 8
  li $a2, 5
  jal draw_vertical_line

  li $a0, 26
  li $a1, 14
  li $a2, 1
  jal draw_vertical_line

  # "restart" R
  lw $a3, GREEN
  
  li $a0, 3
  li $a1, 23
  li $a2, 6
  jal draw_vertical_line

  li $a0, 4
  li $a1, 23
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 4
  li $a1, 26
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 6
  li $a1, 24
  li $a2, 2
  jal draw_vertical_line

  li $a0, 6
  li $a1, 27
  li $a2, 2
  jal draw_vertical_line

  # quit Q
  lw $a3, BLUE

  li $a0, 25
  li $a1, 23
  li $a2, 3
  jal draw_horizontal_line

  li $a0, 24
  li $a1, 24
  li $a2, 4
  jal draw_vertical_line

  li $a0, 28
  li $a1, 24
  li $a2, 3
  jal draw_vertical_line

  li $a0, 25
  li $a1, 28
  li $a2, 2
  jal draw_horizontal_line

  li $a0, 26
  li $a1, 26
  li $a2, 1
  jal draw_vertical_line

  li $a0, 27
  li $a1, 27
  li $a2, 1
  jal draw_vertical_line

  li $a0, 28
  li $a1, 28
  li $a2, 1
  jal draw_vertical_line

  POP_FROM_STACK($ra)
  jr $ra