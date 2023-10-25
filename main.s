.section .data
.globl TopoInicialHeap
.globl TopoHeap
# ------------------- Variaveis -------------------
    TopoInicialHeap: .quad 0
    TopoHeap: .quad 0
    NODO_MSG: .string "addr %ld(0x%lx) aloc: %ld tam: 0x%lx\n"
    GEREN_STR: .string "####"
    ALOC_CHAR: .byte '+'
    LIVRE_CHAR: .byte '-'
    NL: .byte '\n'
# ------------------- Variaveis -------------------

# ------------------- Constantes -------------------
.equ ALOCADO,  1
.equ LIBERADO, 0
.equ BRK_SERVICE, 12
.equ WRITE_SERVICE, 1
.equ GET_BRK,  0
.equ STDOUT, 1
.equ GEREN_SIZE, 4
# ------------------- Constantes -------------------

.section .text
# ------------------- Funções globais -------------------
.globl iniciaAlocador
.globl finalizaAlocador
.globl alocaMem
.globl liberaMem
.globl listaNodos
# ------------------- Funções globais -------------------

# ------------------- ListaNodos -------------------
# cont = -8(%rbp)
# aux = -16(%rbp)
# write_char = -24(%rbp)
listaNodos:
    pushq %rbp
    movq %rsp, %rbp
    subq $24, %rsp
    movq $0, -8(%rbp)

    movq TopoInicialHeap, %rax
    movq %rax, -16(%rbp)
while2:
    # aux >= TopoHeap
    movq TopoHeap, %rbx
    cmpq %rbx, %rax
    jge fim_while2

    # write "####"
    movq $WRITE_SERVICE, %rax
    movq $STDOUT, %rdi
    movq $GEREN_STR, %rsi
    movq $GEREN_SIZE, %rdx
    syscall

    # rdi = aux.tam
    movq -16(%rbp), %rdi
    addq  $8, %rdi
    movq (%rdi), %rdi

    # write_char = aux.alocado ? "+" : "-"
    movq -16(%rbp), %rax
    movq (%rax), %rcx
    cmpq $ALOCADO, %rcx
    je char_alocado
    movq $LIVRE_CHAR, %r8
    movq %r8, -24(%rbp)
    jmp loop
char_alocado:
    movq $ALOC_CHAR, %r8
    movq %r8, -24(%rbp)

loop:
    # tam <= 0
    cmpq $0, %rdi
    jle fim_loop

    # write(write_char)
    pushq %rdi
    movq $WRITE_SERVICE, %rax
    movq $STDOUT, %rdi
    movq -24(%rbp), %rsi
    movq $1, %rdx
    syscall
    popq %rdi

    # tam--
    subq $1, %rdi
    jmp loop

fim_loop:
    movq -8(%rbp), %rcx # cont++
    addq $1, %rcx
    movq %rcx, -8(%rbp)

    # aux = aux+aux->tam+16
    movq -16(%rbp), %rdx
    movq %rdx, %rax
    addq $8, %rdx
    movq (%rdx), %rdx
    addq $16, %rdx
    addq %rdx, %rax
    movq %rax, -16(%rbp)

    jmp while2
fim_while2:

    # Escreve fim da linha
    movq $WRITE_SERVICE, %rax
    movq $STDOUT, %rdi
    movq $NL, %rsi
    movq $1, %rdx
    syscall

    movq -8(%rbp), %rax # return cont
    addq $24, %rsp
    popq %rbp
    ret
# ------------------- ListaNodos -------------------

# ------------------- IniciaAlocador -------------------
iniciaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    # Get brk topo
    movq $BRK_SERVICE, %rax
    movq $GET_BRK, %rdi
    syscall

    # Inicia var globais
    movq %rax, TopoInicialHeap
    movq %rax, TopoHeap

    popq %rbp
    ret
# ------------------- IniciaAlocador -------------------

