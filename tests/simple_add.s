	.file	"danik.c"
	.option nopic
	.attribute arch, "rv32i2p0_a2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	sw	s0,44(sp)
	addi	s0,sp,48
	li	a5,1
	sw	a5,-20(s0)
	li	a5,2
	sw	a5,-24(s0)
	li	a5,3
	sw	a5,-28(s0)
	lw	a5,-20(s0)
	addi	a5,a5,1000
	sw	a5,-32(s0)
	lw	a4,-28(s0)
	lw	a5,-20(s0)
	add	a5,a4,a5
	sw	a5,-36(s0)
#APP
# 6 "danik.c" 1
	ecall
# 0 "" 2
#NO_APP
	li	a5,0
	mv	a0,a5
	lw	s0,44(sp)
	addi	sp,sp,48
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g2ee5e430018) 12.2.0"
	.section	.note.GNU-stack,"",@progbits
