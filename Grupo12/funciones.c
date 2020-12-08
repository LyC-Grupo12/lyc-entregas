#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include "funciones.h"

extern int varADeclarar1;
extern int cantVarsADeclarar;
extern int tipoDatoADeclarar[TAMANIO_TABLA];
extern int indiceDatoADeclarar;
extern int indice_tabla;
extern int auxOperaciones;
char msg[100];
char aux_str[41];
m10_stack_t* pilaAsm;
		
void mensajeDeError(enum tipoError error,const char* info, int linea){
  switch(error){ 
        case ErrorLexico: 
            printf("ERROR Lexico en la linea %d. Descripcion: %s\n",linea,info);
            break ;

		case ErrorSintactico: 
            printf("ERROR Sintactico en la linea %d. Descripcion: %s.\n",linea,info);
            break ;
  }

  system ("Pause");
  exit (1);
}


/* Devuleve la posicion en la que se encuentra el elemento buscado, -1 si no encontro el elemento */
int buscarEnTabla(char * nombre){
   int i=0;
   while(i<=indice_tabla){
	   if(strcmp(tabla_simbolo[i].nombre,normalizarId(nombre)) == 0){
		   return i;
	   }
	   i++;
   }
   return -1;
}

int yyerror(char* mensaje){
	printf("Syntax Error: %s\n", mensaje);
	system ("Pause");
	exit (1);
 }

 void agregarVarATabla(char* nombre,int esCteConNombre,int linea){
	 //Si se llena, error
	 if(indice_tabla >= TAMANIO_TABLA - 1){
		 printf("Error: No hay mas espacio en la tabla de simbolos.\n");
		 system("Pause");
		 exit(2);
	 }
	 //Si no hay otra variable con el mismo nombre...
	 if(buscarEnTabla(nombre) == -1){
		 //Agregar a tabla
		 indice_tabla ++;
		 tabla_simbolo[indice_tabla].esCteConNombre = esCteConNombre; 
		 strcpy(tabla_simbolo[indice_tabla].nombre,normalizarId(nombre));
	 }
	 else 
	 {
	 	sprintf(msg,"'%s' ya se encuentra declarada previamente.", nombre);
	 	mensajeDeError(ErrorSintactico,msg,linea);
	}
 }

 /** Agrega los tipos de datos a las variables declaradas. Usa las variables globales varADeclarar1, cantVarsADeclarar y tipoDatoADeclarar */
void agregarTiposDatosATabla(){
	int i;
	for(i = 0; i < cantVarsADeclarar; i++){
		tabla_simbolo[varADeclarar1 + i].tipo_dato = tipoDatoADeclarar[i];
	}
}

 void agregarEnTabla(char* nombre,int linea,int tipo){
	 if(indice_tabla >= TAMANIO_TABLA - 1){
		 printf("Error: No hay mas espacio en la tabla de simbolos.\n");
		 system("Pause");
		 exit(2);
	 }

	 if(buscarEnTabla(nombre) == -1){
		 //Agregar a tabla
		 indice_tabla ++;
		 strcpy(tabla_simbolo[indice_tabla].nombre,normalizarId(nombre));
		 tabla_simbolo[indice_tabla].tipo_dato = tipo;
	 }
 }

