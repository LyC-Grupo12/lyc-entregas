%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>  
#include <conio.h>
#include "y.tab.h"
#include "funciones.c"
#include "Pila.c"
/*#define YYDEBUG 1 */

int yylex();
int yyerror(char* mensaje);
extern int yylineno;
FILE *fp;
FILE *graph;
char str_aux[50];
char str_auxcmp[10];
m10_stack_t* pilaExpresion;
m10_stack_t* pilaBloque;
m10_stack_t* pilaCondicion;

/* Cosas para la declaracion de variables y la tabla de simbolos */
int varADeclarar1 = 0;
int cantVarsADeclarar = 0;
int tipoDatoADeclarar[TAMANIO_TABLA];
int indiceDatoADeclarar = 0;
int indice_tabla = -1;
int contCuerpo = 0;

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


%token IF ELSE ENDIF
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
      bloq_decla bloque                                     { fprintf(fp,"\nCompilacion OK \n");
                                                              grabarTabla();
                                                              postOrden(&bloquePtr);
                                                              tree_print_dot(&bloquePtr,graph);
                                                            };

bloq_decla: 
      declaraciones                                         { fprintf(fp,"R 1: bloq_decla => bloq_decla \n");};

declaraciones: 
      declaracion                                           { fprintf(fp,"R 2: declaraciones => declaraciones \n");}
	| declaraciones declaracion                           { fprintf(fp,"R 3: declaraciones => declaraciones declaracion\n");};

declaracion: 
      DIM C_A lista_id C_C AS C_A lista_tipo C_C            { fprintf(fp,"R 4: declaracion =>  C_A lista_id C_C AS C_A lista_tipo C_C\n");
                                                              agregarTiposDatosATabla(); 
										  indiceDatoADeclarar = 0; 
                                                            };

lista_tipo: 
      lista_tipo COMA tipo_dato                             { fprintf(fp,"R 5: lista_tipo =>lista_tipo COMA tipo_dato \n");}
	| tipo_dato                                           { fprintf(fp,"R 6: lista_tipo => tipo_dato \n");};

tipo_dato: 
      INTEGER                                               { fprintf(fp,"R 7: tipo_dato => INTEGER\n");
                                                              tipoDatoADeclarar[indiceDatoADeclarar++] = Integer;} 
	| FLOAT                                               { fprintf(fp,"R 8: tipo_dato => FLOAT\n");
                                                              tipoDatoADeclarar[indiceDatoADeclarar++] = Float;}
      | STRING                                              { fprintf(fp,"R 9: tipo_dato => STRING \n");
                                                              tipoDatoADeclarar[indiceDatoADeclarar++] = String;};

lista_id: 
      lista_id COMA ID                                      { fprintf(fp,"R 10: lista_id => lista_id COMA ID \n");
                                                              agregarVarATabla(yylval.valor_string,!ES_CTE_CON_NOMBRE,yylineno);
										  cantVarsADeclarar++;
                                                            }
	| ID                                                  { fprintf(fp,"R 11: lista_id => lista_id \n");
                                                              agregarVarATabla(yylval.valor_string,!ES_CTE_CON_NOMBRE,yylineno);
										  varADeclarar1 = indice_tabla; /* Guardo posicion de primer variable de esta lista de declaracion. */
										  cantVarsADeclarar = 1;
                                                            };



bloque: 
      bloque sentencia                                      { fprintf(fp,"R 12: bloque => bloque sentencia \n\n");
                                                              if(bloquePtr != NULL){
                                                                  sprintf(str_aux, "CUERPO%d",contCuerpo++);
											bloquePtr = crearNodo(str_aux, bloquePtr, sentenciaPtr);
										  } else {
                                                                  sprintf(str_aux, "CUERPO%d",contCuerpo++);
											bloquePtr = crearNodo(str_aux, sentenciaPtr,NULL);
			                                            }
                                                            }
    | sentencia                                             { fprintf(fp,"R 13: bloque => sentencia \n\n");
                                                              if(bloquePtr != NULL) {
                                                                  sprintf(str_aux, "CUERPO%d",contCuerpo++);
											bloquePtr = crearNodo(str_aux, sentenciaPtr,NULL);
										  } else {
											bloquePtr = sentenciaPtr;
										  }
                                                            };

