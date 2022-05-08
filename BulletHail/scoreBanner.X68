*-----------------------------------------------------------
* Title      : scoreBanner
* Written by : Thomas Wilson
* Date       : 9/27/2021
* Description: This program handles the score for the game
* BulletHail. It utilizes a seven segment display for the 
* score that continuously increments the longer the player
* survives. If the score number uses a certain score segment,
* a white rectangle will be drawn at the location of the
* segment. Otherwise, the bitmap background will be drawn
* there instead.
*-----------------------------------------------------------

* Score Chunk Location
SCORE_X         EQU 495
SCORE_Y         EQU 9
SCORE_WIDTH     EQU 136
SCORE_HEIGHT    EQU 82
UPDATE_COUNT_MAX    EQU 3
INCREMENT_COUNT     EQU 15
Padding    dc.b    1            ; Needed to keep functions on even byte address

* Initalizes banner at top of the screen and sets score to 0
initScore
    move.l  #0,(onesScore)
    move.l  #0,(tensScore)
    lea scoreBanner,a0
    move.l  #0,d0
    move.l  #0,d1
    move.l  #640,d2
    move.l  #100,d3
    move.l  #0,d4
    move.l  #0,d5
    jsr drawBitmap
    rts

* Draws the score value over a chunk of the top banner
* a0 - Pointer to the background bitmap file
* a1 - Address for X1 coordinates table
* a2 - Address for Y1 coordinates table
* a3 - Address for X2 coordinates table
* a4 - Address for Y2 coordinates table
* a5 - Address for bitmask table
* a6 - Address for segment function pointer table
* d0 - Trap code register
* d1 - Trap code argument, X1
* d2 - Trap code argument, Y1
* d3 - Trap code argument, X2
* d4 - Trap code argument, Y2
* d5 - Current score to be displayed
* d6 - Bitmask for score digit
* d7 - Counter for iterating through segments
scoreUpdate
    movem.l ALL_REG, -(sp)
    cmpi.l  #0,(updateCount)
    bgt scoreSkip
    
    move.l  #UPDATE_COUNT_MAX,(updateCount)
    lea scoreBanner,a0                      ;Redraws background chunk over score position.
    move.l  #SCORE_X,d0
    move.l  #SCORE_Y,d1
    move.l  #SCORE_WIDTH,d2
    move.l  #SCORE_HEIGHT,d3
    move.l  #SCORE_X,d4
    move.l  #SCORE_Y,d5
    jsr drawBitmap
    
    move.l  #COLOR_WHITE,d1                 ;Initializes pen parameters to prepare to draw segments
    move.l  #FILL_COLOR_TRAP_CODE,d0
    trap    #15
    move.l  #PEN_COLOR_TRAP_CODE,d0
    trap    #15
    move.l  #DRAW_RECT_TRAP_CODE,d0
onesSegmentPrep
    
    lea     onesSegmentX1,a1                ;Loads addresses of coordinate tables
    lea     onesSegmentY1,a2
    lea     onesSegmentX2,a3
    lea     onesSegmentY2,a4
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    
    lea     digitBitmask,a5                 ;Gets bitmask for score value
    move.l  (onesScore),d5
    move.b  (a5,d5),d6
    clr.l   d7
    move.l  #24,d7
    jsr     segmentDrawLoop
    cmpi.l  #INCREMENT_COUNT,(incrementCount)
    bne     skipScoreIncrement
    addi.l  #1,d5
    move.l  #0,(incrementCount)
skipScoreIncrement
    addi.l  #1,(incrementCount)
    cmp.l   #10,d5
    blt     tensSegmentPrep
    move.l  (tensScore),d6
    addi.l  #1,d6
    move.l  d6,(tensScore)
    move.l  #0,d5
    
