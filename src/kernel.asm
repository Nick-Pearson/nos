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

KERNEL_VIRTUAL_BASE equ 0xC0000000
KERNEL_PAGE_TABLE equ (KERNEL_VIRTUAL_BASE >> 22)

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
  jne (HandleNoMultiboot - KERNEL_VIRTUAL_BASE)

	mov dword [MultibootInfo_Structure - KERNEL_VIRTUAL_BASE], EBX
	add dword EBX, 0x4
	mov dword EAX, [EBX]
	mov dword [MultibootInfo_Memory_Low - KERNEL_VIRTUAL_BASE], EAX
	add dword EBX, 0x4
	mov dword EAX, [EBX]
	mov dword [MultibootInfo_Memory_High - KERNEL_VIRTUAL_BASE], EAX

	; Enter protected mode
	mov dword EAX, CR0
	or EAX, 1
	mov dword CR0, EAX

	; Initialise Stack
	mov dword ESP, (Kernel_Stack_Start - KERNEL_VIRTUAL_BASE)

	; Initialise GDT Data
	mov dword [GDT_Pointer - KERNEL_VIRTUAL_BASE + 2], (GDT_Contents - KERNEL_VIRTUAL_BASE)
	mov dword EAX, (GDT_Pointer - KERNEL_VIRTUAL_BASE)
	lgdt [EAX]
	; Set data segments
	mov dword EAX, 0x10
	mov word DS, EAX
	mov word ES, EAX
	mov word FS, EAX
	mov word GS, EAX
	mov word SS, EAX

  ; Force reload of code segment
  jmp 8:(Boot_FlushCsGDT - KERNEL_VIRTUAL_BASE)
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

	; VIRTUAL MEMORY
	; Initilise Page Tables
	lea EAX, [Page_Table1 - KERNEL_VIRTUAL_BASE]
	mov EBX, 7
	mov ECX, (1024 * 4)
	.Loop1:
	mov [EAX], EBX
	add EAX, 4
	add EBX, 4096
	loop .Loop1

	lea EAX, [Page_Table1 - KERNEL_VIRTUAL_BASE]
	add EAX, (KERNEL_PAGE_TABLE * 1024 * 4)
	mov EBX, 7
	mov ECX, (1024 * 4)
	.Loop2:
	mov [EAX], EBX
	add EAX, 4
	add EBX, 4096
	loop .Loop2

	; Initialise Page Directory
	lea EBX, [Page_Table1 - KERNEL_VIRTUAL_BASE]
	or EBX, 7
	lea EDX, [Page_Directory - KERNEL_VIRTUAL_BASE]
	mov ECX, 1024
	.Loop3:
	mov [EDX], EBX
	add EDX, 4
	add EBX, 4096
	loop .Loop3

	; Enable paging
	lea ECX, [Page_Directory - KERNEL_VIRTUAL_BASE]
	mov CR3, ECX
	mov ECX, CR0
	or ECX, 0x80000000
	mov CR0, ECX

	lea ECX, [HighHalf]
	jmp ECX

HighHalf:
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


SECTION .bss

GLOBAL Page_Table1:data
GLOBAL Page_Directory:data

align 4096
Page_Table1: resb (1024 * 4 * 1024)	; Reserve uninitialised space for Page Table -  # of entries/page table * 4 bytes/entry * total # of page tables
											; actual size = 4194304 bytes = 4MiB, represents 4GiB in physical memory
											; ie. each 4 byte entry represent 4 KiB in physical memory
Page_Directory: resb (1024 * 4 * 1) ; Reserve uninitialised space for Page Directory - # of pages tables * 4 bytes/entry * # of directory (4096 = 4 KiB)
