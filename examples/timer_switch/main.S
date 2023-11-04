.cpu cortex-m3
.arch armv7-m
.fpu softvfp
.syntax unified
.thumb


.include "src/stm32f100xb.s"
.equ konst, 100
//.equ konst, 100
.equ doba, 0x10000
//.equ konst, 1
//.equ doba, 0x10

.equ pc8_mask, 0x0100
.equ pc9_mask, 0x0200


.section .data
    button_state:   .word 0x00
    button_value:   .word 0
    timer_state:   .word 0x0000
    timer_value:   .word 25

.global main

.section .text


///////////////// hardware registers configuration  ////////////////////////


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




///////////////// deplay function  ////////////////////////



	delay:
        cmp		r0, #0			    //check if r0 is not 0
        beq		end_delay		    // if r0 = 0, jump to end_delay
		push	{r2, lr}		    // save the value of r2 to the tray (r2 can be edited)
                                    // and saving the return address to the tray
		//b wait1
	wait1:
		ldr		r2, =40000		    // inserting the delay constant into r2
		//b wait
	wait:
		subs	r2, r2, #1		    // subtract 1 from r2,i.e. r2 = r2 - 1 and set the primitive register
		bne		wait			    // jump to set when r2 is non-zero (jump according to the primitive)
		subs	r0, r0, #1
		bne		wait1
	end_delay:
		pop		{r2, pc}		    // return from subroutine, restore the value of r2 from the stack
		// bx      lr				// and return addresses to pc
		nop



///////////////// start of program  ////////////////////////


main:						    // main specifies the main loops of the program
        bl  rcc_cnf			    // subroutine call setting the CPU clock system
        //bl  rcc_hse_cnf              // High-Speed External Clock Configuration
        //bl  rcc_sclk_cnf             // System Clock Configuration (SCLK)
        //bl  rcc_ppre2_cnf            // APB2 Prescaler Configuration
        //bl  rcc_ppre1_cnf            // APB1 Prescaler Configuration
        //bl  rcc_pll_cnf              // Phase-Locked Loop (PLL) Configuration
        //bl  sysclk_cnf               // System Clock Configuration
        //bl  rcc_apb2enr_cnf          // APB2 Peripheral Clock Enable Register

        bl  gpio_cnf		    // subroutine call setting the GPIO
        //bl push_pull_output     // subroutine call setting the GPIO
        //bl push_pull_input      // subroutine call setting the GPIO


        //mov 	r2,#0
        ldr		r7, =gpioc_odr	// copy the address of gate c from r2 to r2, gpioc_odr is in the file stm32f100xb.S
        ldr		r8, =gpioa_idr 	// copy gate address and idr to r5, gpioa_idr is in the file stm32f100xb.S

        // idr - input data register
        //b loop



