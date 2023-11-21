#include <stdio.h>
#include "mylloc.h"

int main (long int argc, char** argv) {
  void *a, *b;

  printf("print inicial para não estragar nada\n");
  fflush(stdout);
  iniciaAlocador();               // Impressão esperada
  imprimeMapa();                  // <vazio>

  a = (void *) alocaMem(10);
  printf("%lx\n", a);
  fflush(stdout);
  imprimeMapa();                  // ################**********
  b = (void *) alocaMem(10);
  imprimeMapa();                  // ################**********##############****
  liberaMem(b);
  b = (void *) alocaMem(6);
  printf("%lx\n", a);
  fflush(stdout);
  imprimeMapa();                  // ################----------##############****
  liberaMem(a);                   // ################----------------------------
                                  // ou
                                  // <vazio>
  finalizaAlocador();
}