sentencia: 
      ciclo                                                 { fprintf(fp,"R 14: sentencia => ciclo \n"); sentenciaPtr = bloqueWhPtr;}
	| seleccion                                           { fprintf(fp,"R 15: sentencia => seleccion\n"); sentenciaPtr = seleccionPtr;}
	| asignacion                                          { fprintf(fp,"R 16: sentencia => asignacion\n"); sentenciaPtr = asigPtr;}
	| entrada_salida                                      { fprintf(fp,"R 17: sentencia => entrada_salida\n"); sentenciaPtr = escrituraPtr;}
      | decl_constante                                      { fprintf(fp,"R 18: sentencia => decl_constante\n"); sentenciaPtr = declConstantePtr;
                                                              agregarTiposDatosATabla(); 
                                                              indiceDatoADeclarar = 0;};

ciclo: 
      WHILE P_A condicion P_C                   { 
                                                      if(bloquePtr){
                                                            ponerenPila(pilaBloque,bloquePtr);
                                                            bloquePtr=NULL;
                                                      }
                                                      else{
                                                            if(sentenciaPtr)
                                                                  ponerenPila(pilaBloque,sentenciaPtr);
                                                      }
                                                      ponerenPila(pilaCondicion,condicionPtr);
                                                }
      L_A bloque L_C                                  {
                                                      fprintf(fp,"R 19: ciclo => WHILE P_A condicion P_C  L_A bloque L_C\n");
                                                      if (topedePila(pilaCondicion)){
                                                            condicionPtr = topedePila(pilaCondicion);
                                                            auxCondicionPtr = (tNodo*)malloc(sizeof(tNodo));
                                                            strcpy(auxCondicionPtr->info.dato,condicionPtr->info.dato);
                                                            auxCondicionPtr->izq = condicionPtr->izq;
                                                            auxCondicionPtr->der = condicionPtr->der;
                                                            condicionPtr = auxCondicionPtr;
                                                            sacardePila(pilaCondicion);
                                                      }
                                                      bloqueWhPtr = crearNodo("WHILE",condicionPtr,bloquePtr);

                                                      if (topedePila(pilaBloque)){
                                                            bloquePtr = topedePila(pilaBloque);
                                                            auxBloquePtr = (tNodo*)malloc(sizeof(tNodo));
                                                            strcpy(auxBloquePtr->info.dato,bloquePtr->info.dato);
                                                            auxBloquePtr->izq = bloquePtr->izq;
                                                            auxBloquePtr->der = bloquePtr->der;
                                                            bloquePtr = auxBloquePtr;
                                                            sacardePila(pilaBloque);
                                                      }
                                                };

condicion: 
      comparacion                                           {
                                                            condicionPtr=comparacionPtr;
                                                            verificarTipoDato(&condicionPtr,yylineno);
                                                            }
      | comparacion { comparacionAuxPtr = comparacionPtr; } OP_AND comparacion {
                                                            condicionPtr = crearNodo("AND",comparacionAuxPtr,comparacionPtr);
                                                            verificarTipoDato(&condicionPtr,yylineno);
                                                            }
      | comparacion { comparacionAuxPtr = comparacionPtr; } OP_OR comparacion {
                                                            condicionPtr = crearNodo("OR",comparacionAuxPtr,comparacionPtr);
                                                            verificarTipoDato(&condicionPtr,yylineno);
                                                            }

      | OP_NOT comparacion                                  {
                                                            condicionPtr = crearNodo("NOT",comparacionPtr,NULL);
                                                            verificarTipoDato(&condicionPtr,yylineno);
                                                            };

comparacion: 
      expresion { exprCMPPtr = exprPtr; } comparador expresion {  comparacionPtr = crearNodo(str_auxcmp,exprCMPPtr,exprPtr); };

comparador: 
      CMP_MAYOR { strncpy(str_auxcmp,"BLE",10);}  
	  | CMP_MAYIG { strncpy(str_auxcmp,"BLT",10);}  
	  | CMP_DIST { strncpy(str_auxcmp,"BEQ",10);}  
	  | CMP_IGUAL { strncpy(str_auxcmp,"BNE",10);}  
	  | CMP_MENOR { strncpy(str_auxcmp,"BGE",10);}  
	  | CMP_MENIG { strncpy(str_auxcmp,"BGT",10);}  ;

seleccion: 
      seleccion_if                                          {seleccionPtr=seleccionIFPtr;}
      

condicion_if:      IF P_A condicion P_C     {
                                                if(bloquePtr){
                                                      ponerenPila(pilaBloque,bloquePtr);
                                                      bloquePtr=NULL;
                                                }
                                                else{
                                                      if(sentenciaPtr)
                                                            ponerenPila(pilaBloque,sentenciaPtr);
                                                }
                                                ponerenPila(pilaCondicion,condicionPtr);
                                                };
