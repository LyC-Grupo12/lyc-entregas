#ifndef FUNCIONES_H
#define FUNCIONES_H

enum tipoError
{
    ErrorSintactico,
    ErrorLexico
};
/* Tipos de datos para la tabla de simbolos */
#define Integer 1
#define Float 2
#define String 3
#define CteInt 4
#define CteFloat 5
#define CteString 6
#define SinTipo 7

#define TAMANIO_TABLA 300
#define TAM_NOMBRE 32
#define ES_CTE_CON_NOMBRE 1

typedef struct {
		char nombre[TAM_NOMBRE];
		int tipo_dato;
		char valor_s[TAM_NOMBRE];
		float valor_f;
		int valor_i;
		int longitud;
		int esCteConNombre;
} TS_Reg;

TS_Reg tabla_simbolo[TAMANIO_TABLA];

void mensajeDeError(enum tipoError error,const char* info, int linea);
void agregarVarATabla(char* nombre,int esCteConNombre,int linea);
void agregarTiposDatosATabla(void);
void agregarCteATabla(int num);
void chequearVarEnTabla(char* nombre,int linea);
int buscarEnTabla(char * nombre);
void grabarTabla(void);
char* normalizarNombre(const char* nombre);
char * reemplazarCaracter(char * aux);
char* normalizarId(const char* cadena);
void validarCteEnTabla(char* nombre,int linea);
void agregarValorACte(int tipo);

#endif