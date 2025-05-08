TITLE Project 6     (Proj6_willica5.asm)

; Author: Cassidy Williams
; Last Modified: 12/9/23
; Course number/section:   CS271 Section 400
; Project Number:  6
; Description: Program to implement string primitives and macros.
;   Program asks user for valid integers, validates and converts the ascii string input to
;   integer values, calculates sum and average, and converts back to ascii to displays the
;    list of values, sum, and average to the user. Does not accept input of non-numeric
;   characters nor values that cannot fit properly in an SDWORD.

INCLUDE Irvine32.inc

; MACROS

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Display prompt and read user's input to memory location
;
; Preconditions: saveLocation references a SDWORD
;                do not use eax, ecx, edx as arguments
;
; Postconditions: all registers restored to pre-call status
;
; Receives: promptForInput = prompt text for input (reference)
;           MAX_LENGTH is a global constant
;
; Returns: saveLocation = memory location now contains input values (reference)
;          bytesRead = number of bytes read (reference)
; ---------------------------------------------------------------------------------
mGetString MACRO promptForInput, saveLocation, bytesRead
    ; preserve registers
    push    eax
    push    ecx
    push    edx

    ; display prompt and save string
    mDisplayString promptForInput
    mov     edx, saveLocation
    mov     ecx, MAX_LENGTH
    inc     ecx     ; read extra character so we can see if string is too long
    call    ReadString
    mov     bytesRead, eax

    ; restore registers
    pop     edx
    pop     ecx
    pop     eax
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Print string stored in memory location to console
;
; Preconditions: savedString holds null-terminated string
;
; Postconditions: all registers restored to pre-call status
;
; Receives: savedString = string memory location (input/reference)
;
; Returns: prints string to console
; ---------------------------------------------------------------------------------
mDisplayString MACRO savedString
    push    edx
    mov     edx, savedString
    call    WriteString
    pop     edx
ENDM

; CONSTANTS
MAX_LENGTH = 12             ; max length of string
ARRAY_SIZE = 10             ; max size of array
MAX_VALUE = 2147483647      ; max value for an SDWORD

.data
intro1              BYTE    "Welcome to Cassidy Williams' String Primitives and Macros Program",10,13,0
intro2              BYTE    "Please enter 10 signed decimal integers. Each number must be in the range of ",
                            "-2,147,483,648 to +2,147,483,647. After 10 valid numbers have been input, ",
                            " the program will then display the list of integers, their sum, and truncated average.",13,10,0
ecStatement         BYTE    "**EC: User input lines are numbered and running subtotal is displayed.",10,13,0
inputPrompt         BYTE    "Please enter a signed number: ",0
displayDotSpace     BYTE    ". ",0
runningSumTitle     BYTE    "The sum of your valid entries so far is: ",0
inputError          BYTE    "ERROR: Your number is out of range or invalid!",13,10,0
outputListTitle     BYTE    "The numbers you entered are:",13,10,0
outputListComma     BYTE    ", ",0
outputSumTitle      BYTE    "The sum of these number is: ",0
truncAverageTitle   BYTE    "The truncated average is: ",0
goodbyeText         BYTE    "Thank you for using my program, have a nice day!",13,10,0
integerArray        SDWORD  ARRAY_SIZE DUP(?)
integerSum          SDWORD  ?
truncAverage        SDWORD  ?
inputBytesRead      SDWORD  ?


.code
main proc
; --------------------------
; Display program introduction and valid input range
; --------------------------
    mDisplayString offset intro1
    call    CrLf
    mDisplayString offset intro2
    call    CrLf
    mDisplayString offset ecStatement
    call    CrLf

    ; initiate necessary values
    mov     edi, offset integerArray
    mov     ecx, ARRAY_SIZE
    mov     ebx, 1
    mov     integerSum, 0

; --------------------------
; Get 10 valid integers from user and store in an array
; --------------------------
_fillListLoop:
    push    ebx                 ; WriteVal parameter: numbering for user input
    call    WriteVal
    mDisplayString offset displayDotSpace

    ; push parameters for ReadVal
    push    offset inputError
    push    inputBytesRead
    push    offset inputPrompt
    push    edi
    call    ReadVal

    ; calculate and display running sum
    mDisplayString offset runningSumTitle
    mov     eax, [edi]
    add     integerSum, eax
    push    integerSum          ; WriteVal parameter
    call    WriteVal
    call    CrLf

    ; iterate to fill list
    add     edi, type integerArray
    inc     ebx                 ; input count
    loop    _fillListLoop
    call    CrLf