seleccion_if: condicion_if bloque ENDIF     {     fprintf(fp,"R 20: seleccion_if => IF P_A condicion P_C L_A bloque L_C \n");
                                                
                                                if (topedePila(pilaCondicion)){
                                                      condicionPtr = topedePila(pilaCondicion);
                                                      auxCondicionPtr = (tNodo*)malloc(sizeof(tNodo));
                                                      strcpy(auxCondicionPtr->info.dato,condicionPtr->info.dato);
                                                      auxCondicionPtr->izq = condicionPtr->izq;
                                                      auxCondicionPtr->der = condicionPtr->der;
                                                      condicionPtr = auxCondicionPtr;
                                                      sacardePila(pilaCondicion);
                                                }     
                                                seleccionIFPtr = crearNodo("IF",condicionPtr,bloquePtr);

                                                if (topedePila(pilaBloque)){
                                                      bloquePtr = topedePila(pilaBloque);
                                                      auxBloquePtr = (tNodo*)malloc(sizeof(tNodo));
                                                      strcpy(auxBloquePtr->info.dato,bloquePtr->info.dato);
                                                      auxBloquePtr->izq = bloquePtr->izq;
                                                      auxBloquePtr->der = bloquePtr->der;
                                                      bloquePtr = auxBloquePtr;
                                                      sacardePila(pilaBloque);
                                                }
							}
      | condicion_if bloque {auxBloquePtr=bloquePtr;} ELSE bloque ENDIF
                                          {
                                                fprintf(fp,"R 21: seleccion_if => condicion_if bloque ELSE bloque ENDIF\n");
                                                if (topedePila(pilaCondicion)){
                                                      condicionPtr = topedePila(pilaCondicion);
                                                      auxCondicionPtr = (tNodo*)malloc(sizeof(tNodo));
                                                      strcpy(auxCondicionPtr->info.dato,condicionPtr->info.dato);
                                                      auxCondicionPtr->izq = condicionPtr->izq;
                                                      auxCondicionPtr->der = condicionPtr->der;
                                                      condicionPtr = auxCondicionPtr;
                                                      sacardePila(pilaCondicion);
                                                }
                                                auxIfPtr = crearNodo("ELSE",auxBloquePtr,bloquePtr);
                                                seleccionIFPtr = crearNodo("IF",condicionPtr,auxIfPtr);

                                                if (topedePila(pilaBloque)){
                                                      bloquePtr = topedePila(pilaBloque);
                                                      auxBloquePtr = (tNodo*)malloc(sizeof(tNodo));
                                                      strcpy(auxBloquePtr->info.dato,bloquePtr->info.dato);
                                                      auxBloquePtr->izq = bloquePtr->izq;
                                                      auxBloquePtr->der = bloquePtr->der;
                                                      bloquePtr = auxBloquePtr;
                                                      sacardePila(pilaBloque);
                                                }

                                          }


asignacion: 
      ID DOS_PUNTOS expresion PUNTO_Y_COMA                    {   fprintf(fp,"R 23: asignacion => ID DOS_PUNTOS expresion PUNTO_Y_COMA\n");
                                                                  int pos=chequearVarEnTabla($1,yylineno);
                                                                  validarCteEnTabla($1,yylineno);//Validar si no se asigna a una cte
                                                                  sprintf(str_aux, "%s",$1);
				                                          asigPtr=crearHoja($1,tabla_simbolo[pos].tipo_dato);
				                                          asigPtr=crearNodo("DOS_PUNTOS",asigPtr, exprAritPtr);
                                                                  verificarTipoDato(&asigPtr,yylineno);
                                                                  };	  														

expresion:
	  expresion_cadena		                                    { exprPtr = exprCadPtr;
                                                                        fprintf(fp,"R 24: expresion => expresion_cadena\n");}
	| expresion_aritmetica			                    	      { 
                                                                        exprPtr = exprAritPtr;
                                                                        fprintf(fp,"R 25: expresion => expresion_aritmetica\n");};

expresion_cadena:
	CONST_STR						                    	{
                                                                              exprCadPtr = crearHoja($1,CteString);
													fprintf(fp,"R 26: expresion_cadena => CONST_STR es: %s\n",yylval.valor_string);
													agregarCteATabla(CteString);
												};
