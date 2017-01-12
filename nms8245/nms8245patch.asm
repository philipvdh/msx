  output "nms8245patched.rom"
  org 	0


newkey:	equ	0fbe5h


; Include NMS8245 rom with sha1sum cc57c1dcd7249ea9f8e2547244592e7d97308ed0
; Search and you will find it ;-)
  incbin "NMS8245SystemROM1.08.bin"


;
; Change function keys
;
  fpos 013c3h
  defb "load ",022h,0
  defb "save ",022h,0
  defb "files",0dh,0
  defb "list ",0
  defb "run",0dh,0
  defb "color 15,4,4",0dh,0
  defb "copy ",0
  defb "files ",022h,0
  defb "dir ",0
  defb "cont",0dh,0,0

;
; Change bios to call the 'skip slot 1 or 2' in the subrom
;
  fpos	07d8ah
  rst	030h
  defb	083h		; It shouldn't hurt to hardcode the subrom slot
  defw	test_ab_key
  nop
  nop


;
; Change the default screen width to 80
; This is to make the boot messages from the mfrs show in width 80
;
  fpos	07f55h
  defb	80


;
; change subrom to call the test_h_key routine
;
  fpos 	08421h
  call	test_h_key


;
; Shorten the wait time after the logo
;
  fpos	08418h
  defw	08000h


;
; Set screen 0 instead of screen 1 after the logo
; This is to make the boot messages from the mfrs show in screen 0
;
  fpos	0842bh
  call	009e5h


;
; Set default display frequency to 60hz
;
  fpos  0a9ffh
  defb	0


;
; Display boot logo in 60hz
;
  fpos  0ab56h
  defb	0




;
; This code will be added at the end of the subrom.
;
; The memory counter will be overwritten with code that will work with mappers
; without io port readback. But due to space restrictions it will only count
; the memory in the ram slot chosen by the bios.
;
; Memory counter
;
  fpos	0be8ch
  disp  03e8ch		; code will be executed at 03e8ch

  push  bc
  push	de
  ld	hl,08000h
  ld	b,00h
mem_fill_loop:
  ld	a,b
  out	(0feh),a
  ld	(hl),0aah
  inc	b
  jr	nz,mem_fill_loop
mem_test_loop:
  ld	a,b
  out	(0feh),a
  inc	b
  ld	a,(hl)
  cp	0aah
  jr	nz,mem_done
  ld	a,55h
  ld	(hl),a
  cp	(hl)
  jr	z,mem_test_loop
mem_done:
  dec	b
  dec	b
  ld	a,01h
  out	(0feh),a
  ld	l,b
 
  ld 	h,000h
  inc 	hl
  add 	hl,hl
l3ea5h:
  add 	hl,hl
  add 	hl,hl
l3ea7h:
  add 	hl,hl
  ld 	de,03030h
  ld 	b,d
  ld 	c,b
l3eadh:
  ld 	a,03ah
  inc 	b
  cp 	b
  jr 	nz,l3ec0h
  ld 	b,030h
  inc 	c
  cp 	c
  jr 	nz,l3ec0h
  ld 	c,b
  inc 	d
  cp 	d
  jr 	nz,l3ec0h
  ld 	d,c
  inc 	e
l3ec0h:
  dec 	hl
  xor 	a
  or 	l
  jr 	nz,l3eadh
  or 	h
  jr 	nz,l3eadh
  ld 	a,e
  cp 	030h
  jr 	nz,l3ecfh
  ld 	e,020h
l3ecfh:
  ld 	a,e
  call 	01224h
  ld 	a,d
  call 	01224h
  ld 	a,c
  call 	01224h
  ld 	a,b
  call 	01224h
  pop 	de
  pop 	bc
  ret
 

;
; If H is pressed during boot, change frequency to 50hz
;
test_h_key:
  call	0063ch
  ld	a,(newkey+3)
  and	000100000b 	; bit 5 is 'H'
  ret	nz		; not pressed
  ld	a,2
  ld	(0ffe8h),a
  ret

;
; Hold A or B key during boot to skip slot 1 or 2 respectively
;
test_ab_key:
  push 	bc		; c has slot
  push 	af
  ld 	a,c
  and 	00000011b   	; remove subslot ( just skip all secundary slots)
  ld 	c,a

  ;FBE7 (keyboard row 2):
  ;A - bf - 1011 1111
  ;B - 7f - 0111 1111
  ld 	a,(newkey+2)
  xor 	255
  and 	11000000b       ; we are only interested in bit 7+6
  rla
  rla
  rla			; a should be 1 for 'A' and 2 for 'B' now
  cp 	c
  jr 	nz,test_ab_notpressed
  pop 	af
  ld 	c,a             ; save a flag
  or 	1               ; reset z flag
  ld 	a,c             ; restore a flag
  pop 	bc

  ret

test_ab_notpressed:
  pop 	af
  pop 	bc
  push	hl
  ld 	hl,04241h
  rst	020h            ; DCOMPR, compare HL with DE
  pop	hl
  ret                   ; ret z if 4142 is found

  ent


