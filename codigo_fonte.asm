.data
	vet: .space 8
	
	seed: .word 10962279
	
	gme_start: .asciz "PEDRA PAPEL TESOURA VERS�O RISC-V\n"
	first_play: .asciz "Escolha sua primeira jogada: Pedra (R), Papel (P) ou Tesoura (S): "
	msg_play: .asciz "Escolha sua jogada: Pedra (R), Papel (P), Tesoura (S) ou finalizar o jogo (E): "
	cmp_play: .asciz "\nO computador escolheu: "
	draw: .asciz "\nEmpate\n"
	ply_win: .asciz "\nVoc� venceu esta rodada\n"
	cmp_win: .asciz "\nO computador venceu esta rodada\n"
	end_gme: .asciz "\nFIM DE JOGO\n"
	all_cmp_ply: .asciz "\nTodas as jogadas feitas pelo computador:\n"
	
	end_msg: .asciz "\nPrograma finalizado com sucesso"
.text

.globl main

.macro PUSH(%reg) #desce o stack pointer para poder fazer o backup com o valor de um registrador para poder altera-lo na fun��o
	addi sp, sp, -4
	sw %reg, 0(sp)
.end_macro

.macro POP(%reg) #salva o valor do backup no registrador e sobe o stack pointer para o valor de in�cio
	lw %reg, 0(sp)
	addi sp, sp, 4
.end_macro

.macro INPUT_STRING(%reg1, %reg2) #reg1 cont�m o endere�o para um espa�o, reg2 o tamanho m�ximo da string
	PUSH a0
	PUSH a1
	PUSH a7
	
	addi a0, %reg1, 0
	addi a1, %reg2, 0
	li a7, 8
	ecall
	
	POP a7
	POP a1
	POP a0
.end_macro

.macro PRINT_STRING(%reg) #reg cont�m o endere�o da string
	PUSH a0
	PUSH a7
	
	addi a0, %reg, 0
	li a7, 4
	ecall
	
	POP a7
	POP a0
.end_macro

#usar a1...a6 como argumentos
.macro ADD_ELEMENT(%reg1, %reg2, %reg3) #reg1 cont�m o endere�o do elemento anterior da lista, %reg2 cont�m o valor a ser adicionado, %reg3 deve ser passado com o valor de 0
	PUSH a7
	PUSH a0

	
	##fazer: SE os 4 primeiros bytes do elemento contido em %reg1 forem -1:
	lw t0, 0(%reg1)
	li t1, -1
	beq t0, t1, create_element
	j next_element #sen�o o progrma pula para o r�tulo prox_elemento
	
	create_element:
	##1. alocar 8 bytes na mem�ria (endere�o do novo elemento ser� salvo em a0)
	li a0, 8 #passando para a0 a quantidade de novos bytes que ser�o alocados na chamada
	li a7, 9
	ecall
	##2. setar os primeiros 4 bytes do novo elemento para -1
	li t1, -1 #t1 recebe o valor de -1
	sw t1, 0(a0) #os 4 primeiros bytes do novo elemento v�o para -1
	##3. setar os 4 �ltimos bytes do novo elemento para o valor contido em %reg2
	sw %reg2, 4(a0)
	##4. setar os primeiros 4 bytes do elemento contido em %reg1 para o endere�o do novo elemento (isto �, passando o valor contido em a0)
	sw a0, 0(%reg1)
	##5. setar o valor de %reg1 para o endere�o do novo elemento
	addi %reg1, a0, 0
	##6. setar o valor de %reg3 para 1 (elemento adicionado com sucesso)
	addi %reg3, x0, 1

	##7. jump
	j end_element
	
	next_element:
	##SEN�O
	##passar para %reg1 o valor dos 4 primeiros bytes do elemento contido no endere�o de %reg1
	lw t0, 0(%reg1)
	addi %reg1, t0, 0
	##%reg2 continua igual
	##%reg3 continua igual
	
	end_element:
	POP a0
	POP a7
.end_macro

.macro COMPUTER_PLAY(%reg) #%reg receber� algum desses valores: (80, 82 ou 83)
	PUSH a0
	PUSH a1
	
	lw a0, seed
	la a1, seed
	## GERADOR CONGRUENTE LINEAR r=(a*seed + c) mod m ## sendo a, c constantes
	li t0, 1904522231  #a
  	li t1, 1273569151 #c
	li t2, -1         #m
    
	mul a0, a0, t0 #multiplica��o de a com a seed
   
	add a0, a0, t1 #soma da a*seed com c

	sw a0, 0(a1) #salva a nova seed na mem�ria

	##ajuste do resultado com o m�dulo de 3 para obter os poss�veis resultados salvos em t0: 0, 1, 2
	li t0, 3
	rem t0, a0, t0
	
	li t1, 0
	beq t0, t1, cmp_paper
	li t1, 1
	beq t0, t1, cmp_rock
	li t1, 2
	beq t0, t1, cmp_scissor
	
	cmp_paper:
	li %reg, 80
	j end_play
	
	cmp_rock:
	li %reg, 82
	j end_play
	
	cmp_scissor:
	li %reg 83
	j end_play
	
	end_play:
	POP a1
	POP a0
.end_macro