/** Guarda la tabla de simbolos en un archivo de texto */
void grabarTabla(){
	if(indice_tabla == -1)
		yyerror("No se encontro la tabla de simbolos");

	FILE* arch = fopen("ts.txt", "w+");
	if(!arch){
		printf("No se pudo crear el archivo ts.txt\n");
		return;
	}
	
	int i;
	char valor[TAM_NOMBRE];
	fprintf(arch, "%-30s|%-30s|%-30s|%-30s|%s\n","NOMBRE","TIPO","VALOR","LONGITUD","ES CTE CON NOMBRE ");
	fprintf(arch, "..............................................................................................................................................\n");
	for(i = 0; i <= indice_tabla; i++){
		fprintf(arch, "%-30s", &(tabla_simbolo[i].nombre) );
			
		switch (tabla_simbolo[i].tipo_dato){
		case Float:
			if(tabla_simbolo[i].esCteConNombre){
				sprintf(valor, "%f", tabla_simbolo[i].valor_f);
			}else{
				strcpy(valor,"--");
			}
			fprintf(arch, "|%-30s|%-30s|%-30s|%d","FLOAT",valor,"--",tabla_simbolo[i].esCteConNombre);
			break;
		case Integer:
			if(tabla_simbolo[i].esCteConNombre){
				sprintf(valor, "%d", tabla_simbolo[i].valor_i);
			}else{
				strcpy(valor,"--");
			}
			fprintf(arch, "|%-30s|%-30s|%-30s|%d","INTEGER",valor,"--",tabla_simbolo[i].esCteConNombre);
			break;
		case String:
		
			if(tabla_simbolo[i].esCteConNombre){
				strcpy(valor,tabla_simbolo[i].valor_s);
			}else{
				strcpy(valor,"--");
			}
			fprintf(arch, "|%-30s|%-30s|%-30s|%d","STRING",tabla_simbolo[i].valor_s,"--",tabla_simbolo[i].esCteConNombre);
			break;
		case CteFloat:
			fprintf(arch, "|%-30s|%-30f|%-30s|%s", "CTE_FLOAT",tabla_simbolo[i].valor_f,"--","--");
			break;
		case CteInt:
			fprintf(arch, "|%-30s|%-30d|%-30s|%s", "CTE_INT",tabla_simbolo[i].valor_i,"--","--");
			break;
		case CteString:
			fprintf(arch, "|%-30s|%-30s|%-30d|%s", "CTE_STRING",&(tabla_simbolo[i].valor_s), tabla_simbolo[i].longitud,"--");
			break;
		}

		fprintf(arch, "\n");
	}
	fclose(arch);
}

 

/** Agrega una constante a la tabla de simbolos */
void agregarCteATabla(int num){
	char nombre[30];

	if(indice_tabla >= TAMANIO_TABLA - 1){
		printf("Error: No hay mas espacio en la tabla de simbolos.\n");
		system("Pause");
		exit(2);
	}
	
	switch(num){
		case CteInt:
			sprintf(nombre, "%d", yylval.valor_int);
			//Si no hay otra variable con el mismo nombre...
			if(buscarEnTabla(nombre) == -1){
			//Agregar nombre a tabla
				indice_tabla++;
				strcpy(tabla_simbolo[indice_tabla].nombre,normalizarId(nombre));
			//Agregar tipo de dato
				tabla_simbolo[indice_tabla].tipo_dato = CteInt;
			//Agregar valor a la tabla
				tabla_simbolo[indice_tabla].valor_i = yylval.valor_int;
			}
		break;

		case CteFloat:
			sprintf(nombre, "%f",yylval.valor_float);
			//Si no hay otra variable con el mismo nombre...
			if(buscarEnTabla(nombre) == -1){
			//Agregar nombre a tabla
				indice_tabla ++;
				strcpy(tabla_simbolo[indice_tabla].nombre, normalizarId(nombre));
			//Agregar tipo de dato
				tabla_simbolo[indice_tabla].tipo_dato = CteFloat;
			//Agregar valor a la tabla
				tabla_simbolo[indice_tabla].valor_f = yylval.valor_float;
			}
		break;

		case CteString:
			strcpy(nombre,normalizarNombre(yylval.valor_string));
			memmove(&nombre[0], &nombre[1], strlen(nombre));//Remover el primer guion "_"
			if(buscarEnTabla(nombre) == -1){
			//Agregar nombre a tabla
				indice_tabla ++;
				strcpy(tabla_simbolo[indice_tabla].nombre,normalizarNombre(yylval.valor_string));				
				//Agregar tipo de dato
				tabla_simbolo[indice_tabla].tipo_dato = CteString;

				//Agregar valor a la tabla
				int length = strlen(yylval.valor_string);
				char auxiliar[length];
				strcpy(auxiliar,yylval.valor_string);
				auxiliar[strlen(auxiliar)-1] = '\0';
				strcpy(tabla_simbolo[indice_tabla].valor_s, auxiliar+1);
				//Agregar longitud
				tabla_simbolo[indice_tabla].longitud = length -2;
				
			}
		break;

			case SinTipo:
			if(buscarEnTabla(yylval.valor_string) == -1){
			//Agregar nombre a tabla
				indice_tabla ++;
				strcpy(tabla_simbolo[indice_tabla].nombre,normalizarNombre(yylval.valor_string));			

				//Agregar tipo de dato
				tabla_simbolo[indice_tabla].tipo_dato = SinTipo;
				

				//Agregar valor a la tabla
				int length = strlen(yylval.valor_string);
				char auxiliar[length];
				strcpy(auxiliar,yylval.valor_string);
				auxiliar[strlen(auxiliar)] = '\0';
				strcpy(tabla_simbolo[indice_tabla].valor_s, "--");
				//Agregar longitud
				tabla_simbolo[indice_tabla].longitud = length -2;
	
			}
		break;

	}
}

