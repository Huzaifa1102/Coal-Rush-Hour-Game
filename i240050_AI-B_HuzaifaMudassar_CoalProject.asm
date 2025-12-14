INCLUDE Irvine32.inc
INCLUDELIB winmm.lib ;links windows sounds
PlaySound PROTO STDCALL :ptr byte, : dword, :dword ;3 parameters
SND_ASYNC equ 1h ;asynchronous sounds
SND_FILENAME equ 20000h

.data
;35 x 70 grid
rows equ 35 ;35 rows
cols equ 70 ;70 columns

;sound effects for pickup, dropoff, crashing, and winnning
crashsnd byte "crash.wav", 0
picksnd byte "pickup.wav", 0
dropsnd byte "drop.wav", 0
winsnd byte "win.wav", 0
oversnd byte "over.wav", 0

;main player car
currX word 2 ;initially set to row 2 col 2
currY word 2
prevX word 2
prevY word 2
carcolor dword 4 ;red
carspeed dword 0 ;taxi speed based on color ;yellow has fast, red has 20
picked byte 0 ;carrying passenger or not

;timer
tremain dword 60 ;1 minute game
lastupdate dword 0 ;last timer update

;leaderboard
filename byte "leaderboard.txt", 0 ;high scores file
fhandle handle ? ;open file
scores dword 10 dup(0) ;top 10 scores
currrow byte ? ;current leaderboard row

;npc cars
npcnum equ 3 ;3 npc cars
npcX word 10,30,50 ;array of initial X coordinates
npcY word 7,16,29 ;array of initial Y coordinates
rnddir byte 1,2,0 ;right, up, left
npccolor dword 3 ;cyan
npcspeed dword 100 ;default 100ms starting speed, increases later
npclastupdate dword 0 ;timestamp to move

arr byte 2450 dup(' ')  ;35 x 70 = 2450
;' ' empty
;# wall
;P passenger
;D destination
;C O npc
;T | tree
;X obstacle

;instruction messages
endmsg byte "Time's Up! Game Over!", 0
scoremsg byte "Current Score: ", 0
keysmsg byte "Arrow Keys: Move", 0
pausemsg byte "P Key: Pause/Resume", 0
spacebarmsg byte "Spacebar Key: Pickup/Dropoff", 0
bonusinstr byte "Magenta Block: Bonus", 0

;game feedback messages
pmsg byte "Taxi has picked up a Passenger, Go to Destination", 0
dmsg byte "Taxi has successfully dropped off a Passenger. Time +5s. Score +10pts", 0
findPmsg byte "Find a Passenger to pickup", 0
goDmsg byte "Go to Green Destination", 0

;siderbar messages
timeleftmsg byte "Time Remaining: ", 0
currscoreheading byte "Your Score: ", 0
currscoremsg byte "Points: ", 0
cmndlabel byte "Game Controls: ", 0
actionmsg byte "SpaceBar: PickUp/DropOff", 0
statusmsg byte "Current Game Status: ", 0
dropmsg byte "Passengers Dropped: ", 0
crashmsg byte "Crashed into an obstacle, Penalty deducted", 0
dropmsg2 byte " / 5", 0
bonusmsg byte "Bonus Picked UP! Time +10 seconds, Score +20 points", 0

;leaderboard messages
leaderboardmenu byte "Game Leaderboard", 0
ldbrdheader byte "Rank                Score", 0
dotsep byte ". ", 0
ldbrdempty byte "Leaderboard Empty. Nothing to Display", 0
highscrmsg byte "You have just made a NEW High Score!", 0
ldbrdsave byte "Your score has been saved!", 0

gamepaused byte "      Game Paused. Press P to Resume      ", 0 ;game pause message
gamemode byte 0 ;0 timed, 1 endless, 2 career

;menu options
option1 byte "       [ 1 ]  Timed Mode             ", 0
option2 byte "       [ 2 ]  Endless Mode             ", 0
option3 byte "       [ 3 ]  Career Mode             ", 0
option4 byte "       [ 4 ]  Leaderboard             ", 0
option5 byte "       [ 5 ]  Game Instructions             ", 0
option6 byte "       [ 6 ]  Exit             ", 0
option7 byte "       [ L ]  Resume Game          ", 0
option8 byte "       [ 7 ]  Change Difficulty      ", 0
optionsel byte "      Please select an option: ", 0

;taxi color options
choosecolor byte "Choose the colour of your taxi: ", 0
colour1 byte "[ 1 ]  Red", 0
colour2 byte "[ 2 ]  Yellow", 0
colour3 byte "[ 3 ]  Random", 0

entername byte "Enter your name: ", 0 ;enter name options
lastcrash dword 0 ;crash time 500ms
dropnum dword 0 ;passengers droppped
gamelevel byte 1 ;difficulty level 0,1,2 == easy , medium , hard 

urname byte 21 dup(0) ;player name
currscore dword 0 ;current score

;save game messages
gamesavefilename byte "save.dat", 0
savemsg byte "Game has been saved", 0
loadmsg byte "Game has been loaded", 0

;difficulty messages
difficultytitle byte "Select Game Difficulty: ", 0
diff1 byte "     [ 1 ]  Easy (Slow npc cars, More time)", 0
diff2 byte "     [ 2 ]  Medium (Normal npc speed and time)", 0
diff3 byte "     [ 3 ]  Hard (Fast npc cars, Less time)", 0
diffsel byte "     Select your difficulty level: ", 0

;instructions messages
instrtitle byte "Game Instructions: ", 0
rule1 byte "1. You are a Taxi Driver.", 0
rule2 byte "2. Use your keyboard's arrow keys to move your taxi.", 0
rule3 byte "3. Find a Passenger.", 0
rule4 byte "4. Press the Spacebar to pick him up.", 0
rule5 byte "5. Drop him off at the Destination (Green Box).", 0
rule6 byte "6. Earn points and bonus time", 0
rule7 byte "7. You have 1 minute", 0
rule8 byte "8. Stay away from obstacles", 0
rule9 byte "9. Pick up red bars for bonus boost", 0
gobackmsg byte "Press any key to return.", 0

;career mode win messages
winmsg byte "Mission Complete!!!", 0
goodmsg byte "You Rock! Well Played.", 0

.code
main PROC
	call Randomize ;calls randomize so that the generator seeds random numbers each time the game is run
afterend:
	call displaymenufunc ;draws menu
	cmp al, 1 ;input stored in al
	je loadgame ;resume saved game

;new game
	call colormenufunc ;choose taxi color
	call namemenufunc ;enter player's name
	mov eax, white+(lightGray*16) ;white text on light gray bg
	call SetTextColor
	call Clrscr ;clear board
	call drawmapfunc ;populate array

;reset variables
	mov ax, 2
	mov currX, ax ;car initially set to row 2, col 2
	mov currY, ax
	mov prevX, ax
	mov prevY, ax
	mov currscore, 0 ;score set to 0
	mov picked, 0 ;no passenger picked
	mov dropnum, 0 ;no passengers dropped

;set time based on game mode
	cmp gamemode, 1 ;current game mode chosen by player
	je infinitetime ;endless mode has no time
	mov tremain, 60 ;in both other modes, 60 seconds
	jmp entergameloop

infinitetime:
	mov tremain, 0 ;set time to 0 to increment it
	jmp entergameloop

loadgame:
	call gameloadfunc ;read the saved file into memory
    call Clrscr
	mov eax, white+(lightGray*16)
	call SetTextColor ;set game colors again
	call Clrscr ;no calling drawmap
    jmp continueloop ;do not want to reset the time variables

entergameloop:
    cmp gamelevel, 0 ;easy mode
    je easymode
    cmp gamelevel, 1 ;medium mode
    je mediummode
    cmp gamelevel, 2 ;hard mode
    je hardmode

easymode:
    mov npcspeed, 150 ;slow npc cars
    cmp gamemode, 1 ;is it endless mode
    je skiptime1
    mov tremain, 90

