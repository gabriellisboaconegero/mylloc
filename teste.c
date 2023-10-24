#include <stdio.h>
#include <unistd.h>
#define TAM 10

extern long int iniciaAlocador();
extern void *alocaMem(long int tam);
extern void liberaMem(void *addr);
extern long int listaNodos();
extern long int finalizaAlocador();
extern long int TopoInicialHeap;
extern long int TopoHeap;

int main(){
    void *a[TAM];
    printf("Iniciando programa: ");
    printf("brk = 0x%lx\n", sbrk(0));
    fflush(stdout);
    iniciaAlocador();
    
    for (int i = 0; i < 7; i++){
        a[i] = alocaMem(128);
        printf("addr %d: 0x%lx\n", i, a[i]);
    }
    liberaMem(a[4]);
    liberaMem(a[1]);
    liberaMem(a[0]);
    for (int i = 7; i < TAM; i++){
        a[i] = alocaMem(20);
        printf("addr %d: 0x%lx\n", i, a[i]);
    }
    listaNodos();
    liberaMem(a[7]);
    liberaMem(a[9]);
    listaNodos();
    a[7] = alocaMem(112);
    a[9] = alocaMem(20);
    printf("Nodos: %ld\n", listaNodos());

    finalizaAlocador();
    printf("Finalizando programa: brk = 0x%lx\n", sbrk(0));
    fflush(stdout);

    return 0;
}
