*-----------------------------------------------------------
* Title      : playerManager
* Written by : Thomas Wilson
* Date       : 9/27/2021
* Description: This program manages the player in the game,
* represented by Santa's red sleigh. It handles input from
* the keyboard and rendering the player character on screen.
*-----------------------------------------------------------

*Trap code inputs
MOVEMENT_KEYBOARD_SPECIFIER     EQU     'W'<<24+'A'<<16+'S'<<8+'D'

MOVE_SPEED  EQU 10
NEG_MOVE_SPEED  EQU -10
PLAYER_WIDTH    EQU 25
PLAYER_HEIGHT   EQU 21

* Puts player into starting position
initPlayer
    move.l  #200,(playerX)
    move.l  #300,(playerY)
    rts

* Checks for input from the keyboard to update player position
* d0 - Trap code for reading keyboard
* d1 - Bitmask value for keyboard specifier
* d4 - Player Left X coordinate
* d5 - Player Top Y coordinate
handleInput
    move.l  (playerX),d4
    move.l  (playerY),d5
    move.l  #MOVEMENT_KEYBOARD_SPECIFIER,d1
    move.l  #READ_KEYBOARD_TRAP_CODE,d0
    trap #15
    
    cmp.l   #$00FF0000,d1           ; Checks d1 value to see if any keys are pressed
    beq     moveLeft
    cmp.l   #$000000FF,d1
    beq     moveRight
    cmp.l   #$FF000000,d1
    beq     moveUp
    cmp.l   #$0000FF00,d1
    beq     moveDown
    bne     moveDone                ; If no keys pressed, player doesn't move
    
moveLeft
    addi.l  #NEG_MOVE_SPEED,d4      ; If 'A', move player left
    cmpi.l  #5,d4
    bge     moveDone
    move.l  #5,d4                   ; Stops player at edge of screen
    rts
moveRight
    addi.l  #MOVE_SPEED,d4          ; If 'D', move player right
    cmpi.l  #610,d4
    ble     moveDone
    move.l  #610,d4                 ; Stops player at edge of screen
    rts
moveUp
    addi.l  #NEG_MOVE_SPEED,d5      ; If 'W', move player up
    cmpi.l  #105,d5
    bge     moveDone
    move.l  #105,d5                 ; Stops player at edge of screen
    rts
moveDown
    addi.l  #MOVE_SPEED,d5          ; If 'S', move player down
    cmpi.l  #450,d5
    ble     moveDone
    move.l  #450,d5                 ; Stops player at edge of screen
moveDone
    move.l  d4,(playerX)            ; Store updated positions
    move.l  d5,(playerY)
    rts
    
    
* Draws the player at a specific position
* d0 - Trap code for reading keyboard
* d1 - Player Left X coordinate, Trap code argument
* d2 - Player Top Y coordinate
* d3 - Player Right X coordinate
* d4 - Player Bottom Y coordinate
* d5 - Player Top Y coordinate
* d6 - Player Left X coordinate    
renderPlayer
    move.l  #COLOR_BLACK,d1
    move.l  #PEN_COLOR_TRAP_CODE,d0
    trap    #15
    move.l  #FILL_COLOR_TRAP_CODE,d0
    trap    #15                     ; Sets pen and fill color to black
    
    move.l  (playerX),d6            ; Grabs player's current coordinates
    move.l  (playerY),d5

    jsr getPlayerCoord
    addi.l  #MOVE_SPEED,d3
    addi.l  #MOVE_SPEED,d4
    addi.l  #NEG_MOVE_SPEED,d1
    addi.l  #NEG_MOVE_SPEED,d2
    move.l  #DRAW_RECT_TRAP_CODE,d0
    trap    #15                     ; Draws black rectangle at old position of player,
                                    ; removing old player drawing
    move.l  d6,d4
    lea     playerBitmap,a0
    move.l  #0,d0
    move.l  #0,d1
    move.l  #PLAYER_WIDTH,d2
    move.l  #PLAYER_HEIGHT,d3        
    jsr drawBitmap                  ; Draws bitmap of player at new position
    
    rts
    
* Gets player coordinates and stores them in d1-d4
* d1 - Player Left X coordinate
* d2 - Player Top Y coordinate
* d3 - Player Right X coordinate
* d4 - Player Bottom Y coordinate
getPlayerCoord
    move.l  (playerX),d1
    move.l  (playerY),d2
    move.l  d1,d3
    move.l  d2,d4
    addi.l  #PLAYER_WIDTH,d3
    addi.l  #PLAYER_HEIGHT,d4
    rts

playerBitmap  INCBIN "Santa.bmp"    ; Bitmap of player
playerX     dc.l    200             ; Player Left X coordinate
playerY     dc.l    300             ; Player Top Y coordinate


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