skiptime1:
    jmp continueloop

mediummode:
    mov npcspeed, 100 ;medium npc cars
    cmp gamemode, 1 ;is it endless mode
    je skiptime2
    mov tremain, 60

skiptime2:
    jmp continueloop

hardmode:
    mov npcspeed, 50 ;fast npc cars
    cmp gamemode, 1 ;is it endless mode
    je skiptime3
    mov tremain, 30

skiptime3:
    jmp continueloop

continueloop:
	call GetMseconds ;current system time passed in milli seconds since game started
	mov lastupdate, eax ;store the time since last tick in update checker
	call drawboardfunc ;draw the board
	call drawcarfunc ;draw taxi
	call drawscreenfunc ;draw the helping screen to the side
	call gameloopfunc ;infinite loop until game ends
	jmp afterend ;after game ends, display the menu again
	exit
main ENDP

;main game controlling function
gameloopfunc PROC
mainloop:
	call npcmovementfunc ;function to move npc cars
	call GetMseconds ;time since game started
	sub eax, lastupdate ;subtract the last update to get the time since last time npc moved
	cmp eax, 1000 ;npc cars move once per second initially
	jl keycheck ;if npc cars have not moved, check for user's key press
	cmp gamemode, 1
	je incrtime ;in endless mode time is incremented
	dec tremain ;in other modes time is decremented
	jmp updategame

incrtime:
	inc tremain ;incrementing time

updategame: ;rest of the game logic 
	call GetMseconds
	mov lastupdate, eax
	call drawscreenfunc
	cmp gamemode, 1
	je keycheck ;in endless ode no need to check time
	cmp tremain, 0
	jg keycheck ;in career and timed mode need to check if time is still greater than 0
	call updatescoresfunc ;game end, update leaderboard
	ret

keycheck: ;checks what key the user has pressed
	call ReadKey
	jnz checkpressed ;if not zero, it means key pressed
	mov eax, 10
	call Delay ;else have a delay of 10 ms until game loops again
	jmp mainloop

;the key pressed stores its ascii in al
checkpressed: ;check which key the user has pressed
	cmp al, 27 ;esc key
	je exitgame
	cmp al, ' ' ;spacebar pressed
	je spacebarpressed ;to check whether to pickup or drop off
	cmp al, 'p'
	je pausegame ;p pressed, game paused
	cmp al, 'P' ;capital P
	je pausegame
	cmp al, 's' ;logic added for saving game directly
	je savegame
	cmp al, 'S' ;capital S
	je savegame

;key movement and how it works was learned from the lab task in which a moving snake game was given
	cmp ah, 72
	je moveup ;car goes up
	cmp ah, 80
	je movedown ;car goes down
	cmp ah, 75
	je moveleft ;car goes left
	cmp ah, 77
	je moveright ;car goes right
	jmp mainloop ;if any other key was pressed that does not correspond to any action

;movzx is used because of size mismatch so we append zeroes in upper half
moveup:
	movzx eax, currX ;current x coordinates
	movzx ebx, currY ;current y coordinates
	dec ebx ;subtracting y coordinates because screen starts from top left
	call validatemovefunc ;validates if movement is possible
	jz mainloop ;movement not done
	dec currY ;car has moved successfully
	jmp aftermove ;skip all other movement checks

movedown:
	movzx eax, currX ;current x coordinates
	movzx ebx, currY ;current y coordinates
	inc ebx ;adding y coordinates because screen starts from top left
	call validatemovefunc ;validates if movement is possible
	jz mainloop ;movement not done
	inc currY ;car has moved successfully
	jmp aftermove ;skip all other movement checks

moveleft:
	movzx eax, currX ;current x coordinates
	movzx ebx, currY ;current y coordinates
	dec eax ;subtracting x coordinates because screen starts from top left
	call validatemovefunc ;validates if movement is possible
	jz mainloop ;movement not done
	dec currX ;car has moved successfully
	jmp aftermove ;skip all other movement checks

moveright:
	movzx eax, currX ;current x coordinates
	movzx ebx, currY ;current y coordinates
	inc eax ;adding x coordinates because screen starts from top left
	call validatemovefunc ;validates if movement is possible
	jz mainloop ;movement not done
	inc currX ;car has moved successfully
	jmp aftermove ;skip all other movement checks

aftermove:
	call updatecarfunc ;updates car's position
    mov eax, carspeed
    call Delay ;if yellow car then no delay, if red car then 20ms delay
	jmp mainloop ;no other checks

spacebarpressed:
	cmp picked, 1
	je dropoffpass ;if person has already been picked, drop him off
	jmp pickuppass ;else pick up person

pickuppass:
	call pickupfunc ;function to pickup passenger
	jmp mainloop ;reloop

dropoffpass:
	call dropofffunc ;function to dropoff passenger
	jmp mainloop ;reloop

pausegame:
	call gamepausefunc ;function to pause game
	call GetMseconds
	mov lastupdate, eax ;store time
	jmp mainloop

savegame:
	call savegamefunc ;saves game by storing everything
    ret ;recalls menu again if you want to load game

exitgame:
	call updatescoresfunc ;update leaderboard
	ret
gameloopfunc ENDP

gamepausefunc PROC ;function to pause the game when P is pressed
	pushad ;push all values till now in the stack to preserve them
	mov dl, 15
	mov dh, 15
	call Gotoxy ;go to row 15 column 15
	mov eax, white+(red*16) ;white text on red bg
	call SetTextColor
	mov edx, offset gamepaused
	call WriteString ;display game paused message on screen

unpausewait: ;waits for user to press P to resume the game
	call ReadChar
	cmp al, 'p'
	je unpausegame
	cmp al, 'P'
	je unpausegame
	jmp unpausewait ;loops indefinitely until P is pressed

unpausegame:
	mov eax, white+(lightGray*16)
	call SetTextColor
	call Clrscr ;clear the screen to redraw the board
	popad ;pop all the pushed register values
	call drawboardfunc
	call drawcarfunc
	call drawscreenfunc
	ret
gamepausefunc ENDP

;validates if the desired the car move to is allowed
validatemovefunc PROC USES ebx ecx edx esi ;preserve these register values when exiting the function as they are important
	cmp eax, 0
	jle blocked ;going too left into the border
	cmp eax, cols-3
	jge blocked ;going too right into the right border
	cmp ebx, 0
	jle blocked ;going too up into top border
	cmp ebx, rows-2
	jge blocked ;going too down into the bottom border
	imul ebx, cols
	add ebx, eax ;in assembly accessing 2D grid of a 1D array requires manipulation y*70 + x
	mov esi, offset arr ;starting to array
    add esi, ebx ;current position of the taxi
    mov dl, [esi]
    call crashtype ;check what cell the car moves into
    cmp al, 0
    je blocked ;cant move there
    mov dl, [esi+1] ;row 0 col 1
    call crashtype
    cmp al, 0
    je blocked
    mov dl, [esi+2] ;row 0 col 2
    call crashtype
    cmp al, 0
    je blocked
    mov dl, [esi+70] ;row 1 col 0
    call crashtype
    cmp al, 0
    je blocked
    mov dl, [esi+71] ;row 1 col 1
    call crashtype
    cmp al, 0
    je blocked
    mov dl, [esi+72] ;row 1 col 2
    call crashtype
    cmp al, 0
    je blocked
    pushad
    mov dh, 38
    mov dl, 1
    call Gotoxy
    mov ecx, 50
clearcrashmsg:
    mov al, ' '
    call WriteChar ;clear the crash message
    loop clearcrashmsg
    popad
    pushad
    mov dh, 36
    mov dl, 1
    call Gotoxy
    mov ecx, sizeof bonusmsg

clearbonusmsg:
    mov al, ' '
    call WriteChar ;clear the bonus message
    loop clearbonusmsg
    popad
    mov al, 1 ;can move
    or al, al ;set flags
    ret