; --------------------------
; Display list of valid integers entered by user
; --------------------------
    mDisplayString offset outputListTitle
    mov     ecx, ARRAY_SIZE
    mov     edi, offset integerArray

_displayListLoop:
    ; print each element in integerArray
    push    [edi]               ; WriteVal parameter
    call    WriteVal
    cmp     ecx, 1
    je      _skipComma          ; don't put comma after last element
    mDisplayString offset outputListComma
_skipComma:
    add     edi, type integerArray
    loop    _displayListLoop
    call    CrLf

; --------------------------
; Display sum  and average of all valid integers entered by user
; --------------------------
    mDisplayString offset outputSumTitle
    push    integerSum          ; WriteVal parameter
    call    WriteVal
    call    CrLf

    ; calculate average
    mov     eax, integerSum
    mov     ebx, ARRAY_SIZE
    cdq
    idiv    ebx
    mov     truncAverage, eax

    ; display average
    mDisplayString offset truncAverageTitle
    push    truncAverage        ; WriteVal parameter
    call    WriteVal
    call    CrLf
    call    CrLf

; --------------------------
; display goodbye message
; --------------------------
    mDisplayString offset goodbyeText
    Invoke ExitProcess,0        ; exit to operating system
main ENDP

; PROCEDURES

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Get string and convert to numerical value representation, validating it is within
;   range of SDWORD, then save to memory location.
;
; Preconditions:  [epb + 8] references a SDWORD
;
; Postconditions: all registers restored to pre-call status
;
; Receives: [ebp + 12] = reference to prompt to input (to pass to mGetString)
;           [ebp + 20] = reference to error message
;           MAX_LENGTH is a global constant (to pass to mGetString)
;
; Returns: [ebp + 8] = reference to validated value
;          [ebp + 16] = number of bytes of input
; ---------------------------------------------------------------------------------
ReadVal PROC USES eax ebx ecx edx edi esi
    local asciiString[MAX_LENGTH]:BYTE
    ; clear string
    lea     edi, asciiString
    mov     ecx, MAX_LENGTH
    mov     al, 0
    rep     stosb

; --------------------------
; get user input as string of ascii chars saved to asciiString
; --------------------------
_getInput:
    lea     esi, asciiString
    mGetString [ebp+12], esi, [ebp+16]
    mov     ecx, [ebp+16]
    mov     eax, 0
    cld
    lodsb

; --------------------------
; convert string of ascii digits to numerical value, validating 
;   the value will fit in an SDWORD as we go
; --------------------------
    ; check if first symbol is - or +
    cmp     al, 45              ; "-"
    je      _negativeValue
    cmp     al, 43              ; "+"
    je      _positiveValue
    push    0                   ; indicate positive result
    push    0                   ; start value at 0, save to stack

_convertToIntLoop:
    ; validate ascii character represents a digit
    cmp     al, 48
    jl      _invalidValueError
    cmp     al, 57
    jg      _invalidValueError

    ; convert ascii digit to numerical value
    sub     al, 48              ; ascii to digit
    pop     edx                 ; saved running value
    push    eax                 ; preserve current digit value
    mov     eax,edx
    mov     ebx, 10
    mul     ebx                 ; shift running value digits (x10)
    jo      _invalidValueError
    mov     edx, eax
    pop     eax                 ; restore current digit value
    add     edx, eax
    push    edx                 ; save running value

    ; check for edge case of -2147483648
    cmp     edx, MAX_VALUE+1
    ja      _invalidValueError
    jne     _loadNext
    pop     edx
    pop     ebx
    cmp     ebx, 1              ; check for negative marker
    push    ebx
    push    edx
    jne     _invalidValueError

_loadNext:
    ; load next character in string
    lodsb
    loop    _convertToIntLoop
    jmp     _saveValueCheckSign

_invalidValueError:
    ; align stack and display invalid input message
    pop     edx
    pop     edx
    mDisplayString [ebp+20]
    jmp     _getInput

