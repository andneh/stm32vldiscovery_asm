.cpu cortex-m3
.thumb

/* Register addresses */
.equ RCC_BASE, 0x40021000
.equ GPIOC_BASE, 0x40011000

.section .text
/* Function prototypes */
.global _start

/* Start function */
_start:

  /* Enable clock for GPIOC peripheral */
  ldr r0, =RCC_BASE
  ldr r1, =0x200000
  str r1, [r0, #0x18]

  /* Configure GPIOC pin 13 as output */
  ldr r0, =GPIOC_BASE
  ldr r1, =0x2000
  str r1, [r0, #0x04]

  /* Infinite loop */
loop:

    /* Set GPIOC pin 13 to high */
    ldr r0, =GPIOC_BASE
    ldr r1, =0x1000
    str r1, [r0, #0x14]

    /* Delay */
    ldr r0, =0
    ldr r1, =200000
loop0:
      add r0, r0, #1
      cmp r0, r1
      bne loop0

    /* Set GPIOC pin 13 to low */
    ldr r0, =GPIOC_BASE
    ldr r1, =0
    str r1, [r0, #0x14]

    /* Delay */
    ldr r0, =0
    ldr r1, =200000
loop1:
      add r0, r0, #1
      cmp r0, r1
      bne loop1

    /* Jump to the beginning of the loop */
    b loop