expresion_aritmetica: 
      termino                                                 { 
                                                                  exprAritPtr = terminoPtr; 
                                                                  fprintf(fp,"R 27: expresion_aritmetica => termino\n");}
      | expresion OP_RES termino                                { 
                                                                  exprAritPtr=crearNodo("OP_RES", exprPtr, terminoPtr);
                                                                  fprintf(fp,"R 28: expresion_aritmetica => expresion OP_RES termino \n");}
      | expresion OP_SUM termino                                { 
                                                                  exprAritPtr=crearNodo("OP_SUM", exprPtr, terminoPtr);
                                                                  fprintf(fp,"R 29: expresion_aritmetica => expresion OP_SUM termino\n");};



entrada_salida: 
      PUT expresion_cadena PUNTO_Y_COMA                       { 
				                                          escrituraPtr=crearNodo("PUT", exprCadPtr, NULL);
                                                                  fprintf(fp,"R 30: entrada_salida => PUT CONST_STR PUNTO_Y_COMA \n");
                                                              }
	| PUT factor PUNTO_Y_COMA                                 { 
                                                                  escrituraPtr=crearNodo("PUT", factorPtr, NULL);
                                                                  fprintf(fp,"R 31: entrada_salida => PUT ID PUNTO_Y_COMA  \n");
                                                              }
      | GET factor PUNTO_Y_COMA                                 { 
                                                                  escrituraPtr=crearNodo("GET", factorPtr, NULL);
                                                                  fprintf(fp,"R 32: entrada_salida => GET ID PUNTO_Y_COMA \n");
                                                              };

decl_constante: 
      CONST ID IGUAL CONST_INT { agregarCteATabla(CteInt); } PUNTO_Y_COMA                   	  
                                                                        { fprintf(fp,"R 33: decl_constante => CONST ID IGUAL CONST_INT PUNTO_Y_COMA \n");
                                                                        agregarVarATabla($2,ES_CTE_CON_NOMBRE,yylineno);
                                                                        cantVarsADeclarar++;
                                                                        varADeclarar1 = indice_tabla;
                                                                        tipoDatoADeclarar[indiceDatoADeclarar++] = Integer;
                                                                        agregarValorACte(CteInt);
                                                                        declConstantePtr=crearHoja($2,CteInt);
                                                                        sprintf(str_aux, "%d",$4);
                                                                        auxAritPtr=crearHoja(str_aux,CteInt);
				                                                declConstantePtr=crearNodo("CONST",declConstantePtr, auxAritPtr);
                                                                        };	  											
      | CONST ID IGUAL CONST_STR { agregarCteATabla(CteString);} PUNTO_Y_COMA               
                                                                        { fprintf(fp,"R 34: decl_constante => CONST ID IGUAL CONST_STR PUNTO_Y_COMA  \n");
                                                                        agregarVarATabla($2,ES_CTE_CON_NOMBRE,yylineno);
                                                                        cantVarsADeclarar++;
                                                                        varADeclarar1 = indice_tabla;
                                                                        tipoDatoADeclarar[indiceDatoADeclarar++] = String;
                                                                        agregarValorACte(CteString);
                                                                        declConstantePtr=crearHoja($2,CteString);
                                                                        auxAritPtr=crearHoja($4,CteString);
				                                                declConstantePtr=crearNodo("CONST",declConstantePtr, auxAritPtr);
                                                                        }
      | CONST ID IGUAL CONST_FLOAT {agregarCteATabla(CteFloat);} PUNTO_Y_COMA             
                                                                        { fprintf(fp,"R 35: decl_constante => CONST ID IGUAL CONST_FLOAT PUNTO_Y_COMA  \n");
                                                                        agregarVarATabla($2,ES_CTE_CON_NOMBRE,yylineno);
                                                                        cantVarsADeclarar++;
                                                                        varADeclarar1 = indice_tabla;
                                                                        tipoDatoADeclarar[indiceDatoADeclarar++] = Float;
                                                                        agregarValorACte(CteFloat);
                                                                        declConstantePtr=crearHoja($2,CteFloat);
                                                                        sprintf(str_aux, "%f",$4,CteFloat);
                                                                        auxAritPtr=crearHoja(str_aux,CteFloat);
				                                                declConstantePtr=crearNodo("CONST",declConstantePtr, auxAritPtr);
                                                                        };
