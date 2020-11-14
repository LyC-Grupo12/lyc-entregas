#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include "funciones.h"

extern int varADeclarar1;
extern int cantVarsADeclarar;
extern int tipoDatoADeclarar[TAMANIO_TABLA];
extern int indiceDatoADeclarar;
extern int indice_tabla;
char msg[100];
		
void mensajeDeError(enum tipoError error,const char* info, int linea)
{
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

int yyerror(char* mensaje)
 {
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
			sprintf(nombre, "_%d", yylval.valor_int);
			//Si no hay otra variable con el mismo nombre...
			if(buscarEnTabla(nombre) == -1){
			//Agregar nombre a tabla
				indice_tabla++;
				strcpy(tabla_simbolo[indice_tabla].nombre, nombre);
			//Agregar tipo de dato
				tabla_simbolo[indice_tabla].tipo_dato = CteInt;
			//Agregar valor a la tabla
				tabla_simbolo[indice_tabla].valor_i = yylval.valor_int;
			}
		break;

		case CteFloat:
			sprintf(nombre, "_%f", yylval.valor_float);
			//Si no hay otra variable con el mismo nombre...
			if(buscarEnTabla(nombre) == -1){
			//Agregar nombre a tabla
				indice_tabla ++;
				strcpy(tabla_simbolo[indice_tabla].nombre, nombre);
			//Agregar tipo de dato
				tabla_simbolo[indice_tabla].tipo_dato = CteFloat;
			//Agregar valor a la tabla
				tabla_simbolo[indice_tabla].valor_f = yylval.valor_float;
			}
		break;

		case CteString:
			if(buscarEnTabla(yylval.valor_string) == -1){
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
	pos=pos=buscarEnTabla(nombre);
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
		if(!compatible)
			mensajeDeError(ErrorSintactico,"Id/Cte de tipo no compatible",linea);
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
	for(i = 0; i <= strlen(aux); i++)
  	{
  		if(aux[i] == '\t' || aux[i] == '\r' || aux[i] == ' ' || aux[i] == ':')  
		{
  			aux[i] = '_';
 		}

		if(aux[i] == '.')  
		{
  			aux[i] = 'p';
 		}
	}
	return aux;
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

tArbol * hijoMasIzq(tArbol *p)
{
    if(*p)
    {
        if((*p)->izq)
            return hijoMasIzq(&(*p)->izq);
        else
            return p;
    }
    return NULL;
}

void enOrden(tArbol *p)
{
    if (*p)
    {
        enOrden(&(*p)->izq);
        verNodo((*p)->info.dato);
        enOrden(&(*p)->der);
    }
}

void postOrden(tArbol *p)
{
    if (*p)
    {
        postOrden(&(*p)->izq);
        postOrden(&(*p)->der);
		verNodo((*p)->info.dato);		
    }
}

void verNodo(const char *p)
{
    printf("%s ", p);
}


void _tree_print_dot_subtree(int nro_padre, tNodo *padre, int nro, tArbol *nodo, FILE* stream)
{
    if (*nodo != NULL)
    {    
        fprintf(stream, "x%d [label=<%s>];\n",nro,(*nodo)->info.dato);
        if (padre != NULL){
            fprintf(stream, "x%d -> x%d;\n",nro_padre,nro);
        }   
        _tree_print_dot_subtree(nro, *nodo, 2 * nro + 1, &(*nodo)->izq, stream);
        _tree_print_dot_subtree(nro, *nodo, 2 * nro + 2, &(*nodo)->der, stream);
        
    }
    /* else {
        fprintf(stream, "nil%d [label=nil,fontcolor=gray,shape=none];\n",nro);
        fprintf(stream, "x%d -> nil%d;\n",nro_padre,nro);
        printf("nil%d [label=nil,fontcolor=gray,shape=none];\n",nro);
        printf("x%d -> nil%d;\n",nro_padre,nro);
    } */
}

void tree_print_dot(tArbol *p,FILE* stream)
{
    fprintf(stream, "digraph BST {\n");
    if (*p)
        _tree_print_dot_subtree(-1, NULL, 0, &(*p), stream);
    fprintf(stream, "}");
}