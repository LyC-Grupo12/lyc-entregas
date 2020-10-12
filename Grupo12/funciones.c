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
void chequearVarEnTabla(char* nombre,int linea){
	//Si no existe en la tabla, error
	if( buscarEnTabla(nombre) == -1){
		sprintf(msg,"La variable '%s' debe ser declarada previamente en la seccion de declaracion de variables", nombre);
		mensajeDeError(ErrorSintactico,msg,linea);
	}
	//Si existe en la tabla, dejo que la compilacion siga
}

void validarCteEnTabla(char* nombre,int linea){
	int pos = buscarEnTabla(nombre); 
	if(tabla_simbolo[pos].esCteConNombre){
		mensajeDeError(ErrorSintactico,"No se puede asignar valor a la cte",linea);
	}
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