blocked:
	mov al, 0
    mov dh, 38
    mov dl, 1
    call Gotoxy
    mov edx, offset crashmsg ;to display that you have crashed
    call WriteString
	or al, al ;clear al
	ret
validatemovefunc ENDP

crashtype PROC
    cmp dl, 'M' ;denotes my own car
    je isempty ;its treated as empty
    cmp dl, '#' ;walls 
    je hitwall ;blocked
    cmp dl, 'X' ;bonus
    je hitbonus 
    cmp dl, 'T' ;tree
    je checkobs ;not cause multiple deductions
    cmp dl, '|' ;tree
    je checkobs
    cmp dl, 'C' ;npc car top
    je checkobs
    cmp dl, 'O' ;nps car wheels
    je checkobs
    cmp dl, 'P' ;passenger
    je checkobs
    cmp dl, 'p' ;passenger
    je checkobs
isempty:
    mov al, 1 ;empty cell
    ret

hitwall:
	mov al, 0 ;cannot move into wall but no deduction
	ret

hitbonus:
    mov dl, 1
    mov dh, 36
    call Gotoxy
    mov edx, offset bonusmsg
    call WriteString
    add currscore, 20 ;20 points
    add tremain, 10 ;10 seconds
    INVOKE PlaySound, offset picksnd, 0, 20001h
    mov eax, 500
    call Delay
    mov al, 1
    ret

checkobs:
	push eax ;need to manipulate values
	call GetMseconds ;system time
	sub eax, lastcrash
	cmp eax, 500 ;if 500ms have passed
	pop eax
	jl hitwall ;dont do anything if multiple collisions detected within 500ms
	push eax
	call GetMseconds
	mov lastcrash, eax ;update time since last crash
	pop eax
    cmp dl, 'P' ;hit a passenger
    je passengerhit
    cmp dl, 'p'
    je passengerhit
    cmp dl, 'T' ;hit tree
    je treehit
    cmp dl, '|'
    je treehit
    jmp carhit ;else must have hit npc car

treehit:
	cmp carcolor, 4
	je redobscrash ;if red taxi
	call minus4pts ;4 score deducted
	jmp crashchecked ;checked this movement

redobscrash:
	call minus2pts ;2 score deducted
	jmp crashchecked

carhit:
	cmp carcolor, 4
	je redcarcrash ;red car hits npc
	call minus2pts ;2 score deducted
	jmp crashchecked

redcarcrash:
	call minus3pts ;3 score deducted
	jmp crashchecked

passengerhit:
	call minus5pts ;5 points deducted
	jmp crashchecked

crashchecked:
	call drawscreenfunc ;update side screen if crash happened
	INVOKE PlaySound, offset crashsnd, 0, 20001h ;play crash sound
	mov al, 0 ;retun 0 i.e. blocked
	ret
crashtype ENDP

minus2pts PROC ;deduct 2 points
    cmp currscore, 2 ;compare current score
    jl zero2 ;if already less than 2
    sub currscore, 2 ;deduct 2 points
    ret
zero2: ;just make zero
    mov currscore, 0
    ret
minus2pts ENDP

minus3pts PROC ;same logic
    cmp currscore, 3
    jl zero3
    sub currscore, 3
    ret
zero3:
    mov currscore, 0
    ret
minus3pts ENDP

minus4pts PROC ;minus 4 points
    cmp currscore, 4
    jl zero4
    sub currscore, 4
    ret
zero4:
    mov currscore, 0
    ret
minus4pts ENDP

minus5pts PROC ;deduct 5 points
    cmp currscore, 5
    jl zero5
    sub currscore, 5
    ret
zero5:
    mov currscore, 0
    ret
minus5pts ENDP

pickupfunc PROC USES eax ebx ecx edx esi edi ;pickup passenger and saves all registers in stack
	movzx eax, currY
	imul eax, cols
	movzx ebx, currX
	add eax, ebx ;using eax for rows here because its easier for arithmetics
	mov esi, offset arr ;starting
	add esi, eax ;current car position
    lea edi, [esi] ;edi point so same address as esi
    call checkpassenger ;check if there is a passenger
    cmp al, 1 ;1 if passenger found
    je removepassenger ;erase the passenger form that cell
    lea edi, [esi+1] ;0,1
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi+2] ;0,2 using edi helps because when remove passenger is called i dont have to check again and again which cell to remove passenger from and cannot directly manipulate esi
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi+70] ;1,0
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi+71] ;1,1
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi+72] ;1,2
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi-70] ;-1,0
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi-69] ;-1,1
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi-68] ;-1,2
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi+140] ;2,0
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi+141] ;2,1
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi+142] ;2,2
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi-1] ;left
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi+69] ;left bottom
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi+3] ;right
    call checkpassenger
    cmp al, 1
    je removepassenger
    lea edi, [esi+73] ;right bottom
    call checkpassenger
    cmp al, 1
    je removepassenger
    ret ;no passenger found

removepassenger:
	mov byte ptr [edi], ' ' ;make the cell empty
	mov byte ptr [edi+70], ' ' ;bottom half of passenger
	mov eax, edi
	sub eax, offset arr ;in terms of bytes
	mov edx, 0
	mov ecx, cols ;to get in terms of rows and columns
	div ecx ;offset addresses converted back to x,y for message printing
    mov dh, al ;that specific coordinate
    mov dl, dl
    call Gotoxy ;go to it
    mov eax, white+(lightGray*16)
    call SetTextColor
    mov al, ' ' ;first we erased it from our array
    call WriteChar
    inc dh ;for legs
    call Gotoxy
    call WriteChar ;now we have deleted it from the board by drawing a gray cell there
	mov picked, 1 ;passenger has been picked
	call displaydestination ;draw the point of dropoff
	call drawscreenfunc
	mov dh, 37
	mov dl, 1
	call Gotoxy
    mov dh, 37
    mov dl, 0
    call Gotoxy
    mov ecx, 70 ;clear the previous message
clearpickmsg:
    mov al, ' '
    call WriteChar
    loop clearpickmsg
    mov dh, 37
    mov dl, 1
    call Gotoxy
	mov edx, offset pmsg ;passenger picked up go to destination instruction
	call WriteString
	INVOKE PlaySound, offset picksnd, 0, 20001h ;sound for successful passenger pickup
	ret
pickupfunc ENDP

checkpassenger PROC ;helper function to check if the cell has a head or a leg of the passenger
    mov dl, [edi]
    cmp dl, 'P' ;capital P for head
    je foundP
    cmp dl, 'p' ;small P for legs
    je foundp_
    mov al, 0 ;no passenger found
    ret
foundP:
    mov al, 1 ;found head
    ret
foundp_:
    sub edi, 70 ;found legs, subtracting to go to head
    mov al, 1
    ret
checkpassenger ENDP	

dropofffunc PROC USES eax ebx ecx edx esi ;function for dropoff of passenger
	movzx eax, currY
	imul eax, cols
	movzx ebx, currX
	add eax, ebx ;using eax for rows here because its easier for arithmetics
	mov esi, offset arr ;starting
	add esi, eax ;current car position
    cmp byte ptr [esi-1], 'D'
    je foundleft ;to the left
    cmp byte ptr [esi+3], 'D'
    je foundright ;to the right
    cmp byte ptr [esi-70], 'D'
    je foundup ;above
    cmp byte ptr [esi+140], 'D'
    je founddown ;below
    cmp byte ptr [esi+69], 'D'
    je foundleftdiag ;diagonally left
    cmp byte ptr [esi+73], 'D'
    je foundrightdiag ;diagonally right
    ret

foundleft: ;found to the left
    mov byte ptr [esi-1], ' ' ;erasing it from the array
    push eax ;storing
    push edx
    movzx eax, currY
    mov dh, al
    movzx eax, currX
    mov dl, al
    dec dl
    call Gotoxy ;go to the coordinate of D
    mov eax, white+(lightGray*16) ;erase it
    call SetTextColor
    mov al, ' '
    call WriteChar
    pop edx
    pop eax ;restore values
    jmp droppedoff ;dropped off the passenger

