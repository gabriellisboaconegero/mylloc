#include <stdio.h>
#include <unistd.h>
#include "mylloc.h"
#define TAM 10

void imprimeMapaC(){
    imprimeMapa();
    printf("\n");
    fflush(stdout);
}

void *alocaMemC(char *msg, long int tam, void *cmp){
    void *r = alocaMem(tam);
    long int ind_uso = *((long int *)(r-16));
    long int tam_aloc = *((long int *)(r-8));
    printf(msg);
    printf("\tLOCAL: %s\n", r-16 == cmp ? "CORRETO" : "INCORRETO");
    printf("\tIND. DE USO: %s\n", ind_uso ? "CORRETO" : "INCORRETO");
    printf("\tTAMANHO: %s\n", tam_aloc == tam ? "CORRETO" : "INCORRETO");
    fflush(stdout);
    imprimeMapaC();
    return r;
}

void liberaMemC(char *msg, void *addr, int expected){
    printf(msg);
    printf("\tLIBERAÇÃO: %s\n", liberaMem(addr) == expected ? "CORRETO" : "INCORRETO");
    fflush(stdout);
    imprimeMapaC();
}

int main(){
    void *a[TAM];
    printf("Iniciando programa: ");
    printf("brk = 0x%lx\n", sbrk(0));
    fflush(stdout);
    iniciaAlocador();
    
    a[0] = alocaMemC("Aloca 20\n", 20, TopoInicialHeap);
    a[1] = alocaMemC("Aloca 20\n", 20, a[0]+20);
    a[2] = alocaMemC("Aloca 20\n", 20, a[1]+20);
    a[3] = alocaMemC("Aloca 20\n", 20, a[2]+20);
    a[4] = alocaMemC("Aloca 20\n", 20, a[3]+20);
    liberaMemC("Libera nodo 4\n", a[4], 1);
    a[4] = alocaMemC("Aloca 20\n", 30, a[3]+20);

    liberaMemC("Libera nodo 3\n", a[3], 1);
    liberaMemC("Libera nodo 4\n", a[4], 1);
    liberaMemC("Libera nodo 1\n", a[1], 1);
    a[1] = alocaMemC("Aloca 19\n", 19, a[0]+20);
    liberaMemC("Libera nodo 2\n", a[2], 1);
    liberaMemC("Libera nodo 0\n", a[0], 1);
    liberaMemC("Libera nodo 1\n", a[1], 1);
    /* for (int i = 0; i < 7; i++) */
    /*     a[i] = alocaMemC("aloca 128\n", 128, 0); */
    /* liberaMemC("libera 4 nodo\n", a[4], 1); */
    /* liberaMemC("libera 1 nodo\n", a[1], 1); */
    /* liberaMemC("libera 0 nodo\n", a[0], 1); */
    /* for (int i = 7; i < TAM; i++) */
    /*     a[i] = alocaMemC("aloca 20\n", 20, 0); */
    /* liberaMemC("libera 7 nodo\n", a[7], 1); */
    /* liberaMemC("libera 8 nodo\n", a[8], 1); */
    /* liberaMemC("libera 9 nodo\n", a[9], 1); */
    /* a[7] = alocaMemC("aloca 111\n", 111, 0); */
    /* a[9] = alocaMemC("aloca 20\n", 20, 0); */
    /* liberaMemC("Tenta liberar STACK\n", (void*)a, 0); */
    /* liberaMemC("Tenta liberar NULL\n", (void*)NULL, 0); */

    finalizaAlocador();
    printf("Finalizando programa: brk = 0x%lx\n", sbrk(0));
    fflush(stdout);

    return 0;
}
