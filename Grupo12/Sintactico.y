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
char str_auxetiq[10];
m10_stack_t* pilaExpresion;
m10_stack_t* pilaBloque;
m10_stack_t* pilaCondicion;
m10_stack_t* pilaEtiq;
m10_stack_t* pilaEtiqExpMax;

/* Cosas para la declaracion de variables y la tabla de simbolos */
int varADeclarar1 = 0;
int cantVarsADeclarar = 0;
int tipoDatoADeclarar[TAMANIO_TABLA];
int indiceDatoADeclarar = 0;
int indice_tabla = -1;
int contCuerpo = 0;
int auxOperaciones=0;
int contCond=0;
int contExpMax=0;
int tipoDatoMax=SinTipo;

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
                                                      contCond++;
                                                      sprintf(str_auxetiq,"%d",contCond);
                                                      auxEtiqPtr = malloc(sizeof(tNodo));
                                                      strcpy(auxEtiqPtr->info.dato,str_auxetiq);
                                                      ponerenPila(pilaEtiq,auxEtiqPtr);
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
                                                            sacardePila(pilaCondicion);
                                                      }

                                                      auxEtiqPtr=topedePila(pilaEtiq);
                                                      sprintf(str_aux,"#FIN%s",auxEtiqPtr->info.dato);
					                        auxWhilePtr=crearHoja(str_aux,SinTipo);
                                                      sprintf(str_aux,"#BLOQ%s:",auxEtiqPtr->info.dato); 
                                                      condicionPtr=crearNodo(str_aux,condicionPtr,auxWhilePtr);

                                                      sprintf(str_aux,"#COND%s:",auxEtiqPtr->info.dato);					
                                                      auxWhilePtr=crearHoja(str_aux,SinTipo);

                                                      condicionPtr=crearNodo("Cuerpo",auxWhilePtr,condicionPtr);
                                                      sprintf(str_aux,"#jmp COND%s",auxEtiqPtr->info.dato);
                                                      bloqueWhPtr=crearNodo(str_aux , condicionPtr , bloquePtr );
                                                      sprintf(str_aux,"#FIN%s:",auxEtiqPtr->info.dato); 
                                                      bloqueWhPtr=crearNodo(str_aux,bloqueWhPtr,NULL);

                                                      if (topedePila(pilaBloque)){
                                                            bloquePtr = topedePila(pilaBloque);
                                                            sacardePila(pilaBloque);
                                                      }
                                                      
                                                      if (topedePila(pilaEtiq)){
                                                            sacardePila(pilaEtiq);
                                                      }
                                                };

condicion: 
      comparacion                                           {
                                                            condicionPtr=comparacionPtr;
                                                            verificarTipoDato(&condicionPtr,yylineno);
                                                            }
      | comparacion { comparacionAuxPtr = comparacionPtr; } OP_AND comparacion {
                                                            verificarTipoDato(&comparacionAuxPtr,yylineno);
                                                            sprintf(str_aux,"#FIN%s",topedePila(pilaEtiq));
                                                            auxIfPtr=crearHoja(str_aux,SinTipo);
                                                            comparacionAuxPtr = crearNodo("Cuerpo",comparacionAuxPtr,auxIfPtr);
                                                            condicionPtr = crearNodo("AND",comparacionAuxPtr,comparacionPtr);
                                                            
                                                            verificarTipoDato(&comparacionPtr,yylineno);
                                                            }
      | comparacion { comparacionAuxPtr = comparacionPtr; } OP_OR comparacion {
                                                            verificarTipoDato(&comparacionAuxPtr,yylineno);
                                                            sprintf(str_aux,"#BLOQ%s",topedePila(pilaEtiq));
				                                    auxIfPtr=crearHoja(str_aux,SinTipo);
				                                    invertirSalto(&comparacionAuxPtr);
				                                    comparacionAuxPtr = crearNodo("Cuerpo",comparacionAuxPtr,auxIfPtr);

                                                            condicionPtr = crearNodo("OR",comparacionAuxPtr,comparacionPtr);
                                                            verificarTipoDato(&comparacionPtr,yylineno);	
                                                            }

      | OP_NOT comparacion                                  {
                                                            invertirSalto(&comparacionPtr);
                                                            condicionPtr = crearNodo("NOT",comparacionPtr,NULL);
                                                            verificarTipoDato(&condicionPtr,yylineno);
                                                            };