foundright: ;found to the right
    mov byte ptr [esi+3], ' ' ;erasing it from the array
    push eax ;storing
    push edx
    movzx eax, currY
    mov dh, al
    movzx eax, currX
    mov dl, al
    add dl, 3
    call Gotoxy ;go to the coordinate of D
    mov eax, white+(lightGray*16) ;erase it
    call SetTextColor
    mov al, ' '
    call WriteChar
    pop edx
    pop eax ;restore values
    jmp droppedoff ;dropped off the passenger

foundup: ;found above
    mov byte ptr [esi-70], ' ' ;erasing it from the array
    push eax ;storing
    push edx
    movzx eax, currY
    mov dh, al
    movzx eax, currX
    mov dl, al
    dec dh
    call Gotoxy ;go to the coordinate of D
    mov eax, white+(lightGray*16) ;erase it
    call SetTextColor
    mov al, ' '
    call WriteChar
    pop edx
    pop eax ;restore values
    jmp droppedoff ;dropped off the passenger

founddown: ;found below
    mov byte ptr [esi+140], ' ' ;erasing it from the array
    push eax ;storing
    push edx
    movzx eax, currY
    mov dh, al
    movzx eax, currX
    mov dl, al
    add dh, 2
    call Gotoxy ;go to the coordinate of D
    mov eax, white+(lightGray*16) ;erase it
    call SetTextColor
    mov al, ' '
    call WriteChar
    pop edx
    pop eax ;restore values
    jmp droppedoff ;dropped off the passenger

foundleftdiag: ;found diagonally to the left
    mov byte ptr [esi+69], ' ' ;erasing it from the array
    push eax ;storing
    push edx
    movzx eax, currY
    mov dh, al
    movzx eax, currX
    mov dl, al
    inc dh
    dec dl
    call Gotoxy ;go to the coordinate of D
    mov eax, white+(lightGray*16) ;erase it
    call SetTextColor
    mov al, ' '
    call WriteChar
    pop edx
    pop eax ;restore values
    jmp droppedoff ;dropped off the passenger

foundrightdiag: ;found diagonally to the right
    mov byte ptr [esi+73], ' ' ;erasing it from the array
    push eax ;storing
    push edx
    movzx eax, currY
    mov dh, al
    movzx eax, currX
    mov dl, al
    inc dh
    add dl, 3
    call Gotoxy ;go to the coordinate of D
    mov eax, white+(lightGray*16) ;erase it
    call SetTextColor
    mov al, ' '
    call WriteChar
    pop edx
    pop eax ;restore values
    jmp droppedoff ;dropped off the passenger

droppedoff: ;successfully dropped a passenger
    add tremain, 5 ;bonus 5 seconds
    add currscore, 10 ;increase 10 points
    inc dropnum ;number of passengers dropped
    INVOKE PlaySound, offset dropsnd, 0, 20001h ;sound played when successfully dropped off
    cmp npcspeed, 10 ;check if already at maximum speed
    jle skipflash ;dont increase speed any further
    mov eax, dropnum
    mov edx, 0
    mov ecx, 2
    div ecx ;divide number of passengers dropped by 2 to see if even number dropped
    cmp edx, 0 ;remainder 0 means even
    jnz skipflash ;skip increasing speed
    sub npcspeed, 10 ;make the npc cars faster to elevate difficulty
    
skipflash:
    cmp gamemode, 2 ;check if not endless mode
    jne continuegame ;continue the game
    cmp dropnum, 5
    je gamewin ;if 5 passengers dropped in career mode then game won

continuegame:
    mov picked, 0 ; reset the passenger picked up bool
    call spawnpassengerfunc ;draw a new passenger
    call drawboardfunc ;redraw the board with new passenger
    call drawcarfunc
    call drawscreenfunc
    mov dh, 37
    mov dl, 1
    call Gotoxy ;go to row 37 column 0
    mov ecx, 70
    mov al, ' '

deleteprevmsg:
    call WriteChar
    loop deleteprevmsg ;deletes the previous message from screen
    mov dh, 37
    mov dl, 1
    call Gotoxy
    mov edx, offset dmsg ;dropped off message
    call WriteString
    ret

gamewin:
    call winmenufunc ;display winning screen
    call updatescoresfunc ;update leaderboard
    exit ;end game
dropofffunc ENDP

displaydestination PROC ;displays a green cell when passenger picked up
    pushad ;preserve all registers by pushing into a stack
    call getrandomposfunc ;gets an empty random cell
    mov esi, offset arr
    add esi, eax ;the randompos returns eax
    mov byte ptr [esi], 'D' ;update a new D in the map array
    mov edx, 0
    mov ecx, cols
    div ecx ;gets coordinates for the screen in terms of rows and cols
    mov dh, al
    mov dl, dl
    call Gotoxy ;goes to them
    mov eax, green+(lightGray*16)
    call SetTextColor
    mov al, 219 ;draws a green colored cell there
    call WriteChar
    popad ;retrieves the registers
    ret
displaydestination ENDP

spawnpassengerfunc PROC ;gets a new passenger after one is dropped off
    pushad

tryagain:
    call getrandomposfunc ;gets a random empty cell
    cmp eax, 2380
    jge tryagain ;because passenger is 2 by 1 so his legs might be in the bottom border
    mov esi, OFFSET arr
    add esi, eax ;goes to the array's address
    cmp byte ptr [esi+70], ' ' ;checks if its below cell is empty
    jne tryagain ;if not then retry
    mov byte ptr [esi], 'P' ;head
    mov byte ptr [esi+70], 'p' ;legs
    mov edx, 0
    mov ecx, cols
    div ecx
    mov dh, al
    mov dl, dl ;gets coordinates in terms of rows and cols
    call Gotoxy ;goes to them
    mov eax, black+(lightGray*16) ;black text with gray bg
    call SetTextColor
    mov al, 'O' ;head
    call WriteChar
    inc dh ;cell below
    call Gotoxy
    mov al, '^' ;legs below
    call WriteChar ;draw on screen
    popad ;retrieve
    ret
spawnpassengerfunc ENDP

drawmapfunc PROC ;populates the array with everything
    pushad ;preserve register values
    mov ecx, 2450 ;array size
    mov esi, offset arr

cleararr:
    mov byte ptr [esi], ' '
    inc esi
    loop cleararr ;clears the array to all empty cells
    mov esi, offset arr
    mov ecx, cols
    mov edi, 0

topwall:
    mov byte ptr [esi+edi], '#' ;walls
    mov byte ptr [esi+edi+2380], '#'
    inc edi ;from left most to number of columns
    loop topwall
    mov ecx, rows
    mov edi, 0

leftwall:
    mov byte ptr [esi+edi], '#' ;walls
    mov byte ptr [esi+edi+1], '#'
    add edi, cols
    loop leftwall ;column 0-1
    mov ecx, rows
    mov edi, 0

rightwall:
    mov byte ptr [esi+edi+68], '#'
    mov byte ptr [esi+edi+69], '#' ;walls
    add edi, cols
    loop rightwall ;column 68-69
    mov edx, 4

looprows:
    mov ebx, 6 ;y from 4 to 30

loopcols:
    mov eax, 10
    call RandomRange
    cmp eax, 3
    jl skipblock
    call spawnblockfunc ;spawns a 3x8 block

skipblock:
    add ebx, 14
    cmp ebx, 55 ;x from 6 to 55
    jl loopcols
    add edx, 6
    cmp edx, 30
    jl looprows
    mov ecx, npcnum ;number of npc cars
    mov esi, 0

spawnnpcloop:
    push ecx
    call getrandomposfunc ;get 3 random positions to place npc cars
    mov edx, 0
    mov ecx, cols
    div ecx ;get in terms of x y coordinates
    mov npcX[esi], dx ;x coordinates into the array
    mov npcY[esi], ax ;y coordinates into the array
    pop ecx
    add esi, 2
    loop spawnnpcloop
    mov ecx, 3

