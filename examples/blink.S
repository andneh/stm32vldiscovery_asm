.cpu cortex-m3
.thumb

// Register addresses
.equ RCC_BASE, 0x40021000
.equ GPIOC_BASE, 0x40011000

.equ RCC_APB2ENR, RCC_BASE + 0x18
.equ GPIOC_CRH, GPIOC_BASE + 0x04
.equ GPIOC_ODR, GPIOC_BASE + 0x0C

.equ RCC_IOPCEN, 1 << 4
.equ GPIOC13, 1 << 13

.global main

main:
    // Enable GPIOC clock
    ldr r0, =RCC_APB2ENR
    ldr r1, [r0]
    ldr r2, =RCC_IOPCEN
    orr r1, r1, r2
    str r1, [r0]

    // Configure GPIOC pin 13 as output
    ldr r0, =GPIOC_CRH
    ldr r1, [r0]
    ldr r2, = 0xFF0FFFFF
    and r1, r1, r2
    ldr r2, = #0x00200000
    orr r1, r1, r2
    str r1, [r0]

loop:
    // Set GPIOC pin 13
    ldr r0, =GPIOC_ODR
    ldr r1, [r0]
    ldr r2, = GPIOC13
    orr r1, r1, r2
    str r1, [r0]

    // Arbitrary delay (adjust as needed)
    ldr r2, =0
delay_on:
    cmp r2, #1000000  // Adjust the delay as needed
    bge delay_off
    ldr r5, =1
    add r2, r2, r5
    b delay_on

delay_off:
    // Clear GPIOC pin 13
    ldr r1, [r0]
    ldr r5, =GPIOC13
    bic r1, r1, r5
    str r1, [r0]

    // Arbitrary delay (adjust as needed)
    ldr r2, =0
delay_off_loop:
    cmp r2, #1000000  // Adjust the delay as needed
    bge loop
    ldr r5, =1
    adds r2, r2, r5
    b delay_off_loop