/** Se fija si ya existe una entrada con ese nombre en la tabla de simbolos. Si no existe, muestra un error de variable sin declarar y aborta la compilacion. */
int chequearVarEnTabla(char* nombre,int linea){
	int pos=0;
	pos=buscarEnTabla(nombre);
	//Si no existe en la tabla, error
	if( pos == -1){
		sprintf(msg,"La variable '%s' debe ser declarada previamente en la seccion de declaracion de variables", nombre);
		mensajeDeError(ErrorSintactico,msg,linea);
	}
	//Si existe en la tabla, dejo que la compilacion siga
	return pos;
}

void validarCteEnTabla(char* nombre,int linea){
	int pos = buscarEnTabla(nombre); 
	if(tabla_simbolo[pos].esCteConNombre){
		mensajeDeError(ErrorSintactico,"No se puede asignar valor a la cte",linea);
	}
}

//Verifica el tipo de dato si es compatible entre todos los nodos del sub arbol
int verificarTipoDato(tArbol * p,int linea){
	tArbol *pAux = hijoMasIzq(p);//tipo a comparar contra el resto
	int tipoAux = (*pAux)->info.tipoDato;
	verificarTipo(p,tipoAux,linea);
}

void verificarTipo(tArbol* p,int tipoAux,int linea){
	int compatible,tipo;
	if (*p){
        verificarTipo(&(*p)->izq,tipoAux,linea);
        verificarTipo(&(*p)->der,tipoAux,linea);
		if((*p)->izq==NULL && (*p)->der==NULL){
			tipo = (*p)->info.tipoDato;
			compatible=verificarCompatible(tipo,tipoAux);
		}
		if(!compatible){
			mensajeDeError(ErrorSintactico,"Id/Cte de tipo no compatible",linea);
		}
	}
}

int verificarCompatible(int tipo,int tipoAux){
	if(tipo==tipoAux)
		return TRUE;
	if(tipo==CteInt && tipoAux==Integer || tipoAux==CteInt && tipo==Integer )
		return TRUE;
	if(tipo==CteFloat && tipoAux==Float || tipoAux==CteFloat && tipo==Float )
		return TRUE;
	if(tipo==CteString && tipoAux==String || tipoAux==CteString && tipo==String )
		return TRUE;
	return FALSE;
}

char* normalizarNombre(const char* nombre){
    char *aux = (char *) malloc( sizeof(char) * (strlen(nombre)) + 2);
	char *retor = (char *) malloc( sizeof(char) * (strlen(nombre)) + 2);
	
	strcpy(retor,nombre);
	int len = strlen(nombre);
	retor[len-1] = '\0';
	
	strcpy(aux,"_");
	strcat(aux,++retor);

	return reemplazarCaracter(aux);
}

char* normalizarId(const char* cadena){
	char *aux = (char *) malloc( sizeof(char) * (strlen(cadena)) + 2);
	strcpy(aux,"_");
	strcat(aux,cadena);
	reemplazarCaracter(aux);
	return aux;
}

char * reemplazarCaracter(char * aux){
	int i=0;
	for(i = 0; i <= strlen(aux); i++){
  		if(aux[i] == '\t' || aux[i] == '\r' || aux[i] == ' ' || aux[i] == ':' || aux[i] == '!'){
  			aux[i] = '_';
 		}

		if(aux[i] == '.'){
  			aux[i] = 'p';
 		}
	}
	return aux;
}

