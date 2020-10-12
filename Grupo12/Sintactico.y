%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>  
#include <conio.h>
#include "y.tab.h"
#include "funciones.c"
/*#define YYDEBUG 1 */

int yylex();
int yyerror(char* mensaje);
extern int yylineno;


/* Cosas para la declaracion de variables y la tabla de simbolos */
int varADeclarar1 = 0;
int cantVarsADeclarar = 0;
int tipoDatoADeclarar[TAMANIO_TABLA];
int indiceDatoADeclarar = 0;
int indice_tabla = -1;

int yystopparser=0;
FILE  *yyin;

%}

%union {
int valor_int;
double valor_float;
char *valor_string;
}


%token DIM AS
%token FLOAT INTEGER STRING

%token CONST
%token PUT
%token GET

%token MAXIMO


%token IF ELSE
%token WHILE
%token OP_SUM OP_RES OP_MUL OP_DIV

%token P_A P_C
%token C_A C_C
%token L_A L_C

%token IGUAL OP_AND OP_OR OP_NOT
%token CMP_MAYOR CMP_MAYIG CMP_DIST CMP_IGUAL CMP_MENOR CMP_MENIG
%token COMA DOS_PUNTOS PUNTO_Y_COMA
%token <valor_string>ID
%token <valor_string>CONST_STR 
%token <valor_int>CONST_INT 
%token <valor_float>CONST_FLOAT


%%
programa: 
      bloq_decla bloque                                       { printf("\nCompilacion OK \n");
                                                              grabarTabla();};

bloq_decla: 
      declaraciones                                       { printf("R 1: bloq_decla => bloq_decla \n");};

declaraciones: 
      declaracion                                             { printf("R 2: declaraciones => declaraciones \n");}
	| declaraciones declaracion                               { printf("R 3: declaraciones => declaraciones declaracion\n");};

declaracion: 
    DIM C_A lista_id C_C AS C_A lista_tipo C_C                    { printf("R 4: declaracion =>  C_A lista_id C_C AS C_A lista_tipo C_C\n");
                                                                agregarTiposDatosATabla(); 
																indiceDatoADeclarar = 0; 
                                                              };

lista_tipo: 
      lista_tipo COMA tipo_dato                               { printf("R 5: lista_tipo =>lista_tipo COMA tipo_dato \n");}
	| tipo_dato                                               { printf("R 6: lista_tipo => tipo_dato \n");};

tipo_dato: 
    INTEGER                                                   { printf("R 7: tipo_dato => INTEGER\n");
                                                              tipoDatoADeclarar[indiceDatoADeclarar++] = Integer;} 
	| FLOAT                                                   { printf("R 8: tipo_dato => FLOAT\n");
                                                              tipoDatoADeclarar[indiceDatoADeclarar++] = Float;}
    | STRING                                                  { printf("R 9: tipo_dato => STRING \n");
                                                              tipoDatoADeclarar[indiceDatoADeclarar++] = String;};

lista_id: 
      lista_id COMA ID                                        { printf("R 10: lista_id => lista_id COMA ID \n");
                                                              agregarVarATabla(yylval.valor_string,!ES_CTE_CON_NOMBRE,yylineno);
										  					  cantVarsADeclarar++;
                                                              }
	| ID                                                      { printf("R 11: lista_id => lista_id \n");
                                                              agregarVarATabla(yylval.valor_string,!ES_CTE_CON_NOMBRE,yylineno);
										  					  varADeclarar1 = indice_tabla; /* Guardo posicion de primer variable de esta lista de declaracion. */
										 					  cantVarsADeclarar = 1;
                                                              };



bloque: 
      bloque sentencia                                        { printf("R 12: bloque => bloque sentencia \n\n");}
    | sentencia                                               { printf("R 13: bloque => sentencia \n\n");};

sentencia: 
      ciclo                                                   { printf("R 14: sentencia => ciclo \n");}
	| seleccion                                               { printf("R 15: sentencia => seleccion\n");}
	| asignacion                                              { printf("R 16: sentencia => asignacion\n");}
	| entrada_salida                                          { printf("R 17: sentencia => entrada_salida\n");}
    | decl_constante                                          { printf("R 18: sentencia => decl_constante\n");
                                                                        agregarTiposDatosATabla(); 
                                                                        indiceDatoADeclarar = 0;};

ciclo: 
      WHILE P_A condicion P_C  L_A bloque L_C                 { printf("R 19: ciclo => WHILE P_A condicion P_C  L_A bloque L_C\n");};

condicion: 
      comparacion
      | comparacion OP_AND comparacion
      | comparacion OP_OR comparacion
      | OP_NOT comparacion;

comparacion: 
      expresion comparador expresion;

comparador: 
      CMP_MAYOR | CMP_MAYIG | CMP_DIST | CMP_IGUAL | CMP_MENOR | CMP_MENIG ;

seleccion: 
      seleccion_if
	| seleccion_if_else
    | seleccion_if_sin_llave;

seleccion_if: 
      IF P_A condicion P_C L_A bloque L_C                     { printf("R 20: seleccion_if => IF P_A condicion P_C L_A bloque L_C \n");};

seleccion_if_else: 
      seleccion_if else;

