;~ ----------------------------------------------------------------
;~  This script cleans up old directories at designated location(s)
;~  
;~  Language: AutoIt 3
;~  cleanup.au3 v.0.99b by Mikhail Kostechuk
;~ ----------------------------------------------------------------
#Include<mail.au3>
#Include<cleanup.conf>

Func AgeInDays($year,$month,$day)
   Local $DaysInMonth[12] = [31,28,31,30,31,30,31,31,30,31,30,31]
   
   Local $Days = $day
   For $i=$month-1 to 1 Step -1
	  $Days = $Days + $DaysInMonth[$i-1]
   Next
 
   Local $Age = @YDAY - $Days
   If $Age < 0 Then $Age = 365 + $Age
   
   If (@YEAR > $year) and (@MON >= $month) and (@MDAY >= $day) Then $Age = $Age + 365 * (@YEAR - $year)
   
   Return $Age
EndFunc

Func List($path)
   ; Shows the filenames of all files in the current directory.
   Local $search = FileFindFirstFile($path & "*.*")

   ; Check if the search was successful
   If $search = -1 Then
	  MsgBox(0, "Error", "No files/directories matched the search pattern")
	  Exit
   EndIf

   Local $Ar=0

   While 1
	  Local $file = FileFindNextFile($search)
	  If @error Then ExitLoop
	  
	  If @extended = 1 AND NOT((StringLeft($file,1) = "_") OR (StringLeft($file,1) = "!"))  Then ;~ and Not(StringInStr(FileGetAttrib($path & $file),"H"))  |  $FNS = "_" OR $FNS = "!"
		 If IsArray($Ar) Then
			ReDim $Ar[UBound($Ar, 1)+1][3] 
		 Else
			Dim $Ar[1][3]
		 EndIf
		 
		 $Ar[UBound($Ar, 1)-1][0] = $file
;~ 		 $Ar[UBound($Ar, 1)-1][1] = Round(DirGetSize($path & $file) / 1024 / 1024 / 1024,3)
;~ 		 $Ar[UBound($Ar, 1)-1][1] = 1
		 Local $fgt = FileGetTime($path & $file)
		 $Ar[UBound($Ar, 1)-1][2] = AgeInDays($fgt[0],$fgt[1],$fgt[2])
	  EndIf
   WEnd

   ; Close the search handle
   FileClose($search)
   
   Return $Ar
EndFunc

Func PrintArrayContents($array)
   Local $output = ""
   For $r = 0 To UBound($array, 1) - 1
	  $output = $output & @LF
	  For $c = 0 To UBound($array, 2) - 1
		 $output = $output & $array[$r][$c] & @TAB & @TAB & @TAB
		 If (StringLen($array[$r][0]) < 8)  and ($c = 0) Then $output = $output & @TAB		 
	  Next
   Next
 
   MsgBox(4096, "Array Contents", $output)
EndFunc

Func BubbleSort($array,$col=2)
   Local $hasChanges = True
   
   While $hasChanges
	  $hasChanges = False
	  For $i=0 To UBound($array)-2
		 If $array[$i][$col] < $array[$i+1][$col] Then
			For $j=0 To UBound($array,2)-1
			   Local $temp = $array[$i][$j]
			   $array[$i][$j] = $array[$i+1][$j]
			   $array[$i+1][$j] = $temp
			Next
			$hasChanges = True
		 EndIf
	  Next
   WEnd
   
   
   Return $array
EndFunc

Func CurrDate()
    Return @MDAY&"."&@MON&"."&@YEAR
EndFunc
 
Func CurrTime()
    Return @HOUR&":"&@MIN&":"&@SEC
EndFunc

Func LogLine($line,$logFileName)
   $fh = FileOpen($logFileName, 1)

   ; Check if file opened for writing OK
   If $fh = -1 Then
	  MsgBox(0, "Error", "Unable to open file.")
	  Exit
   EndIf

   FileWriteLine($fh, "["&CurrDate()&"]["&CurrTime()&"] "&$line)
   
   FileClose($fh)
EndFunc

Func DumpToFileArrayContents($array,$dumpFileName)
   Local $output = ""
   For $r = 0 To UBound($array, 1) - 1
	  $output = $output & @LF
	  For $c = 0 To UBound($array, 2) - 1
		 $output = $output & $array[$r][$c] & @TAB & @TAB & @TAB
		 If (StringLen($array[$r][0]) < 8)  and ($c = 0) Then $output = $output & @TAB		 
	  Next
   Next
 
   $fh = FileOpen($dumpFileName, 2)
   ; Check if file opened for writing OK
   If $fh = -1 Then
	  MsgBox(0, "Error", "Unable to open file " & $dumpFileName)
	  Exit
   EndIf

   FileWriteLine($fh, "["&CurrDate()&"]["&CurrTime()&"] "&"Current directory table:")
   FileWriteLine($fh, $output)
   
   FileClose($fh)   
   
;~    MsgBox(4096, "Array Contents", $output)
EndFunc

For $j=0 To UBound($pathArray, 1)-1
   $path = $pathArray[$j]
   $logFileName = $path & $logFN
   $dumpFileName = $path & $dumpFN
   Local $myArray = List($path)
   $myArray = BubbleSort($myArray)
   DumpToFileArrayContents($myArray, $dumpFileName)
   ;~ PrintArrayContents($myArray)

   For $i=0 To UBound($myArray)-2
	  If $myArray[$i][2] = $maxAge Then
		 For $k=0 To UBound($ToAddressArray)-1
			$ToAddress = $ToAddressArray[$k]
			$rc = _INetSmtpMailCom($SmtpServer, $FromName, $FromAddress, $ToAddress, $path & $myArray[$i][0] & " WILL BE DELETED TOMORROW!", $path & $myArray[$i][0] & " WILL BE DELETED TOMORROW!", $AttachFiles, $CcAddress, $BccAddress, $Importance, $Username, $Password, $IPPort, $ssl)
			If @error Then
			   MsgBox(0, "Error sending message", "Error code:" & @error & "  Description:" & $rc)
			EndIf
		 Next
	  EndIf
   
	  If $myArray[$i][2] > $maxAge Then
		 LogLine("Deleting " & $myArray[$i][0] & " folder...", $logFileName)
		 DirRemove($path & $myArray[$i][0], 1)
		 LogLine("OK", $logFileName)
	  EndIf
   Next
Next