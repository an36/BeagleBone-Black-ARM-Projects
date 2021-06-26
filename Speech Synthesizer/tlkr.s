@ Talker on interrupt basis using a Button.
@ This program uses the button on GPIO1_29 to turn the Talker (UART5) on on an interrupt basis.
@ When the button is pushed the program will turn on talker (UART5) which will say
@ a specified sentence on an interrupt basis.
@ Uses: R0-R5 & R10. GPIO1_29. UART5.
@ Abdullah Almarzouq Decemeber 2019


.text
.global _start
.global INT_DIRECTOR
_start:

		LDR R13,=STACK1				@Point to base of stack for SVC mode
		ADD R13,R13,#0X1000			@Point to top of stack
		CPS #0x12					@switch to IRQ mode
		LDR R13,=STACK2				@Point to IRQ stack
		ADD R13,R13,#0X1000			@Point to top of stack
		CPS #0x13					@Back to SVC mode
		
		@Changing to Mode 6 for CTS & RTS and to Mode 4 for TxD & RxD
		LDR R0,=0x44E10000			@Base address of control Module
		MOV R1,#0x00000004			@Value to change to Mode 4 (UART5_TxD)
		STR R1,[R0,#0x8C0]			@Writing to lcd_data8 register
		
		MOV R1,#0x00000024			@Value to change to Mode 4 (UART5_RxD)
		STR R1,[R0,#0x8C4]			@Writing to lcd_data9 register
		
		MOV R1,#0x00000026			@Value to change to Mode 6 (UART5_CTS)
		STR R1,[R0,#0x8D8]			@Writing to lcd_data14 register

		MOV R1,#0x00000006			@Value to change to Mode 6 (UART5_RTS)
		STR R1,[R0,#0x8DC]			@Writing to lcd_data15 register
		
		@Enable clock for GPIO1 module
		MOV R0,#0x02				@Value to enable clock for a GPIO1 module
		LDR R1,=0x44E000AC			@Address of CM_PER_GPIO1_CLKCTRL register
		STR R0,[R1]					@Write 0x02 to register
		
		
		@Detect falling edge on GPIO1_29 and enable to assert POINTRPEND1
		LDR R1,=0x4804C000			@Base Address of GPIO1
		MOV R2,#0x20000000			@Load value for Bit 29
		LDR R3,[R1,#0x14C]			@Read GPIO1_FALLINGDETECT register
		ORR R3,R3,R2				@Modify (set bit 29)
		STR R3,[R1,#0x14C]			@Write back
		STR R2,[R1,#0x34]			@Enable GPIO1_29 request on POINTRPEND1
		
		@Initialize INTC
		LDR R1,=0x48200000			@Base Address of INTC register
		MOV R2,#0x2					@Value to reset INTC
		STR R2,[R1,#0x10]			@Write to INTC Config register
		
		MOV R2,#0x00004000			@Unmask INTC INT #46, UART5 interrupt
		STR R2,[R1,#0xA8]			@Write to INTC_MIRCLEAR1 register
		
		MOV R2,#0x04				@Value to unmask INTC INT 98, GPIOINT1A
		STR R2,[R1,#0xE8]			@Write to INTC_MIR_CLEAR3 register
		
		@Turn on UART5 CLK
		LDR R1,=0x44E00038			@Address of CM_PER_UART5_CLKCTRL
		MOV R2,#0x2					@Value to enable UART5 CLK
		STR R2,[R1]					@Turn on CLK
		
		@Set UART5 to Configuration mode A
		LDR R0,=0x481AA000			@Base address of UART5
		MOV	R1,#0x83				@Value to set UART5 in Mode A
		STR R1,[R0,#0x0C]			@Write to UART5_LCR
		
		@Setting the Baud Rate and 16x divisor for UART5
		MOV R1,#0x4E				@Value to set 38.4Kbps Baud Rate in DLL
		STR R1,[R0,#0x0]			@Write value to DLL register
		MOV R1,#0x00				@Value to set 38.4Kbps Baud Rate in DLH
		STR R1,[R0,#0x4]			@Write value to DLH register
		MOV R1,#0x000				@Value to set 16x divisor
		STR R1,[R0,#0x20]			@Write value to MDR1 register
		
		@Switch UART5 to Operational Mode to enable sources of interrupts
		MOV R1,#0x03				@Value to switch to operational mode
		STR R1,[R0,#0x0C]			@Write to UART5_LCR
		MOV R1,#0x0000				@Value to enable THRIT bit and MODDEMSTSIT bit
		STR R1,[R0,#0x04]			@Write to IER_UART5 register
		
		@Disabling FIFOs
		MOV R1,#0x04				@Value to disable FIFOs
		STR R1,[R0,#0x8]			@Write to FCR register
		
		@Clear off the button request if the button was pressed before the program was running, or from a previous run
		LDR R1,=0x4804C000			@Base address of GPIO1
		MOV R2,#0x20000000			@Value turns off GPIO1_29 Interrupt request and INTC interrupt request
		STR R2,[R1,#0x2C]			@Write to GPIO1_IRQSTATUS_0
		
		@Turn off NEWIRQA bit in INTC_CONTROL, so processor can respond to new IRQ
		LDR R0,=0x48200048			@Address of INTC_CONTROL register
		MOV R1,#0x1					@Value to clear bit 0
		STR R1,[R0]					@Write to INTC_CONTROL register
		
		@Enable IRQ processor in CPSR
		MRS R3,CPSR					@Copy CPSR to R3
		BIC R3,#0x80				@Clear bit 7
		MSR CPSR_c,R3				@Write back to CPSR
		
		MOV R10,#0					@R10 is button counter, if the button if pushed for the first time and LEDs are on then R10=1 otherwise R10=0
		
		@Dead loop to wait for intrrupt
LOOP:	NOP
		B LOOP
		
INT_DIRECTOR:
		STMFD SP!,{R0-R3,LR}		@Push registers on stack
		LDR R0,=0X482000B8			@Address of INTC-PENDING_IRQ1 register
		LDR R1,[R0]					@Read INTC-PENDING_IRQ1 register
		TST R1,#0X00004000			@TEST BIT 14
		BNE UART5_CHK				@ If bit 14=0 then not GPIOINT1A, check if UART5,else
		LDR R0,=0X4804C02C			@Load GPIO1_IRQSTATUS_0 register address
		LDR R1,[R0]					@Read STATUS register
		TST R1,#0x20000000			@Cheack if bit 29 =1
		BNE BUTTON_SVC				@If bit 29 =1, then button is pushed, else
		
		LDR R0,=0x48200048			@Go back. INTC_CONTROL register address
		MOV R1,#0x1					@Value to clear bit 0
		STR R1,[R0]					@Write to INTC_CONTROL register
		
		LDMFD SP!,{R0-R3,LR}		@Restore register
		SUBS PC,LR,#4				@Pass execution to wait LOOP for now
		
PASS_ON: 

		@Enable IRQ processor in CPSR
		MRS R3,CPSR					@Copy CPSR to R3
		BIC R3,#0x80				@Clear bit 7
		MSR CPSR_c,R3				@Write back to CPSR
		
		LDR R0,=0x48200048			@Go back. INTC_CONTROL register address
		MOV R1,#0x1					@Value to clear bit 0
		STR R1,[R0]					@Write to INTC_CONTROL register
		
		LDMFD SP!, {R0-R3,LR}		@Restore registers
		SUBS PC, LR, #4				@Pass execution on to dead loop for now
		
BUTTON_SVC:
		LDR R8,=0xFFFF				@Counter for Delay2 branch loop to fix the debounced button debounce
	Delay2: @this delay loop fixes the problem when the button is acting as if it was being pushed twice
		SUBS R8,R8,#0x01
		BNE Delay2

		MOV R1,#0x20000000			@Value turns off GPIO1_29 Interrupt request and INTC interrupt request
		STR R1,[R0]					@Write to GPIO1_IRQSTATUS_0
		
		@Turn off NEWIRQA bit in INTC_CONTROL, so processor can respond to new IRQ
		LDR R0,=0x48200048			@Address of INTC_CONTROL register
		MOV R1,#0x1					@Value to clear bit 0
		STR R1,[R0]					@Write to INTC_CONTROL register
		
		@Enable IRQ processor in CPSR
		MRS R3,CPSR					@Copy CPSR to R3
		BIC R3,#0x80				@Clear bit 7
		MSR CPSR_c,R3				@Write back to CPSR
		
		LDR R0,=0x481AA004			@Address of IER_UART5
		MOV R1,#0x000A				@Value to enable THR, MODEM and CTS interrupts on IER_UART5
		STR R1,[R0]					@Write to IER_UART5 register
		
		LDMFD SP!,{R0-R3,LR}		@Restore registers
		SUBS PC,LR,#4				@Pass execution on to wait loop
		
UART5_CHK:@Branch to check if CTS# asserted low and THR is empty to be able to send characters to UART5
		LDR R0,=0x481AA018			@Reading UART5_MSR register
		LDR R1,[R0]					@Read value in UART5_MSR register
		TST R1,#0x00000020			@Check if CTS# asserted low by checking bit 4=1
		BEQ THR_MASK				@Jump to mask/disable THR interrupt
		BNE THR_CHK					@if bit 4=1 then check if THR is one by jumping to THR_CHK branch
THR_MASK:@Branch to disable THR interrupt
		LDR R0,=0x481AA014			@Reading LSR_UART register
		LDR R1,[R0]					@Read value in LSR_UART5 register
		TST R1,#0x00000020			@Check if bit 5=1 (THR bit)
		BEQ PASS_ON					@If bit 5=0 then jump to PASS_ON
		LDR R0,=0x481AA004			@Address of IER_UART5
		MOV R1,#0x0					@Value to reset THR interrupt if bit 5=1
		STR R1,[R0]					@Write to IER_UART5 register
		B PASS_ON
THR_CHK:@Bracnh to check if THR is asserted
		LDR R0,=0x481AA014			@Reading LSR_UART register
		LDR R1,[R0]					@Reading LSR_UART value
		TST R1,#0x00000020			@Check if bit 5=1 (THR bit)
		BEQ PASS_ON					@If bit 5=0 then jump to PASS_ON
		BNE VADERV					@Else, if bit 5=1 then jump to VADERV branch

VADERV:@Branch to change the voice to Darth Vader
		CMP R10,#1					@Check if R10=1 or =0
		BPL TLKR_SVC				@if R10=1 then go to TLKR_SVC
		
		LDR R0,=VDR_CHPTR			@Load address of the ommand that changes the voice
		LDR R1,[R0]					@Pointer of the desired character
		LDR R2,=VDR_COUNT1			@Load the address of teh vader command character count
		LDR R3,[R2]					@Load value of counter to R3
		LDRB R4,[R1],#1				@Load character into R4 and increment pointer
		STR R1,[R0]					@Put incremented address back in VDR_CHPTR
		LDR R5,=0x481AA000			@Address of UART5_THR
		STRB R4,[R5]				@Send character to THR
		SUBS R3,R3,#1				@Decrement counter
		STR R3,[R2]					@Store decremented counter value in VDR_COUNT1
		BPL PASS_ON					@If counter value greater than or equal to zero then go back to wait loop
		LDR R3,=VADER				@Reload address of command
		STR R3,[R0]					@Store address in VDR_CHPTR
		LDR R3,=VDR_COUNT2			@Reload value of command count
		LDR R4,[R3]					@Load value of count
		STR R4,[R2]					@Store value of count in VDR_COUNT1
		MOV R10,#1					@Let R10=1 to indicate that the voice has been changed already
		
TLKR_SVC:@Branch to send characters to UART5
		R10=0						@Indicate that the program has been to TLKR_SVC
		LDR R0,=CHAR_PTR			@Send character, R0= address of pointer
		LDR R1,[R0]					@R1= address of desired character in text string
		LDR R2,=CHAR_COUNT1			@R2= address of count store location
		LDR R3,[R2]					@Get current character count value
		LDRB R4,[R1],#1				@Read char to send from string, INC PTR in R1
		STR R1,[R0]					@Put incremented address back in CHAR_PTR location
		LDR R5,=0x481AA000			@Point to UART5_THR
		STRB R4,[R5]				@Write character to THR
		SUBS R3,R3,#1				@Decrement character counter by 1
		STR R3,[R2]					@Store character value counter back in memory
		BPL PASS_ON					@Greater than or equal to zero then go to PASS_ON
		LDR R3,=MESSAGE				@Done, reload. GET address of start of string
		STR R3,[R0]					@Write in CHAR POINTER store locatio in memory
		LDR R3,=CHAR_COUNT2			@Load original number of characters in string again
		LDR R4,[R3]					@Load the count value from the address of CHAR_COUNT2
		STR R4,[R2]					@Write back in to memory for next message send
		LDR R0,=0x481AA004			@Address of IER_UART
		LDRB R1,[R0]				@Read current value in register
		BIC R1,R1,#0x0A				@Clear interrupt bits
		STRB R1,[R0]				@Write byte back to register
		
		B PASS_ON
		
		
		NOP
		
.data
.align 2
MESSAGE:
.byte 0x0d
.ascii "May the force be with you."
.byte 0x0d
VADER:
.byte 0x01
.ascii "1O"
.byte 0x01
.align 2

VDR_COUNT1: .word 4
VDR_COUNT2: .word 4
VDR_CHPTR: .word VADER		@Pointer to the command that changes the voice to darth vader
CHAR_COUNT1: .word 28
CHAR_PTR: .word MESSAGE
CHAR_COUNT2: .word 28
STACK1:		.rept 1024
			.word 0x0000
			.endr
STACK2:		.rept 1024
			.word 0x0000
			.endr
.end