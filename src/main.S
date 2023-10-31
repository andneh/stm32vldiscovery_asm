.cpu cortex-m3
.arch armv7-m
.fpu softvfp
.syntax unified
.thumb


.include "src/stm32f100xb.s"
.equ konst, 100
.equ doba, 0x10000
//.equ konst, 1
//.equ doba, 0x10


.global main

.section .text

    main:						    // main specifies the main loops of the program
        bl  rcc_cnf			    // subroutine call setting the CPU clock system
                                    // i.e. jump to the address with the rcc_cnf setting and save the return
                                    // address to lr (link register)
                                    // i.e. jump to the address with gpio_cnf set
                                    //*!* note when using the subroutine call to the bl instruction
                                    // this instruction is already used in the subroutine handler, because
                                    // would overwrite lr and lose the return address ->
                                    // other instructions (push, pop) can be used *!*

        //bl  rcc_hse_cnf              // High-Speed External Clock Configuration
        //bl  rcc_sclk_cnf             // System Clock Configuration (SCLK)
        //bl  rcc_ppre2_cnf            // APB2 Prescaler Configuration
        //bl  rcc_ppre1_cnf            // APB1 Prescaler Configuration
        //bl  rcc_pll_cnf              // Phase-Locked Loop (PLL) Configuration
        //bl  sysclk_cnf               // System Clock Configuration
        //bl  rcc_apb2enr_cnf          // APB2 Peripheral Clock Enable Register

        bl  gpio_cnf		    // subroutine call setting the GPIO

        ldr		r2, =gpioc_odr	// copy the address of gate c from r2 to r2, gpioc_odr is in the file stm32f100xb.S
        mov 	r1,#0			// auxiliary register with led status
        mov		r3,#0			// auxiliary register determining the branching of the program
        mov		r4,#0			// auxiliary software citator slowing down flashing
        ldr		r5, =gpioa_idr 	// copy gate address and idr to r5, gpioa_idr is in the file stm32f100xb.S
        // idr - input data register
        bl loop
        b .







    rcc_cnf:                        // Reset and Clock Control (RCC) Configuration
		ldr		r0, =rcc_cr		    // copy the address of rcc_cr (clock control register) to r0
		ldr		r1, [r0]		    // loading the contents of the register at the address in r0 into r1
		bic		r1, r1, #0x50000    // editing the value in r1, i.e. zeroing the value where '1' is
                                    // hse oscillator off (hseon), ext.oscillator not bzpassed(hsebyp)
		str		r1, [r0]		    // saving the edited value in r1 to the address in r0
        //bx		lr
        //b      rcc_hse_cnf
    rcc_hse_cnf:                    // High-Speed External Clock Configuration
		ldr		r1, [r0]		    // reload the rcc_cr register state into r1
		orr		r1, r1, #0x10000    // mask to enable HSE (crystal oscillator)
		str		r1, [r0]		    // hse High-Speed External Clock on
		//b       no_hse_rdy
	no_hse_rdy:                 // No High-Speed External Clock Ready
		ldr		r1, [r0]		    // load rcc_cr register state to r1
		tst	 	r1, #0x20000	    // stability test hse, (r0 & 0x20000)
		beq 	no_hse_rdy		    // jump on instability, continue code on stability
        //bx		lr
        //b       rcc_sysclk_cnf
    rcc_sysclk_cnf:                  // System Clock Configuration (SCLK)
		ldr		r0, =rcc_cfgr	    // loading the address rcc_cfgr (clock configuration register) into r0
		ldr		r1, [r0]		    // load the state of the rcc_cfgr register into r1
		bic		r1, r1, #0xf0	    // editing, sclk undivided
		str		r1, [r0]		    // save new state to rcc_cfgr
        //bx      lr
        //b       rcc_ppre2_cnf
    rcc_ppre2_cnf:                  // APB2 Prescaler Configuration
		ldr		r1, [r0]		    // loading rcc_cfgr again
		bic		r1, r1, #0x3800	    // editing, hclk undivided (ppre2)
		str		r1, [r0]		    // save new value
        //bx		lr
        //b      rcc_ppre1_cnf
    rcc_ppre1_cnf:                  // APB1 Prescaler Configuration
		ldr		r1, [r0]		    // reload rcc_cfgr
		bic		r1, r1, #0x700	    // hclk undivided (ppre1)
		orr		r1, r1, #0x400	    // masking, constant for hclk/2
		str     r1, [r0]		    // save new value
	    //bx		lr
        //b       rcc_pll_cnf
    rcc_pll_cnf:                    // Phase-Locked Loop (PLL) Configuration
		ldr		r1, [r0]		    // reload rcc_cfgr
		bic		r1, r1, #0x3f0000   // zeroes pllmul, pllxtpre, pllsrc
		ldr		r2, =0x50000	    // mask, pll x3, hse as pll input =24mhz clk
		orr		r1, r1, r2		    // masking, logical set of r1 and r2
		str		r1, [r0]		    // save new value
	    //b pll_on
    pll_on:                     // Phase-Locked Loop (PLL) On
		ldr		r0, =pllon		    // loading the address of the pllon bit into r0(address bit banding)
		mov		r1, #0x01		    // pll enable constant (phase-locked)
		str		r1, [r0]		    // save new value
		//b pll_rdy
    pll_rdy:                    // Phase-Locked Loop (PLL) Ready
		ldr		r0, =rcc_cr		    // copy of address rcc_cr to r0
		//b no_pll_rdy
    no_pll_rdy:                 //No Phase-Locked Loop (PLL) Ready.
		ldr		r1, [r0]		    // loading the rcc_cr register state into r1
		tst		r1, #0x2000000	    // pll startup test (stability test)
		beq		no_pll_rdy		    // jump to indicate no_pll_rdy when pll is not running
        //bx		lr
        //b       rcc_sysclk_sw_cnf
    rcc_sysclk_sw_cnf:              // System Clock Configuration
		ldr		r0, =rcc_cfgr	    // copies the rcc_cfgr address to r0
		ldr		r1, [r0]		    // loading the rcc_cfgr register state into r1
		bic		r1, r1, #0x3	    // use HSI as system clock
		//	orr		r1, r1, #0x1	// use HSE as system clock
		orr		r1, r1, #0x2	    // use PLL as system clock
		str		r1, [r0]		    // PLL is the clock source
        //bx      lr
        //b       rcc_apb2enr_cnf
    rcc_apb2enr_cnf:                // APB2 Peripheral Clock Enable Register
        ldr		r0, =rcc_apb2enr    // copy address rcc_apb2enr (apb2 peripheral clock enable register) to r0
		ldr		r1, [r0]            // loading the state of the rcc_apb2enr register into r1
		ldr		r2, =0x14		    // clock enable constant for gate a and c
		orr		r1, r1, r2		    // masking
		str		r1, [r0]		    // save new value
		bx		lr				    // return from subroutine, jump to address in lr







	gpio_cnf:                       // GPIO Configuration set pc08 and pc09 as output (10mhz), pa0 as push-pull input
    push_pull_output:                // push-pull output
		ldr		r2, =0xff		    // (mask) constant for resetting bits 8, 9
		ldr		r0, =gpioc_crh	    // copy of address gpioc_crh (port configuration register high)
                		                            // to r0, gpioc_crh is in the file stm32f100xb.S
		ldr		r1, [r0]		    // loading the value from the address in r0 to r1
		bic		r1, r1, r2 		    // zeroing of bits in r2
        mov		r2, #0x11           // insert 1 into r2
		orr		r1, r1, r2		    // masking, bits 8, 9 set as push-pull output in mode 1 (10mhz)
		str		r1, [r0]		    // save configuration of pco9 and pc09
    push_pull_input:                 // push-pull input
		ldr		r2, =0xf		    // constant for resetting bit 0
		ldr		r0, =gpioa_crl	    // copy of address gpioa_crl (port configuration register low)
		                            // to r0, gpioa_crl is in the file stm32f100xb.S
		ldr		r1, [r0]		    // loading the value from the address in r0 to r1
		bic		r1, r1, r2 		    // zeroing of bits in r2
		mov		r2, #0x8		    // insert 1 into r2
		orr		r1, r1, r2		    // masking, bit 0 set as push-pull input
		str		r1, [r0]		    // save configuration pao0

		bx		lr				    // return from subroutine, jump to address in lr








	delay:
		push	{r2, lr}		    // save the value of r2 to the tray (r2 can be edited)
                                    // and saving the return address to the tray
		b wait1
	wait1:
		ldr		r2, =40000		    // inserting the delay constant into r2
		b wait
	wait:
		subs	r2, r2, #1		    // subtract 1 from r2,i.e. r2 = r2 - 1 and set the primitive register
		bne		wait			    // jump to set when r2 is non-zero (jump according to the primitive)
		subs	r0, r0, #1
		bne		wait1
		pop		{r2, pc}		    // return from subroutine, restore the value of r2 from the stack
		// bx      lr				// and return addresses to pc
		nop








	loop:
		tst		r3, #0x1	        // test which branch is selected by register r3
		beq		branch2		        // if branch2 then jump to it, otherwise continue


	branch1:
		tst		r4, #0x80000
		beq 	zero		        // if r4 has incremented to 0x80000 continue, otherwise jump to zero
        mov 	r4, #0 		        // reset r4, tick the cycle once every 0x80000

		tst 	r1, #0x0100	        // test which led was last lit
		beq 	blue		        // if blue, continue, if red jump to blue

	red:
		mov		r1, #0x0200	        // 9th bit to 1
		str		r1, [r2]	        // light up the red led
		b 		common		        // continue with button test

	blue:
		mov		r1, #0x0100	        // 8th bit to 1
		str		r1, [r2]	        //light blue led
		b 		common		        // continue button test

	branch2:
		tst		r4, #0x80000
		beq 	zero		        // if r4 has incremented to 0x80000 continue, otherwise jump to zero
		mov 	r4, #0		        // reset r4, tick the cycle once every 0x80000
		tst 	r1, #0x0300	        // test if both leds were lit last time or none
		beq 	both                // if none jump to indicate both, otherwise continue

	none:
		mov		r1, #0		        // last time both were lit, must reset
		str		r1, [r2]	        // both leds off
		b 		common		        // jump to test button

	both:
		mov		r1, #0x0300	        // they were not lit last time, turn on both
		str		r1, [r2]	        // light both leds
		b 		common		        // jump to test button

	zero:
		add		r4,r4,#1	        // test r4 was negative (not reached 0x080000), we have to increment further


	common:
		ldr		r0, [r5]	// copy the value from the address in r5 to r0
		tst		r0, #0x1	// test if there is 1 = button pressed
		beq		loop		// if not, go to the beginning

		mov		r0, #50		// if yes, do a small delay for debouncing
		bl		delay

		tst		r3, #0x1	// test the last r3 throw
		beq		test		// if 0, jump to the next test otherwise continue

		mov		r3, #0		// last test was 1, write 0
		b 		loop		// jump to the beginning

	test:
		mov		r3, #1		// last time was 0, write 1
		b		loop		// jump to loop

.end
