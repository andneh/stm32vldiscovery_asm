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
	main:						// main navesti hlavni smycky programu
		bl		rcc_cnf			// volani podprogramu nastaveni hodinoveho systemu procesoru
								// tj. skok na adresu s navestim rcc_cnf a ulozeni navratove
								// adresy do lr (link register)
		bl		gpio_cnf		// volani podprogramu konfigurace vyvodu procesoru
								// tj. skok na adresu s navestim gpio_cnf
								//*!* poznamka pri pouziti volani podprogramu instrukci bl nesmi
								// byt v obsluze podprogramu tato instrukce jiz pouzita, nebot
								// by doslo k prepsani lr a ztrate navratove adresy ->
								// lze ale pouzit i jine instrukce (push, pop) *!*

		ldr		r2, =gpioc_odr	// kopie adresy brany c odr do r2, gpioc_odr je v souboru ini.s
		mov 	r1,#0			// pomocny registr se stavem led
		mov		r3,#0			// pomocny registr urcujici vetveni programu
		mov		r4,#0			// pomocny softwareov citac zpomalujici blikani
		ldr		r5, =gpioa_idr 	// kopie adresy brany a idr do r5, gpioa_idr je v souboru ini.s
		// idr - input data register

	loop:			
		tst		r3, #0x1	// test jakou branch je zvolena registrem r3
		beq		branch2		// pokud branch2 tak skok na ni, jinak pokracjeme


	branch1:			
		tst		r4, #0x80000
		beq 	zero		//pokud r4 doinkrementovala do 0x80000 pokracujeme, jinak skok na navesti zero
		mov 	r4, #0 		// vynulujeme r4, provede se jednou za 0x80000 tick prociku

		tst 	r1, #0x0100	// otestujeme ktera led byla naposledy rozsvicena
		beq 	modra		// pokud modra, pokracujeme, pokud cervena skok na navesi modra
	
	cervena:			
		mov		r1, #0x0200	// 9. bit do 1
		str		r1, [r2]	// rozsviti cervenou led
		b 		common		// pokracujem testem tlacitka
	
	modra:			
		mov		r1, #0x0100	// 8. bit do 1
		str		r1, [r2]	// rozsviti modrou led
		b 		common		// pokracujem testem tlacitka

	branch2:			
		tst		r4, #0x80000
		beq 	zero		//pokud r4 doinkrementovala do 0x80000 pokracujeme, jinak skok na navesti zero
		mov 	r4, #0		// vynulujeme r4, provede se jednou za 0x80000 tick prociku
		tst 	r1, #0x0300	// otestujeme jesti naposledy svitily obe led nebo zadna
		beq 	obe			// pokud zadna skocime na navesti obe, jinak pokracujeme
	
	zadna:			
		mov		r1, #0		// naposledy svitily obe, musime vynulovat
		str		r1, [r2]	// zhasnuti obou led
		b 		common		// skok na test tlacitka
		
	obe:				
		mov		r1, #0x0300	// minule nesvitily, rozsvitime obe
		str		r1, [r2]	// rozsviceni obou led
		b 		common		// skok na test tlacitka

	zero:			
		add		r4,r4,#1	// test r4 vysel negavni (nedocitano do 0x080000), musime dale ikrementovat


	common:			
		ldr		r0, [r5]	// kopie hodnoty z adresy v r5 do r0
		tst		r0, #0x1	// test jestli je tam 1 = stiskle tlacitko
		beq		loop		// pokud ne, jdeme na zacatek

		mov		r0, #50		// pokud ano, provedeme maly delay kvuli debouncingu
		bl		delay

		tst		r3, #0x1	// test posledni hodoty r3
		beq		test		// pokud byla 0 skocime na navesti test jinak pokracujeme

		mov		r3, #0		// minule byla 1, zapiseme 0
		b 		loop		// skok na zacatek

	test:			
		mov		r3, #1		// minule byla 0, zapiseme 1
		b		loop		// skok na zacatek


		//***************************************************************************************************
		//* jmeno funkce		: rcc_cnf
		//* popis			: konfigurace systemovych hodin a hodin periferii
		//* vstup			: zadny
		//* vystup			: zadny
		//* komentar			: nastaveni pll jako zdroj hodin systemu (24mhz),
		//*  				  a privedeni hodin na branu a a c
		//**************************************************************************************************
	
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
		b no_hse_rdy

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
		ldr		r2, =0x14		// konstanta pro zapnuti hodin pro branu a a c
		orr		r1, r1, r2		// maskovani
		str		r1, [r0]		// ulozeni nove hodnoty

		bx		lr				// navrat z podprogramu, skok na adresu v lr

		//**************************************************************************************************
		//* jmeno funkce		: gpio_cnf
		//* popis			: konfigurace brany a a c
		//* vstup			: zadny
		//* vystup			: zadny
		//* komentar			: nastaveni pc08 a pc09 jako vystup (10mhz), pa0 jako vstup push-pull
		//**************************************************************************************************
	gpio_cnf:
		// navesti zacatku podprogramu
		ldr		r2, =0xff		// konstanta pro nulovani nastaveni bitu 8, 9
		ldr		r0, =gpioc_crh	// kopie adresy gpioc_crh (port configuration register high)
		// do r0, gpioc_crh je v souboru ini.s
		ldr		r1, [r0]		// nacteni hodnoty z adresy v r0 do r1
		bic		r1, r1, r2 		// nulovani bitu v r2
		mov		r2, #0x11		// vlozeni 1 do r2
		orr		r1, r1, r2		// maskovani, bit 8, 9 nastven jako vystup push-pull v modu 1 (10mhz)
		str		r1, [r0]		// ulozeni konfigurace pco9 a pc09

		ldr		r2, =0xf		// konstanta pro nulovani nastaveni bitu 0
		ldr		r0, =gpioa_crl	// kopie adresy gpioa_crl (port configuration register low)
		// do r0, gpioa_crl je v souboru ini.s
		ldr		r1, [r0]		// nacteni hodnoty z adresy v r0 do r1
		bic		r1, r1, r2 		// nulovani bitu v r2
		mov		r2, #0x8		// vlozeni 1 do r2
		orr		r1, r1, r2		// maskovani, bit 0 nastven jako push-pull vstup
		str		r1, [r0]		// ulozeni konfigurace pao0

		bx		lr				// navrat z podprogramu, skok na adresu v lr

	//**************************************************************************************************
	//* jmeno funkce		: delay
	//* popis			: softwarove zpozdeni procesoru
	//* vstup			: r0 = pocet opakovani cyklu spozdeni
	//* vystup			: zadny
	//* komentar			: podprodram zpozdi prubech vykonavani programu
	//**************************************************************************************************
	delay: 									// navesti zacatku podprogramu
		push	{r2, lr}		// ulozeni hodnoty r2 do zasobniku (r2 muze byt editovan)
		// a ulozeni navratove adresy do zasobniku
		b wait1

	wait1:
		ldr		r2, =40000		// vlozeni konstanty pro prodlevu do r2
		b wait

	wait:
		subs	r2, r2, #1		// odecteni 1 od r2,tj. r2 = r2 - 1 a nastaveni priznakoveho registru
		bne		wait			// skok na navesti pri nenulovosti r2 (skok dle priznaku)
		subs	r0, r0, #1
		bne		wait1

		pop		{r2, pc}		// navrat z podprogramu, obnoveni hodnoty r2 ze zasobniku
		// bx      lr				// a navratove adresy do pc

		//**************************************************************************************************
		nop
.end