spawnbonusloop:
    push ecx
    call getrandomposfunc
    mov byte ptr [arr+eax], 'X'
    pop ecx
    loop spawnbonusloop
    mov ecx, 6 ;6 trees


spawntreeloop:
    push ecx ;pushing ecx to preserve it because it runs the loops
    call getrandomposfunc
    cmp eax, 2300 ;donot want the tree to collide within the bottom border
    jge skiptreespawn ;do not put a tree there
    mov byte ptr [arr+eax], 'T' ;T is the canopy
    mov byte ptr [arr+eax+70], '|' ;just below it is the trunk

skiptreespawn:
    pop ecx
    loop spawntreeloop
    mov ecx, 5 ;5 passengers
    
spawnpassengersloop:
    push ecx
    call getrandomposfunc
    cmp eax, 2300
    jge skippassspawn ;no passenger in the bottom rows
    mov byte ptr [arr+eax], 'P' ;P is the head
    mov byte ptr [arr+eax+70], 'p' ;just below it are the legs

skippassspawn:
    pop ecx
    loop spawnpassengersloop
    popad ;retrieve all initial values
    ret
drawmapfunc ENDP

spawnblockfunc PROC USES eax ebx ecx edx edi
    mov ecx, 3 ;3 rows

drawblockloop: ;calculates starting index
    push ebx
    push ecx
    mov edi, 8 ;8 columns
    mov eax, edx
    imul eax, cols
    add eax, ebx ;70*y + x

blockrow: ;draws the walls
    mov byte ptr [arr+eax], '#'
    inc eax
    dec edi
    jnz blockrow
    pop ecx
    pop ebx
    inc edx
    dec ecx
    jnz drawblockloop ;move to the next row
    ret
spawnblockfunc ENDP

drawboardfunc PROC
    mov eax, white+(lightGray*16)
    call SetTextColor
    mov dh, 0
    mov ecx, rows
    mov esi, offset arr

boardrow:
    push ecx
    mov dl, 0
    mov ecx, cols

boardcol:
    call Gotoxy
    mov al, [esi]
    cmp al, '#'
    je drawwalls ;draw wall at this offset
    cmp al, 'P'
    je drawhead ;draw head at this offset
    cmp al, 'p'
    je drawlegs ;draw legs at this offset
    cmp al, 'D'
    je drawdestination ;draw destination at this offset
    cmp al, 'C'
    je drawnpccar ;draw npc car body at this offset
    cmp al, 'O'
    je drawwheels ;draw npc car wheels at this offset
    cmp al, 'T'
    je drawleaves ;draw canopy at this offset
    cmp al, '|'
    je drawtrunk ;draw trunk at this offset
    cmp al, 'X'
    je drawobs ;draw bonus at this offset
    cmp al, 'M' ;my car
    je nextiteration ;dont draw it
    mov eax, white+(lightGray*16) ;restore colors
    call SetTextColor
    call WriteChar
    jmp nextiteration

drawwalls:
    mov eax, black+(black*16) ;black on black
    call SetTextColor
    mov al, 219 ;full block
    call WriteChar
    jmp nextiteration

drawhead:
    mov eax, black+(lightGray*16) ;black on gray
    call SetTextColor
    mov al, 'O' ;full head
    call WriteChar
    jmp nextiteration

drawlegs:
    mov eax, black+(lightGray*16) ;black on gray
    call SetTextColor
    mov al, '^' ;full legs
    call WriteChar
    jmp nextiteration

drawdestination:
    mov eax, green+(lightGray*16) ;green on gray
    call SetTextColor
    mov al, 219 ;full block
    call WriteChar
    jmp nextiteration

drawobs:
    mov eax, lightMagenta+(lightGray*16) ;red on gray
    call SetTextColor
    mov al, 219 ;bonus sun symbol
    call WriteChar
    jmp nextiteration

drawleaves:
    mov eax, green+(lightGray*16) ;green on gray
    call SetTextColor
    mov al, 'O' ;canopy
    call WriteChar
    jmp nextiteration

drawtrunk:
    mov eax, brown+(lightGray*16) ;brown on gray
    call SetTextColor
    mov al, '|' ;trunk
    call WriteChar
    jmp nextiteration

drawnpccar:
    mov eax, cyan+(lightGray*16) ;cyan body on gray bg
    call SetTextColor
    mov al, 219 ;full block
    call WriteChar
    jmp nextiteration

drawwheels:
    mov eax, white+(lightGray*16) ;white on gray
    call SetTextColor
    mov al, 'O' ;wheels
    call WriteChar
    jmp nextiteration

nextiteration: ;go to the next thing to be drawn
    inc esi ;next column
    inc dl ;increment x coordinate
    mov eax, white+(lightGray*16)
    call SetTextColor
    dec ecx
    jnz boardcol ;continue looping columns in one row
    inc dh ;increment y coordinate
    pop ecx ;get back row loop handler
    dec ecx
    jnz boardrow ;continue to the next row
    ret
drawboardfunc ENDP

drawcarfunc PROC
    pushad ;preserve register
    movzx eax, currY
    imul eax, cols
    movzx ebx, currX
    add eax, ebx
    mov esi, offset arr
    add esi, eax
    mov byte ptr [esi], 'M' ;the car is denoted by M in the array so no collisions occur
    mov byte ptr [esi+1], 'M'
    mov byte ptr [esi+2], 'M'
    mov byte ptr [esi+70], 'M'
    mov byte ptr [esi+71], 'M'
    mov byte ptr [esi+72], 'M'
    mov eax, carcolor ;eax holds the color chosen
    add eax, (lightGray*16) ;that color on gray bg
    call SetTextColor
    mov dh, byte ptr currY ;row
    mov dl, byte ptr currX ;column
    call Gotoxy ;go to it
    mov al, 219 ;full block
    call WriteChar
    call WriteChar
    call WriteChar ;3 blocks wide
    inc dh ;next row
    call Gotoxy
    mov eax, white+(lightGray*16) ;wheels
    call SetTextColor
    mov al, 'O' ;left wheel
    call WriteChar
    mov al, '-' ;base
    call WriteChar
    mov al, 'O' ;right wheel
    call WriteChar
    popad ;retrieve
    ret
drawcarfunc ENDP

erasecarfunc PROC
    pushad
    movzx eax, prevY
    imul eax, cols
    movzx ebx, prevX
    add eax, ebx
    mov esi, offset arr
    add esi, eax
    mov byte ptr [esi], ' ' ;clears the car from the array
    mov byte ptr [esi+1], ' '
    mov byte ptr [esi+2], ' '
    mov byte ptr [esi+70], ' '
    mov byte ptr [esi+71], ' '
    mov byte ptr [esi+72], ' '
    mov eax, white+(lightGray*16) ;restore the cell
    call SetTextColor
    mov dh, byte ptr prevY ;previous row
    mov dl, byte ptr prevX ;previous column
    call Gotoxy
    mov al, ' '
    call WriteChar
    call WriteChar
    call WriteChar ;erase body
    inc dh ;next column
    call Gotoxy
    call WriteChar
    call WriteChar
    call WriteChar ;erase wheels and base
    popad
    ret
erasecarfunc ENDP

updatecarfunc PROC
    call erasecarfunc ;erase car from previous coordinates
    call drawcarfunc ;draw car at new coordinates
    mov ax, currX
    mov prevX, ax ;copy current values to previous x coordinates
    mov ax, currY
    mov prevY, ax ;copy current values to previous y coordinates
    ret
updatecarfunc ENDP

