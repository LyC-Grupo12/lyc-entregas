%{
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include "y.tab.h"
#include "funciones.h"

%}

%option noyywrap  
%option yylineno 

DIGITO			        [0-9]
LETRA			        [a-zA-Z]
INICIO_FIN_STR          \"
CONST_STR               {INICIO_FIN_STR}{CADENA}*{INICIO_FIN_STR}
CONST_FLOAT             "-"?{DIGITO}+"."{DIGITO}+
CONST_INT               "-"?{DIGITO}+
ID			            {LETRA}({LETRA}|{DIGITO}|_)*
DOS_PUNTOS   		    [":"]
CADENA                  ({LETRA}|{DIGITO}|\.|\:|\;\-|\_|\!|_|" "|\n|\s|\t|\r|\@|\%\!)*
INICIO_COMENTARIO       "*-"
FIN_COMENTARIO          "-*"
COMENTARIO             {INICIO_COMENTARIO}{CADENA}*{FIN_COMENTARIO}|{INICIO_COMENTARIO}{CADENA}{INICIO_COMENTARIO}{CADENA}{FIN_COMENTARIO}{CADENA}{FIN_COMENTARIO}|{INICIO_COMENTARIO}{INICIO_COMENTARIO}{CADENA}{FIN_COMENTARIO}{CADENA}{FIN_COMENTARIO}|{INICIO_COMENTARIO}{CADENA}{FIN_COMENTARIO}{CADENA}{FIN_COMENTARIO}{FIN_COMENTARIO}


%%

"DIM"		            { return DIM;}
"CONST"		            { return CONST;}
"AS"		            { return AS;}
"PUT"		            { return PUT;}
"GET"		            { return GET;}
"maximo"		        { return MAXIMO;}
"Integer"		        { 
                            yylval.valor_int = atoi( yytext );
                            return INTEGER;
                        }
"Float"		            {
                            yylval.valor_float = atof( yytext );
                            return FLOAT;
                        }
"String"		        { 
                            yylval.valor_string = strdup( yytext );
                            return STRING;
                        }
"if"			        { return IF;}
"else"   		        { return ELSE;}
"endif"   		        { return ENDIF;}
"while"			        { return WHILE;}
"+"			            { return OP_SUM;}
"-"			            { return OP_RES;}
"*"			            { return OP_MUL;}
"/"			            { return OP_DIV;}
"("			            { return P_A;}
")"			            { return P_C;}
"["                     { return C_A;}
"]"                     { return C_C;}
"{"                     { return L_A;}
"}"                     { return L_C;}
"="                     { return IGUAL;}
">"						{ return CMP_MAYOR; }
">="					{ return CMP_MAYIG; }
"<>"					{ return CMP_DIST; }
"=="					{ return CMP_IGUAL;}
"<"						{ return CMP_MENOR; }
"<="					{ return CMP_MENIG; }
"and"					{ return OP_AND; }
"or"					{ return OP_OR; }
"not"					{ return OP_NOT; } 
";"						{ return PUNTO_Y_COMA;}   
{ID}			        {
			                if(strlen(yytext) <= 30){
			                  yylval.valor_string = strdup(yytext);
			                  return ID;
			                }
							mensajeDeError(ErrorLexico,"El nombre de variable excede el limite permitido.",yylineno);
			            }                            
{CONST_INT}		        { 
                        if(atoll(yytext)>=-32768 && atoll(yytext)<=32767){
		                      	yylval.valor_int = atoi(yytext);
		                      	return CONST_INT;
		                    }
							 mensajeDeError(ErrorLexico,"El valor de un entero excede el limite permitido.",yylineno);
                        }
{CONST_STR}		        {	
							if(strlen(yytext)<=30){
							yylval.valor_string = strdup(yytext);
							return CONST_STR;
							}
							mensajeDeError(ErrorLexico,"El contenido de una cadena excede el limite permitido.",yylineno);
						}
{CONST_FLOAT}		    { 
                        if(atof(yytext)>=-3.40282347e+38F && atof(yytext)<=3.40282347e+38F){
		                    	yylval.valor_float = atof(yytext);
		                    	return CONST_FLOAT;
		                    }
							mensajeDeError(ErrorLexico,"El valor de un flotante excede el limite permitido.",yylineno);
                        }                           
","		           		{ return COMA;}
{DOS_PUNTOS}			{ return DOS_PUNTOS;}
{COMENTARIO}
<<EOF>> 				{ yyterminate();}
"\n"
"\r\n"
"\t"
" "
. 						{ mensajeDeError(ErrorLexico,"Caracter invalido",yylineno);}

%%
