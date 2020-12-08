flex Lexico.l
pause
bison -dyv Sintactico.y
pause
gcc.exe lex.yy.c y.tab.c -o Tercera.exe
pause
Tercera.exe Prueba.txt
del lex.yy.c
del y.tab.c
del y.output
del y.tab.h

pause
