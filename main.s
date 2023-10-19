.section .data
.globl TopoInicialHeap
.globl TopoHeap
    TopoInicialHeap: .quad 0
    TopoHeap: .quad 0
    NODO_MSG: .string "addr %ld(0x%lx) aloc: %ld tam: 0x%lx\n"
    GEREN_STR: .string "####"
    ALOC_CHAR: .byte '+'
    LIVRE_CHAR: .byte '-'
    NL: .byte '\n'

# Constantes
.equ ALOCADO,  1
.equ LIBERADO, 0
.equ BRK_SERVICE, 12
.equ WRITE_SERVICE, 1
.equ GET_BRK,  0
.equ STDOUT, 1
.equ GEREN_SIZE, 4

.section .text
.globl iniciaAlocador
.globl finalizaAlocador
.globl alocaMem
.globl liberaMem
.globl listaNodos
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
    # movq $NODO_MSG, %rdi
    # movq -8(%rbp), %rsi
    # movq %rax, %rdx
    # movq (%rax), %rcx
    # addq $8, %rax
    # movq (%rax), %r8
    # call printf

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
    je print_alocado
    movq $LIVRE_CHAR, %r8
    movq %r8, -24(%rbp)
    jmp loop
print_alocado:
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

    movq $WRITE_SERVICE, %rax
    movq $STDOUT, %rdi
    movq $NL, %rsi
    movq $1, %rdx
    syscall

    movq -8(%rbp), %rax # return cont
    addq $24, %rsp
    popq %rbp
    ret

iniciaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    # Get brk topo
    movq $BRK_SERVICE, %rax
    movq $GET_BRK, %rdi
    syscall

    movq %rax, TopoInicialHeap
    movq %rax, TopoHeap

    popq %rbp
    ret

# struct nodo {
#     long int alocado = base+0
#     long int tam = base+8
#     void *data = base+16
# }
# novo_nodo = -8(%rbp)
# tam = %rdi = -16(%rbp)
# aux = %rax
# TODO: Fazer o prox_nodoo antes do while
alocaMem:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    movq %rdi, -16(%rbp)   # tam = parametro tam

    # TopoInicialHeap == TopoHeap
    movq TopoInicialHeap, %rax
    movq %rax, -8(%rbp)    # novo_nodo = TopoInicialHeap
    movq TopoHeap, %rbx
    cmpq %rax, %rbx
    je increase_brk

    # Nao vazio
while:
    movq (%rax), %rbx   # aux.alocado
    cmpq $ALOCADO, %rbx
    je prox_nodo

    movq %rax, %rcx
    addq $8, %rcx 
    movq (%rcx), %rbx
    movq -16(%rbp), %rdx
    subq %rdx, %rbx
    jz novo_nodo    # aux.tam == tam -> aux.tam - tam == 0
    subq $16, %rbx  # next_tam
    jl prox_nodo    # aux.tam-16 < tam -> aux.tam-16-tam < 0
    # Se tiver espaço fazer split do nodo
    # Ou seja, apenas criar um novo nodo na frente de
    # aux, com tamaho aux->tam-16-tam. E depois chamar
    # novo_nodo para colocar os valores certos no nodo alocado
    addq $8, %rcx   # next_nodo
    addq %rdx, %rcx

    movq $LIBERADO, (%rcx)  # next_nodo.alocado = 0

    addq $8, %rcx   # net_nodo.tam = next_tam
    movq %rbx, (%rcx)

    jmp novo_nodo   # Alocao novo nodo

prox_nodo:
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

novo_nodo:
    movq -8(%rbp), %rax # novo_nodo.alocado = 1
    movq $ALOCADO, (%rax)
    
    addq $8, %rax # novo_nodo.tam = tam
    movq -16(%rbp), %rbx
    movq %rbx, (%rax)

    addq $8, %rax # return novo_nodo.data
end:
    addq $16, %rsp
    popq %rbp
    ret

# addr = %rdi
liberaMem:
    pushq %rbp
    movq %rsp, %rbp

    # TODO: Verificar se addr é valido
    subq $16, %rdi
    movq $LIBERADO, (%rdi)

    popq %rbp
    ret

finalizaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    # Limpa toda a memória alocada.
    # fazer verificação se teve leak de memoria??
    movq $BRK_SERVICE, %rax
    movq TopoInicialHeap, %rdi
    # Segurança :)
    movq %rdi, TopoHeap
    syscall

    popq %rbp
    ret
