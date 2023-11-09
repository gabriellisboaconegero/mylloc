#ifndef MYLLOC_H_
#define MYLLOC_H_

long int iniciaAlocador();
void *alocaMem(long int tam);
void liberaMem(void *addr);
long int imprimeMapa();
long int finalizaAlocador();

#endif
