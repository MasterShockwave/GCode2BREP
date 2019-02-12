#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;This script now works up to outputting a debug .brep file (not in brep format).
;It looks ready to move onto customising output to brep format.
;Currently, if point if not found on a line, then the value is null. For brep, this will need to be changed so that a null retains the last value.
;Otherwise it will go back to origin for that value on each unchanged line.

;if the command is G0 or G1, find the point data and count it as current point.
;	note that if one coord is missing, then this remains the same as the previous value.
;if there is an E command in the code, draw a line from previous point to current point.
;if not, store current point but don't draw line.

FileSelectFile, inFile,,%A_ScriptDir%\, Select G-Code file
if inFile =
	ExitApp

;check file type
filecheck := InStr(inFile, ".g",,0)
if filecheck = 0
	{
	Msgbox This is not a G-code file.
	ExitApp
	}
	
;determine output filename
slashPos := InStr(inFile, "\",,0) ;starting position of 0 reads the string from right to left.
outPath := substr(inFile, 1, slashpos) ;find the path to the input file. This is where the output file will go.
str_temp := substr(inFile, slashPos + 1)
dotPos := InStr(str_temp,".",,1)
outFile := substr(str_temp, 1, strlen(str_temp) - dotPos - 1) ;this is a stringright equivalent
outFile := outFile . ".brep"
;remove comment below for final
;outfile := outPath . outFile

;delete any existing brep file of the same name
FileDelete, %outFile%

;for each line in gcode
Loop, Read, %inFile%, %outFile%
{
if (instr(A_LoopReadLine, "G1",,1) = 1 OR instr(A_LoopReadLine, "G0",,1) = 1) ;if the line is a G1 or G0 move.
	{
	current_point := [empty,empty,empty] ;reinitialise current point in case the readXYZ function makes no changes to this variable. The "empty" variable is not set, thus enters nulls.
	current_point := readXYZ(A_LoopReadLine) ;read the XYZ data from line string using defined function
	xVal := current_point[1]
	yVal := current_point[2]
	zVal := current_point[3]
	
;msgbox Debug. Line is %A_Index%. Found values are:`n`nX = %xVal%`nY = %yVal%`nZ = %zVal%

	if (instr(A_LoopReadLine, "E",,1) > 0) ;if the current line has an E value (that is, it has an extrude command and prints a line) (or any other "e"!)
		{
		if (instr(A_LoopReadLine, ";",,1) = 0) or (instr(A_LoopReadLine, "E",,1) < instr(A_LoopReadLine, ";",,1)) ;if the current line DOES NOT have a comment in it, OR the "E" was found BEFORE the comment.			
			{
			FileAppend, On line %A_Index%`, X = %xVal%%A_Tab%Y = %yVal%%A_Tab%Z = %zVal%%A_Tab%Previous point is: x%prev_xVal%`, y%prev_yVal%`, z%prev_zVal%`n  ;create line b/w prev point and current point. If previous point is null, then goto Next line (break loop)
			}
		}
	prev_xVal := xVal
	prev_yVal := yVal
	prev_zVal := zVal
	}
}

;line read function definition.

readXYZ(lineString) ;returns a 1 x 3 matrix in format {X,Y,Z}. Value is blank if corresponding value is not found.
;NEED TO GO THRU THIS FUNCTION AND REPLACE STRINGLEFT AND RIGHTS WITH SUBSTRS.
{
;check if line has a comment to watch out for.
if InStr(lineString, ";",,1) > 0
	hasComment = 1
else
	hasComment = 0

if (hasComment = 0) or ((hasComment = 1) and (InStr(lineString, "X",,1) < InStr(lineString, ";",,1))) ;if the X value is found before any comments (if they exist)
	Xpos := InStr(lineString, "X",,1) ;find X position
Else
	Xpos := 0 ;manually set to 0 if the only x value is part of a comment.
if Xpos = 0
	Goto skipX
StringLen, lineLen, lineString ;find string length
StringRight, Xright, lineString, lineLen - Xpos ;find text right of X position
spacePos := InStr(Xright, " ",,1) ;find space position in this resulting text
if spacepos = 0
	X_ptData := Xright ;if no space after the value, then the value is at the end of the string, and no string left manipulation is required.
else
	StringLeft, X_ptData, Xright, spacePos - 1 ;find text left of this space position.
skipX:

;repeat for other cartesian coords
if (hasComment = 0) or ((hasComment = 1) and (InStr(lineString, "Y",,1) < InStr(lineString, ";",,1)))
	Ypos := InStr(lineString, "Y",,1)
Else
	Ypos := 0
if Ypos = 0
	Goto skipY
StringRight, Yright, lineString, lineLen - Ypos
spacePos := InStr(Yright, " ",,1)
if spacepos = 0
	Y_ptData := Yright
else
	StringLeft, Y_ptData, Yright, spacePos - 1
skipY:

if (hasComment = 0) or ((hasComment = 1) and (InStr(lineString, "Z",,1) < InStr(lineString, ";",,1)))
	Zpos := InStr(lineString, "Z",,1)
Else
	Zpos := 0
if Zpos = 0
	Goto skipZ
StringLen, lineLen, lineString
StringRight, Zright, lineString, lineLen - Zpos
spacePos := InStr(Zright, " ",,1)
if spacepos = 0
	Z_ptData := Zright
else
	StringLeft, Z_ptData, Zright, spacePos - 1
skipZ:



return XYZdata := [X_ptData, Y_ptData, Z_ptData]
}