void invertirSalto(tArbol *p){
	if(strcmp((*p)->info.dato,"BEQ")==0){
		strcpy((*p)->info.dato,"BNE");
	}
	else if(strcmp((*p)->info.dato,"BNE")==0){
		strcpy((*p)->info.dato,"BEQ");
	}
	else if(strcmp((*p)->info.dato,"BGT")==0){
		strcpy((*p)->info.dato,"BLT");
	}
	else if(strcmp((*p)->info.dato,"BLT")==0){
		strcpy((*p)->info.dato,"BGT");
	}
	else if(strcmp((*p)->info.dato,"BGE")==0){
		strcpy((*p)->info.dato,"BLE");
	}
	else if(strcmp((*p)->info.dato,"BLE")==0){
		strcpy((*p)->info.dato,"BGE");
	}
}

int resolverTipoDatoMaximo(int tipo){
	if(tipo==CteInt || tipo==Integer )
		return Integer;
	else if(tipo==CteFloat  || tipo==Float )
		return Float;
	return SinTipo;
}

void crearNodoCMP(char * comp){
	comparacionPtr = crearNodo("CMP",exprCMPPtr,exprPtr);
	comparacionPtr = crearNodo(comp,comparacionPtr,NULL);
}

void agregarValorACte(int tipo){
	switch (tipo){
		case CteInt:{
			tabla_simbolo[indice_tabla].valor_i = tabla_simbolo[indice_tabla - 1].valor_i;
			break;
		}
		case CteFloat:{
			tabla_simbolo[indice_tabla].valor_f = tabla_simbolo[indice_tabla - 1].valor_f;
			break;
		}
		case CteString:{
			strcpy(tabla_simbolo[indice_tabla].valor_s, tabla_simbolo[indice_tabla -1].valor_s);
		break;	
		}
	}
}

tNodo* crearNodo(const char* dato, tNodo *pIzq, tNodo *pDer){
    
    tNodo* nodo = malloc(sizeof(tNodo));   
    tInfo info;
    strcpy(info.dato, dato);
    nodo->info = info;
    nodo->izq = pIzq;
    nodo->der = pDer;

    return nodo;
}

tNodo* crearHoja(char* dato,int tipo){	
    tNodo* nodoNuevo = (tNodo*)malloc(sizeof(tNodo));

	strcpy(nodoNuevo->info.dato, dato);
	nodoNuevo->info.tipoDato = tipo;
    nodoNuevo->izq = NULL;
    nodoNuevo->der = NULL;

    return nodoNuevo;
}

tArbol * hijoMasIzq(tArbol *p){
    if(*p){
        if((*p)->izq)
            return hijoMasIzq(&(*p)->izq);
        else
            return p;
    }
    return NULL;
}

void enOrden(tArbol *p){
    if (*p)
    {
        enOrden(&(*p)->izq);
        verNodo((*p)->info.dato);
        enOrden(&(*p)->der);
    }
}

void postOrden(tArbol *p){
    if (*p){
        postOrden(&(*p)->izq);
        postOrden(&(*p)->der);
		verNodo((*p)->info.dato);
    }
}

void verNodo(const char *p){
    printf("%s ", p);
}


void _tree_print_dot_subtree(int nro_padre, tNodo *padre, int nro, tArbol *nodo, FILE* stream){
    if (*nodo != NULL)
    {    
        fprintf(stream, "x%d [label=<%s>];\n",nro,(*nodo)->info.dato);
        if (padre != NULL){
            fprintf(stream, "x%d -> x%d;\n",nro_padre,nro);
        }   
        _tree_print_dot_subtree(nro, *nodo, 2 * nro + 1, &(*nodo)->izq, stream);
        _tree_print_dot_subtree(nro, *nodo, 2 * nro + 2, &(*nodo)->der, stream);
        
    }
}

void tree_print_dot(tArbol *p,FILE* stream){
    fprintf(stream, "digraph BST {\n");
    if (*p)
        _tree_print_dot_subtree(-1, NULL, 0, &(*p), stream);
    fprintf(stream, "}");
}