; --------------------------
; handle input with leading - or +
; --------------------------
_positiveValue:
    ; input string has leading + we must ignore
    push    0                   ; indicate positive result
    push    0                   ; start value at 0, save to stack
    lodsb
    loop    _convertToIntLoop
    jmp     _invalidValueError  ; + cannot be only character

_negativeValue:
    ; input string has leading - we must note
    push    1                   ; indicate negative result
    push    0                   ; start value at 0, save to stack
    lodsb
    loop    _convertToIntLoop
    jmp     _invalidValueError  ; - cannot be only character

; --------------------------
; save value to memory location
; --------------------------
_saveValueCheckSign:
    ; check if input was negative
    pop     eax
    pop     ebx
    cmp     ebx, 0
    je      _saveValue          ; save positive as is
    neg     eax                 ; save negative as negative

_saveValue:
    ; save value to destination
    mov     edi, [ebp+8]
    mov     [edi], eax
    ret     16
ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Convert a numeric value to a string of ascii digits and print to console.
;
; Preconditions: [ebp + 8] references some SDWORD
;
; Postconditions: all registers restored to pre-call status
;
; Receives: [ebp + 8] = value to be displayed
;
; Returns: prints value as ascii digits to console
; ---------------------------------------------------------------------------------
WriteVal PROC USES eax ebx ecx edx edi esi
    local asciiString[MAX_LENGTH]:BYTE
    ; clear string
    lea     edi, asciiString
    mov     ecx, MAX_LENGTH
    mov     al, 0
    rep     stosb
    std                     ; build string backwards

; --------------------------
; Convert numeric value to string of ascii digits
; --------------------------
    lea     edi, asciiString
    add     edi, MAX_LENGTH
    dec     edi             ; offset index
    dec     edi             ; leave room for null terminator
    mov     eax, [ebp+8]    ; grab value

    ; check if value is negative
    cmp     eax, 0ffffffffh
    push    0               ; mark as positive number for display later
    jg     _asciiConvert
    pop     ebx
    push    1               ; mark as negative number for display later
    neg     eax             ; switch to positive for correct ascii results

_asciiConvert:
    ; isolate lowest digit and convert to ascii
    mov     ebx, 10
    mov     edx, 0
    div     ebx
    add     edx, 48         ; convert digit to ascii
    push    eax
    mov     eax, edx
    stosb                   ; store ascii char in string

    ; check if conversion is complete
    pop     eax
    cmp     eax, 0
    jg      _asciiConvert   ; jump back to convert remaining digits

    ; add negative sign if necessary
    pop     eax
    cmp     eax, 0          ; check negative marker
    je      _stringShift
    mov     eax, 45         ; add negative sign to string
    stosb

; --------------------------
; shift string characters to beginning of string (we built string backwards from end)
; --------------------------
_stringShift:
    lea     eax, asciiString
    mov     ecx, 0          ; count of empty characters
    mov     edx, 0          ; current index
    mov     ebx, 0          ; bl to hold current character

_countEmptyChars:
    ; count empty characters to know by how may positions to shift string
    mov     bl, [eax]
    cmp     bl, 0           ; check if empty character
    jne     _characterShift
    inc     ecx
    inc     eax
    inc     edx
    cmp     edx, MAX_LENGTH ; check if at last position
    je      _characterShift
    jmp     _countEmptyChars

_characterShift:
    ; shift characters so string is displayed properly
    cld
    mov     ebx, ecx        ; ebx now to hold count of empty characters
    inc     ebx             ; null character at end empty as well
    mov     ecx, MAX_LENGTH
    sub     ecx, ebx
    push    ecx             ; save count of non empty characters
    lea     esi, asciiString
    add     esi, ebx
    dec     esi             ; first non empty character
    lea     edi, asciiString
    rep     movsb           ; shift each character

    ; add null terminator to end of shifted string
    lea     edi, asciiString
    pop     ecx             ; load count of non empty characters
    add     edi, ecx
    mov     al, 0
    stosb

; --------------------------
; print resulting ascii string to console
; --------------------------
    lea     esi, asciiString
    mDisplayString esi
    ret     4
WriteVal ENDP

END main
