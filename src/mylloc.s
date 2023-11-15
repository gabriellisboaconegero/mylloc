.section .data
# ------------------- Variaveis -------------------
    .globl TopoInicialHeap
    TopoInicialHeap: .quad 0
    TopoHeap: .quad 0
    GEREN_STR: .string "################"
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
.equ GEREN_SIZE, 16
# ------------------- Constantes -------------------

.section .text
# ------------------- Funções globais -------------------
.globl iniciaAlocador
.globl finalizaAlocador
.globl alocaMem
.globl liberaMem
.globl imprimeMapa
# ------------------- Funções globais -------------------

# ------------------- Funções locais -------------------
# addr = %rdi
get_next_nodo:
    pushq %rbp
    movq %rsp, %rbp

    movq %rdi, %rax

    # new_addr = addr + 16 + addr.tam
    movq %rax, %rdx
    addq $8, %rdx
    movq (%rdx), %rdx
    addq $GEREN_SIZE, %rdx
    addq %rdx, %rax

    pop %rbp
    ret

# fusiona nodos livres na e nb
# nodo_atual = %rdi
# prox_nodo = %rsi
fusiona:
    pushq %rbp
    movq %rsp, %rbp
    # rdx = nodo_atual.tam
    # rdi = &(nodo_atual.tam)
    addq $8, %rdi
    movq (%rdi), %rdx

    # rsi = prox_nodo.tam
    addq $8, %rsi
    movq (%rsi), %rsi

    # rdx = nodo_atual.tam + prox_nodo.tam + 16
    addq $GEREN_SIZE, %rdx
    addq %rsi, %rdx

    # nodo_atual.tam = nodo_atual.tam + prox_nodo.tam + 16
    movq %rdx, (%rdi)

    popq %rbp
    ret

# não precisa fazer verificação se tem pelo menos um nodo pois ela
# não vai ser chamada se não tiver
# nodo_atual = rbx = -8(%rbp)
# prox_nodo = rax = -16(%rbp)
fusiona_nodos:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    # prox_nodo = TopoInicialHeap
    movq TopoInicialHeap, %rax
    movq %rax, -16(%rbp)

# loop até achar os nodos_livres
fusiona_prox_nodo:
    # nodo_atual = prox_nodo
    movq -16(%rbp), %rax
    movq %rax, -8(%rbp)

    # prox_nodo = get_prox_nodo(nodo_atual)
    movq %rax, %rdi
    call get_next_nodo
    movq %rax, -16(%rbp)
    
    # nodo_atual
    movq -8(%rbp), %rbx
    
    # if prox_nodo => TopoHeap goto end_fusiona_nodos
    movq TopoHeap, %rcx
    cmpq %rcx, %rax
    jge end_fusiona_nodos

    # if nodo_atual.alocado goto fusiona_prox_nodo
    cmpq $ALOCADO, (%rbx)
    je fusiona_prox_nodo

    # if prox_nodo.alocado goto fusiona_prox_nodo
    cmpq $ALOCADO, (%rax)
    je fusiona_prox_nodo

    movq %rbx, %rdi
    movq %rax, %rsi
    call fusiona

# ------------ Verifica se prox nodo tambem é livre --------------
    # prox_nodo = get_prox_nodo(nodo_atual)
    movq -8(%rbp), %rdi
    call get_next_nodo
    movq %rax, -16(%rbp)
    
    # nodo_atual
    movq -8(%rbp), %rbx
    
    # if prox_nodo => TopoHeap goto end_fusiona_nodos
    movq TopoHeap, %rcx
    cmpq %rcx, %rax
    jge end_fusiona_nodos

    # Ja sei que nodo_atual não esta alocado
    # if nodo_atual.alocado goto fusiona_prox_nodo
    # cmpq $ALOCADO, (%rbx)
    # je fusiona_prox_nodo

    # if prox_nodo.alocado goto fusiona_prox_nodo
    cmpq $ALOCADO, (%rax)
    je end_fusiona_nodos

    movq %rbx, %rdi
    movq %rax, %rsi
    call fusiona

end_fusiona_nodos:
    addq $16, %rsp
    pop %rbp
    ret
# ------------------- Funções locais -------------------

# ------------------- ListaNodos -------------------
# cont = -8(%rbp)
# aux = -16(%rbp)
# write_char = -24(%rbp)
imprimeMapa:
    pushq %rbp
    movq %rsp, %rbp
    subq $24, %rsp
    movq $0, -8(%rbp)

    movq TopoInicialHeap, %rax
while2:
    movq %rax, -16(%rbp)
    # aux >= TopoHeap
    movq TopoHeap, %rbx
    cmpq %rbx, %rax
    jge fim_while2

    # write "################"
    movq $WRITE_SERVICE, %rax
    movq $STDOUT, %rdi
    movq $GEREN_STR, %rsi
    movq $GEREN_SIZE, %rdx
    syscall

    # write_char = aux.alocado ? "+" : "-"
    movq -16(%rbp), %rax
    movq (%rax), %rcx
    cmpq $ALOCADO, %rcx
    je alocado_select

livre_select:
    movq $LIVRE_CHAR, %r8
    jmp fim_select
alocado_select:
    movq $ALOC_CHAR, %r8
fim_select:
    movq %r8, -24(%rbp)

    # rdi = aux.tam
    movq -16(%rbp), %rdi
    addq  $8, %rdi
    movq (%rdi), %rdi