.macro VERIFY_WINNER(%reg1, %reg2, %reg3) #recebe em %reg1 a jogada do usu�rio, em %reg2 a jogada do computador e salva em %reg3 o vencedor (0 == USU�RIO, 1 == COMPUTADOR, -1 == EMPATE)
	
	beq %reg1, %reg2, v_draw #se as jogadas forem iguais, h� um empate
	
	sub t0, %reg1, %reg2 #t0 recebe o valor de %reg1-%reg2, verificar o motivo na tabela
	
	li t1, -2
	beq t0, t1, v_player
	li t1, -3
	beq t0, t1, v_computer
	li t1, 2
	beq t0, t1, v_computer
	li t1, -1
	beq t0, t1, v_player
	li t1, 3
	beq t0, t1, v_player
	li t1, 1
	beq t0, t1, v_computer
	
	v_player:
	li %reg3, 0
	j end_verify
	
	v_computer:
	li %reg3, 1
	j end_verify
	
	v_draw:
	li %reg3, -1
	j end_verify
	
	end_verify:
.end_macro

#usar a1...a6 como argumentos
.macro PRINT_ELEMENTS(%reg1, %reg2) #reg1 cont�m o endere�o para o in�cio da lista encadeada, %reg2 deve ser passado com o valor de 0
	PUSH a7
	PUSH a0
	
	lw t0, 0(%reg1) #salva os 4 primeiros bytes do elemento
	li t1, -1
	bne t0, t1, print_character #se os 4 primeiros bytes do elemento forem diferentes de -1, o valor do registrador 2 deve continuar sendo 0 (ainda tem mais elementos na lista)
	li %reg2, 1
	
	print_character:
	lb a0, 4(%reg1) #salva o �ltimo byte do elemento (cont�m o char da jogada)
	li a7, 11
	ecall
	
	lw t0, 0(%reg1) #t0 recebe o valor do endere�o para a pr�xima lista
	beq t0, t1, end_print #se t0=t1=-1 n�o h� mais elementos na lista, portanto o valor de %reg1 n�o ser� alterado
	addi %reg1, t0, 0
	
	end_print:
	POP a0
	POP a7
.end_macro

main:

	##fazer: setar os 4 primeiros bytes de vet para -1: isto representa que n�o h� outro elemento sendo apontado por ele
	la a2, vet
	li t0, -1
	sw t0, 0(a2)
	
	########## COME�O DO JOGO ##########
	
	la a0, gme_start
	li a7, 4
	ecall
	
	la a0, first_play
	li a7, 4
	ecall
	li a7, 12 #faz a leitura de um caractere do console e salva em a0
	ecall
	addi s0, a0, 0 #s0 guarda a jogada do jogador
	
	COMPUTER_PLAY s1 ##jogada escolhida pelo computador � salva em s1
	## GUARDO NA LISTA VET A PRIMEIRA JOGADA DO COMPUTADOR
	sw s1, 4(a2)
	
	la a0, cmp_play
	li a7, 4
	ecall
	addi a0, s1, 0
	li a7, 11
	ecall
	
	VERIFY_WINNER s0, s1, t6 #t6 guarda quem ganhou a rodada (0 == USU�RIO, 1 == COMPUTADOR, -1 == EMPATE)
	
	li t0, 0
	beq t0, t6, player_win
	li t0, 1
	beq t0, t6, computer_win
	li t0, -1
	beq t0, t6, draw_
	
	player_win:
	la a0, ply_win
	li a7, 4
	ecall
	j game
	
	computer_win:
	la a0, cmp_win
	li a7, 4
	ecall
	j game
	
	draw_:
	la a0, draw
	li a7, 4
	ecall
	j game
	
	
	### COME�O DO LOOP DO JOGO
	li s11, 0
	game:
	la a0, msg_play #mensagem pedindo para o usu�rio escolher a opcao (R, S, P, E) E sendo para finalizar o jogo
	li a7, 4
	ecall
	li a7, 12 #faz a leitura de um caractere do console e salva em a0
	ecall
	addi s0, a0, 0 #s0 guarda a jogada do jogador	
	
	li t0, 69 #se o usu�rio escolheu a op��o 'E', o jogo acaba imediatamente
	beq a0, t0, end_game
	
	COMPUTER_PLAY s1 ##jogada escolhida pelo computador � salva em s1
	la a0, cmp_play ##texto anunciando a jogada escolhida pelo computador
	li a7, 4
	ecall
	addi a0, s1, 0
	li a7, 11
	ecall
	##### GUARDAR NA LISTA A JOGADA DO COMPUTADOR:
	li a6, 0
	ADD_ELEMENT a2, s1, a6
	
	VERIFY_WINNER s0, s1, t6 #t6 guarda quem ganhou a rodada (0 == USU�RIO, 1 == COMPUTADOR, -1 == EMPATE)
	
	li t0, 0
	beq t0, t6, player_win_loop
	li t0, 1
	beq t0, t6, computer_win_loop
	li t0, -1
	beq t0, t6, draw_loop
	
	player_win_loop:
	la a0, ply_win
	li a7, 4
	ecall
	j continue_game
	
	computer_win_loop:
	la a0, cmp_win
	li a7, 4
	ecall
	j continue_game
	
	draw_loop:
	la a0, draw
	li a7, 4
	ecall
	j continue_game
	
	end_game:
	li s11, 1
	
	continue_game:
	beqz s11, game #se s11 for igual a 0, o jogo continua
	
	######### FIM DO JOGO: LISTAR TODAS AS JOGADAS FEITAS PELO COMPUTADOR ########
	
	la a0, end_gme
	li a7, 4
	ecall
	la a0, all_cmp_ply
	li a7, 4
	ecall
	
	la a2, vet
	li a3, 0
	end_loop_print:
		
		li a0, 10 #valor ASCII de '\n'
		li a7, 11
		ecall
		
		PRINT_ELEMENTS a2, a3
				
	beqz a3, end_loop_print
	
	########## FIM DA EXECU��O ##########
	
end_program:
	la a0, end_msg
	li a7, 4
	ecall
	li a7, 10
	ecall

