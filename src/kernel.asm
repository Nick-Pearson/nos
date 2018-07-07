;
; FlingOS™ Getting Started tutorials
; Copyright (C) 2015  Edward Nutting
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along
; with this program; if not, write to the Free Software Foundation, Inc.,
; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
;

BITS 32

GLOBAL _Kernel_Start:function

EXTERN cmain

SECTION .text

; BEGIN - Multiboot Header
MultibootSignature dd 464367618
MultibootFlags dd 3
MultibootChecksum dd -464367621
MultibootGraphicsRuntime_VbeModeInfoAddr dd 2147483647
MultibootGraphicsRuntime_VbeControlInfoAddr dd 2147483647
MultibootGraphicsRuntime_VbeMode dd 2147483647
MultibootInfo_Memory_High dd 0
MultibootInfo_Memory_Low dd 0
; END - Multiboot Header

MultibootInfo_Structure dd 0

Kernel_Stack_End:
  TIMES 65535 db 0
Kernel_Stack_Start:

GDT_Contents:
db 0, 0, 0, 0, 0, 0, 0, 0			; Offset: 0  - Null selector - required
db 255, 255, 0, 0, 0, 0x9A, 0xCF, 0	; Offset: 8  - KM Code selector - covers the entire 4GiB address range
db 255, 255, 0, 0, 0, 0x92, 0xCF, 0	; Offset: 16 - KM Data selector - covers the entire 4GiB address range
db 255, 255, 0, 0, 0, 0xFA, 0xCF, 0	; Offset: 24 - UM Code selector - covers the entire 4GiB address range
db 255, 255, 0, 0, 0, 0xF2, 0xCF, 0	; Offset: 32 - UM Data selector - covers the entire 4GiB address range
GDT_Pointer db 39, 0, 0, 0, 0, 0

_Kernel_Start:

  cli

  mov dword ECX, 0x2BADB002
  cmp ECX, EAX
  jne HandleNoMultiboot


	; Init Screen Colour
	mov EAX, 0x2000
	mov EBX, 0xB8000
	mov ECX, 2000
Print:
	mov word [EBX], AX
	add EBX, 2
	loop Print

	; Enter protected mode
	mov dword EAX, CR0
	or EAX, 1
	mov dword CR0, EAX

	mov dword ESP, Kernel_Stack_Start

	mov dword [GDT_Pointer + 2], GDT_Contents
	mov dword EAX, GDT_Pointer
	lgdt [EAX]
	; Set data segments
	mov dword EAX, 0x10
	mov word DS, EAX
	mov word ES, EAX
	mov word FS, EAX
	mov word GS, EAX
	mov word SS, EAX

  ; Force reload of code segment
  jmp 8:Boot_FlushCsGDT
Boot_FlushCsGDT:
  ; END - Tell CPU about GDT

  ; BEGIN - Set Screen Colour
  mov dword EAX, 0x5F		; Colour: 0x5- = Purple background, 0x-F = White foreground
  mov dword EBX, 0xB8000 	; Display Memory address
  mov dword ECX, 2000		; 80 x 25 Characters - VGA Text-mode Display size
  .ColourOutput4:
  mov byte [EBX], 0
  mov byte [EBX+1], AL
  add EBX, 2
  loop .ColourOutput4
  ; END - Set Screen Colour

	call cmain

	jmp Halt

Halt:

	cli

  ; Set Screen Colour
  mov dword EAX, 0x0F		; Colour: 0x0- = Black background, 0x-F = White foreground
  mov dword EBX, 0xB8000 	; Display Memory address
  mov dword ECX, 2000		; 80 x 25 Characters - VGA Text-mode Display size
  .ColourOutput5:
  mov byte [EBX], 0
  mov byte [EBX+1], AL
  add EBX, 2
  loop .ColourOutput5

	; Display SYSTEM HALT message
  mov dword EBX, 0xB8000 	; Display Memory address

	mov byte [EBX], 0x53
	add EBX, 2
	mov byte [EBX], 0x59
	add EBX, 2
	mov byte [EBX], 0x53
	add EBX, 2
	mov byte [EBX], 0x54
	add EBX, 2
	mov byte [EBX], 0x45
	add EBX, 2
	mov byte [EBX], 0x4d
	add EBX, 2
	mov byte [EBX], 0x20
	add EBX, 2
	mov byte [EBX], 0x48
  add EBX, 2
	mov byte [EBX], 0x41
  add EBX, 2
	mov byte [EBX], 0x4c
  add EBX, 2
	mov byte [EBX], 0x54
  add EBX, 2


	hlt
  jmp Halt

HandleNoMultiboot:
  mov EAX, 0x4F00
  mov EBX, 0xB8000
  mov ECX, 2000
Output:
	mov word [EBX], AX
	add EBX, 2
	loop Output
  jmp Halt