drawscreenfunc PROC ;draws a siderbar
    pushad
    mov eax, black+(lightGray*16) ;black text on gray bg
    call SetTextColor
    mov dh, 2
    mov dl, 72
    call Gotoxy ;row 2 column 72
    mov edx, offset currscoreheading ;your score
    call WriteString
    mov dh, 3
    mov dl, 72
    call Gotoxy ;row below
    mov edx, offset currscoremsg ;points
    call WriteString
    mov eax, currscore ;points
    call WriteDec
    mov dh, 4
    mov dl, 72
    call Gotoxy ;row below
    mov edx, offset dropmsg
    call WriteString
    mov eax, dropnum ;number of passenger dropped
    call WriteDec
    cmp gamemode, 2 ;if career
    jne skipmode
    mov edx, offset dropmsg2 ;/5
    call WriteString

skipmode:
    mov dh, 6
    mov dl, 72
    call Gotoxy
    mov edx, offset timeleftmsg ;time remaining
    call WriteString
    mov dh, 7
    mov dl, 72
    call Gotoxy
    mov eax, tremain ;actual time left
    call WriteDec
    mov al, ' '
    call WriteChar ;draws a character because time behaves irrationally
    mov dh, 9
    mov dl, 72
    call Gotoxy
    mov edx, offset cmndlabel ;commands
    call WriteString
    mov dh, 10
    mov dl, 72
    call Gotoxy
    mov edx, offset keysmsg ;arrow keys do what
    call WriteString
    mov dh, 11
    mov dl, 72
    call Gotoxy
    mov edx, offset pausemsg ;p pressed to pause
    call WriteString
    mov dh, 12
    mov dl, 72
    call Gotoxy
    mov edx, offset actionmsg ;what action performed
    call WriteString
    mov dh, 13
    mov dl, 72
    call Gotoxy
    mov edx, offset bonusinstr
    call WriteString
    mov dh, 15
    mov dl, 72
    call Gotoxy
    mov edx, offset statusmsg ;game status right now
    call WriteString
    mov dh, 16
    mov dl, 72
    call Gotoxy
    mov ecx, 40
    mov al, ' '
clearstats: 
    call WriteChar
    loop clearstats ;clears the previous message
    mov dh, 16
    mov dl, 72
    call Gotoxy
    cmp picked, 1 ;is there a passenger picked
    je showdrop
    mov edx, offset findPmsg
    jmp printstat

showdrop:
    mov edx, offset goDmsg

printstat:
    call WriteString
    popad
    ret
drawscreenfunc ENDP

updatescoresfunc PROC
    mov eax, white+(blue*16) ;white text on blue bg
    call SetTextColor
    call Clrscr ;clear the board
    mov edx, offset filename
    call OpenInputFile ;opens file in input mode
    cmp eax, INVALID_HANDLE_VALUE ;i looked up this checks if file exists or not
    je createnewfile ;then create a file
    mov fhandle, eax ;store its handle
    mov edx, offset scores ;stores array
    mov ecx, sizeof scores ;loop till its size
    call ReadFromFile ;read from file
    mov eax, fhandle ;to close file
    call CloseFile
    jmp checkscores

createnewfile:
    mov edx, offset filename
    call CreateOutputFile ;create a output file now
    mov fhandle, eax ;save file handle
    mov edx, offset scores
    mov ecx, sizeof scores
    call WriteToFile ;write in it
    mov eax, fhandle
    call CloseFile ;close it

checkscores:
    mov ecx, 10 ;top 10
    mov esi, 0 ;from start

findspot:
    mov eax, scores[esi]
    cmp currscore, eax ;check if current score can come in any top 10
    jg foundspot ;placed in top 10
    add esi, 4
    loop findspot
    jmp nospotfound ;no place in top 10

foundspot:
    mov ebx, 36

shiftarray: ;shifts array to create space
    cmp ebx, esi
    jle insertscore ;insert score in the array
    mov eax, scores[ebx-4]
    mov scores[ebx], eax
    sub ebx, 4
    jmp shiftarray

insertscore:
    mov eax, currscore
    mov scores[esi], eax ;store current score in array
    mov edx, offset filename
    call CreateOutputFile ;create a newer output file
    mov fhandle, eax
    mov edx, offset scores
    mov ecx, sizeof scores
    call WriteToFile ;write into it
    mov eax, fhandle
    call CloseFile
    mov edx, offset highscrmsg ;new high score
    call WriteString
    call Crlf

nospotfound:
    mov edx, offset endmsg ;game over time is up
    call WriteString
    call Crlf
    call WaitMsg ;wait unitl a key is pressed
    ret
updatescoresfunc ENDP

displayleaderboardfunc PROC
    mov eax, white+(green*16) ;white text on green bg
    call SetTextColor
    call Clrscr ;clear the board
    mov dl, 29
    mov dh, 5 ;row 5 column 29
    call Gotoxy
    mov edx, offset leaderboardmenu ;game leaderboard
    call WriteString
    mov dl, 25
    mov dh, 7 ;row 7 col 25
    call Gotoxy
    mov edx, offset ldbrdheader
    call WriteString
    mov edx, offset filename
    call OpenInputFile ;open the file
    cmp eax, INVALID_HANDLE_VALUE ;check if file exists
    je nofilefound ;file does not exist
    mov fhandle, eax
    mov edx, offset scores
    mov ecx, sizeof scores
    call ReadFromFile ;read scores from file
    mov eax, fhandle
    call CloseFile
    mov ecx, 10
    mov esi, 0
    mov ebx, 1
    mov currrow, 9

printldbrd:
    mov eax, scores[esi] ;load into eax
    cmp eax, 0 ;compare if 0
    je skipprint ;zero will not be printed
    mov dh, currrow
    mov dl, 25 ;row 9 column 25
    call Gotoxy
    mov eax, ebx ;1
    call WriteDec
    mov edx, offset dotsep ;prints .
    call WriteString
    mov dh, currrow
    mov dl, 45 ;row 9 column 45
    call Gotoxy
    mov eax, scores[esi]
    call WriteDec
    inc currrow

skipprint:
    inc ebx
    add esi, 4
    loop printldbrd
    jmp waitforkey ;wait until user presses key

nofilefound:
    mov dh, 9
    mov dl, 29
    call Gotoxy
    mov edx, offset ldbrdempty ;leaderboard empty message
    call WriteString

waitforkey:
    mov dh, 22
    mov dl, 25
    call Gotoxy
    call WaitMsg
    ret
displayleaderboardfunc ENDP

colormenufunc PROC ;lets user choose taxi color
    mov eax, black+(yellow*16) ;black text on yellow bg
    call SetTextColor
    call Clrscr ;clears board
    mov dl, 20
    mov dh, 5
    call Gotoxy ;row 5 col 20
    mov edx, offset choosecolor ;choose your taxi color
    call WriteString
    mov dl, 20
    mov dh, 7
    call Gotoxy
    mov edx, offset colour1 ;red
    call WriteString
    mov dl, 20
    mov dh, 8
    call Gotoxy
    mov edx, offset colour2 ;yellow
    call WriteString
    mov dl, 20
    mov dh, 9
    call Gotoxy
    mov edx, offset colour3 ;random
    call WriteString
    call ReadChar
    cmp al, '1' ;user chooses red
    je setcolorred
    cmp al, '2' ;yellow
    je setcoloryellow
    cmp al, '3' ;random color
    je setcolorrandom
    jmp colormenufunc ;if wrong key pressed prompt again
setcolorred:
    mov carcolor, 4 ;color red
    mov carspeed, 20
    ret
setcoloryellow:
    mov carspeed, 0
    mov carcolor, 14 ;color yellow
    ret
setcolorrandom:
    call GetMseconds ;gets time
    test al, 1 ;to get random
    jz setcolorred
    jmp setcoloryellow
colormenufunc ENDP