void generarAsm(tArbol *arbol){
	tArbol *auxArbol=arbol;
	pilaAsm = crearPila();      
      
	int i;//Contador for
	FILE *pf = fopen("Final.asm", "w+");
	if (!pf){
		printf("Error al guardar el archivo assembler.\n");
		exit(1);
	}
	//includes asm
	fprintf(pf, "include macros2.asm\n");
	fprintf(pf, "include number.asm\n\n");
	fprintf(pf,".MODEL LARGE\n.STACK 200h\n.386\n.387\n.DATA\n\n\tMAXTEXTSIZE equ 50\n");
	
	//Data
	
	//Auxiliares
	for(i=0;i<auxOperaciones;i++){
		fprintf(pf,"\t@_auxR%d \tDD 0.0\n",i);
		fprintf(pf,"\t@_auxE%d \tDD 0\n",i);
	}

	for (i = 0; i <= indice_tabla; i++){
		switch (tabla_simbolo[i].tipo_dato){
			case Integer:
				if(tabla_simbolo[i].esCteConNombre){
					fprintf(pf, "\t@%s \tDD %d\n",tabla_simbolo[i].nombre,tabla_simbolo[i].valor_i);
				}
				else{
					fprintf(pf, "\t@%s \tDD 0\n",tabla_simbolo[i].nombre);
				}
				break;
			case Float:
				if(tabla_simbolo[i].esCteConNombre){
					fprintf(pf, "\t@%s \tDD %f\n",tabla_simbolo[i].nombre,tabla_simbolo[i].valor_f);
				}
				else{
					fprintf(pf, "\t@%s \tDD 0.0\n",tabla_simbolo[i].nombre);
				}
				break;
			case CteInt:
				fprintf(pf,"\t@%s \tDD %d\n",tabla_simbolo[i].nombre,tabla_simbolo[i].valor_i);
				break;
			case CteFloat:
				sprintf(aux_str,"%f",tabla_simbolo[i].valor_f);
				fprintf(pf,"\t@%s \tDD %s\n",tabla_simbolo[i].nombre,aux_str);
				break;
			default:
				break;
			}
	}

	for (i = 0; i <= indice_tabla; i++){
		switch (tabla_simbolo[i].tipo_dato){
			case String:
				if(tabla_simbolo[i].esCteConNombre){
					fprintf(pf,"\t@%s \tDB \"%s\",'$',%d dup(?)\n",tabla_simbolo[i].nombre,tabla_simbolo[i].valor_s,50-tabla_simbolo[i].longitud);
				}
				else{
					fprintf(pf, "\t@%s \tDB MAXTEXTSIZE dup (?),'$'\n",tabla_simbolo[i].nombre);
				}
				break;
	
			case CteString:
				fprintf(pf,"\t@%s \tDB \"%s\",'$',%d dup(?)\n",tabla_simbolo[i].nombre,tabla_simbolo[i].valor_s,50-tabla_simbolo[i].longitud);
				break;
			default:
				break;
			}
	}
	
	fprintf(pf,"\n.CODE\n.startup\n\tmov AX,@DATA\n\tmov DS,AX\n\n\tFINIT\n\n");

	recorrerArbol(auxArbol,pf);

	fprintf(pf,"\tmov ah, 4ch\n\tint 21h\n\n");

	//FUNCIONES PARA MANEJO DE ENTRADA/SALIDA Y CADENAS
	fprintf(pf,"\nstrlen proc\n\tmov bx, 0\n\tstrl01:\n\tcmp BYTE PTR [si+bx],'$'\n\tje strend\n\tinc bx\n\tjmp strl01\n\tstrend:\n\tret\nstrlen endp\n");
	fprintf(pf,"\ncopiar proc\n\tcall strlen\n\tcmp bx , MAXTEXTSIZE\n\tjle copiarSizeOk\n\tmov bx , MAXTEXTSIZE\n\tcopiarSizeOk:\n\tmov cx , bx\n\tcld\n\trep movsb\n\tmov al , '$'\n\tmov byte ptr[di],al\n\tret\ncopiar endp\n");
	fprintf(pf,"\nconcat proc\n\tpush ds\n\tpush si\n\tcall strlen\n\tmov dx , bx\n\tmov si , di\n\tpush es\n\tpop ds\n\tcall strlen\n\tadd di, bx\n\tadd bx, dx\n\tcmp bx , MAXTEXTSIZE\n\tjg concatSizeMal\n\tconcatSizeOk:\n\tmov cx , dx\n\tjmp concatSigo\n\tconcatSizeMal:\n\tsub bx , MAXTEXTSIZE\n\tsub dx , bx\n\tmov cx , dx\n\tconcatSigo:\n\tpush ds\n\tpop es\n\tpop si\n\tpop ds\n\tcld\n\trep movsb\n\tmov al , '$'\n\tmov byte ptr[di],al\n\tret\nconcat endp\n");

	//Fin archivo
	fprintf(pf, "\nEND");
	fclose(pf);
	vaciarPila(pilaAsm);
}