print_aloc_state_loop:
    # tam <= 0
    cmpq $0, %rdi
    jle fim_print_aloc_state_loop

    # write(write_char)
    pushq %rdi  # Salva %rdi
    movq $WRITE_SERVICE, %rax
    movq $STDOUT, %rdi
    movq -24(%rbp), %rsi
    movq $1, %rdx
    syscall
    popq %rdi   # Restaura rdi

    # tam--
    subq $1, %rdi
    jmp print_aloc_state_loop

fim_print_aloc_state_loop:
    movq -8(%rbp), %rcx # cont++
    addq $1, %rcx
    movq %rcx, -8(%rbp)

    # aux = aux+aux->tam+16
    movq -16(%rbp), %rdi
    call get_next_nodo
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

    # verifica se ja iniciou
    movq TopoHeap, %rax
    cmpq $0, %rax
    jne end_iniciaAlocador

    # Get brk topo
    movq $BRK_SERVICE, %rax
    movq $GET_BRK, %rdi
    syscall

    # Inicia var globais
    movq %rax, TopoInicialHeap
    movq %rax, TopoHeap

end_iniciaAlocador:
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
alocaMem:
    pushq %rbp
    movq %rsp, %rbp
    subq $24, %rsp
    # tam = parametro tam
    movq %rdi, -16(%rbp)
    # prev = 0
    movq $0, -24(%rbp)

    # TopoInicialHeap == TopoHeap
    movq TopoInicialHeap, %rax
    movq TopoHeap, %rbx
    cmpq %rax, %rbx
    je increase_brk

    # novo_nodo = TopoInicialHeap
    movq %rax, -8(%rbp)

while:
    # aux = novo_nodo
    movq -8(%rbp), %rax

    # if aux.alocado goto prox_nodo
    cmpq $ALOCADO, (%rax)
    je prox_nodo

    # ESPAÇO IGUAL AO REQUESITADO
    # aux.tam == tam -> aux.tam - tam == 0
    # if aux.tam == tam goto set_tamanho
    movq %rax, %rcx
    addq $8, %rcx 
    movq (%rcx), %rbx
    movq -16(%rbp), %rdx
    subq %rdx, %rbx
    jz set_tamanho

    # ESPACO MENOR QUE O REQUESITADO
    # if aux.tam - tam < 0
    jl prox_nodo

    # SEM ESPAÇO PARA SPLIT DE NODO
    # 0 < if aux.tam - tam < 16
    # Não pular para set_tamanho pois tem que continuar com o
    # mesmo tamanho
    subq $GEREN_SIZE, %rbx
    jl set_alocado

    # ESPAÇO MAIOR QUE O REQUESITADO
    # aux.tam >= tam -> aux.tam-16 - tam >= 0

    # Faz o split do nodo, onde o next_nodo é o nodo livre após o novo_nodo
    # alocado
    # rcx = aux+16+tam
    movq %rax, %rcx
    addq $GEREN_SIZE, %rcx
    addq %rdx, %rcx

    # next_nodo.alocado = 0
    movq $LIBERADO, (%rcx)

    # next_nodo.tam = next_tam
    addq $8, %rcx
    movq %rbx, (%rcx)

    jmp set_tamanho

prox_nodo:
    # prev = aux
    movq %rax, -24(%rbp)

    # aux = get_prox_nodo
    movq %rax, %rdi
    call get_next_nodo
    movq %rax, -8(%rbp) # nodo_novo = aux

    # aux >= TopoHeap
    movq TopoHeap, %rbx
    cmpq %rbx, %rax
    jl while

    # if prev.alocado goto increase_brk
    movq -24(%rbp), %rax
    cmpq $ALOCADO, (%rax)
    je increase_brk

    # Nesse ponto prev.tam < tam e prev.alocado == 1
    # então podemos aproveitar esse espaço sobrando
    # Como increase_brk vai pegar o topo e somar 16 + tam, basta voltar
    # o topo para prev e deixar increase_brk cuidar do resto
    movq %rax, TopoHeap

increase_brk:
    movq TopoHeap, %rcx # novo_nodo
    movq %rcx, -8(%rbp)

    movq -16(%rbp), %rdi
    # TopoHeap += 16 + tam
    addq $GEREN_SIZE, %rdi
    addq TopoHeap, %rdi
    movq %rdi, TopoHeap
    movq $BRK_SERVICE, %rax
    syscall

# requer que novo_nodo {-8(%rbp)} esteja iniciado
set_tamanho:
    movq -8(%rbp), %rax # novo_nodo.alocado = 1
    addq $8, %rax # novo_nodo.tam = tam
    movq -16(%rbp), %rbx
    movq %rbx, (%rax)

set_alocado:
    movq -8(%rbp), %rax # novo_nodo.alocado = 1
    movq $ALOCADO, (%rax)

    addq $GEREN_SIZE, %rax # return novo_nodo.data
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
    # Valor de retorno
    movq $0, %rbx

    # if TopoInicialHeap == TopoHeap goto end_liberaMem
    movq TopoInicialHeap, %rax
    movq TopoHeap, %rcx
    cmpq %rax, %rcx
    je end_liberaMem

    # Verifica se memoria é valida
    # if !(TopoInicialHeap <= addr < TopoHeap) goto end_liberaMem
    movq TopoInicialHeap, %rax
    cmpq %rdi, %rax
    jg end_liberaMem
    movq TopoHeap, %rax
    cmpq %rax, %rdi
    jge end_liberaMem

    # marca como liberada a memoria
    subq $GEREN_SIZE, %rdi
    movq $LIBERADO, (%rdi)
    movq $1, %rbx

    pushq %rbx
    call fusiona_nodos   
    popq %rbx

end_liberaMem:
    movq %rbx, %rax
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