termino: 
      factor                                                  {
                                                                  terminoPtr = factorPtr;
                                                                  fprintf(fp,"R 36: termino => factor\n");}
      | termino OP_MUL factor                                 {
                                                                  terminoPtr=crearNodo("OP_MUL", terminoPtr, factorPtr);
                                                                  fprintf(fp,"R 37: termino => termino OP_MUL factor \n");}
      | termino OP_DIV factor                                 {
                                                                  terminoPtr=crearNodo("OP_DIV", terminoPtr, factorPtr);
                                                                  fprintf(fp,"R 38: termino => termino OP_DIV factor\n");};

factor:           
      ID                                                      {
                                                                fprintf(fp,"R 39: factor => ID es: %s\n", yylval.valor_string);
                                                                int pos = chequearVarEnTabla(yylval.valor_string,yylineno);
                                                                factorPtr = crearHoja($1,tabla_simbolo[pos].tipo_dato);
                                                                }
      | CONST_INT                                             { 
                                                                sprintf(str_aux, "%d",$1);
                                                                fprintf(fp,"R 40: factor => CONST_INT: %d\n", yylval.valor_int);
                                                                agregarCteATabla(CteInt);
                                                                factorPtr = crearHoja(str_aux,CteInt);
                                                                }
      | CONST_FLOAT                                           { 
                                                                sprintf(str_aux, "%f",$1); 
                                                                fprintf(fp,"R 41: factor => CONST_FLOAT: %f\n",yylval.valor_float);
                                                                agregarCteATabla(CteFloat);
                                                                factorPtr = crearHoja(str_aux,CteFloat);
                                                              };

      | P_A {     ponerenPila(pilaExpresion,exprAritPtr);
                  } 
            expresion_aritmetica P_C                                     
                                                            { 
                                                                  factorPtr = exprAritPtr;
                                                                  exprAritPtr = topedePila(pilaExpresion);
                                                                  sacardePila(pilaExpresion);
                                                                  fprintf(fp,"R 42: factor => P_A expresion P_C\n");
                                                            }
      
      | expr_maximo                                         { 
                                                                  fprintf(fp,"R 43: factor => expr_maximo;\n");
                                                                  factorPtr=exprMaximoPtr;
                                                            };

expr_maximo: 
      MAXIMO P_A lista_expresion P_C                        { 
                                                                  fprintf(fp,"R 44: expr_maximo => MAXIMO P_A lista_expresion P_C\n");
                                                                  exprMaximoPtr = auxMaxNodo;
                                                            };

lista_expresion: 
      lista_expresion COMA expresion_aritmetica
															{fprintf(fp,"R 43: lista_expresion => lista_expresion COMA expresion_aritmetica;\n");
															auxMaximoHojaPtr = crearHoja("@Max",Float);
															auxMaxSelNodo = crearNodo("CMP_MAYOR",exprAritPtr,auxMaximoHojaPtr);
															auxMaximoHojaPtr = crearHoja("@Max",Float);
                                                                                          //TODO  insertar en tabla de simbolos @Max# concatenar con un numero
															auxMaxAsigNodo = crearNodo("DOS_PUNTOS",auxMaximoHojaPtr,exprAritPtr);											
															auxMaxIFNodo = crearNodo("IF",auxMaxSelNodo,auxMaxAsigNodo);
															auxMaxNodoAnterior = auxMaxNodo;
															auxMaxNodo = crearNodo("Maximo",auxMaxNodoAnterior,auxMaxIFNodo);
															};
															
      | expresion_aritmetica								
															{ fprintf(fp,"R 43: lista_expresion => expresion_aritmetica;\n");
																auxMaximoHojaPtr = crearHoja("@Max",Float);
																auxMaxNodo = crearNodo("DOS_PUNTOS",auxMaximoHojaPtr,exprAritPtr);
															};

%%

int main(int argc,char *argv[])
{
      pilaExpresion = crearPila();      
      pilaBloque = crearPila();
      pilaCondicion = crearPila();
      fp = fopen("reglas.txt","w"); 
      if (!fp)
            printf("\nNo se puede abrir el archivo reglas.txt \n");
            
      graph = fopen("graph.dot","w"); 
      if (!graph)
            printf("\nNo se puede abrir el archivo \n");

      if ((yyin = fopen(argv[1], "rt")) == NULL)
      {
            printf("\nNo se puede abrir el archivo: %s\n", argv[1]);
      }
      else
      {
            yyparse();
            fclose(yyin);
      }
      fclose(fp);
      fclose(graph);
      vaciarPila(pilaExpresion);      
      vaciarPila(pilaBloque);      
      vaciarPila(pilaCondicion);
      return 0;
}