displaymenufunc PROC ;displays menu
    mov eax, white+(red*16) ;white text on red bg
    call SetTextColor
    call Clrscr ;clears board
    mov eax, yellow+(red*16) ;yellow text
    call SetTextColor
    mov dh, 12
    mov dl, 25 ;row 12 col 25
    call Gotoxy
    mov edx, offset option1 ;timed mode
    call WriteString
    mov dh, 13
    mov dl, 25
    call Gotoxy
    mov edx, offset option2 ;endless mode
    call WriteString
    mov dh, 14
    mov dl, 25
    call Gotoxy
    mov edx, offset option3 ;career mode
    call WriteString
    mov dh, 15
    mov dl, 25
    call Gotoxy
    mov edx, offset option4 ;leaderboard
    call WriteString
    mov dh, 16
    mov dl, 25
    call Gotoxy
    mov edx, offset option5 ;instructions screen
    call WriteString
    mov dh, 17
    mov dl, 25
    call Gotoxy
    mov edx, offset option7 ;resume
    call WriteString
    mov dh, 18
    mov dl, 25
    call Gotoxy
    mov edx, offset option6 ;exit
    call WriteString
    mov dh, 19
    mov dl, 25
    call Gotoxy
    mov edx, offset option8 ;difficulty level
    call WriteString
    mov dh, 22
    mov dl, 25
    call Gotoxy
    mov edx, offset optionsel ;select an option
    call WriteString

menuloop:
    call ReadChar ;read user input
    cmp al, '1' ;option 1 pressed
    je timedsel ;timed mode selected
    cmp al, '2' ;option 2 pressed
    je endlesssel ;endless mode selected
    cmp al, '3' ;option 3 pressed
    je careersel ;career mode selected
    cmp al, 'l'
    je resumesel
    cmp al, 'L'
    je resumesel ;l or L pressed, game resume chosen
    cmp al, '4' ;leaderboard
    je viewldbrd
    cmp al, '5' ;instructions
    je viewinstructions
    cmp al, '6'
    je exitmenu ;exit game
    cmp al, '7'
    je gamedifficulty
    jmp menuloop

gamedifficulty:
    call difficultymenufunc ;change difficulty level
    call displaymenufunc
    ret

timedsel:
    mov gamemode, 0
    mov al, 0 ;new game
    ret

endlesssel:
    mov gamemode, 1
    mov al, 0 ;new game
    ret

careersel:
    mov gamemode, 2
    mov al, 0 ;new game
    ret

resumesel:
    mov al, 1 ;load game
    ret

viewldbrd:
    call displayleaderboardfunc ;display leaderboard
    call displaymenufunc ;again show menu
    ret

viewinstructions:
    call displayinstructionsfunc ;display game instructions
    call displaymenufunc
    ret

exitmenu:
    exit
displaymenufunc ENDP 

showmenufunc PROC
    call Clrscr
    call displaymenufunc
    ret
showmenufunc ENDP

displayinstructionsfunc PROC
    mov eax, white+(blue*16) ;white text on blue bg
    call SetTextColor
    call Clrscr ;clear board
    mov dh, 5
    mov dl, 30 ;row 5 col 30
    call Gotoxy
    mov edx, offset instrtitle ;instruction
    call WriteString
    mov dh, 8
    mov dl, 20
    call Gotoxy
    mov edx, offset rule1 ;you are a taxi driver
    call WriteString
    mov dh, 9
    mov dl, 20
    call Gotoxy
    mov edx, offset rule2 ;use your arrow keys
    call WriteString
    mov dh, 10
    mov dl, 20
    call Gotoxy
    mov edx, offset rule3 ;find a passenger
    call WriteString
    mov dh, 11
    mov dl, 20
    call Gotoxy
    mov edx, offset rule4 ;press spacebar to pick him up
    call WriteString
    mov dh, 12
    mov dl, 20
    call Gotoxy
    mov edx, offset rule5 ;drop him off at a destination
    call WriteString
    mov dh, 13
    mov dl, 20
    call Gotoxy
    mov edx, offset rule6 ;earn points and time
    call WriteString
    mov dh, 14
    mov dl, 20
    call Gotoxy
    mov edx, offset rule7 ;you have 60 seconds
    call WriteString
    mov dh, 15
    mov dl, 20
    call Gotoxy
    mov edx, offset rule8 ;dont crash
    call WriteString
    mov dh, 16
    mov dl, 20
    call Gotoxy
    mov edx, offset rule9 ;pick up bonusses
    call WriteString
    mov dh, 20
    mov dl, 20
    call Gotoxy
    mov edx, OFFSET gobackmsg ;press any key to return
    call WriteString
    call ReadChar
    ret
displayinstructionsfunc ENDP

namemenufunc PROC ;ask user to enter name
    mov eax, white+(yellow*16) ;white text on yellow bg
    call SetTextColor
    call Clrscr ;clear board
    mov ecx, 21 ;21 character long
    mov esi, offset urname
nameloop: mov byte ptr [esi], 0
    inc esi
    loop nameloop ;initialize to 0
    mov dl, 10
    mov dh, 5
    call Gotoxy
    mov edx, offset entername ;enter your name
    call WriteString
    mov edx, offset urname
    mov ecx, 19
    call ReadString ;enter name
    ret
namemenufunc ENDP

winmenufunc PROC
    mov eax, white+(green*16) ;white on green because win
    call SetTextColor
    call Clrscr ;clear board
    mov dh, 10
    mov dl, 20
    call Gotoxy
    mov edx, offset winmsg ;you win the game
    call WriteString
    mov dh, 12
    mov dl, 20
    call Gotoxy
    mov edx, offset goodmsg ;you rock
    call WriteString
    mov dh, 15
    mov dl, 25
    call Gotoxy
    mov edx, offset gobackmsg ;play any key
    call WriteString
    INVOKE PlaySound, offset winsnd, 0, 20001h ;winning sound
    call ReadChar
    ret
winmenufunc ENDP

savegamefunc PROC
    mov edx, offset gamesavefilename ;save the current game into a file
    call CreateOutputFile ;create a file
    mov fhandle, eax
    mov edx, offset currX ;cuurent X coordinates
    mov ecx, sizeof currX ;how many times loop runs for everything is stored in ecx
    call WriteToFile ;write in file
    mov edx, offset currY ;current Y coordinates
    mov ecx, sizeof currY
    call WriteToFile
    mov edx, offset currscore ;players score
    mov ecx, offset currscore
    call WriteToFile
    mov edx, offset tremain ;remaining time
    mov ecx, sizeof tremain
    call WriteToFile
    mov edx, offset carcolor ;color of taxi
    mov ecx, sizeof carcolor
    call WriteToFile
    mov edx, offset carspeed ;speed of taxi based on color
    mov ecx, sizeof carspeed
    call WriteToFile
    mov edx, offset gamemode ;current game mode
    mov ecx, sizeof gamemode
    call WriteToFile
    mov edx, offset dropnum ;number of passengers dropped
    mov ecx, sizeof dropnum
    call WriteToFile
    mov edx, offset npcspeed ;speed of npc cars
    mov ecx, sizeof npcspeed
    call WriteToFile
    mov edx, offset arr
    mov ecx, 2450
    call WriteToFile
    mov eax, fhandle
    call CloseFile
    mov dh, 12
    mov dl, 30
    call Gotoxy
    mov eax, yellow+(red*16) ;yellow text on red bg
    call SetTextColor
    mov edx, offset savemsg
    call WriteString
    mov eax, 1000 ;delay the game for 10000ms
    call Delay
    mov eax, white+(lightGray*16)
    call SetTextColor
    call Clrscr
    ret
savegamefunc ENDP

