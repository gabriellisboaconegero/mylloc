## A estrutura dos nodos
Para fins didáticos vamos olhar para cada nodo com a seguinte estrutura
```c
struct Nodo {
    long int alocado;
    long int tam;
    void *data;
};
```
Dado um registrador (%rxx) que aponta para um nodo então para acessar um campo da
estrutura Nodo temos
```c
nodo.alocado = *(long int *)(%rxx)
nodo.tam = *(long int *)(%rxx + 8)
nodo.data = *(long int *)(%rxx + 16)
```

## Acesso ao próximo nodo
Como os nodos estão em sequencia na memória então para acessar o próximo nodo
basta avançar a parte de informações do nodo (16 bytes) mais o tamanho do nodo
(armazenado em nodo.tam). Então dado um registrador (%rxx) que aponta para um nodo
para ir para o proximo nodo é feito
```c
prox = %rxx + *(long int *)(%rxx + 8) + 16
```

## A fusão de nodos
A fusão de nodos funciona da seguinte forma, ele armazena uma variável "prev",
que guarda o endereço do nodo anterior, para cada nodo é feita a verificação se
o nodo atual e o nodo anterior (guardado em "prev") são vazios, se ambos estão
vazio então é feita a fusão deles, apenas aumentando o tamanho do nodo anterior
para prev.tam + 16 + atual.tam. Após mudar o tamanho, o nodo anterior se torna
o atual e então são feitas a verificações para alocar o nodo.

O primeiro nodo não tem nodo anterior, logo não fazemos a fusão na primeira 
passada da iteração.