tensSegmentPrep
    move.l  d5,(onesScore)
    lea     tensSegmentX1,a1                ;Loads addresses of coordinate tables
    lea     tensSegmentY1,a2
    lea     tensSegmentX2,a3
    lea     tensSegmentY2,a4
    move.l  #0,d1
    move.l  #0,d2
    move.l  #0,d3
    move.l  #0,d4
    move.l  #0,d5
    
    lea     digitBitmask,a5                 ;Gets bitmask for score value
    move.l  (tensScore),d5
    move.b  (a5,d5),d6
    clr.l   d7
    move.l  #24,d7
    jsr     segmentDrawLoop
    cmp.l   #10,d5
    blt     scoreReturn
    move.l  #0,d5
    
scoreReturn
    move.l  d5,(tensScore)
    movem.l (sp)+,ALL_REG
    rts
    
segmentDrawLoop
    move.b  d6,d1
    and.b   #1,d1
    beq     skipDraw
    
    move.l  #0,d1
    move.l  #0,d2
    move.l  #0,d3
    move.l  #0,d4
    lea     segFuncPtr,a6                   ;Grabs the function pointer for the segment to draw
    move.l  (a6,d7),a6
    jsr     (a6)
    
skipDraw
    lsr.b   #1,d6
    subi.l  #4,d7
    cmpi.l  #0,d7
    bge segmentDrawLoop  
scoreDone
    subi.l  #1,(updateCount)
    rts
scoreSkip
    subi.l  #1,(updateCount)
    movem.l (sp)+,ALL_REG
    rts


* These next functions draw the various segments of the display
* Different offsets into the arrays load different coordinates for the segments    
drawSegA
    move.w  (a1),d1
    move.w  (a3),d3
    move.w  (a2),d2
    move.w  (a4),d4
    trap    #15
    rts
    
drawSegB
    move.w  2(a1),d1
    move.w  2(a3),d3
    move.w  2(a2),d2
    move.w  2(a4),d4
    trap    #15
    rts
    
drawSegC
    move.w  4(a1),d1
    move.w  4(a3),d3
    move.w  4(a2),d2
    move.w  4(a4),d4
    trap    #15
    rts
    
drawSegD
    move.w  6(a1),d1
    move.w  6(a3),d3
    move.w  6(a2),d2
    move.w  6(a4),d4
    trap    #15
    rts
    
drawSegE
    move.w  8(a1),d1
    move.w  8(a3),d3
    move.w  8(a2),d2
    move.w  8(a4),d4
    trap    #15
    rts
    
drawSegF
    move.w  10(a1),d1
    move.w  10(a3),d3
    move.w  10(a2),d2
    move.w  10(a4),d4
    trap    #15
    rts
    
drawSegG
    move.w  12(a1),d1
    move.w  12(a3),d3
    move.w  12(a2),d2
    move.w  12(a4),d4
    trap    #15
    rts

scoreBanner INCBIN "ScoreBackground.bmp"
onesScore       dc.l    0
tensScore       dc.l    0
updateCount     dc.l    0
incrementCount  dc.l    0
digitBitmask    dc.b    $7E,$30,$6D,$79,$33,$5B,$5F,$70,$7F,$7B ;Bitmasks for digits 0-9 for seven segment display
segFuncPtr      dc.l    drawSegA,drawSegB,drawSegC,drawSegD,drawSegE,drawSegF,drawSegG
onesSegmentX1   dc.w    590,620,620,590,590,590,590 ;Holds rectangle coordinates for each segment A-G, stored in long format where first word is Top left X, second word is bottom right X.
onesSegmentY1   dc.w    10,10,50,80,50,10,45 ;Same as previous array, but for Y coordinates.
onesSegmentX2   dc.w    630,630,630,630,600,600,630
onesSegmentY2   dc.w    20,50,90,90,90,50,55
tensSegmentX1   dc.w    540,570,570,540,540,540,540 ;Holds rectangle coordinates for each segment A-G, stored in long format where first word is Top left X, second word is bottom right X.
tensSegmentY1   dc.w    10,10,50,80,50,10,45 ;Same as previous array, but for Y coordinates.
tensSegmentX2   dc.w    580,580,580,580,550,550,580
tensSegmentY2   dc.w    20,50,90,90,90,50,55










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
