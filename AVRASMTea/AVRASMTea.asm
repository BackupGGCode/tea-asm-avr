.include "tn26def.inc"


	;delta
	.def	d0 = r0
	.def	d1 = r1
	.def	d2 = r2
	.def	d3 = r3
	;key
	.def	k00 = r4	.
	.def	k01 = r5
	.def	k02 = r6
	.def	k03 = r7
	.def	k10 = r8	.
	.def	k11 = r9
	.def	k12 = r10
	.def	k13 = r11
	.def	k20 = r12	.
	.def	k21 = r13
	.def	k22 = r14
	.def	k23 = r15
	.def	k30 = r16	.
	.def	k31 = r17
	.def	k32 = r18
	.def	k33 = r19
	;v0 or v1
	.def	v0 = r20	.
	.def	v1 = r21
	.def	v2 = r22
	.def	v3 = r23
	;sum
	.def	s0 = r24	.
	.def	s1 = r25
	.def	s2 = r26
	.def	s3 = r27
	
	.def	temp = r29
	;Z is in use


	.dseg

	v0_param:	.byte 4
	v1_param:	.byte 4
	xor_tmp:	.byte 4
	round_cnt:	.byte 1	

	.cseg
	.org	0  	
	rjmp RESET ; Reset handler
	reti ;EXT_INT0 ; IRQ0 handler
	reti;$002 rjmp PIN_CHANGE ; Pin change handler
	reti;rjmp TIM1_CMP1A ; Timer1 compare match 1A
	reti;$004 rjmp TIM1_CMP1B ; Timer1 compare match 1B
	reti ;TIM1_OVF ; Timer1 overflow handler
	reti ;TIM0_OVF ; Timer0 overflow handler
	reti;$007 rjmp USI_STRT ; USI Start handler
	reti;rjmp USI_OVF ; USI Overflow handler
	reti;$009 rjmp EE_RDY ; EEPROM Ready handler
	reti;$00A rjmp ANA_COMP ; Analog Comparator handler
	reti ;ADC_DONE ; ADC Conversion Handler

	

RESET:	


	;init stack
	ldi temp, RAMEND
	out sp, temp
	ldi ZH, 0

main:
	ldi temp, 0x44
	ldi ZL, low(v0_param)
	st Z+, temp	
	st Z+, temp
	st Z+, temp
	st Z+, temp
	ldi temp, 0x11
	ldi ZL, low(v1_param)
	st Z+, temp	
	st Z+, temp
	st Z+, temp
	st Z+, temp

	rcall init
	rcall decrypt;0x53488426
	;rcall encrypt;0x55A42D34
	rjmp main

	;init delta, key
	;rewrite this routine for you)
init:
	;define delta 0x9e3779b9
	ldi temp, 0xb9
	mov d0, temp
	ldi temp, 0x79
	mov d1, temp
	ldi temp, 0x37
	mov d2, temp
	ldi temp, 0x9e
	mov d3, temp
	;define key
	ldi temp, 0xAA
	mov k00, temp
	ldi temp, 0xAA
	mov k01, temp
	ldi temp, 0xAA
	mov k02, temp
	ldi temp, 0xAA
	mov k03, temp
	ldi temp, 0xBB
	mov k10, temp
	ldi temp, 0xBB
	mov k11, temp
	ldi temp, 0xBB
	mov k12, temp
	ldi temp, 0xBB
	mov k13, temp
	ldi temp, 0xCC
	mov k20, temp
	ldi temp, 0xCC
	mov k21, temp
	ldi temp, 0xCC
	mov k22, temp
	ldi temp, 0xCC
	mov k23, temp
	ldi temp, 0xDD
	mov k30, temp
	ldi temp, 0xDD
	mov k31, temp
	ldi temp, 0xDD
	mov k32, temp
	ldi temp, 0xDD
	mov k33, temp
	ret

	;load v0 or v1 from mem to reg
load_v0:
	ldi ZL, low(v0_param)
	rjmp load_v
load_v1:
	ldi ZL, low(v1_param)
load_v:
	ld	v0, Z+
	ld	v1, Z+
	ld	v2, Z+
	ld	v3, Z+
	ret

	;store v0 or v1 from reg to mem
store_v0:
	ldi ZL, low(v0_param)
	rjmp store_v
store_v1:
	ldi ZL, low(v1_param)
store_v:
	st	Z+, v0
	st	Z+, v1
	st	Z+, v2
	st	Z+, v3
	ret

;clear temprory xor variable
xor_init:
	ldi temp, 0
	ldi ZL, low(xor_tmp)
	st Z+, v0
	st Z+, v1
	st Z+, v2
	st Z+, v3
	ret