void recorrerArbol(tArbol *arbol,FILE * pf){
 	if (*arbol){
		recorrerArbol(&(*arbol)->izq,pf);
    	recorrerArbol(&(*arbol)->der,pf);
    	tratarNodo(arbol,pf);
	}
}

void tratarNodo(tArbol *nodo,FILE *pf){
	//Escribimos en el .asm 
	int pos;
	int i;
	int nroAuxEntero=0;
	int nroAuxReal=0;
	char aux1[50]="aux\0";
	char aux2[10];
	
	//Variables y Constantes
	sprintf(aux_str,"%s",&(*nodo)->info.dato);

	switch((*nodo)->info.tipoDato){

		case CteFloat:
			sprintf(aux_str, "%s",(*nodo)->info.dato);
			pos=buscarEnTabla(aux_str);
			break;
		case CteString:
			strcpy(aux_str,normalizarNombre(aux_str));
			memmove(&aux_str[0], &aux_str[1], strlen(aux_str));//Remover el primer guion "_"
			pos=buscarEnTabla(aux_str);
		break;
		default:
			pos=buscarEnTabla(aux_str);
		break;
	}

	if(pos!=-1){
		strcpy((*nodo)->info.dato,normalizarId(aux_str));
		ponerenPila(pilaAsm,*nodo);
	}	
	
	//PUT
	if(strcmp(aux_str,"PUT")==0){
		auxPtr = topedePila(pilaAsm);
		switch(auxPtr->info.tipoDato){
			case Integer:
			case CteInt:
				fprintf(pf,"\tdisplayInteger \t@%s,3\n\tnewLine 1\n",auxPtr->info.dato);
			break;
			case Float:
			case CteFloat:
				fprintf(pf,"\tdisplayFloat \t@%s,3\n\tnewLine 1\n",auxPtr->info.dato);
			break;
			case String:
			case CteString:
				fprintf(pf,"\tdisplayString \t@%s\n\tnewLine 1\n",auxPtr->info.dato);
			break;
		}
		sacardePila(pilaAsm);
	}

	if(strcmp(aux_str,"GET")==0){
		auxPtr = topedePila(pilaAsm);
		switch(auxPtr->info.tipoDato){
			case Integer:
				fprintf(pf,"\tGetInteger \t@%s\n",auxPtr->info.dato);
			break;
			case Float:
				fprintf(pf,"\tgetFloat \t@%s\n",auxPtr->info.dato);
				break;
			case String:
				fprintf(pf,"\tgetString \t@%s\n",auxPtr->info.dato);
				break;	
		}
		sacardePila(pilaAsm);
	}

	//Asignacion 
	if(strcmp(aux_str,"DOS_PUNTOS")==0 ){
		auxPtr = topedePila(pilaAsm);
		switch(auxPtr->info.tipoDato){
			case Integer:
			case CteInt:
				fprintf(pf,"\tfild \t@%s\n",auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfistp \t@%s\n",auxPtr->info.dato);
			break;
			case Float:
			case CteFloat:
				fprintf(pf,"\tfld \t@%s\n",auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfstp \t@%s\n",auxPtr->info.dato);
			break;
			case String:
			case CteString:
				fprintf(pf,"\tmov ax, @DATA\n\tmov ds, ax\n\tmov es, ax\n");
				fprintf(pf,"\tmov si, OFFSET\t@%s\n", auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tmov di, OFFSET\t@%s\n",auxPtr->info.dato);
				fprintf(pf,"\tcall copiar\n");
			break;
		}
		sacardePila(pilaAsm);
	}

	//Operaciones aritmeticas
	if(strcmp(aux_str,"OP_MUL")==0){
		auxPtr = topedePila(pilaAsm);
		switch(auxPtr->info.tipoDato){
			case Integer:
			case CteInt:
				fprintf(pf,"\tfild \t@%s\n",auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfimul \t@%s\n",auxPtr->info.dato);
				strcpy(aux1,"_auxE");
				itoa(nroAuxEntero,aux2,10);
				strcat(aux1,aux2);
				fprintf(pf,"\tfistp \t@%s\n", aux1);
				sacardePila(pilaAsm);
				strcpy(auxPtr->info.dato,aux1);
				auxPtr->info.tipoDato=Integer;
				ponerenPila(pilaAsm,auxPtr);
				nroAuxEntero++;
			break;
			case Float:
			case CteFloat:
				fprintf(pf,"\tfld \t@%s\n",auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfld \t@%s\n",auxPtr->info.dato);
				fprintf(pf,"\tfmul\n");
				strcpy(aux1,"_auxR");
				itoa(nroAuxReal,aux2,10);
				strcat(aux1,aux2);
				fprintf(pf,"\tfstp \t@%s\n", aux1);	
				sacardePila(pilaAsm);			
				strcpy(auxPtr->info.dato,aux1);
				auxPtr->info.tipoDato=Float;
				ponerenPila(pilaAsm,auxPtr);
				nroAuxReal++;
			break;
		}
	}

	if(strcmp(aux_str,"OP_SUM")==0){
		auxPtr = topedePila(pilaAsm);
		switch(auxPtr->info.tipoDato){
			case Integer:
			case CteInt:	
				fprintf(pf,"\tfild \t@%s\n", auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfiadd \t@%s\n",auxPtr->info.dato);
				strcpy(aux1,"_auxE");
				itoa(nroAuxEntero,aux2,10);
				strcat(aux1,aux2);
				fprintf(pf,"\tfistp \t@%s\n", aux1);
				sacardePila(pilaAsm);			
				strcpy(auxPtr->info.dato,aux1);
				auxPtr->info.tipoDato=Integer;
				ponerenPila(pilaAsm,auxPtr);
				nroAuxEntero++;
		break;
		case Float:
		case CteFloat:
			fprintf(pf,"\tfld \t@%s\n",auxPtr->info.dato);
			sacardePila(pilaAsm);
			auxPtr = topedePila(pilaAsm);
			fprintf(pf,"\tfld \t@%s\n",auxPtr->info.dato);
			fprintf(pf,"\tfadd\n");
			strcpy(aux1,"_auxR");
			itoa(nroAuxReal,aux2,10);
			strcat(aux1,aux2);
			fprintf(pf,"\tfstp \t@%s\n", aux1);
			sacardePila(pilaAsm);			
			strcpy(auxPtr->info.dato,aux1);
			auxPtr->info.tipoDato=Float;
			ponerenPila(pilaAsm,auxPtr);
			nroAuxReal++;
			break;				
		}
	}

	if(strcmp(aux_str,"OP_DIV")==0){
		auxPtr = topedePila(pilaAsm);
		switch(auxPtr->info.tipoDato){
			case Integer:
			case CteInt:
				fprintf(pf,"\tfild \t@%s\n", auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfidivr \t@%s\n", auxPtr->info.dato);
				strcpy(aux1,"_auxE");
				itoa(nroAuxEntero,aux2,10);
				strcat(aux1,aux2);
				fprintf(pf,"\tfistp \t@%s\n", aux1);
				sacardePila(pilaAsm);			
				strcpy(auxPtr->info.dato,aux1);
				auxPtr->info.tipoDato=Integer;
				ponerenPila(pilaAsm,auxPtr);
				nroAuxEntero++;
			break;
			case Float:
			case CteFloat:
				fprintf(pf,"\tfld \t@%s\n", auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfld \t@%s\n", auxPtr->info.dato);
				fprintf(pf,"\tfdivr\n");
				strcpy(aux1,"_auxR");
				itoa(nroAuxReal,aux2,10);
				strcat(aux1,aux2);
				fprintf(pf,"\tfstp \t@%s\n", aux1);
				sacardePila(pilaAsm);			
				strcpy(auxPtr->info.dato,aux1);
				auxPtr->info.tipoDato=Float;
				ponerenPila(pilaAsm,auxPtr);
				nroAuxReal++;
			break;	
		}
	}


	if(strcmp(aux_str,"OP_RES")==0){
		auxPtr = topedePila(pilaAsm);
		switch(auxPtr->info.tipoDato){	
			case Integer:
			case CteInt:
				fprintf(pf,"\tfild \t@%s\n", auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfisubr \t@%s\n", auxPtr->info.dato);
				strcpy(aux1,"_auxE");
				itoa(nroAuxEntero,aux2,10);
				strcat(aux1,aux2);
				fprintf(pf,"\tfistp \t@%s\n", aux1);
				sacardePila(pilaAsm);			
				strcpy(auxPtr->info.dato,aux1);
				auxPtr->info.tipoDato=Integer;
				ponerenPila(pilaAsm,auxPtr);
				nroAuxEntero++;
			break;
			case Float:
			case CteFloat:
				fprintf(pf,"\tfld \t@%s\n", auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfld \t@%s\n", auxPtr->info.dato);
				fprintf(pf,"\tfsubr\n");
				strcpy(aux1,"_auxR");
				itoa(nroAuxReal,aux2,10);
				strcat(aux1,aux2);
				fprintf(pf,"\tfstp \t@%s\n", aux1);
				sacardePila(pilaAsm);			
				strcpy(auxPtr->info.dato,aux1);
				auxPtr->info.tipoDato=Float;
				ponerenPila(pilaAsm,auxPtr);
				nroAuxReal++;
		break;			
		}
	}

	if(strcmp(aux_str,"CMP")==0){
		auxPtr = topedePila(pilaAsm);
		switch(auxPtr->info.tipoDato){
			case Integer:
			case CteInt:
				fprintf(pf,"\tfild \t@%s\n", auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfild \t@%s\n", auxPtr->info.dato);
			break;
			case Float:
			case CteFloat:
				fprintf(pf,"\tfld \t@%s\n", auxPtr->info.dato);
				sacardePila(pilaAsm);
				auxPtr = topedePila(pilaAsm);
				fprintf(pf,"\tfld \t@%s\n", auxPtr->info.dato);
			break;
		}
		sacardePila(pilaAsm);
	}

	// >
	if(strcmp(aux_str,"BLE")==0){
		fprintf(pf,"\tfcomp\n\tfstsw\tax\n\tfwait\n\tsahf\n\tjbe\t\t");
	}

	//<
	if(strcmp(aux_str,"BGE")==0){
		fprintf(pf,"\tfcomp\n\tfstsw\tax\n\tfwait\n\tsahf\n\tjae\t\t");
	}

	//!=
	if(strcmp(aux_str,"BEQ")==0){
		fprintf(pf,"\tfcomp\n\tfstsw\tax\n\tfwait\n\tsahf\n\tje\t\t");
	}

	//==
	if(strcmp(aux_str,"BNE")==0){
		fprintf(pf,"\tfcomp\n\tfstsw\tax\n\tfwait\n\tsahf\n\tjne\t\t");
	}

	//>=
	if(strcmp(aux_str,"BLT")==0){
		fprintf(pf,"\tfcomp\n\tfstsw\tax\n\tfwait\n\tsahf\n\tjb\t\t");
	}

	//<=
	if(strcmp(aux_str,"BGT")==0){
		fprintf(pf,"\tfcomp\n\tfstsw\tax\n\tfwait\n\tsahf\n\tja\t\t");
	}

	//ETIQUETAS
	if(strchr(aux_str, '#')!=NULL){
		memmove(&aux_str[0], &aux_str[1], strlen(aux_str));//Remover el primer caracter "#"
		fprintf(pf,"%s\n",aux_str);
	}
}