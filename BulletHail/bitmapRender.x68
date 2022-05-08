*-----------------------------------------------------------
* Program Number: Programming 2
* Written by    : Thomas Wilson
* Date Created  : 9/27/2021
* Description   : Assignment 3 - Interactive Assembly Project
* This program contains functionality for displaying
* sections of a bitmap file. It utilizes a subroutine that 
* takes arguments for a pointer to the bitmap file and the
* arguments for the subsection to display. The program
* currently works for 32-bit bitmaps, but not for 24-bit
* bitmaps. It can display at 1920x1080 resolution, and returns
* an error if the bitmap is larger than those bounds. If an error is
* encountered, an error message will be displayed and the user
* will have to restart the program. It is up to the user to ensure that 
* the chunk they want displayed has proper bounds, as entering dimensions
* that go beyond the bitmap data could have unexpected results.
*-----------------------------------------------------------

ALL_REG         REG     D0-D7/A0-A6

*Offsets for various parts of bitmap information
BITMAP_DATA_START       EQU     10
BITMAP_SIZE             EQU     02
BITMAP_WIDTH            EQU     18
BITMAP_HEIGHT           EQU     22
BITMAP_BIT_DEPTH        EQU     28

*Offsets for referencing values placed on the stack
CHUNK_X         EQU     0
CHUNK_Y         EQU     4
CHUNK_WIDTH     EQU     8
CHUNK_HEIGHT    EQU     12
DISPLAY_X       EQU     16
DISPLAY_Y       EQU     20
BITMAP_POINTER  EQU     32

*Trap codes for drawing bitmap
PEN_COLOR_TRAP_CODE     EQU     80
DRAW_PIXEL_TRAP_CODE    EQU     82


* Loads the various parameters to be used into registers
* a0 - Pointer to the bitmap file
* a1 - Error string if needed
* a2 - Location of bitmap data start
* d0 - File type for error check
* d3 - Size of the bitmap file
* d5 - Bitmap height in pixels
* d6 - Pixel depth of bitmap
* d7 - Bitmap width in pixels (saved in d7 because it is used in next part)
drawBitmap
        movem.l ALL_REG, -(sp)          ; Stores argument registers on the stack to reference later
        move.l  BITMAP_POINTER(sp),a0
        move.l  BITMAP_DATA_START(a0),d2
        move.l  BITMAP_SIZE(a0),d3
        move.l  BITMAP_WIDTH(a0),d7
        move.l  BITMAP_HEIGHT(a0),d5
        move.l  BITMAP_BIT_DEPTH(a0),d6
   
* All bitmap files have 0x424D as the first 2 bytes of data in the header file.     
* If the first 2 bytes do not equal 0x424D, then the file is not a bitmap file and
* the user will have to restart the program.
        lea     fileError,a1
        move.w  (a0),d0
        cmpi.   #$424D,d0
        bne     errorHandler       
 
*The bitmap data is stored in little endian format, so the next
*instructions convert the data to a more readable big endian format.
        rol.w   #8,d2
        swap.w  d2
        rol.w   #8,d2
        move.l  d2,a2
        adda.l  a0,a2   ;a2 is now pointed at the start of the bitmap pixel data.

        rol.w   #8,d3   ;Swaps for the size of the bitmap
        swap.w  d3
        rol.w   #8,d3
        
        rol.w   #8,d7   ;Swaps for the width of the bitmap
        swap.w  d7
        rol.w   #8,d7
        
        rol.w   #8,d5   ;Swaps for the height of the bitmap
        swap.w  d5
        rol.w   #8,d5
        
        rol.w   #8,d6   ;Swaps for the bit depth of the bitmap
        swap.w  d6
        rol.w   #8,d6
        
*Checks that bitmap is 32-bit, prints error message if not
        lea     sizeError,a1
        cmpi.l  #32,d6
        bne     errorHandler
        
        move.l  d5,d0   ;Moves bitmap height into d0 to use for calculating offset into bitmap data
        
* This is where registers are initalized to begin drawing the bitmap chunk
* a2 - Current location in bitmap pixel data
* d0 - Bitmap height in pixels, then trap code specifier
* d1 - Top Left X of bitmap chunk, trap code register
* d2 - Top Left Y of bitmap chunk, trap code register
* d3 - Top Left X of display location
* d4 - Height of bitmap chunk, then upper bound of Y coordinate loop
* d5 - Width of bitmap chunk, then upper bound of X coordinate loop
* d6 - Top Left Y of display location
* d7 - Bitmap width in pixels
        move.l  CHUNK_X(sp),d1
        move.l  CHUNK_Y(sp),d2
        move.l  DISPLAY_X(sp),d3
        move.l  DISPLAY_Y(sp),d6
        move.l  CHUNK_WIDTH(sp),d5
        move.l  CHUNK_HEIGHT(sp),d4
        
* It first has to be determined where in the data the chunk begins, so the offset has to be calculated.
* Offset into bitmap data = Beginning of data address + 4*(CHUNK_X +(BITMAP_WIDTH*(BITMAP_HEIGHT-CHUNK_Y-CHUNK_HEIGHT)))
        sub.l   d4,d0
        sub.l   d2,d0
        mulu    d7,d0
        add.l   d1,d0
        lsl.l   #2,d0
        adda.l  d0,a2
        
* Get upper bounds for X and Y by adding display coordinates to chunk height and width
        add.l   d6,d4
        add.l   d3,d5
        
* The bitmap pixel data does not need to be swapped like the data in the header because
* the colors are already lined up for the trap code argument.
        move.l  (a2)+,d1        
        lsr.l   #8,d1           ; The pixel data is left-shifted by 8 bits to organize the hex color codes
                                ; for the trap code and ignore the alpha value.
        move.l  #PEN_COLOR_TRAP_CODE,d0
        trap    #15
        
        move.l  d3,d1
        move.l  d4,d2
        move.l  #DRAW_PIXEL_TRAP_CODE,d0
       
* This is the loop that draws each row of the chunk. It will grab the pixel data,
* set the pen color, then set up the coordinates for the pixel to be drawn at.
* It will always draw the pixel at the beginning of the next loop.
drawRow:
        trap    #15
        move.l  (a2)+,d1
        lsr.l   #8,d1                   
        move.l  #PEN_COLOR_TRAP_CODE,d0
        trap    #15
        move.l  #DRAW_PIXEL_TRAP_CODE,d0
        
        addi.l  #1,d3
        move.l  d3,d1
        cmp.l   d3,d5
        bne drawRow
* If the end of the row is reached, increment the column to draw the next row
* When moving to next row, increment data offset by 4*(BITMAP_WIDTH - CHUNK_WIDTH)
        move.l  d7,d3
        sub.l   CHUNK_WIDTH(sp),d3
        lsl.l   #2,d3
        adda.l  d3,a2
        move.l  DISPLAY_X(sp),d3
        move.l  d3,d1
        
        subi.l  #1,d4 ;The Y coordinate is decremented instead of incremented because the bitmap
                      ;stores information from the bottom of the image, so if it were incremented
                      ;the image would display upside down.
        move.l  d4,d2
        cmp.l   d6,d4
        bne drawRow
        movem.l (sp)+,ALL_REG
        rts
        
*Prints the error message that was loaded into a1 before call and exits program.
errorHandler:
        move.l  #13,d0
        trap #15  
        movem.l (sp)+,ALL_REG
        rts

sizeError       dc.b 'Error: this is not a 32-bit bitmap. Please try a different bitmap and restart program.',0
fileError       dc.b 'Error: the file entered is not a bitmap file. Please use a bitmap file and restart the program.',0





















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