///////////////// logical flow  ////////////////////////




	loop:
        mov		r0, 50		        // if yes, do a small delay for debouncing
        bl		delay

        ldr r0, =button_state    // load button state address to r0
        ldr r1, [r0]            // copy the value from the address in r5 to r0
        cmp r1, 0x01    //        if r1 == 0x1000:            # if button was pressed before
        beq timer_alert_switch_check    //            r1 = r1 + 1             # each 25ms +1 bit of button time state
        after_button_released_check:

        bl get_idr_value_in_r0
        cmp		r0, #0x1            //  if the button is  pressed
        beq     button_pressed      // true  if the button is  pressed
        b button_not_pressed        // false  if the button is  pressed
        after_idr_check:

        b loop


    button_pressed:
        //push {lr}
        bl blue_on                      // turn on led 8

        ldr r1, =button_state   // get the address of the button_state
        mov     r0, #0x10    // button was pressed bit
        str     r0, [r1]      // save new value to button_state

        ldr r1, =button_value   // get the address of the button_state
        ldr     r0, [r1]    // button was pressed bit
        add     r0, r0, 1    // adding 1*0.25s to button_value
        str     r0, [r1]      // save new value to button_state
        b after_idr_check




    button_not_pressed:
       //push {lr}

       ldr r0, =button_state    // load button state address to r0
       ldr r1, [r0]            // copy the value from the address in r5 to r0
       cmp r1, 0x10    //        if r1 == 0x1000:            # if button was pressed before
       beq button_was_pressed    //            r1 = r1 + 1             # each 25ms +1 bit of button time state
       b button_was_not_pressed

       end_of_button_pressed_check:
       //pop {pc}
       b loop


       button_was_not_pressed:
           //        if r1 == 0x0000:            # if button was not pressed before
           //            r1 = r1 + 0x1000        # button pressed bit
           b end_of_button_pressed_check

       button_was_pressed:
            bl red_on
            ldr r1, =button_state   // get the address of the button_state
            mov     r0, #0x01    // button was released bit
            str     r0, [r1]      // save new value to button_state


            ldr r1, =button_value   // get the address of the button_state
            ldr     r0, [r1]    // button was pressed bit
            cmp     r0, 12    // if button was pressed for 4*0.25 seconds
            blt     set_timer_value_to_24
            bgt     set_timer_value_to_48

            ldr     r1, =button_value   // get the address of the button_state
            mov     r0, 0    // button was pressed bit
            str     r0, [r1]      // save new value to button_state


           b end_of_button_pressed_check
           b loop


       set_timer_value_to_24:
            ldr r1, =timer_value   // get the address of the button_state
            mov     r0, #24    // button was pressed bit
            str     r0, [r1]      // save new value to button_state
            b end_of_button_pressed_check


       set_timer_value_to_48:
            ldr r1, =timer_value   // get the address of the button_state
            mov     r0, #48    // button was pressed bit
            str     r0, [r1]      // save new value to button_state
            b end_of_button_pressed_check

    button_was_released:

    timer_alert_switch_check:
            ldr     r1, =timer_value
            ldr     r0, [r1]            // copy the value from the address in r5 to r0

            cmp     r0, 12                //if r5 == 0x12:                   # 6 second time state
            beq     time_switch_red_off                    //blue_off()                       # turn on led8


            cmp     r0, 10                //if r5 == 0x10:                 # 10 second time state
            beq     time_switch_red_on                    //blue_on()                   # toogle led8

            cmp     r0, 8                //if r5 == 0x8:                   # 4 second time state
            beq     time_switch_red_off                    //blue_off()                       # turn on led8

            cmp     r0, 6                //if r5 == 0x6:                   # 3 second time state
            beq     time_switch_red_on                    //blue_on()                   # toogle led8

            cmp     r0, 4                //if r5 == 0x4:                   # 2 second time state
            beq     time_switch_red_off                    //blue_off()                       # turn on led8

            cmp     r0, 2                //if r5 == 0x2:                   # 1 second time state
            beq     time_switch_red_on                    //blue_on()                   # toogle led8

            cmp     r0, 0                //if r5 == 0x0:                   # 0 second time state
            beq     offboth                    //blue_off()                   # toogle led8
    end_of_timer_alert_switch_check:
            ldr     r1, =timer_value
            ldr     r0, [r1]            // copy the value from the address in r5 to r0
            cmp     r0, 0                //if r5 == 0x0:                   # 0 second time state
            bne     decrease_timer_value  // if timer_value != 0, decrease timer_value
            b after_button_released_check
    decrease_timer_value:
            ldr     r1, =timer_value
            ldr		r0, [r1]		// copy the value from the address in r5 to r0
            sub     r0, r0, 1               //r0  = r0 - 1                    # each 25ms -1 bit of time state
            str     r0, [r1]      // save new value to timer_value
            b after_button_released_check

















///////////////// single action ////////////////////////
    time_switch_red_on:
        bl red_on
        b end_of_timer_alert_switch_check

    time_switch_red_off:
        bl red_off
        b end_of_timer_alert_switch_check

    onboth:
        b blue_on
        b red_on

    offboth:
         bl blue_off
         bl red_off
         b end_of_timer_alert_switch_check

    blue_on:
        mov r0, #pc8_mask
        b set_r0_pin_on

    blue_off:
        mov r0, #pc8_mask
        b set_r0_pin_off

    red_on:
        mov r0, #pc9_mask
        b set_r0_pin_on

    red_off:
        mov r0, #pc9_mask
        b set_r0_pin_off


///////////////// functions  ////////////////////////


    set_r0_pin_on:
        ldr     r7, =gpioc_odr      // get the address of the GPIO output data register
        ldr     r1, [r7]            // get the value of the GPIO output data register
        orr     r1, r1, r0          // set the pin to 1 (bitwise OR)
        str     r1, [r7]            // write the new value to the GPIO output data register
        bx      lr                  // return from subroutine, jump to address in lr


    set_r0_pin_off:
        //mov     r0, #mask             // move the PIN mask
        ldr		r7, =gpioc_odr      // get the address of the GPIO output data register
        ldr		r1, [r7]            // get the value of the GPIO output data register
        bic     r1, r1, r0          // set pin to 0
        str     r1, [r7]            // write the new value to the GPIO output data register
        bx 		lr                  // return from subroutine, jump to address in lr

    get_idr_value_in_r0:

        //ldr		r8, =gpioa_idr 	// copy gate address and idr to r5, gpioa_idr is in the file stm32f100xb.S
        ldr		r8, =aidr0 	// copy gate address and idr to r5, gpioa_idr is in the file stm32f100xb.S
        ldr		r0, [r8]	// copy the value from the address in r5 to r0
        bx		lr

.end