else: 
      ELSE L_A bloque L_C                                     { printf("R 21: else => ELSE L_A bloque L_C  \n");}
    | ELSE sentencia                                          { printf("R 22: else => ELSE sentencia \n");};

seleccion_if_sin_llave: 
      IF P_A condicion P_C  sentencia ;

asignacion: 
      ID DOS_PUNTOS expresion PUNTO_Y_COMA                    { printf("R 23: asignacion => ID DOS_PUNTOS expresion PUNTO_Y_COMA\n");
                                                                  chequearVarEnTabla($1,yylineno);
                                                                  validarCteEnTabla($1,yylineno);//Validar si no se asigna a una cte
                                                                  };
		  														

expresion:
	  expresion_cadena				                    	  { printf("R 24: expresion => expresion_cadena\n");}
	| expresion_aritmetica			                    	  { printf("R 25: expresion => expresion_aritmetica\n");};

expresion_cadena:
	CONST_STR						                    	  {
															  printf("R 26: expresion_cadena => CONST_STR es: %s\n",yylval.valor_string);
															  agregarCteATabla(CteString);
															  };
expresion_aritmetica: 
      termino                                                 { printf("R 27: expresion_aritmetica => termino\n");}
    | expresion OP_RES termino                                { printf("R 28: expresion_aritmetica => expresion OP_RES termino \n");}
    | expresion OP_SUM termino                                { printf("R 29: expresion_aritmetica => expresion OP_SUM termino\n");};



entrada_salida: 
      PUT expresion_cadena PUNTO_Y_COMA                       { printf("R 30: entrada_salida => PUT CONST_STR PUNTO_Y_COMA \n");
                                                              }
	| PUT factor PUNTO_Y_COMA                                 { printf("R 31: entrada_salida => PUT ID PUNTO_Y_COMA  \n");
                                                              }
    | GET factor PUNTO_Y_COMA                                 { printf("R 32: entrada_salida => GET ID PUNTO_Y_COMA \n");
                                                              };

decl_constante: 
      CONST ID IGUAL CONST_INT { agregarCteATabla(CteInt); } PUNTO_Y_COMA                   	  
                                                                        { printf("R 33: decl_constante => CONST ID IGUAL CONST_INT PUNTO_Y_COMA \n");
                                                                        agregarVarATabla($2,ES_CTE_CON_NOMBRE,yylineno);
                                                                        cantVarsADeclarar++;
                                                                        varADeclarar1 = indice_tabla;
                                                                        tipoDatoADeclarar[indiceDatoADeclarar++] = Integer;
                                                                        agregarValorACte(CteInt);
                                                                        };	  											
      | CONST ID IGUAL CONST_STR { agregarCteATabla(CteString);} PUNTO_Y_COMA               
                                                                        { printf("R 34: decl_constante => CONST ID IGUAL CONST_STR PUNTO_Y_COMA  \n");
                                                                        agregarVarATabla($2,ES_CTE_CON_NOMBRE,yylineno);
                                                                        cantVarsADeclarar++;
                                                                        varADeclarar1 = indice_tabla;
                                                                        tipoDatoADeclarar[indiceDatoADeclarar++] = String;
                                                                        agregarValorACte(CteString);
                                                                        }
      | CONST ID IGUAL CONST_FLOAT {agregarCteATabla(CteFloat);} PUNTO_Y_COMA             
                                                                        { printf("R 35: decl_constante => CONST ID IGUAL CONST_FLOAT PUNTO_Y_COMA  \n");
                                                                        agregarVarATabla($2,ES_CTE_CON_NOMBRE,yylineno);
                                                                        cantVarsADeclarar++;
                                                                        varADeclarar1 = indice_tabla;
                                                                        tipoDatoADeclarar[indiceDatoADeclarar++] = Float;
                                                                        agregarValorACte(CteFloat);
                                                                        };
termino: 
      factor                                                  {printf("R 36: termino => factor\n");}
      | termino OP_MUL factor                                 {printf("R 37: termino => termino OP_MUL factor \n");}
      | termino OP_DIV factor                                 {printf("R 38: termino => termino OP_DIV factor\n");};

factor:           
      ID                                                      {
                                                              printf("R 39: factor => ID es: %s\n", yylval.valor_string);
                                                              chequearVarEnTabla(yylval.valor_string,yylineno);}
      | CONST_INT                                             { printf("R 40: factor => CONST_INT: %d\n", yylval.valor_int);
                                                              agregarCteATabla(CteInt);}
      | CONST_FLOAT                                           { printf("R 41: factor => CONST_FLOAT: %f\n",yylval.valor_float);
                                                              agregarCteATabla(CteFloat);};

      | P_A expresion P_C                                      { printf("R 42: factor => P_A expresion P_C\n");}
      | expr_maximo                                           { printf("R 43: factor => expr_maximo;\n");};

expr_maximo: 
      MAXIMO P_A lista_expresion P_C                          { printf("R 44: expr_maximo => MAXIMO P_A lista_expresion P_C\n");};

lista_expresion: 
      lista_expresion COMA expresion
      | expresion;

%%

int main(int argc,char *argv[])
{
  if ((yyin = fopen(argv[1], "rt")) == NULL)
  {
	printf("\nNo se puede abrir el archivo: %s\n", argv[1]);
  }
  else
  {
	yyparse();
      fclose(yyin);
  }
  return 0;
}
