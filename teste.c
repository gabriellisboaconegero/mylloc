#include <stdio.h>
#include <unistd.h>
extern long int iniciaAlocador();
extern void *alocaMem(long int tam);
extern long int finalizaAlocador();
extern long int TopoInicialHeap;
extern long int TopoHeap;

int main(){
    printf("Iniciando programa: ");
    printf("brk = 0x%lx\n", sbrk(0));
    fflush(stdout);
    iniciaAlocador();
    alocaMem(100);
    printf("TopoHeap: %lx\n", TopoHeap);
    alocaMem(100);
    printf("TopoHeap: %lx\n", TopoHeap);
    finalizaAlocador();
    printf("Finalizando programa: brk = 0x%lx\n", sbrk(0));
    fflush(stdout);

    return 0;
}
