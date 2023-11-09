#include <stdio.h>
#include <unistd.h>
#include "mylloc.h"
#define TAM 10

void imprimeMapaC(){
    imprimeMapa();
    printf("\n");
    fflush(stdout);
}

void *alocaMemC(char *msg, long int tam){
    void *r = alocaMem(tam);
    printf(msg);
    fflush(stdout);
    imprimeMapaC();
    return r;
}

void liberaMemC(char *msg, void *addr){
    liberaMem(addr);
    printf(msg);
    fflush(stdout);
    imprimeMapaC();
}

int main(){
    void *a[TAM];
    printf("Iniciando programa: ");
    printf("brk = 0x%lx\n", sbrk(0));
    fflush(stdout);
    iniciaAlocador();
    
    for (int i = 0; i < 7; i++)
        a[i] = alocaMemC("aloca 128\n", 128);
    liberaMemC("libera 4 nodo\n", a[4]);
    liberaMemC("libera 1 nodo\n", a[1]);
    liberaMemC("libera 0 nodo\n", a[0]);
    for (int i = 7; i < TAM; i++)
        a[i] = alocaMemC("aloca 20\n", 20);
    liberaMemC("libera 7 nodo\n", a[7]);
    liberaMemC("libera 8 nodo\n", a[8]);
    liberaMemC("libera 9 nodo\n", a[9]);
    a[7] = alocaMemC("aloca 112\n", 112);
    a[9] = alocaMemC("aloca 20\n", 20);
    imprimeMapa();
    fflush(stdout);

    finalizaAlocador();
    printf("Finalizando programa: brk = 0x%lx\n", sbrk(0));
    fflush(stdout);

    return 0;
}