# ------------------- AlocaMem -------------------
# struct nodo {
#     long int alocado = base+0
#     long int tam = base+8
#     void *data = base+16
# }
# novo_nodo = -8(%rbp)
# tam = %rdi = -16(%rbp)
# prev = %r8 = -24(%rbp)
# aux = %rax
# TODO: Fazer o prox_nodoo antes do while
alocaMem:
    pushq %rbp
    movq %rsp, %rbp
    subq $24, %rsp
    movq %rdi, -16(%rbp)   # tam = parametro tam

    # TopoInicialHeap == TopoHeap
    movq TopoInicialHeap, %rax
    movq TopoHeap, %rbx
    cmpq %rax, %rbx
    je increase_brk

    # novo_nodo = TopoInicialHeap
    movq %rax, -8(%rbp)
    # Nao vazio
    # -------------- PRIMEIRA ITERAÇÃO, NÃO FUNDE NODOS ---------------
    # prev = TopoInicialHeap
    movq %rax, %r8
    movq %r8, -24(%rbp)

    # aux.alocado
    movq (%rax), %rbx
    cmpq $ALOCADO, %rbx
    je prox_nodo

    # aux.tam == tam -> aux.tam - tam == 0
    movq %rax, %rcx
    addq $8, %rcx 
    movq (%rcx), %rbx
    movq -16(%rbp), %rdx
    subq %rdx, %rbx
    jz novo_nodo

    # aux.tam-16 < tam -> aux.tam-16 - tam < 0
    subq $16, %rbx
    jl prox_nodo

    # auxtam >= tam -> aux.tam-16 - tam >= 0
    # rcx = aux+16+tam
    movq %rax, %rcx
    addq $16, %rcx
    addq %rdx, %rcx

    # next_nodo.alocado = 0
    movq $LIBERADO, (%rcx)

    # next_nodo.tam = next_tam
    addq $8, %rcx
    movq %rbx, (%rcx)

    jmp novo_nodo
    # -------------- PRIMEIRA ITERAÇÃO, NÃO FUNDE NODOS ---------------

while:
    # aux.alocado
    movq (%rax), %rbx
    cmpq $ALOCADO, %rbx
    je prox_nodo
    
    # if (!prev.alocado){
    #   prev.tam = prev.tam + 16 + aux.tam
    #   aux = prev
    # }
    movq -24(%rbp), %r8
    movq (%r8), %r9
    cmpq $LIBERADO, %r9
    jne fim_fusao

    # r10 = prev.tam+16
    movq %r8, %r9
    addq $8, %r9
    movq (%r9), %r10
    addq $16, %r10

    # r11 = aux.tam
    movq %rax, %r11
    addq $8, %r11
    movq (%r11), %r11

    # r11 = prev.tam + 16 + aux.tam
    addq %r10, %r11
    movq %r11, (%r9)

    # aux = prev
    movq %r8, %rax

fim_fusao:
    movq %rax, -8(%rbp)

    # aux.tam == tam -> aux.tam - tam == 0
    movq %rax, %rcx
    addq $8, %rcx 
    movq (%rcx), %rbx
    movq -16(%rbp), %rdx
    subq %rdx, %rbx
    jz novo_nodo

    # aux.tam-16 < tam -> aux.tam-16 - tam < 0
    subq $16, %rbx
    jl prox_nodo

    # auxtam >= tam -> aux.tam-16 - tam >= 0
    # rcx = aux+16+tam
    movq %rax, %rcx
    addq $16, %rcx
    addq %rdx, %rcx

    # next_nodo.alocado = 0
    movq $LIBERADO, (%rcx)

    # next_nodo.tam = next_tam
    addq $8, %rcx
    movq %rbx, (%rcx)

    jmp novo_nodo

prox_nodo:
    # prev = aux
    movq %rax, -24(%rbp)

    # aux+aux->tam+16
    movq %rax, %rdx
    addq $8, %rdx
    movq (%rdx), %rdx
    addq $16, %rdx
    addq %rdx, %rax
    movq %rax, -8(%rbp) # nodo_novo = aux

    # aux >= TopoHeap
    movq TopoHeap, %rbx
    cmpq %rbx, %rax
    jl while

increase_brk:
    # mem vazia
    movq TopoHeap, %rcx # novo_nodo
    movq %rcx, -8(%rbp)

    # TopoHeap += 16 + tam
    addq $16, %rdi
    addq TopoHeap, %rdi
    movq %rdi, TopoHeap
    movq $BRK_SERVICE, %rax
    syscall

# requer que novo_nodo {-8(%rbp)} esteja iniciado
novo_nodo:
    movq -8(%rbp), %rax # novo_nodo.alocado = 1
    movq $ALOCADO, (%rax)
    
    addq $8, %rax # novo_nodo.tam = tam
    movq -16(%rbp), %rbx
    movq %rbx, (%rax)

    addq $8, %rax # return novo_nodo.data
end:
    addq $24, %rsp
    popq %rbp
    ret
# ------------------- AlocaMem -------------------

# ------------------- LiberaMem -------------------
# addr = %rdi
liberaMem:
    pushq %rbp
    movq %rsp, %rbp

    # TODO: Verificar se addr é valido
    subq $16, %rdi
    movq $LIBERADO, (%rdi)

    popq %rbp
    ret
# ------------------- LiberaMem -------------------

# ------------------- FinalizaAlocador -------------------
finalizaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    # Limpa toda a memória alocada.
    movq $BRK_SERVICE, %rax
    movq TopoInicialHeap, %rdi
    # limpar TopoHeap por Segurança :)
    movq %rdi, TopoHeap
    syscall

    popq %rbp
    ret
# ------------------- FinalizaAlocador -------------------
