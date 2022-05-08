*-----------------------------------------------------------
* Title      : BulletHail
* Written by : Thomas Wilson
* Date       : 9/27/2021
* Description: Assignment 3 - Interactive Assembly Project
* This is a game where you play as Santa Claus doing a 
* test flight for his sleigh to prepare for Christmas.
* While doing the test flight, a hailstorm occurs! Survive as
* long as you can before you get hit!
* 
* Includes files: bitmapRender.x68, scoreBanner.x68, hailManager.x68,
*                  playerManager.x68, GameOver.bmp, GameStart.bmp, Loading.bmp
*
* Requirements Locations:
* 1. User input control - playerManager.x68, handleInput function
* 2. Bitmap background - scoreBanner.x68, scoreUpdate function
* 3. Physics update - hailManager.x68, renderBullets function
* 4. Fixed point math - hailManager.x68, renderBullets function
* 5. Collision detection - hailManager.x68, collisionCheck function
* 6. 7-segment display - scoreBanner.x68, scoreUpdate function
* 7. Randomness - hailManager.x68, initBullet function
*-----------------------------------------------------------

*Drawing Macros
DRAWING_MODE_TRAP_CODE  EQU     92
SWAP_BUFFER_TRAP_CODE   EQU     94
ENABLE_DOUBLE_BUFFERING EQU     17
SET_OUTPUT_RES_TRAP_CODE        EQU     33
OUTPUT_RESOLUTION       EQU     $028001E0   ; Output resolution is 640x580
COLOR_BLACK             EQU     0
COLOR_WHITE             EQU     $00FFFFFF
DRAW_RECT_TRAP_CODE     EQU     87
FILL_COLOR_TRAP_CODE    EQU     81

READ_KEYBOARD_TRAP_CODE EQU     19
R_KEY_SPECIFIER         EQU     'R'
CLEAR_SCREEN_TRAP_CODE  EQU     11

GAME_UPDATE_COUNT       EQU     2

START   ORG $1000                 
        move.l  #OUTPUT_RESOLUTION,d1           ;Sets output window to 640x580 resolution.
        move.l  #SET_OUTPUT_RES_TRAP_CODE,d0
        trap    #15
        
        move.l  #ENABLE_DOUBLE_BUFFERING,d1     ;Enables double buffering
        move.l  #DRAWING_MODE_TRAP_CODE,d0
        trap    #15
        
        lea gameLoading,a0
        move.l  #0,d0
        move.l  #0,d1
        move.l  #200,d2
        move.l  #100,d3
        move.l  #220,d4
        move.l  #200,d5
        jsr drawBitmap
        move.l  #SWAP_BUFFER_TRAP_CODE,d0
        trap #15
        
        lea gameStartScreen,a0
        move.l  #0,d0
        move.l  #0,d1
        move.l  #640,d2
        move.l  #580,d3
        move.l  #0,d4
        move.l  #0,d5
        jsr drawBitmap
        move.l  #SWAP_BUFFER_TRAP_CODE,d0
        trap #15
gameStart                                       ; Waits for 'R' to be pressed for restart
        move.l  #READ_KEYBOARD_TRAP_CODE,d0
        move.l  #R_KEY_SPECIFIER,d1
        trap    #15
        
        cmp.l   #$000000FF,d1
        bne     gameStart        
gameLoad                                        ; Initalizes score, player position, and bullets
        move.l  #CLEAR_SCREEN_TRAP_CODE,d0
        move.l  #$0000FF00,d1
        trap    #15
        jsr initScore
        jsr initPlayer
        jsr clearBullets
gameLoop                                        ; Looks for player input, spawns bullets
        move.l  #SWAP_BUFFER_TRAP_CODE,d0
        trap #15
        jsr handleInput
        jsr initBullet
        
renderGameLoop                                  ; Draws player, score, bullets, checks collisions
        jsr renderPlayer
        jsr scoreUpdate
        jsr collisionCheck
        jsr renderBullets
        
        cmpi.l  #1,d0                           ; If there's been a collision, the game ends
        bne gameLoop
gameOver                                        ; Clears screen for restart prompt      
        jsr setPenFillBlack
        move.l  #0,d1
        move.l  #100,d2
        move.l  #640,d3
        move.l  #580,d4
        move.l  #DRAW_RECT_TRAP_CODE,d0
        trap #15
        
        move.l  #SWAP_BUFFER_TRAP_CODE,d0
        trap #15
        
        lea gameEndScreen,a0
        move.l  #0,d0
        move.l  #0,d1
        move.l  #400,d2
        move.l  #200,d3
        move.l  #120,d4
        move.l  #200,d5
        jsr drawBitmap
        move.l  #SWAP_BUFFER_TRAP_CODE,d0
        trap #15
restartPrompt                                   ; Waits for 'R' to be pressed for restart
        move.l  #READ_KEYBOARD_TRAP_CODE,d0
        move.l  #R_KEY_SPECIFIER,d1
        trap    #15
        
        cmp.l   #$000000FF,d1
        beq     gameLoad
        bne     restartPrompt
        
        SIMHALT             ; halt simulator
        STOP #$2000
bitmapDraw INCLUDE "bitmapRender.x68"
score      INCLUDE "scoreBanner.x68"
bullet     INCLUDE "hailManager.x68"
player     INCLUDE "playerManager.x68"

gameEndScreen   INCBIN "GameOver.bmp"
gameStartScreen INCBIN "GameStart.bmp"
gameLoading     INCBIN "Loading.bmp"

    END    START        ; last line of source









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
