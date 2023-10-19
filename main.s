.section .data
.globl TopoInicialHeap
.globl TopoHeap
    TopoInicialHeap: .quad 0
    TopoHeap: .quad 0

# Constantes
.equ ALOCADO,  1
.equ LIBERADO, 0
.equ BRK_SERVICE, 12
.equ GET_BRK,  0

.section .text
.globl iniciaAlocador
.globl finalizaAlocador
.globl alocaMem
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
# tam = %rdi = -16(%rbp)
# novo_nodo = -8(%rbp)
alocaMem:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp
    movq %rdi, -16(%rbp)   # tam = parametro tam

    # TopoInicialHeap == TopoHeap
    movq TopoInicialHeap, %rax
    movq TopoHeap, %rbx
    cmpq %rax, %rbx
    je increase_brk
    # Nao vazio
    movq (%rax), %rbx
    
    jmp end

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

    jmp end
end:
    popq %rbp
    addq $16, %rsp
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
