#ifndef MYLLOC_H_
#define MYLLOC_H_

extern long int iniciaAlocador();
extern void *alocaMem(long int tam);
extern void liberaMem(void *addr);
extern long int listaNodos();
extern long int finalizaAlocador();
extern long int TopoInicialHeap;
extern long int TopoHeap;

#endif
