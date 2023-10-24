.cpu cortex-m3
.arch armv7-m
.fpu softvfp
.syntax unified
.thumb

//.word 0x20005000
//.word reset_handler


.include "src/stm32f100xb.s"
.equ konst, 100
.equ doba, 0x10000
//.equ konst, 1
//.equ doba, 0x10


.global main

.section .text

//    .global rcc_cnf
//    .global delay
//    .global gpio_cnf

//    .global reset_handler
//    reset_handler:
//        b main
//        b .


    main:
        bl rcc_cnf
        bl gpio_cnf
        bl loop


    rcc_cnf:
        ldr		r0, =rcc_cr		// kopie adresy rcc_cr (clock control register) do r0,
                                // rcc_crje v souboru ini.s
        ldr		r1, [r0]		// nacteni obsahu registru na adrese v r0 do r1
        bic		r1, r1, #0x50000// editace hodnoty v r1, tj. nulovani hodnoty, kde je '1'
                                // hse oscilator off (hseon), ext.oscilator not bzpassed(hsebyp)
        str		r1, [r0]		// ulozeni editovane hodnoty v r1 na adresu v r0

        ldr		r1, [r0]		// opet nacteni do r1 stav registru rcc_cr
        orr		r1, r1, #0x10000// maska pro zapnuti hse	(krystalovy oscilator)
        str		r1, [r0]		// hse zapnut
        b  no_hse_rdy
    no_hse_rdy:
        ldr		r1, [r0]		// nacteni do r1 stav registru rcc_cr
        tst	 	r1, #0x20000	// test stability hse, (r0 & 0x20000)
        beq 	no_hse_rdy		// skok pri nestabilite, pri stabilite se pokracuje v kodu

        ldr		r0, =rcc_cfgr	// nacteni adresy rcc_cfgr (clock configuration register) do r0
        ldr		r1, [r0]		// nacteni do r1 stav registru rcc_cfgr
        bic		r1, r1, #0xf0	// editace, sclk nedeleno
        str		r1, [r0]		// ulozeni noveho stavu do rcc_cfgr

        ldr		r1, [r0]		// opet nacteni rcc_cfgr
        bic		r1, r1, #0x3800	// editace, hclk nedeleno (ppre2)
        str		r1, [r0]		// ulozeni nove hodnoty

        ldr		r1, [r0]		// opet nacteni rcc_cfgr
        bic		r1, r1, #0x700	// hclk nedeleno	(ppre1)
        orr		r1, r1, #0x400	// maskovani, konstanta pro hclk/2
        str		r1, [r0]		// ulozeni nove hodnoty

        ldr		r1, [r0]		 // opet nacteni rcc_cfgr
        bic		r1, r1, #0x3f0000// nuluje pllmul, pllxtpre, pllsrc
        ldr		r2, =0x50000	 // maska, pll x3, hse jako pll vstup =24mhz clk
        orr		r1, r1, r2		 // maskovani, logicky soucet r1 a r2
        str		r1, [r0]		 // ulozeni nove hodnoty

        ldr		r0, =pllon		// nacteni adresy bitu pllon do r0(adresa bit banding)
        mov		r1, #0x01		// konstanta pro povoleni pll (fazovy zaves)
        str		r1, [r0]		// ulozeni nove hodnoty

        ldr		r0, =rcc_cr		// kopie adresy  rcc_cr do r0
        b no_pll_rdy
    no_pll_rdy:
        ldr		r1, [r0]		// nacteni stavu registru rcc_cr do r1
        tst		r1, #0x2000000	// test spusteni pll (test stability)
        beq		no_pll_rdy		// skok na navesti no_pll_rdy pri nespustene pll

        ldr		r0, =rcc_cfgr	// kopie adresy rcc_cfgr do r0
        ldr		r1, [r0]		// nacteni stavu registru rcc_cfgr do r1
        bic		r1, r1, #0x3	// hsi jako hodiny
        //	orr		r1, r1, #0x1	// maskovani, hse jako hodiny
        orr		r1, r1, #0x2	// maskovani, pll jako hodiny
        str		r1, [r0]		// pll je zdroj hodin

        ldr		r0, =rcc_apb2enr// kopie adresy rcc_apb2enr (apb2 peripheral clock enable register) do r0
        ldr		r1, [r0]		// nacteni stavu registru rcc_apb2enr do r1
        ldr		r2, =0x10		// konstanta pro zapnuti hodin pro branu c
        orr		r1, r1, r2		// maskovani
        str		r1, [r0]		// ulozeni nove hodnoty

        bx		lr				// navrat z podprogramu, skok na adresu v lr



    gpio_cnf:
        ldr		r2, =0xf		// konstanta pro nulovani nastaveni bitu 8
        ldr		r0, =gpioc_crh	// kopie adresy gpioc_crh (port configuration register high)
                                // do r0, gpioc_crh je v souboru ini.s
        ldr		r1, [r0]		// nacteni hodnoty z adresy v r0 do r1
        bic		r1, r1, r2 		// nulovani bitu v r2
        mov		r2, #0x1		// vlozeni 1 do r2
        orr		r1, r1, r2		// maskovani, bit 8 nastven jako vystup push-pull v modu 1 (10mhz)
        str		r1, [r0]		// ulozeni konfigurace pco8

        bx		lr				// navrat z podprogramu, skok na adresu v lr


   loop:
        ldr		r2, =gpioc_odr	// kopie adresy brany c odr do r2, gpioc_odr je v souboru ini.s
                //ldr		r2, =codr8        //adresa pro bitove adresovani pc8, zapisuje se pouze jediny bit- nejnizsi bit ze slova
                            //  zkuste zamenit dva predchazejici radky  zamenou stredniku a jeste dale nize
                                // navesti loop hlani smysky
        mov		r1, #0x000			// vlozeni hodnoty 0 do r1

        str		r1, [r2]		// zapis hodnoty v r1 na adresu v r2, tj. nulovani vsech bitu
                                // na brane c (led na pc8 nesviti)

        mov		r0,#konst		// vlozeni do ro hodnoty prodlevy, tj. 100 dekadicky
                                // ro je v tomto pripade jako vstupni parametr podprogramu delay
        bl		delay			// volani podprogramu delay s ulozenim navratove adresy do lr

        mov		r1, #0x100	    // vlozeni hodnoty 0x100 do r1, konstanta pro bit 8
                                // zkuste zamenit radky vyse
                    //       mov		r1, #0x1   	//alternativni zpusob bitovym adresovanim jedineho bitu brany bit banding
                                // zkuste zamenit dva predchazejici radky
        str		r1, [r2]		// zapis hodnoty v r1 na adresu v r2, tj. nastaveni bitu 8
                                // na brane c (led na pc8 sviti), ostatni bity 0-7 a 9-15
                                // jsou nulovany

        mov		r0,#konst		// opet vlozeni hodnoty prodlevy do r0, zde tato isntrukce jiz
                                // neni nutna nebot hodnota v r0 nebyla prepsana, ale takto
                                // je to jistejsi
        bl		delay			// volani podprogramu pro zpozdeni


        b		loop			// skok na navesti loop, tj. nekonecke opakovani smycky (led blika)


   delay:
       //push    {lr}
       //bx      lr

       b wait1
   wait1:
        ldr     r3, =doba     // Load delay constant into r3
        b wait
   wait:
       sub    r3, r3, #1       // Decrement r3
       cmp     r3, #0           // Compare r0 with zero
       bne     wait            // Loop until r3 is zero
       sub    r0, r0, #1       // Decrement r0 (if you are using it as a loop counter)
       cmp     r0, #0           // Compare r0 with zero
       bne     wait1            // Loop until r0 is zero
       //pop     {lr}
       bx      lr


 .end

