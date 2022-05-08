*-----------------------------------------------------------
* Title      : hailManager
* Written by : Thomas Wilson
* Date       : 9/27/2021
* Description: This program handles the bullets (hail) that
* the player has to dodge in the game. It handles collision
* between the player and the bullets, the physics attached 
* to each bullet, and managing the randomness of where the 
* bullets spawn on screen.
*-----------------------------------------------------------

DRAW_CIRCLE_TRAP_CODE EQU 88
BULLET_RADIUS   EQU 5
SCREEN_TOP      EQU 420     ; 105 in fixed point
SCREEN_BOTTOM   EQU 2320    ; 580 in fixed point
SPAWN_TIME_MAX  EQU 3

*Physics
INT_VELOCITY    EQU 12      ; 3 pixels/frame in fixed point
ACCELERATION    EQU 5       ; 1.25 pixels/frame in fixed point

* Clears bullet arrays to reset bullets on game start/restart
* a0 - Bullet X Coordinates
* a1 - Bullet Y Coordinates
* a2 - Bullet Velocity
* d5 - Bullet position checker
* d7 - Offset into bullet array
clearBullets
    lea bulletsX1,a0
    lea bulletsY1,a1
    lea bulletVelocity,a2
    move.l  #0,d7
    move.l  (numBullets),d5
clearLoop                   ; Moves 0 into each array value, clearing the bullets
    move.l  #0,(a0,d7)
    move.l  #0,(a1,d7)
    move.l  #0,(a2,d7)
    addi.l  #4,d7
    cmp.l   d5,d7
    blt     clearLoop
    rts
    
* Initializes a bullet at a random location at top of screen
* a0 - Bullet X Coordinates
* a1 - Bullet Y Coordinates
* a2 - Bullet Velocity
* d0 - Return value, total bullets
* d1 - Player Left X
* d2 - Player Top Y
* d3 - Player Right X
* d4 - Bullet Spawn Time
* d5 - Bullet position checker
* d7 - Offset into bullet array
initBullet
    movem.l ALL_REG, -(sp)
    move.l  (bulletSpawnTime),d4
    cmpi.l  #0,d4                               ; If it isn't time to spawn a new bullet, exits function
    bne initDone
    move.l  #SPAWN_TIME_MAX,(bulletSpawnTime)
    
    jsr findOpenBullet                          ; Loads open bullet offset into d7
    lea     bulletsY1,a1
    lea     bulletVelocity,a2
    jsr     getRandomWord                       ; Generates random word value
    move.w  (a3),d3
    divu    #620,d3
    clr.w   d3
    swap    d3
    addi.l  #10,d3                              ; Confines random value between 10 and 630 for bullet X coordinate
    lsl.l   #2,d3
    move.l  d3,(a0,d7)                          ; Bullet is created with random X coordinate, Y at top of screen,
    move.l  #SCREEN_TOP,(a1,d7)                 ; and initial velocity of 3 pixels/frame
    move.l  #INT_VELOCITY,(a2,d7)
initDone
    subi.l  #1,(bulletSpawnTime)
    movem.l (sp)+,ALL_REG
    rts
    
    
* Finds the next spot in the array that doesn't have a bullet
findOpenBullet
    move.l  #0,d7
    move.l  (numBullets),d5
    lea     bulletsX1,a0
openLoop
    move.l  (a0,d7),d6
    cmpi.l  #0,d6
    beq     openDone
    addi.l  #4,d7
    cmp.l   d5,d7
    bge     initDone
    blt     openLoop
openDone
    rts
    
* Sets pen and fill color to black
setPenFillBlack
    move.l  #COLOR_BLACK,d1
    move.l  #FILL_COLOR_TRAP_CODE,d0
    trap    #15
    move.l  #PEN_COLOR_TRAP_CODE,d0
    trap    #15
    rts  

* Sets pen and fill color to white
setPenFillWhite
    move.l  #COLOR_WHITE,d1
    move.l  #FILL_COLOR_TRAP_CODE,d0
    trap    #15
    move.l  #PEN_COLOR_TRAP_CODE,d0
    trap    #15
    rts
       
* Renders all active bullets specified in the arrays
* a0 - Bullet X Coordinates
* a1 - Bullet Y Coordinates
* a2 - Bullet Velocity
* d0 - Trap Code specifier
* d1 - Player Left X, Trap code argument
* d2 - Player Top Y
* d3 - Player Right X
* d4 - Player Bottom Y
* d5 - Bullet position checker
* d6 - Saves d1 value to replace trap code argument
* d7 - Offset into bullet array
renderBullets
    movem.l ALL_REG, -(sp)
    move.l  #0,d7
    lea     bulletsX1,a0
    lea     bulletsY1,a1
    lea     bulletVelocity,a2
    move.l  (numBullets),d5
