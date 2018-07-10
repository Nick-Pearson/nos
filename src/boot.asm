BITS 32

SECTION .text

GLOBAL _Kernel_Start:function

EXTERN cmain

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

KERNEL_VIRTUAL_BASE equ 0xC0000000
KERNEL_PAGE_TABLE equ (KERNEL_VIRTUAL_BASE >> 22)

Kernel_Stack_End: TIMES 65535 db 0
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

	mov ESP, 0xF0F0F0F0

  mov dword ECX, 0x2BADB002
  cmp ECX, EAX
  jne (HandleNoMultiboot - KERNEL_VIRTUAL_BASE)

	mov ESP, 0xE0E0E0E0

	mov dword [MultibootInfo_Structure - KERNEL_VIRTUAL_BASE], EBX
	add dword EBX, 0x4
	mov dword EAX, [EBX]
	mov dword [MultibootInfo_Memory_Low - KERNEL_VIRTUAL_BASE], EAX
	add dword EBX, 0x4
	mov dword EAX, [EBX]
	mov dword [MultibootInfo_Memory_High - KERNEL_VIRTUAL_BASE], EAX
	mov ESP, 0xD0D0D0D0

	mov dword eax, 0x2F
	mov dword ebx, 0xB8000
	mov dword ecx, 2000
	.ColourSetup:
	mov byte [ebx], 0
	mov byte [ebx+1], al
	add ebx, 2
	loop .ColourSetup

	; Enter protected mode
	mov dword EAX, CR0
	or EAX, 1
	mov dword CR0, EAX

	mov ESP, 0xC0C0C0C0

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

	mov ESP, 0xB0B0B0B0
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

	mov ESP, 0xA0A0A0A0

	lea EAX, [Page_Table1 - KERNEL_VIRTUAL_BASE]
	add EAX, (KERNEL_PAGE_TABLE * 1024 * 4)
	mov EBX, 7
	mov ECX, (1024 * 4)
	.Loop2:
	mov [EAX], EBX
	add EAX, 4
	add EBX, 4096
	loop .Loop2

	mov ESP, 0x90909090
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

	mov ESP, 0x80808080
	; Enable paging
	lea ECX, [Page_Directory - KERNEL_VIRTUAL_BASE]
	mov CR3, ECX
	mov ECX, CR0
	mov ESP, 0x70707070
	or ECX, 0x80000000
	mov CR0, ECX


	lea ECX, [HighHalf]
	jmp ECX

HighHalf:
	nop
	mov ESP, 0x60606060

	; Initialise Stack
	mov dword ESP, Kernel_Stack_Start

	; Initialise GDT Data
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
  jmp 8:(Boot_FlushCsGDT - KERNEL_VIRTUAL_BASE)
Boot_FlushCsGDT:

  ; END - Tell CPU about GDT
	mov byte [0xB82A6], 0x64
	mov byte [0xB82A8], 0x6f
	mov byte [0xB82AA], 0x6e
	mov byte [0xB82AC], 0x65
	mov byte [0xB82AE], 0x2e

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