comparacion: 
      expresion { exprCMPPtr = exprPtr; } comparador expresion {  crearNodoCMP(str_auxcmp); };

comparador: 
      CMP_MAYOR { strncpy(str_auxcmp,"BLE",10);}  
	  | CMP_MAYIG { strncpy(str_auxcmp,"BLT",10);}  
	  | CMP_DIST { strncpy(str_auxcmp,"BEQ",10);}  
	  | CMP_IGUAL { strncpy(str_auxcmp,"BNE",10);}  
	  | CMP_MENOR { strncpy(str_auxcmp,"BGE",10);}  
	  | CMP_MENIG { strncpy(str_auxcmp,"BGT",10);}  ;

seleccion: 
      seleccion_if                                          {seleccionPtr=seleccionIFPtr;}
      

condicion_if:     IF P_A            {
                                          contCond++;//Apilo Etiqueta correspondiente
                                          sprintf(str_auxetiq,"%d",contCond);
                                          auxEtiqPtr = malloc(sizeof(tNodo));
                                          strcpy(auxEtiqPtr->info.dato,str_auxetiq);
                                          ponerenPila(pilaEtiq,auxEtiqPtr);
                                          
                                    } 
                  condicion P_C     {
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
seleccion_if: condicion_if bloque ENDIF     {   fprintf(fp,"R 20: seleccion_if => IF P_A condicion P_C L_A bloque L_C \n");
                                                
                                                if (topedePila(pilaCondicion)){
                                                      condicionPtr = topedePila(pilaCondicion);
                                                      sacardePila(pilaCondicion);
                                                }
                                                sprintf(str_aux,"#FIN%s",topedePila(pilaEtiq));
                                                auxIfPtr=crearHoja(str_aux,SinTipo);
                                                sprintf(str_aux,"#BLOQ%s:",topedePila(pilaEtiq)); 					
                                                condicionPtr=crearNodo(str_aux,condicionPtr,auxIfPtr);
                                                
                                                condicionPtr=crearNodo("Cuerpo",NULL,condicionPtr);
                                                sprintf(str_aux,"#FIN%s:",topedePila(pilaEtiq)); 
                                                seleccionIFPtr=crearNodo( "IF" , condicionPtr , bloquePtr );
                                                seleccionIFPtr=crearNodo(str_aux,seleccionIFPtr,NULL);
                                                
                                                if (topedePila(pilaBloque)){
                                                      bloquePtr = topedePila(pilaBloque);
                                                      sacardePila(pilaBloque);
                                                }
                                                
                                                if (topedePila(pilaEtiq)){
                                                      sacardePila(pilaEtiq);
                                                }
							}
      | condicion_if bloque {auxBloquePtr=bloquePtr;} ELSE bloque ENDIF
                                          {
                                                fprintf(fp,"R 21: seleccion_if => condicion_if bloque ELSE bloque ENDIF\n");
                                                if (topedePila(pilaCondicion)){
                                                      condicionPtr = topedePila(pilaCondicion);
                                                      sacardePila(pilaCondicion);
                                                }
                                                
							      sprintf(str_aux,"#ELSE%s",topedePila(pilaEtiq));
							      auxIfPtr=crearHoja(str_aux,SinTipo);
							      sprintf(str_aux,"#BLOQ%s:",topedePila(pilaEtiq)); 					
							      condicionPtr=crearNodo(str_aux,condicionPtr,auxIfPtr);
							      condicionPtr=crearNodo("Cuerpo",NULL,condicionPtr);
							
							      sprintf(str_aux,"#jmp FIN%s",topedePila(pilaEtiq));
							      auxIfPtr=crearHoja(str_aux,SinTipo);
							      seleccionIFPtr=crearNodo("Cuerpo",auxBloquePtr,auxIfPtr);

							      sprintf(str_aux,"#ELSE%s:",topedePila(pilaEtiq));
							      auxIfPtr=crearHoja(str_aux,SinTipo);
							      seleccionIFPtr=crearNodo("Cuerpo",seleccionIFPtr,auxIfPtr);

							      sprintf(str_aux,"#FIN%s:",topedePila(pilaEtiq));
							      bloquePtr=crearNodo(str_aux,seleccionIFPtr,bloquePtr);
							      seleccionIFPtr=crearNodo( "IF" , condicionPtr, bloquePtr );
					
                                                if (topedePila(pilaBloque)){
                                                      bloquePtr = topedePila(pilaBloque);
                                                      sacardePila(pilaBloque);
                                                }
                                                
                                                if (topedePila(pilaEtiq)){
                                                      sacardePila(pilaEtiq);
                                                }

                                          }


asignacion: 
      ID DOS_PUNTOS expresion PUNTO_Y_COMA                    {   fprintf(fp,"R 23: asignacion => ID DOS_PUNTOS expresion PUNTO_Y_COMA\n");
                                                                  int pos=chequearVarEnTabla($1,yylineno);
                                                                  validarCteEnTabla($1,yylineno);//Validar si no se asigna a una cte
                                                                  sprintf(str_aux, "%s",$1);
				                                          asigPtr=crearHoja($1,tabla_simbolo[pos].tipo_dato);
				                                          asigPtr=crearNodo("DOS_PUNTOS",asigPtr, exprPtr);
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
                                                                  exprAritPtr->info.tipoDato= terminoPtr->info.tipoDato;
                                                                  fprintf(fp,"R 27: expresion_aritmetica => termino\n");}
      | expresion OP_RES termino                                { 
                                                                  exprAritPtr=crearNodo("OP_RES", exprPtr, terminoPtr);
                                                                  auxOperaciones++;
                                                                  exprAritPtr->info.tipoDato= terminoPtr->info.tipoDato;
                                                                  fprintf(fp,"R 28: expresion_aritmetica => expresion OP_RES termino \n");}
      | expresion OP_SUM termino                                { 
                                                                  exprAritPtr=crearNodo("OP_SUM", exprPtr, terminoPtr);
                                                                  auxOperaciones++;
                                                                  exprAritPtr->info.tipoDato= terminoPtr->info.tipoDato;
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
                                                                  terminoPtr->info.tipoDato= factorPtr->info.tipoDato;
                                                                  fprintf(fp,"R 36: termino => factor\n");}
      | termino OP_MUL factor                                 {
                                                                  terminoPtr=crearNodo("OP_MUL", terminoPtr, factorPtr);
                                                                  auxOperaciones++;
                                                                  terminoPtr->info.tipoDato= factorPtr->info.tipoDato;
                                                                  fprintf(fp,"R 37: termino => termino OP_MUL factor \n");}
      | termino OP_DIV factor                                 {
                                                                  terminoPtr=crearNodo("OP_DIV", terminoPtr, factorPtr);
                                                                  terminoPtr->info.tipoDato= factorPtr->info.tipoDato;
                                                                  auxOperaciones++;
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

      | P_A {     
                  if(exprAritPtr){
                        ponerenPila(pilaExpresion,exprAritPtr);
                  }
            } 
            expresion_aritmetica P_C                                     
                                                            { 
                                                                  factorPtr = exprAritPtr;
                                                                  if(topedePila(pilaExpresion)){
                                                                        exprAritPtr = topedePila(pilaExpresion);
                                                                        sacardePila(pilaExpresion);
                                                                  }
                                                                  fprintf(fp,"R 42: factor => P_A expresion P_C\n");
                                                            }
      
      | expr_maximo                                         { 
                                                                  fprintf(fp,"R 43: factor => expr_maximo;\n");
                                                                  factorPtr=exprMaximoPtr;
                                                            };

expr_maximo: 
      MAXIMO P_A                    {
                                          contCond++;//Apilo Etiqueta correspondiente
                                          sprintf(str_auxetiq,"%d",contCond); // nro de etiqueta
                                          auxEtiqPtr = malloc(sizeof(tNodo));
                                          strcpy(auxEtiqPtr->info.dato,str_auxetiq);
                                          ponerenPila(pilaEtiq,auxEtiqPtr); // apilo nro de etiqueta
                                          
                                    }
      lista_expresion P_C           { 
                                          fprintf(fp,"R 44: expr_maximo => MAXIMO P_A lista_expresion P_C\n");
                                          exprMaximoPtr = auxMaxNodo;
                              
                                          sprintf(str_aux,"_Max%s",topedePila(pilaEtiq));
                                          auxMaxNodo = malloc(sizeof(tNodo));
                                          strcpy(auxMaxNodo->info.dato,auxMaximoHojaPtr->info.dato);
                                          auxMaxNodo->info.tipoDato=tipoDatoMax;
                                          exprMaximoPtr=crearNodo("Maximo",exprMaximoPtr,auxMaxNodo);
                                          
                                          if (topedePila(pilaEtiq)){
                                                sacardePila(pilaEtiq);
                                          }
                                    };

lista_expresion: 
      lista_expresion COMA expresion_aritmetica
                                                      {
                                                      fprintf(fp,"R 43: lista_expresion => lista_expresion COMA expresion_aritmetica;\n");
                                                      // IF ExpresionN > @max
                                                      // THEN
                                                      // @max = ExpresionN
                                                      // ENDIF

                                                      contExpMax++;

                                                      sprintf(str_aux,"_Max%s",topedePila(pilaEtiq));
                                                      auxMaximoHojaPtr = crearHoja(str_aux,tipoDatoMax);
                                                      
                                                      auxMaxIFNodo = crearNodo("CMP",exprAritPtr,auxMaximoHojaPtr);
                                                      auxMaxIFNodo = crearNodo("BLE",auxMaxIFNodo,NULL);
                                                      auxMaxCond=auxMaxIFNodo;

                                                      sprintf(str_aux,"#FINMAX%d",contExpMax); // ELSE JUMP TO FINMAX
                                                      auxIfPtr=crearHoja(str_aux,tipoDatoMax);
                                                      auxMaxCond=crearNodo("CUERPO",auxMaxCond,auxIfPtr);
                                                      
                                                      auxMaximoHojaPtr = crearHoja(auxMaximoHojaPtr->info.dato,tipoDatoMax);
                                                      int auxTipoDato = exprAritPtr->info.tipoDato;
                                                      exprAritPtr = crearNodo(exprAritPtr->info.dato,exprAritPtr->izq,exprAritPtr->der);
                                                      exprAritPtr->info.tipoDato = auxTipoDato;
                                                      
                                                      auxMaxAsigNodo = crearNodo("DOS_PUNTOS",auxMaximoHojaPtr,exprAritPtr); // @MAX = E

                                                      auxMaxIFNodo = crearNodo("IF",auxMaxCond,auxMaxAsigNodo);	
                                                      sprintf(str_aux,"#FINMAX%d:",contExpMax);
                                                      auxMaxIFNodo=crearNodo(str_aux,auxMaxIFNodo,NULL);
                                                      										
                                                      auxMaxNodoAnterior = auxMaxNodo;
                                                      auxMaxNodo = crearNodo("Maximo",auxMaxNodoAnterior,auxMaxIFNodo);
                                                      // FIN ETIQUETA

                                                      };
															
      | expresion_aritmetica								
                                                      { 
                                                            fprintf(fp,"R 43: lista_expresion => expresion_aritmetica;\n");
                                                            
                                                            sprintf(str_aux,"_Max%s",topedePila(pilaEtiq)); // crea nombre @MaxN donde N se desapila
                                                            tipoDatoMax=resolverTipoDatoMaximo(exprAritPtr->info.tipoDato);
                                                            agregarEnTabla(str_aux,yylineno,tipoDatoMax); // crea @MaxN en ts
                                                            auxMaximoHojaPtr = crearHoja(str_aux,tipoDatoMax); // crea @MaxN
                                                            auxMaxNodo = crearNodo("DOS_PUNTOS",auxMaximoHojaPtr,exprAritPtr); // @MaxN = E1
                                                      };

%%

int main(int argc,char *argv[])
{
      pilaExpresion = crearPila();      
      pilaBloque = crearPila();
      pilaCondicion = crearPila();
      pilaEtiq = crearPila();
      pilaEtiqExpMax = crearPila();
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
      generarAsm(&bloquePtr);
      fclose(fp);
      fclose(graph);
      vaciarPila(pilaExpresion);      
      vaciarPila(pilaBloque);      
      vaciarPila(pilaCondicion);
      vaciarPila(pilaEtiq);
      vaciarPila(pilaEtiqExpMax);

      return 0;
}