renderLoop
    move.l  (a0,d7),d1                  ; If bullet X coordinate is 0, the bullet doesn't exist
    beq     skipRender                  ; and it moves on to the next bullet in the array
    
    lsr.l   #2,d1                       ; Right shift to get rid of fixed point for position drawing
    move.l  d1,d6     
    move.l  (a1,d7),d2
    lsr.l   #2,d2
    move.l  d1,d3
    addi.l  #BULLET_RADIUS,d3
    move.l  d2,d4
    addi.l  #BULLET_RADIUS,d4
    jsr setPenFillBlack                 ; Draw black circle at old bullet position to get rid of old bullet
    move.l  #DRAW_CIRCLE_TRAP_CODE,d0
    move.l  d6,d1
    trap #15
    jsr setPenFillWhite
    move.l  #DRAW_CIRCLE_TRAP_CODE,d0
    move.l  d6,d1
    lsl.l   #2,d2                       ; Left shift to prepare for fixed point velocity addition
    add.l   (a2,d7),d2                  ; Apply velocity to bullet Y coordinates
    move.l  d2,(a1,d7)
    lsl.l   #2,d4
    add.l   (a2,d7),d4
    addi.l  #ACCELERATION,(a2,d7)       ; Increment velocity by fixed point acceleration amount
    lsr.l   #2,d4                       ; Right shift to get rid of fixed point for position drawing 
    lsr.l   #2,d2
    trap #15                            ; Draw white circle at new bullet position
    cmpi.l  #SCREEN_BOTTOM,d2           ; If bullet reaches bottom of screen, delete bullet from array
    blt     skipRender
deleteBullet
    move.l  #0,(a0,d7)
    move.l  #0,(a1,d7)
    move.l  #0,(a2,d7)
skipRender
    addi.l  #4,d7
    cmp.l   d5,d7                       ; If bullet offset equals numBullets, all bullets have been dealt with
    blt     renderLoop
renderDone
    movem.l (sp)+,ALL_REG
    rts
    
    
    
* Checks all bullets to see if collision with player occurs
* a0 - Bullet X Coordinates
* a1 - Bullet Y Coordinates
* d0 - Return value, total bullets
* d1 - Player Left X
* d2 - Player Top Y
* d3 - Player Right X
* d4 - Player Bottom Y
* d5 - Bullet position checker
* d7 - Offset into bullet array
collisionCheck
    jsr     getPlayerCoord              ; Loads player coordinates into d1-d4
    move.l  (numBullets),d0
    move.l  #0,d7
    lea     bulletsX1,a0
    lea     bulletsY1,a1
collisionLoop
    move.l  (a0,d7),d5
    lsr.l   #2,d5                       ; Right shift to get rid of fixed point
    cmpi.l  #0,d5                       ; If bullet X coordinate is 0, the bullet doesn't exist
    beq     noCollision                 ; and it moves on to the next bullet in the array
    cmp.l   d3,d5                       ; If bullet left X is greater than player right X, no collision
    bgt     noCollision
    addi.l  #BULLET_RADIUS,d5
    cmp.l   d1,d5                       ; If bullet right X is less than player left X, no collision
    blt     noCollision
    move.l  (a1,d7),d5
    lsr.l   #2,d5                       ; Right shift to get rid of fixed point
    cmp.l   d4,d5                       ; If bullet top Y is greater than player bottom Y, no collision
    bgt     noCollision
    addi.l  #BULLET_RADIUS,d5
    cmp.l   d2,d5                       ; If bullet bottom Y is less than player top Y, no collision
    blt     noCollision
    move.l  #1,d0                       ; If all checks passed, stores 1 into d0 and returns, signifying collision
    rts      
noCollision
    addi.l  #4,d7                       ; If all bullets checked with no collision, stores 0 into d0
    cmp.l   d0,d7
    blt     collisionLoop
    move.l  #0,d0
    rts
    
; Random number generator gotten from Utsab who got it from the web.
getRandomWord
	movem.l	D0-D7,-(sp)		;save off regs
	lea	RANDOMVAL,a3
	move.l	(a3),d0			;get current seed longword
	move.l	#$AF-$100,d1		;set EOR value
	move.l	#18,d2			;do this 19 times
keepLooping
	add.l	d0,d0			;shift left 1 bit
	bcc.s	doneLooping		;if bit not set skip feedback

	eor.w	d1,d0			;do Galois LFSR feedback
doneLooping
	dbf	d2,keepLooping		;loop

	MOVE.l	d0,(a3)			;save back to seed longword


	movem.l	(sp)+,D0-D7		;restore regs
	RTS

numBullets  dc.l    80                                          ; Set to four times the actual numBullets for the offset in findOpenBullet.
bulletsX1   dc.l    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; These arrays contain coordinate information for each possible bullet.
bulletsY1   dc.l    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0     ; All bullets are 5x5 pixels, so we don't need tables for X2 and Y2.
bulletVelocity  dc.l    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 ; Contains the current velocity of each bullet.
bulletSpawnTime dc.l    0                                       ; Variable for bullet spawn time
RANDOMVAL   ds.l    1                                           ; Stores random value generated by getRandomWord



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
