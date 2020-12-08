include macros2.asm
include number.asm

.MODEL LARGE
.STACK 200h
.386
.387
.DATA

	MAXTEXTSIZE equ 50
	@_auxR0 	DD 0.0
	@_auxE0 	DD 0
	@_auxR1 	DD 0.0
	@_auxE1 	DD 0
	@_contador 	DD 0
	@_promedio 	DD 0.0
	@_actual 	DD 0.0
	@_suma 	DD 0
	@_pivot 	DD 0
	@_85 	DD 85
	@_nombre 	DD 85
	@_1p200000 	DD 1.200000
	@_constFloat 	DD 1.200000
	@_0 	DD 0
	@_25 	DD 25
	@_5p800000 	DD 5.800000
	@_Pruebaptxt_LyC_Tema_3_ 	DB "Prueba.txt LyC Tema 3!",'$',28 dup(?)
	@_Ingrese_un_valor_entero__ 	DB "Ingrese un valor entero: ",'$',25 dup(?)
	@_prueba_const_string 	DB "prueba const string",'$',31 dup(?)
	@_constString 	DB "prueba const string",'$',50 dup(?)
	@_La_suma_es__ 	DB "La suma es: ",'$',38 dup(?)

.CODE
.startup
	mov AX,@DATA
	mov DS,AX

	FINIT

	displayString 	@_Pruebaptxt_LyC_Tema_3_
	newLine 1
	displayString 	@_Ingrese_un_valor_entero__
	newLine 1
	getFloat 	@_actual
	displayString 	@_constString
	newLine 1
	fild 	@_0
	fistp 	@_contador
	fild 	@_nombre
	fiadd 	@_25
	fistp 	@_auxE0
	fild 	@_auxE0
	fistp 	@_suma
	displayString 	@_La_suma_es__
	newLine 1
	displayInteger 	@_suma,3
	newLine 1
	fld 	@_5p800000
	fld 	@_constFloat
	fmul
	fstp 	@_auxR0
	fld 	@_auxR0
	fstp 	@_promedio
	displayFloat 	@_promedio,3
	newLine 1
	mov ah, 4ch
	int 21h


strlen proc
	mov bx, 0
	strl01:
	cmp BYTE PTR [si+bx],'$'
	je strend
	inc bx
	jmp strl01
	strend:
	ret
strlen endp

copiar proc
	call strlen
	cmp bx , MAXTEXTSIZE
	jle copiarSizeOk
	mov bx , MAXTEXTSIZE
	copiarSizeOk:
	mov cx , bx
	cld
	rep movsb
	mov al , '$'
	mov byte ptr[di],al
	ret
copiar endp

concat proc
	push ds
	push si
	call strlen
	mov dx , bx
	mov si , di
	push es
	pop ds
	call strlen
	add di, bx
	add bx, dx
	cmp bx , MAXTEXTSIZE
	jg concatSizeMal
	concatSizeOk:
	mov cx , dx
	jmp concatSigo
	concatSizeMal:
	sub bx , MAXTEXTSIZE
	sub dx , bx
	mov cx , dx
	concatSigo:
	push ds
	pop es
	pop si
	pop ds
	cld
	rep movsb
	mov al , '$'
	mov byte ptr[di],al
	ret
concat endp

END