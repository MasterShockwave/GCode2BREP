#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

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
str_temp := substr(inFile, slashPos + 1)
dotPos := InStr(str_temp,".",,1)
outFile := substr(str_temp, dotPos + 1)
;StringLeft, outFile, str_temp, dotPos - 1
outFile := outFile . ".brep"

;--WORKING--

;for each line in gcode
Loop, Read, %inFile%, %outFile%
{
if (instr(A_LoopReadLine, "G1",,1) = 1 OR instr(A_LoopReadLine, "G0",,1) = 1) ;if the line is a G1 of G0 move.
		if (instr(A_LoopReadLine, "E",,1) = 1 ; if the current line has an E value (that is, it has an extrude command and prints a line)
			{
			current_point = readXYZ(A_LoopReadLine) ;read the XYZ data from line string using defined function
			if previous_point = ;catch the case where the first line is read but the previous point is not defined yet
			else
				{
				xVal := current_point[1]
				FileAppend, %xVal% ;create line b/w prev point and current point. If previous point is null, then goto Next line (break loop)
				}
			}
		;else
			;current point = XYZ (read)
;previous point = current point
;Next line
}


readXYZ(lineString) ;returns a 1 x 3 matrix in format {X,Y,Z}. Value is blank if corresponding value is not found.
{
Xpos := InStr(lineString, "X",,1) ;find X position
if Xpos = 0
	Goto skipX
StringLen, lineLen, lineString ;find string length
StringRight, Xright, lineString, lineLen - Xpos ;find text right of X position
spacePos := InStr(Xright, " ",,1) ;find space position in this resulting text
StringLeft, X_ptData, Xright, spacePos ;find text left of this space position.
skipX:

;repeat for other cartesian coords
Ypos := InStr(lineString, "Y",,1)
if Ypos = 0
	Goto skipY
StringRight, Yright, lineString, lineLen - Ypos
spacePos := InStr(Yright, " ",,1)
StringLeft, Y_ptData, Yright, spacePos
skipY:

Zpos := InStr(lineString, "Z",,1)
if Zpos = 0
	Goto skipZ
StringLen, lineLen, lineString
StringRight, Zright, lineString, lineLen - Zpos
spacePos := InStr(Zright, " ",,1)
StringLeft, Z_ptData, Zright, spacePos
skipZ:

return XYZdata := [X_ptData, Y_ptData, Z_ptData]
}