gameloadfunc PROC
    mov edx, offset gamesavefilename ;file in which game is stored
    call OpenInputFile ;open in input mode
    cmp eax, INVALID_HANDLE_VALUE ;check if file exists
    je nofileexists ;does not exist
    mov fhandle, eax
    mov edx, offset currX ;retrieve x position of car
    mov ecx, sizeof currX
    call ReadFromFile
    mov edx, offset currY ;retrieve y position of car
    mov ecx, sizeof currY
    call ReadFromFile
    mov edx, offset currscore ;retrieve player score
    mov ecx, sizeof currscore
    call ReadFromFile
    mov edx, offset tremain ;retrieve time left
    mov ecx, sizeof tremain
    call ReadFromFile
    mov edx, offset carcolor ;retrieve car color
    mov ecx, sizeof carcolor
    call ReadFromFile
    mov edx, offset carspeed ;retrieve car speed
    mov ecx, sizeof carspeed
    call ReadFromFile
    mov edx, offset gamemode ;retrieve chosen game mode
    mov ecx, sizeof gamemode
    call ReadFromFile
    mov edx, offset dropnum ;retrieve number of passengers dropped
    mov ecx, sizeof dropnum
    call ReadFromFile
    mov edx, offset npcspeed ;retrieve npc speed
    mov ecx, sizeof npcspeed
    call ReadFromFile
    mov edx, offset arr
    mov ecx, 2450
    call ReadFromFile
    mov eax, fhandle
    call CloseFile
    mov ax, currX
    mov prevX, ax ;initialize old coordinates to not mix them up
    mov ax, currY
    mov prevY, ax
    ret
nofileexists:
    ret
gameloadfunc ENDP

getrandomposfunc PROC
    push ebx
    push ecx
    push edx
    push esi
    
retry:
    mov eax, 64
    call RandomRange ;between 1 and 64
    add eax, 3
    mov ebx, eax ;store in ebx
    mov eax, 30
    call RandomRange ;between 1 and 30
    add eax, 3
    mov ecx, cols
    mul ecx ;eax x ecx
    add eax, ebx ;y*70 + x
    mov esi, offset arr
    add esi, eax ;that index
    cmp byte ptr [esi], ' ' ;top left
    jne retry
    cmp byte ptr [esi+1], ' ' ;top right
    jne retry
    cmp byte ptr [esi+70], ' ' ;bottom left
    jne retry
    cmp byte ptr [esi+71], ' ' ;bottom right
    jne retry
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
getrandomposfunc ENDP

npcmovementfunc PROC USES eax ebx ecx edx esi edi ;need to preserve all register values
    call GetMseconds
    sub eax, npclastupdate ;check how much time has passed since last time npc car moved
    cmp eax, npcspeed
    jl exitnpcfunc ;cannot move car in this iteration
    add npclastupdate, eax
    mov ecx, npcnum ;number of npc cars
    mov esi, 0
    mov edi, 0

movementloop:
    push ecx
    mov dh, byte ptr npcY[esi] ;per iteration and car coordinates
    mov dl, byte ptr npcX[esi]
    call Gotoxy ;move to those coordinates
    mov al, ' '
    call WriteChar
    call WriteChar
    call WriteChar
    inc dh
    call Gotoxy
    call WriteChar
    call WriteChar
    call WriteChar ;erase 2 by 3 car
    movzx eax, npcY[esi]
    movzx ebx, npcX[esi] ;go to that address in map array
    imul eax, cols
    add eax, ebx
    mov edx, offset arr
    add edx, eax
    mov byte ptr [edx], ' '
    mov byte ptr [edx+1], ' '
    mov byte ptr [edx+2], ' '
    mov byte ptr [edx+70], ' '
    mov byte ptr [edx+71], ' '
    mov byte ptr [edx+72], ' ' ;remove npc car from those coordinates
    mov al, rnddir[edi]
    cmp al, 1 ;right check
    je checkright
    cmp al, 0 ;left check
    je checkleft
    cmp al, 2 ;up check
    je checkup
    cmp al, 3 ;down check
    je checkdown

checkright:
    mov cl, [edx+3]
    cmp cl, ' '
    jne pickdirection ;not empty
    mov cl, [edx+73]
    cmp cl, ' '
    jne pickdirection ;not empty
    jmp moveright ;can move right

checkleft:
    mov cl, [edx-1] ;check left
    cmp cl, ' '
    jne pickdirection
    mov cl, [edx+69]
    cmp cl, ' '
    jne pickdirection ;not empty
    jmp moveleft ;can move left

checkup:
    mov cl, [edx-70]
    cmp cl, ' '
    jne pickdirection ;cant move
    mov cl, [edx-69]
    cmp cl, ' '
    jne pickdirection ;not empty
    mov cl, [edx-68]
    cmp cl, ' '
    jne pickdirection
    jmp moveup ;go up

checkdown:
    mov cl, [edx+140]
    cmp cl, ' '
    jne pickdirection ;left bottom cell
    mov cl, [edx+141]
    cmp cl, ' '
    jne pickdirection
    mov cl, [edx+142]
    cmp cl, ' '
    jne pickdirection ;not empty
    jmp movedown ;can go down

pickdirection:
    ;picks another random direction
    rdtsc ;i have no clue what this does didnt do this line myself (what i learnt is that this uses the cpu time to generate some random number)
    and eax, 3
    mov rnddir[edi], al ;store this direction
    jmp drawatnewpos ;draw at new place
    
moveright:
    inc npcX[esi] ;increment x coordinate
    jmp drawatnewpos

moveleft:
    dec npcX[esi] ;decrement x coordinate
    jmp drawatnewpos

moveup:
    dec npcY[esi] ;decrement y coordinate
    jmp drawatnewpos

movedown:
    inc npcY[esi] ;increment y coordinate
    jmp drawatnewpos

drawatnewpos: ;draws the car at new posiiton
    movzx eax, npcY[esi]
    movzx ebx, npcX[esi]
    imul eax, cols
    add eax, ebx ;y*70 + x
    mov edx, offset arr
    add edx, eax ;go to the new coordinates
    mov byte ptr [edx], 'C' ;populate the car in the array
    mov byte ptr [edx+1], 'C'
    mov byte PTR [edx+2], 'C' ;upper body
    mov byte ptr [edx+70], 'O' ;left wheel
    mov byte ptr [edx+71], '-' ;base
    mov byte ptr [edx+72], 'O' ;right wheel
    mov dh, byte ptr npcY[esi]
    mov dl, byte ptr npcX[esi]
    call Gotoxy ;go to the x and y coordinates of npc car
    mov eax, cyan+(lightGray*16) ;cyan on light gray bg
    call SetTextColor
    mov al, 219 ;full block
    call WriteChar ;draw the car on screen
    call WriteChar
    call WriteChar ;body
    inc dh ;row below
    call Gotoxy ;goes to the coordinates
    mov eax, white+(lightGray*16) ;white wheels
    call SetTextColor
    mov al, 'O' ;wheels and lower body
    call WriteChar
    mov al, '-'
    call WriteChar
    mov al, 'O'
    call WriteChar
    pop ecx ;retrieve ecx for all other cars
    add esi, 2 ;increment to the other cars coordinates
    inc edi
    dec ecx
    jnz movementloop

exitnpcfunc:
    ret
npcmovementfunc ENDP

difficultymenufunc PROC
    mov eax, black+(cyan*16) ;black on cyan bg
    call SetTextColor
    call Clrscr ;clear board
    mov dl, 20
    mov dh, 5 ;row 5 col 20
    call Gotoxy
    mov edx, offset difficultytitle ;menu for difficulty
    call WriteString
    mov dl, 20
    mov dh, 7
    call Gotoxy
    mov edx, offset diff1 ;easy level
    call WriteString
    mov dl, 20
    mov dh, 8
    call Gotoxy
    mov edx, offset diff2 ;medium level
    call WriteString
    mov dl, 20
    mov dh, 9
    call Gotoxy
    mov edx, offset diff3 ;hard level
    call WriteString
    mov dl, 20
    mov dh, 11
    call Gotoxy
    mov edx, offset diffsel ;please choose an option
    call WriteString

difficultyloop:
    call ReadChar ;check what user enters
    cmp al, '1' ;easy mode
    je seteasy
    cmp al, '2' ;medium mode
    je setmedium
    cmp al, '3' ;hard mode
    je sethard
    jmp difficultyloop ;wrong key pressed

seteasy:
    mov gamelevel, 0
    ret

setmedium:
    mov gamelevel, 1
    ret

sethard:
    mov gamelevel, 2
    ret
difficultymenufunc ENDP

END main