xor_add:
	ldi temp, 0
	ldi ZL, low(xor_tmp)
	ld temp, Z
	eor temp, v0
	st Z+, temp
	ld temp, Z
	eor temp, v1
	st Z+, temp
	ld temp, Z
	eor temp, v2
	st Z+, temp
	ld temp, Z
	eor temp, v3
	st Z+, temp
	ret	

;((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
;результат хранится в xor_tmp
xor_1:
	;load v1
	rcall load_v1
	;((v1<<4) + k0)
	ldi temp, 4
x11:
	lsl v0 ;
	rol v1
	rol v2
	rol v3
	dec temp
	brne x11
	add v0, k00 
	adc v1, k01
	adc v2, k02
	adc v3, k03
	rcall xor_init

	;(v1 + sum)
	rcall load_v1
	add v0, s0 
	adc v1, s1
	adc v2, s2
	adc v3, s3
	rcall xor_add

	;((v1>>5) + k1)
	rcall load_v1
	ldi temp, 5
x12:
	lsr v3 ;
	ror v2
	ror v1
	ror v0
	dec temp
	brne x12
	add v0, k10 
	adc v1, k11
	adc v2, k12
	adc v3, k13
	rcall xor_add
	ret

;((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3); 
xor_2:
	;load v0
	rcall load_v0
	;((v0<<4) + k2)
	ldi temp, 4
x21:
	lsl v0 ;
	rol v1
	rol v2
	rol v3
	dec temp
	brne x21
	add v0, k20 
	adc v1, k21
	adc v2, k22
	adc v3, k23
	rcall xor_init

	;(v0 + sum)
	rcall load_v0
	add v0, s0 
	adc v1, s1
	adc v2, s2
	adc v3, s3
	rcall xor_add

	;((v0>>5) + k3)
	rcall load_v0
	ldi temp, 5
x22:
	lsr v3 ;
	ror v2
	ror v1
	ror v0
	dec temp
	brne x22
	add v0, k30 
	adc v1, k31
	adc v2, k32
	adc v3, k33
	rcall xor_add
	ret


encrypt:
	ldi temp, 0
	mov s0, temp
	mov s1, temp
	mov s2, temp
	mov s3, temp

	ldi temp, 32
	ldi ZL, low(round_cnt)
	st Z, temp
e1:
	;sum += delta;
	add s0, d0
	adc s1, d1
	adc s2, d2
	adc s3, d3

	rcall xor_1

	;v0 +=
	rcall load_v0

	ldi ZL, low(xor_tmp)
	ld temp, Z+
	add v0, temp
	ld temp, Z+
	adc v1, temp	;ld - не влияет на carry))
	ld temp, Z+
	adc v2, temp	
	ld temp, Z+
	adc v3, temp	
	rcall store_v0

	rcall xor_2

	;v1 +=
	rcall load_v1

	ldi ZL, low(xor_tmp)
	ld temp, Z+
	add v0, temp
	ld temp, Z+
	adc v1, temp	;ld - не влияет на carry))
	ld temp, Z+
	adc v2, temp	
	ld temp, Z+
	adc v3, temp	
	rcall store_v1


	;loop
	ldi ZL, low(round_cnt)
	ld temp, Z
	dec temp
	breq e_end
	st Z, temp
	rjmp e1
e_end:
	ret







decrypt:
	ldi temp, 0x20 ;0xC6EF3720
	mov s0, temp
	ldi temp, 0x37
	mov s1, temp
	ldi temp, 0xEF
	mov s2, temp
	ldi temp, 0xC6
	mov s3, temp

	ldi temp, 32
	ldi ZL, low(round_cnt)
	st Z, temp

dt1:
	rcall xor_2

	;v1 -=
	rcall load_v1

	ldi ZL, low(xor_tmp)
	ld temp, Z+
	sub v0, temp
	ld temp, Z+
	sbc v1, temp
	ld temp, Z+
	sbc v2, temp
	ld temp, Z+
	sbc v3, temp
	rcall store_v1


	rcall xor_1

	;v0 -=
	rcall load_v0

	ldi ZL, low(xor_tmp)
	ld temp, Z+
	sub v0, temp
	ld temp, Z+
	sbc v1, temp
	ld temp, Z+
	sbc v2, temp
	ld temp, Z+
	sbc v3, temp
	rcall store_v0

	;sum -= delta;
	clc

	sub s0, d0
	sbc s1, d1
	sbc s2, d2
	sbc s3, d3


	;loop
	ldi ZL, low(round_cnt)
	ld temp, Z
	dec temp
	breq d_end
	st Z, temp
	rjmp dt1
d_end:
	ret
