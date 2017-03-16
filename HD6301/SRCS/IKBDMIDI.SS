; /// SSAVCALL 3.02 - KeyBoard & MIDI DRIVER - ATARI Falcon030 - KOSS 2000 ////

; Author   : Kochise
; Date     : 04/19/07/2000
; Type     : SSAVCALL DRIVER Module
; Language : Assembler (Motorola 68030)
; Sequence : IKBD/MIDI Interruption
; Purpose  : ATARI Intelligent Keyboard & MIDI DRIVER

; Machina  : ATARI Falcon030
; O.S.     : SSAVCALL 3

; ### HardWare Informations ###################################################
; Address     Size Status Name         Purpose
; $FFFF9200.w WORD READ   JoyButtons   States of the JoyPads Standard Buttons
