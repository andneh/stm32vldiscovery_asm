.cpu cortex-m3
.thumb

/* Define the base addresses for RCC and GPIO peripherals */
.equ RCC_BASE, 0x40021000
.equ GPIOC_BASE, 0x40011000

/* Register offsets for RCC and GPIOC */
.equ RCC_CR, 0x00
.equ RCC_CFGR, 0x04
.equ RCC_APB2ENR, 0x18

.equ GPIOC_CRH, 0x04
.equ GPIOC_ODR, 0x0C

/* Define the bit positions for RCC and GPIOC */
.equ RCC_HSE_ON, 16
.equ RCC_HSE_RDY, 17
.equ RCC_PLL_ON, 24
.equ RCC_PLL_RDY, 25

/* Define the bit positions for GPIOC */
.equ GPIOC_PIN13, 13

/* Set up the stack pointer and reset vector */
.global _start
.section .vector_table, "a"
.word _start  /* Initial stack pointer value */
.word Reset_Handler /* Reset handler (entry point) */

.section .text
_start:
  /* Set up the stack pointer */
  ldr sp, =_estack

  /* Enable the HSE oscillator and wait for it to be ready */
  ldr r0, =RCC_BASE
  ldr r1, =RCC_HSE_ON
  str r1, [r0, #RCC_CR]
  wait_hse_ready:
    ldr r2, [r0, #RCC_CR]
    ands r2, r2, #(1 << RCC_HSE_RDY)
    beq wait_hse_ready

  /* Configure the PLL for 72MHz and wait for it to be ready */
  ldr r1, =RCC_CFGR
  ldr r2, =RCC_PLL_ON
  str r2, [r0, #RCC_CR]
  wait_pll_ready:
    ldr r3, [r0, #RCC_CR]
    ands r3, r3, #(1 << RCC_PLL_RDY)
    beq wait_pll_ready

  /* Configure Flash latency for 72MHz */
  ldr r1, =0x10
  ldr r2, =0x40022000
  str r1, [r2]

  /* Configure the system clock to use PLL as the source */
  ldr r1, [r0, #RCC_CFGR]
  orr r1, r1, #(0x2 << 0)   /* PLL selected as system clock */
  str r1, [r0, #RCC_CFGR]

  /* Enable the clock to GPIOC */
  ldr r0, =RCC_BASE
  ldr r1, =RCC_APB2ENR
  mov r2, #(1 << 4)  /* GPIOC bit */
  str r2, [r0, #RCC_APB2ENR]

  /* Configure PC13 (built-in LED) as an output pin */
  ldr r0, =GPIOC_BASE
  ldr r1, =GPIOC_CRH
  ldr r2, [r0, #GPIOC_CRH]
  bic r2, r2, #(0xF << 20)  /* Clear PC13 configuration bits */
  orr r2, r2, #(0x3 << 20)  /* Configure PC13 as output (push-pull) */
  str r2, [r0, #GPIOC_CRH]

  /* Infinite loop to toggle the LED */
  loop:
    ldr r0, =GPIOC_BASE
    ldr r1, =GPIOC_ODR
    ldr r2, [r0, #GPIOC_ODR]
    xor r2, r2, #(1 << GPIOC_PIN13)  /* Toggle PC13 (LED) */
    str r2, [r0, #GPIOC_ODR]
    bl delay
    b loop

delay:
  /* Simple delay loop */
  mov r3, #0
  delay_outer:
    mov r2, #0
    delay_inner:
      add r2, r2, #1
      cmp r2, #50000
      bne delay_inner
    add r3, r3, #1
    cmp r3, #1000
    bne delay_outer
  bx lr

/* Reset handler */
Reset_Handler:
  /* Initialize data and bss sections */
  ldr r0, =_data_start
  ldr r1, =_data_end
  ldr r2, =_data_init
  mov r3, r0
  copy_loop:
    ldr r4, [r2], #4
    str r4, [r3], #4
    cmp r3, r1
    blo copy_loop
  ldr r0, =_bss_start
  ldr r1, =_bss_end
  mov r2, #0
  clear_loop:
    str r2, [r0], #4
    cmp r0, r1
    blo clear_loop

  /* Call main() */
  bl main

  /* If main() returns, stay here */
halt:
  b halt

/* Data Section */
.section .data
_data_start:
  .word _data_init
_data_end:
_data_init:
  .word 0

.section .bss
_bss_start:
  .word _bss_end
_bss_end:

/* Stack Section */
.section .stack
_estack:
  .word 0x20005000
